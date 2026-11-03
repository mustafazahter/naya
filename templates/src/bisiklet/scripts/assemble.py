"""Adacıkları gruplara göre birleştirir ve her grubu tek bir nesne yapar.

    blender -b islands.blend --python assemble.py -- groups.json çıkış.glb
"""
import json
import math
import sys

import bpy
from collections import defaultdict
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
groups = json.load(open(args[0]))
by_group = defaultdict(list)
for o in list(bpy.context.scene.objects):
    if o.type != 'MESH':
        continue
    if o.name in groups:
        by_group[groups[o.name]].append(o)
    else:
        # Hiçbir parçaya atanmayanlar (lastik yazıları gibi) modelden çıkar.
        bpy.data.objects.remove(o)

def join(objs, name):
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = obj.data.name = name
    # Parçanın kökü kendi merkezinde olsun; parçalara ayırırken buradan döner/kayar.
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    return obj

parts = {name: join(objs, name) for name, objs in by_group.items()}

# Bisikleti zemine oturt, ortala ve ileri yönü +X yap (glTF'te -Z/+X fark etmez,
# viewer kamerayı kendisi yerleştiriyor).
root = bpy.data.objects.new('Bicycle', None)
bpy.context.collection.objects.link(root)
for o in parts.values():
    o.parent = root
root.rotation_euler = (0, 0, math.pi / 2)
bpy.context.view_layer.update()
mins = Vector((1e9, 1e9, 1e9)); maxs = -mins
for o in parts.values():
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        mins = Vector(map(min, mins, w)); maxs = Vector(map(max, maxs, w))
root.location -= Vector(((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z))

# Kaynaktan kalan boş düğümleri sil; sahnede yalnız Bicycle ve parçaları kalsın.
for o in list(bpy.context.scene.objects):
    if o.type == 'EMPTY' and o.name != 'Bicycle':
        bpy.data.objects.remove(o)
bpy.ops.export_scene.gltf(filepath=args[1], export_format='GLB', export_apply=True)
print('parça', len(parts))
