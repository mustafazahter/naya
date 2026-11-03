"""Kaynak modeli kopuk parçalara (adacıklara) böler ve her birinin kutusunu yazar.

    blender -b --python split_islands.py -- kaynak.glb islands.json islands.blend

Kaynaktaki nesneler malzemeye göre birleştirilmiş geldiği için önce böyle
bölüp sonra classify.py ile gerçek parçalara gruplamak gerekiyor.
"""
import json
import sys

import bpy

args = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=args[0])

meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in bpy.context.scene.objects:
    o.select_set(o in meshes)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.separate(type='LOOSE')
bpy.ops.object.mode_set(mode='OBJECT')

islands = []
for o in bpy.context.scene.objects:
    if o.type != 'MESH' or not len(o.data.vertices):
        continue
    co = [v.co for v in o.data.vertices]
    islands.append({
        'n': o.name,
        'm': o.data.materials[0].name if o.data.materials else '-',
        'f': len(o.data.polygons),
        'min': [min(c[i] for c in co) for i in range(3)],
        'max': [max(c[i] for c in co) for i in range(3)],
    })
json.dump(islands, open(args[1], 'w'))
bpy.ops.wm.save_as_mainfile(filepath=args[2])
print('adacık', len(islands))
