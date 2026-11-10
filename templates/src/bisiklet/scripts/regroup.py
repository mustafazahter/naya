"""Konuma göre yapılan gruplamada yanlış parçaya düşen adacıkları düzeltir.

classify.py adacıkları referans noktalarına uzaklıkla parçalara dağıtıyor;
orta göbek çevresinde parçalar iç içe olduğu için bazıları yanlış yere
düştü:
  - sağ pedal arka vites değiştiriciye, arka vites değiştiricinin gövdesi
    kasete,
  - sağ pedal kolu, aynakol cıvataları ve diş parçaları kadroya,
  - ön vites değiştirici kadroya ve kelepçesi aynakola (ayrı bir düğüm
    olmalı).

Bu betik optimize.py çıktısının üstünde çalışır:

    blender -b --python regroup.py -- ../model/product.glb ../model/product.glb

Koordinatlar Blender'ın (Z yukarı) dünya koordinatları; bisiklet X boyunca,
zincir tarafı -Y.
"""
import math
import sys

import bmesh
import bpy

# Orta göbeğin ve arka göbeğin ekseni (x, z).
BB = (-0.153, 0.306)
REAR_HUB = (-0.544, 0.364)


def islands(obj):
    """Nesnenin kopuk parçaları: (köşe indeksleri, merkez, boyut)."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    seen = set()
    result = []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, comp = [v], []
        seen.add(v.index)
        while stack:
            x = stack.pop()
            comp.append(x)
            for e in x.link_edges:
                y = e.other_vert(x)
                if y.index not in seen:
                    seen.add(y.index)
                    stack.append(y)
        pts = [obj.matrix_world @ c.co for c in comp]
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        center = [(lo[i] + hi[i]) / 2 for i in range(3)]
        size = [hi[i] - lo[i] for i in range(3)]
        result.append(({c.index for c in comp}, center, size))
    bm.free()
    return result


def rear_derailleur_body(c, size):
    """Kasete düşmüş arka vites değiştirici gövdesi. Kaset dişlileri arka
    göbeğin çevresinde halka; merkezleri göbekte. Gövde en dış dişlinin de
    dışında (y < -0.072) ve göbekten, en küçük dişlinin yarıçapından
    (~0.025) daha uzakta; askıya bağlandığı cıvata da buna dahil."""
    x, y, z = c
    return y < -0.072 and math.hypot(x - REAR_HUB[0], z - REAR_HUB[1]) > 0.028


def front_derailleur(c, size):
    x, y, z = c
    return -0.24 <= x <= -0.12 and 0.355 <= z <= 0.49 and -0.10 <= y <= -0.035


def derailleur_clamp(c, size):
    """Ön vites değiştiricinin sele borusundaki kelepçesi; aynakolun en
    üst dişinden (z ≈ 0.42) yukarıda kalır."""
    x, y, z = c
    return -0.24 <= x <= -0.12 and 0.43 <= z <= 0.49


def crank_side(c, size):
    """Kadroya düşmüş aynakol cıvataları, diş parçaları ve pedal kolu.

    Zincir tarafında orta göbeğe yakın küçük adacıklar aynakolun; zincir
    kalıbının parçaları da oradan geçtiği için büyük adacıklar alınmaz. Sol
    tarafta aynakol yok, yalnız pedal kolu var.
    """
    x, y, z = c
    near_bb = (
        y < -0.045
        and math.hypot(x - BB[0], z - BB[1]) < 0.135
        and max(size) < 0.06
    )
    crank_arm = abs(y) > 0.07 and 0.27 <= z <= 0.345 and -0.37 <= x <= 0.07
    return near_bb or crank_arm


def split(obj, rules):
    """[rules]: (hedef ad, koşul). Koşulu tutan adacıkları hedefe taşır."""
    for target, test in rules:
        # Her taşımadan sonra köşe numaraları değişir; adacıkları yeniden bul.
        verts = set()
        for ids, center, size in islands(obj):
            if test(center, size):
                verts |= ids
        if not verts:
            continue
        move(obj, verts, target)
        print(f'{obj.name} -> {target}: {len(verts)} köşe')


def move(obj, verts, target):
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    # Seçim köşe, kenar ve yüzde ayrı tutuluyor; düzenleme moduna geçerken
    # önceki taşımadan kalan seçim karışmasın diye üçünü de baştan yaz.
    mesh = obj.data
    for v in mesh.vertices:
        v.select = v.index in verts
    for e in mesh.edges:
        e.select = all(v in verts for v in e.vertices)
    for p in mesh.polygons:
        p.select = all(v in verts for v in p.vertices)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_mode(type='VERT')
    bpy.ops.mesh.separate(type='SELECTED')
    bpy.ops.object.mode_set(mode='OBJECT')
    piece = [o for o in bpy.context.selected_objects if o is not obj][0]

    existing = bpy.data.objects.get(target)
    if existing is None:
        piece.name = target
        piece.data.name = target
        return
    bpy.ops.object.select_all(action='DESELECT')
    piece.select_set(True)
    existing.select_set(True)
    bpy.context.view_layer.objects.active = existing
    bpy.ops.object.join()


def main():
    src, dst = sys.argv[sys.argv.index('--') + 1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    objects = bpy.data.objects

    # Sağ pedal arka vites değiştiricinin içinde: x > -0.45 olan her şey.
    split(objects['drive_derailleur'], [
        ('drive_pedals', lambda c, size: c[0] > -0.45),
    ])
    split(objects['drive_cassette'], [
        ('drive_derailleur', rear_derailleur_body),
    ])
    split(objects['frame'], [
        ('drive_front_derailleur', front_derailleur),
        ('drive_crankset', crank_side),
    ])
    split(objects['drive_crankset'], [
        ('drive_front_derailleur', derailleur_clamp),
    ])

    bpy.ops.export_scene.gltf(
        filepath=dst,
        export_format='GLB',
        export_draco_mesh_compression_enable=True,
        export_draco_mesh_compression_level=7,
    )


main()
