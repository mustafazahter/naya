"""Model incelemesinde yanlış düğümde bulunan parçaları taşır, yeni düğümler
ayırır ve üst üste binen yüzleri siler.

regroup.py'den sonra, onun çıktısı üstünde çalışır:

    blender -b --python fix_nodes.py -- ../model/product.glb ../model/product.glb

İncelemede bulunanlar (her düğüm tek başına turuncu çizilerek bakıldı):
  - Çabuk sökme mandalları ön ve arka fren düğümündeydi, arka mandalın
    somunu kasette; göbeğe taşınır.
  - Vites askısı kasetteydi; arka vites değiştiriciye taşınır.
  - Ön vites değiştiricinin gövdesi, pimleri ve kelepçe şeridi kadroda,
    cıvata başları aynakoldaydı; ön vites değiştiriciye taşınır.
  - Aynakolun bir cıvatası ve orta aynanın diş parçaları ön vites
    değiştiricideydi; aynakola geri döner.
  - Aynakolda kalan kadro boyası parçaları kadroya döner.
  - Sele borusu kelepçesinin cıvatası, somunu ve sele borusunun başı
    kadrodaydı; sele borusuna taşınır.
  - Vites ve fren kabloları kadroya, gidona, çatala, kasete ve ön frene
    dağılmıştı; `cables_shift` ve `cables_brake` düğümlerine toplanır.
  - İç lastik janta, sibop tellere düşmüştü; `wheel_*_tube` düğümlerine
    ayrılır.
  - Fren diskleri kaliperle aynı düğümdeydi; `brakes_*_rotor` düğümlerine
    ayrılır.
  - Orta göbek aynakolla aynı düğümdeydi; `drive_bottom_bracket` düğümüne
    ayrılır.

Koordinatlar Blender'ın dünya koordinatları (Z yukarı): bisiklet X
boyunca (ön +X), zincir tarafı -Y.
"""
import math
import sys

import bmesh
import bpy

FRONT_HUB = (0.544, 0.351)   # (x, z)
REAR_HUB = (-0.544, 0.364)
BB = (-0.153, 0.306)


def dist(c, point):
    return math.hypot(c[0] - point[0], c[2] - point[1])


def bodies(obj, materials=None):
    """Nesnenin katı gövdeleri: yakın köşeler birleştirilince birbirine
    bağlanan yüz kümeleri. [(yüz indeksleri, merkez, boyut, malzemeler)].
    [materials] verilirse yalnız o malzemelerin yüzleri sayılır."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    orig = bm.faces.layers.int.new('orig')
    for f in bm.faces:
        f[orig] = f.index
    if materials:
        names = [m.name for m in obj.data.materials]
        drop = [f for f in bm.faces if names[f.material_index] not in materials]
        bmesh.ops.delete(bm, geom=drop, context='FACES')
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0003)
    mw = obj.matrix_world
    seen, result = set(), []
    for f in bm.faces:
        if f.index in seen:
            continue
        stack, comp = [f], []
        seen.add(f.index)
        while stack:
            x = stack.pop()
            comp.append(x)
            for e in x.edges:
                for y in e.link_faces:
                    if y.index not in seen:
                        seen.add(y.index)
                        stack.append(y)
        pts = [mw @ v.co for g in comp for v in g.verts]
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        mats = {obj.data.materials[g.material_index].name for g in comp}
        result.append(({g[orig] for g in comp},
                       [(a + b) / 2 for a, b in zip(lo, hi)],
                       [b - a for a, b in zip(lo, hi)], mats))
    bm.free()
    return result


def plan(obj, rule, materials=None):
    """[rule](merkez, boyut, malzemeler, yüz sayısı, en büyük mü) → hedef
    düğüm ya da None. Hedefe göre yüz indeksleri."""
    found = bodies(obj, materials)
    largest = max(len(b[0]) for b in found)
    moves = {}
    for faces, c, s, mats in found:
        target = rule(c, s, mats, len(faces), len(faces) == largest)
        if target:
            moves.setdefault(target, set()).update(faces)
    return moves


def move(obj, faces, target):
    """Yüzleri hedef düğüme taşır; hedef yoksa yeni düğüm olur."""
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    mesh = obj.data
    for p in mesh.polygons:
        p.select = p.index in faces
    for e in mesh.edges:
        e.select = False
    for v in mesh.vertices:
        v.select = False
    for p in mesh.polygons:
        if p.select:
            for i in p.vertices:
                mesh.vertices[i].select = True
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_mode(type='FACE')
    bpy.ops.mesh.separate(type='SELECTED')
    bpy.ops.object.mode_set(mode='OBJECT')
    piece = [o for o in bpy.context.selected_objects if o is not obj][0]
    print(f'{obj.name} -> {target}: {len(faces)} yüz')
    existing = bpy.data.objects.get(target)
    if existing is None:
        piece.name = piece.data.name = target
        bpy.ops.object.select_all(action='DESELECT')
        piece.select_set(True)
        bpy.context.view_layer.objects.active = piece
        bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
        return
    bpy.ops.object.select_all(action='DESELECT')
    piece.select_set(True)
    existing.select_set(True)
    bpy.context.view_layer.objects.active = existing
    bpy.ops.object.join()


def apply(name, rule, materials=None):
    obj = bpy.data.objects[name]
    moves = plan(obj, rule, materials)
    # Her taşımadan sonra yüz numaraları değişir; hedefi yüz özniteliğine
    # yazıp her seferinde oradan oku.
    targets = sorted(moves)
    dest = obj.data.attributes.new('dest', 'INT', 'FACE')
    for i, target in enumerate(targets, 1):
        for f in moves[target]:
            dest.data[f].value = i
    for i, target in enumerate(targets, 1):
        values = obj.data.attributes['dest'].data
        faces = {p.index for p in obj.data.polygons if values[p.index].value == i}
        move(obj, faces, target)
    for o in bpy.data.objects:
        if o.type == 'MESH' and 'dest' in o.data.attributes:
            o.data.attributes.remove(o.data.attributes['dest'])


def remove_duplicates(obj):
    """Aynı yerde, aynı büyüklükte ve aynı yönde iki yüz varsa birini siler;
    kaynak CAD modelinde bazı yüzler iki kez var ve ışıkta titreşiyor."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    seen, extra = set(), []
    for f in bm.faces:
        c, n = f.calc_center_median(), f.normal
        key = (round(c.x, 5), round(c.y, 5), round(c.z, 5),
               round(f.calc_area() * 1e7), round(abs(n.x), 2),
               round(abs(n.y), 2), round(abs(n.z), 2))
        if key in seen:
            extra.append(f)
        else:
            seen.add(key)
    if extra:
        bmesh.ops.delete(bm, geom=extra, context='FACES')
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces],
                         context='VERTS')
        bm.to_mesh(obj.data)
        print(f'{obj.name}: {len(extra)} çift yüz silindi')
    bm.free()


# --- Kurallar ---------------------------------------------------------------

def front_brake(c, s, mats, n, largest):
    # Mandal, kamı ve pulu: göbek ekseninde, diskin dışında (y > 0.055).
    if dist(c, FRONT_HUB) < 0.04 and c[1] > 0.055:
        return 'wheel_front_hub'
    # Kaliperden yukarı çıkan fren teli.
    if mats == {'AppC74'} and s[2] > 0.1:
        return 'cables_brake'
    # Disk ve cıvataları göbeğe ortalı.
    if dist(c, FRONT_HUB) < 0.03:
        return 'brakes_front_rotor'
    return None


def rear_brake(c, s, mats, n, largest):
    # Mandal ve kamı (y > 0.07) ile göbekten geçen mil (Y boyunca uzun).
    if dist(c, REAR_HUB) < 0.04 and (c[1] > 0.07 or s[1] > 0.05):
        return 'wheel_rear_hub'
    if dist(c, REAR_HUB) < 0.03:
        return 'brakes_rear_rotor'
    return None


def cassette(c, s, mats, n, largest):
    if mats == {'App82'}:
        return 'cables_shift'
    if c[1] < -0.075:
        # Mil ucundaki somun göbeğin; altındaki plaka vites askısı.
        return 'wheel_rear_hub' if dist(c, REAR_HUB) < 0.012 else \
            'drive_derailleur'
    return None


def front_derailleur(c, s, mats, n, largest):
    # Kafesin altındaki aynakol cıvatası ve orta aynanın diş parçaları.
    if not largest and c[2] < 0.385:
        return 'drive_crankset'
    return None


def crankset(c, s, mats, n, largest):
    if c[2] > 0.41:
        return 'drive_front_derailleur'
    if mats == {'App2E3'}:
        return 'frame'
    # Orta göbek: yataklar ve mil; eksende, kısa, pedal kollarının içinde.
    if (dist(c, BB) < 0.025 and abs(c[1]) < 0.06 and s[0] < 0.05
            and s[2] < 0.05):
        return 'drive_bottom_bracket'
    return None


def frame(c, s, mats, n, largest):
    if largest or 'App2E3' in mats:
        return None
    if -0.20 <= c[0] <= -0.13 and 0.415 <= c[2] <= 0.47:
        return 'drive_front_derailleur'
    if -0.25 <= c[0] <= -0.19 and c[2] > 0.685:
        return 'seatpost'
    return None


def frame_cables(c, s, mats, n, largest):
    # Arka fren kablosu sol tarafta (+Y) arka kalipere iner; diğerleri vites.
    return 'cables_brake' if c[1] > 0.03 else 'cables_shift'


def handlebar_cables(c, s, mats, n, largest):
    if max(s) < 0.05:
        return None   # kollardaki kablo yuvaları
    # Sağ kollardan çıkan iki kablodan arka fren kablosu sol tarafa geçer.
    if s[1] > 0.18:
        return 'cables_brake'
    return 'cables_shift'


def spokes(tube):
    def rule(c, s, mats, n, largest):
        # Sibop jantın içinden göbeğe doğru uzanan kısa parça; tellerde bu
        # malzemelerden başka bir şey yok.
        return None if max(s) > 0.06 else tube
    return rule


def main():
    src, dst = sys.argv[sys.argv.index('--') + 1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)

    apply('brakes_front', front_brake)
    apply('brakes_rear', rear_brake)
    apply('drive_cassette', cassette)
    apply('drive_front_derailleur', front_derailleur)
    apply('drive_crankset', crankset)
    apply('frame', frame)
    apply('frame', frame_cables, {'App82', 'App52'})
    apply('handlebar', handlebar_cables, {'App82', 'App52'})
    apply('fork', lambda *a: 'cables_brake', {'App52'})
    for side in ('front', 'rear'):
        apply(f'wheel_{side}_rim', lambda *a, t=f'wheel_{side}_tube': t,
              {'AppC8'})
        apply(f'wheel_{side}_spokes', spokes(f'wheel_{side}_tube'),
              {'App5D4', 'AppC74'})

    for o in bpy.data.objects:
        if o.type == 'MESH':
            remove_duplicates(o)

    bpy.ops.export_scene.gltf(
        filepath=dst,
        export_format='GLB',
        export_draco_mesh_compression_enable=True,
        export_draco_mesh_compression_level=7,
    )


main()
