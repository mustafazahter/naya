"""DM'lerdeki çizimleri (ICN) modelden üretir.

Bisiklettekiyle aynı teknik çizim görünümü: beyaz zemin, gri, kontur ve
boşluk gölgesi; konusu olan parçalar turuncu. Bir görünüşte araya giren
parçalar (kaput, tekerlek) gizlenir.

    blender -b --python render_icn.py -- ../model/product.glb cikti/

Çıkan PNG'ler JPEG'e çevrilip csdb/ altına ICN adıyla konur:

    sips -s format jpeg -s formatOptions 82 cikti/00001.png --out \
        ../csdb/ICN-NAYACAR-AAA-D000000-0-NAYA0-00001-A-001-01.JPG
"""
import sys

import bpy
import mathutils

GREY = (0.82, 0.84, 0.87, 1)
ORANGE = (0.85, 0.45, 0.12, 1)

ENGINE = [
    'engine_block', 'engine_head', 'engine_head_gasket', 'engine_head_cover',
    'engine_camshafts', 'engine_timing_chain', 'engine_timing_cover',
    'engine_crankshaft', 'engine_pistons', 'engine_rods', 'engine_oil_pan',
    'engine_oil_pump', 'engine_oil_filter', 'engine_water_pump',
    'engine_crank_pulley', 'engine_intake', 'engine_exhaust_manifold',
    'engine_coils', 'engine_spark_plugs',
]

# (dosya, bakılan yer, uzaklık, bakış yönü, vurgulananlar, gösterilenler,
#  gizlenenler). Bakılan yer parça listesi, bir nokta ya da None (bütün
#  araç); gösterilenler None ise hepsi.
# Blender'da aracın önü -Y, solu +X yönünde.
VIEWS = [
    ('00001', None, 8.5, (1, 0.05, 0.12), (), None, ()),
    ('00002', ['radiator', 'battery', 'brake_booster'], 2.9,
     (0.35, -0.7, 1), ('battery', 'air_filter', 'coolant_tank',
                       'engine_oil_filter', 'brake_booster'),
     None, ('hood', 'body', 'fender_l', 'fender_r')),
    ('00003', ENGINE, 1.25, (0.6, -1, 0.55), (), ENGINE, ()),
    ('00004', (0.62, -1.29, 0.36), 1.3, (1, -0.3, 0.3),
     ('brake_front', 'strut_front', 'control_arm_front', 'driveshaft_front'),
     None, ('wheel_fl', 'fender_l', 'bumper_front', 'door_fl', 'body')),
    ('00005', ['engine_coils'], 0.75, (0.4, -1, 0.9),
     ('engine_coils', 'engine_spark_plugs'), ENGINE, ('engine_head_cover',)),
    ('00006', ['wheel_fl'], 1.3, (1, -0.15, 0.12), ('wheel_fl',), None, ()),
]


def main():
    argv = sys.argv[sys.argv.index('--') + 1:]
    glb, out = argv
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
    camera_data.lens = 60
    camera = bpy.data.objects.new('kamera', camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera

    def center(names):
        points = []
        for name in names:
            o = objects[name]
            points += [o.matrix_world @ mathutils.Vector(c) for c in o.bound_box]
        return [(min(p[i] for p in points) + max(p[i] for p in points)) / 2
                for i in range(3)]

    for name, target, distance, direction, highlight, shown, hidden in VIEWS:
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


main()
