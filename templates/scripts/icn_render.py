"""DM'lerdeki çizimleri (ICN) modelden üreten ortak Blender kodu.

Bisikletteki ve Corolla'daki teknik çizim görünümü: beyaz zemin, gri,
kontur ve boşluk gölgesi; konusu olan parçalar turuncu. Her şablonun
`scripts/render_icn.py` dosyası görünüşleri tanımlar ve `render` çağırır.

Bir görünüş: (dosya, bakılan yer, uzaklık, bakış yönü, vurgulananlar,
gösterilenler, gizlenenler). Bakılan yer parça listesi, bir nokta ya da
None (bütün model); gösterilenler None ise hepsi.
"""
import bpy
import mathutils

GREY = (0.82, 0.84, 0.87, 1)
ORANGE = (0.85, 0.45, 0.12, 1)


def render(glb, out, views, lens=60):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=glb)
    objects = {o.name: o for o in bpy.data.objects if o.type == 'MESH'}

    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 800
    scene.view_settings.view_transform = 'Standard'
    shading = scene.display.shading
    shading.light = 'STUDIO'
    shading.color_type = 'OBJECT'
    shading.show_cavity = True
    shading.cavity_type = 'BOTH'
    shading.show_object_outline = True
    shading.object_outline_color = (0.1, 0.12, 0.15)
    shading.background_type = 'VIEWPORT'
    shading.background_color = (1, 1, 1)

    camera_data = bpy.data.cameras.new('kamera')
    camera_data.lens = lens
    camera_data.clip_end = 500
    camera = bpy.data.objects.new('kamera', camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera

    def center(names):
        points = []
        for name in names:
            o = objects[name]
            points += [o.matrix_world @ mathutils.Vector(c)
                       for c in o.bound_box]
        return [(min(p[i] for p in points) + max(p[i] for p in points)) / 2
                for i in range(3)]

    for name, target, distance, direction, highlight, shown, hidden in views:
        for part, o in objects.items():
            o.color = ORANGE if part in highlight else GREY
            o.hide_render = part in hidden or (
                shown is not None and part not in shown)
        if isinstance(target, tuple):
            t = mathutils.Vector(target)
        else:
            t = mathutils.Vector(center(target or objects))
        camera.location = t + mathutils.Vector(direction).normalized() * distance
        camera.rotation_euler = (t - camera.location).to_track_quat(
            '-Z', 'Y').to_euler()
        scene.render.filepath = f'{out}/{name}.png'
        bpy.ops.render.render(write_still=True)
