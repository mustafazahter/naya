"""DM'lerdeki çizimleri (ICN) modelden üretir.

Teknik çizim görünümü: beyaz zemin, tek renk gri, kontur ve boşluk gölgesi.
Konusu olan parçalar turuncu.

    blender -b --python render_icn.py -- ../model/product.glb cikti/

Çıkan PNG'ler JPEG'e çevrilip csdb/ altına ICN adıyla konur:

    sips -s format jpeg -s formatOptions 82 00001.png --out \
        ../csdb/ICN-NAYABIKE-AAA-D000000-0-NAYA0-00001-A-001-01.JPG
"""
import sys

import bpy
import mathutils

GREY = (0.82, 0.84, 0.87, 1)
ORANGE = (0.85, 0.45, 0.12, 1)

# (dosya, bakılan parçalar, uzaklık, bakış yönü, vurgulanan parçalar)
VIEWS = [
    ('00001', None, 3.2, (0, -1, 0.12), ()),
    ('00002', [(-0.3, -0.1, 0.33)], 1.15, (0.1, -1, 0.15),
     ('drive_chain', 'drive_crankset', 'drive_cassette', 'drive_derailleur')),
    ('00003', ['brakes_front'], 0.55, (0.15, 1, 0.15), ('brakes_front',)),
    ('00004', ['drive_derailleur'], 0.55, (0.2, -1, 0.1), ('drive_derailleur',)),
    ('00005', ['wheel_rear_tire'], 1.6, (0.05, -1, 0.1),
     ('wheel_rear_tire', 'wheel_rear_rim', 'wheel_rear_spokes', 'wheel_rear_hub')),
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

    for name, target, distance, direction, highlight in VIEWS:
        if target is None:
            target = center(objects)
        elif isinstance(target[0], str):
            target = center(target)
        else:
            target = target[0]
        for part, o in objects.items():
            o.color = ORANGE if part in highlight else GREY
        t = mathutils.Vector(target)
        camera.location = t + mathutils.Vector(direction).normalized() * distance
        camera.rotation_euler = (t - camera.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = f'{out}/{name}.png'
        bpy.ops.render.render(write_still=True)


main()
