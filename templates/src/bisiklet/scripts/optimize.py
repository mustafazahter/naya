"""Gruplanmış modeli telefona uygun hale getirir: ağır parçaları sadeleştirir,
Draco ile sıkıştırarak yazar.

    blender -b --python optimize.py -- giriş.glb çıkış.glb
"""
import sys

import bpy
args = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=args[0])
total_before = total_after = 0
for o in bpy.context.scene.objects:
    if o.type != 'MESH':
        continue
    # three.js düğüm adındaki noktaları siler; alt çizgiyle yaz.
    o.name = o.name.replace('.', '_')
    faces = len(o.data.polygons)
    total_before += faces
    # Küçük parçalara dokunma; büyükleri ~30 bin üçgene doğru indir.
    if faces > 40000:
        mod = o.modifiers.new('decimate', 'DECIMATE')
        mod.ratio = max(0.35, 30000 / faces)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=mod.name)
    total_after += len(o.data.polygons)
# Kaynaktan kalan boş düğümleri sil; sahnede yalnız Bicycle ve parçaları kalsın.
for o in list(bpy.context.scene.objects):
    if o.type == 'EMPTY' and o.name != 'Bicycle':
        bpy.data.objects.remove(o)
bpy.ops.export_scene.gltf(
    filepath=args[1],
    export_format='GLB',
    export_draco_mesh_compression_enable=True,
    export_draco_mesh_compression_level=7,
)
print('yüz', total_before, '->', total_after)
