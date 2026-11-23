"""Leopard 2A6 modelini kaynak .blend dosyasından kurar.

Kaynak model dıştan ayrıntılı ama birkaç büyük nesneden oluşuyor (gövde,
kule, paletler) ve içi boş: motor, şanzıman, soğutma yok. Paletler,
yürüyen takım tekerlekleri ve avaralar modifier'larla (array, curve,
mirror) çoğaltılmış. Bu betik:

1. Modifier'ları uygular, nesneleri dünya koordinatlarına sabitler.
2. Büyük nesneleri birbirine değmeyen parçalara (adacık) ayırır ve
   konumlarına göre uygulamanın düğümlerine toplar (`track_l`, `main_gun`...).
   Düğüm adı `map/parts.json`'daki `meshNodes` ile aynı.
3. Kaynakta olmayan güç paketini basit şekillerle modeller: motor,
   şanzıman ve son dişliler, radyatörler, fanlar, hava filtreleri, yakıt
   tankları, akü ve egzoz. Bunlar temsilidir, ölçüleri gerçek değildir.
4. Malzemeleri düğüme göre yeniden renklendirir.
5. Gerçek ölçeğe getirir, yere oturtur ve Draco ile sıkıştırıp yazar.

    blender -b --python build_model.py -- Leopard_2A6.blend ../model/product.glb

Kaynakta Z yukarı, tankın önü -Y, solu +X yönünde. Kaynak model gerçeğin
yaklaşık 2,26 katı büyük; ölçek, paletler dahil 3,75 m'lik genişlikten.
"""
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

SCALE = 0.443

# --- Malzemeler -----------------------------------------------------------

PALETTE = {
    'armor': ((0.20, 0.23, 0.14), 0.75, 0.0),
    'armor_dark': ((0.11, 0.12, 0.08), 0.8, 0.0),
    'rubber': ((0.03, 0.03, 0.03), 0.9, 0.0),
    'track': ((0.16, 0.15, 0.14), 0.6, 0.7),
    'steel': ((0.42, 0.43, 0.44), 0.4, 1.0),
    'engine': ((0.10, 0.11, 0.12), 0.5, 0.6),
    'alu': ((0.62, 0.63, 0.65), 0.4, 1.0),
    'filter': ((0.55, 0.45, 0.20), 0.7, 0.0),
    'fuel': ((0.30, 0.32, 0.22), 0.6, 0.2),
    'battery': ((0.06, 0.06, 0.07), 0.6, 0.0),
    'radiator': ((0.35, 0.36, 0.37), 0.5, 0.8),
    'glass': ((0.25, 0.35, 0.40), 0.05, 0.0),
    'lens': ((0.9, 0.92, 0.95), 0.05, 0.0),
    'amber': ((0.9, 0.45, 0.05), 0.2, 0.0),
    'tail': ((0.55, 0.02, 0.02), 0.15, 0.0),
}

# Kaynak malzeme adındaki parça → renk. Listede yoksa düğümün rengi.
SOURCE_MATERIALS = [
    ('Rubber', 'rubber'), ('rubber', 'rubber'), ('BlackGlass', 'glass'),
    ('orange', 'amber'), ('red_l', 'tail'), ('wheel_red', 'steel'),
    ('vida', 'steel'), ('wire', 'steel'), ('Gun', 'armor_dark'),
]

# Düğümün temel rengi; listede olmayan düğüm `armor`.
NODE_COLORS = {
    'track_l': 'track', 'track_r': 'track',
    'sprocket_l': 'track', 'sprocket_r': 'track',
    'suspension_l': 'steel', 'suspension_r': 'steel',
    'optics': 'armor_dark', 'machine_gun': 'armor_dark',
    'headlights': 'lens', 'taillights': 'tail',
    'engine': 'engine', 'transmission': 'alu', 'cooling_fans': 'steel',
    'radiators': 'radiator', 'air_filters': 'filter', 'fuel_tanks': 'fuel',
    'batteries': 'battery', 'exhaust': 'steel',
}


def material(key, cache={}):
    if key in cache:
        return cache[key]
    color, roughness, metallic = PALETTE[key]
    m = bpy.data.materials.new(f'naya_{key}')
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    cache[key] = m
    return m


def recolor(obj, default):
    for slot in obj.material_slots:
        name = slot.material.name if slot.material else ''
        key = next((k for p, k in SOURCE_MATERIALS if p in name), default)
        slot.material = material(key)
    if not obj.material_slots:
        obj.data.materials.append(material(default))


# --- Kaynak parçaların düğümleri ---------------------------------------------
#
# Her kural bir adacığın (merkez, boyut, malzeme adları) bilgisinden düğüm
# adını döndürür. Koordinatlar kaynak ölçeğinde.

LIGHTS = ('orange_light', 'red_ligh', 'BlackGlass')


def side(c, left, right):
    return left if c.x > 0 else right


def light(c, s, mats):
    # Kaynakta lamba camı malzemesi periskoplarda da var; yalnız ön ve arka
    # uçtakiler lamba.
    if any(m.startswith(LIGHTS) for m in mats) and max(s) < 1.0:
        if c.y < -5.5:
            return 'headlights'
        if c.y > 9.0:
            return 'taillights'
    return None


def hull_rule(c, s, mats):
    if abs(c.x) > 3.55 and 1.6 < c.z < 3.7 and s.x < 0.6 and c.y > -6.5:
        return side(c, 'side_skirt_l', 'side_skirt_r')
    return light(c, s, mats) or 'hull'


def fittings_rule(c, s, mats):
    """Çamurluklar, yan etekler, motor güvertesi ızgaraları, lambalar."""
    if s.x > 1.5 and s.y > 1.5 and s.z < 0.1 and c.y > 6.5 and abs(c.x) < 2.5:
        return 'engine_deck'
    if abs(c.x) > 3.6 and 1.0 < c.z < 3.6 and s.y < 3.0 and c.y > -6.0:
        return side(c, 'side_skirt_l', 'side_skirt_r')
    return light(c, s, mats) or 'hull'


def wheels_rule(c, s, mats):
    if abs(c.x) > 2.55:
        return side(c, 'road_wheels_l', 'road_wheels_r')
    return side(c, 'suspension_l', 'suspension_r')


def gun_rule(c, s, mats):
    # Namlu, duman tahliye tüpü, namlu ağzı ve kalkan kulenin önünde,
    # ortada.
    if abs(c.x) < 0.75 and s.x < 1.2 and c.y < -6.0:
        return 'main_gun'
    return 'turret'


def turret_side_rule(c, s, mats):
    if 2.4 < abs(c.x) < 3.5 and 2.0 < c.y < 5.5 and 4.5 < c.z < 5.9:
        return 'smoke_dischargers'
    return 'turret'


def roof_rule(c, s, mats):
    # Yükleyici kapağındaki makineli tüfek ve kundağı.
    if (c.x > 0.6 and 'Gun' in mats) or (abs(c.x - 1.75) < 0.4 and abs(c.y - 1.3) < 1.5
                         and c.z > 5.95):
        return 'machine_gun'
    # Nişancı ve komutan nişan optikleri kulenin ön sağ tavanında.
    if c.z > 5.2 and c.y < 0 and c.x < -0.6:
        return 'optics'
    return 'turret'


SOURCE_RULES = {
    'Tank_Base': hull_rule,
    'Tank_Base.001': hull_rule,
    'Box72': hull_rule,
    'Cylinder303': hull_rule,
    'Cylinder304': hull_rule,
    'Cylinder305': hull_rule,
    'Cylinder80': hull_rule,
    'Circle.003_Circle.020': fittings_rule,
    'Circle.009_Circle.013': wheels_rule,
    'Cube.000_Cube.000': lambda c, s, m: side(c, 'track_l', 'track_r'),
    'Circle.002': lambda c, s, m: side(c, 'idler_l', 'idler_r'),
    'Tube02.001': lambda c, s, m: side(c, 'sprocket_l', 'sprocket_r'),
    'Up1': gun_rule,
    'Up2': turret_side_rule,
    'Up3': roof_rule,
}

# Üst gövde plakası tek parça; motor güvertesi (arka) yüz yüz ayrılır.
DECK_SPLIT = ('Box0ewfef', lambda c: 'engine_deck'
              if c.y > 4.4 and c.z > 3.3 and abs(c.x) < 2.5 else 'hull')


# --- Yardımcılar ------------------------------------------------------------

def evaluated_copy(obj, depsgraph):
    """Modifier'ları uygulanmış, dünya koordinatlarında yeni bir nesne."""
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    mesh.transform(obj.matrix_world)
    copy = bpy.data.objects.new(obj.name + '_eval', mesh)
    bpy.context.scene.collection.objects.link(copy)
    return copy


def islands(obj):
    """Adacıklar: (yüz listesi, kutu merkezi, kutu boyutu, malzeme adları)."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    names = [s.material.name if s.material else '' for s in obj.material_slots]
    seen = set()
    result = []
    for face in bm.faces:
        if face.index in seen:
            continue
        stack, group = [face], []
        seen.add(face.index)
        while stack:
            f = stack.pop()
            group.append(f)
            for edge in f.edges:
                for other in edge.link_faces:
                    if other.index not in seen:
                        seen.add(other.index)
                        stack.append(other)
        points = [v.co for f in group for v in f.verts]
        lo, hi = Vector(map(min, *points)), Vector(map(max, *points))
        mats = {names[f.material_index] for f in group if names}
        result.append(([f.index for f in group], (lo + hi) / 2, hi - lo, mats))
    bm.free()
    return result


def face_centers(obj):
    return [p.center.copy() for p in obj.data.polygons]


def take_faces(obj, faces, name):
    """[obj]'nin [faces] yüzlerini yeni bir nesneye kopyalar."""
    copy = obj.copy()
    copy.data = obj.data.copy()
    bpy.context.scene.collection.objects.link(copy)
    keep = set(faces)
    bm = bmesh.new()
    bm.from_mesh(copy.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep],
                     context='FACES')
    bm.to_mesh(copy.data)
    bm.free()
    copy.name = name
    return copy


def join(objects, name):
    objects = [o for o in objects if o and o.type == 'MESH']
    with bpy.context.temp_override(active_object=objects[0],
                                   selected_editable_objects=objects):
        bpy.ops.object.join()
    result = objects[0]
    result.name = name
    result.data.name = name
    return result


def bake(obj):
    obj.data = obj.data.copy()
    obj.data.transform(obj.matrix_world)
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    return obj


def solid(kind, location, size, rotation=(0, 0, 0), key='engine', **kw):
    """Kutu ya da silindir; dünya koordinatlarına sabitlenmiş."""
    if kind == 'box':
        bpy.ops.mesh.primitive_cube_add(size=1, location=location,
                                        rotation=rotation)
        obj = bpy.context.active_object
        obj.scale = size
    else:
        radius, depth = size
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=kw.get('vertices', 32), radius=radius, depth=depth,
            location=location, rotation=rotation)
        obj = bpy.context.active_object
    bpy.context.view_layer.update()
    bake(obj)
    obj.data.materials.append(material(key))
    return obj


AXIS_X = (0, math.pi / 2, 0)
AXIS_Y = (math.pi / 2, 0, 0)


def pipe(points, radius, key='steel'):
    pieces = []
    for a, b in zip(points, points[1:]):
        a, b = Vector(a), Vector(b)
        d = b - a
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius,
                                            depth=d.length,
                                            location=(a + b) / 2)
        p = bpy.context.active_object
        p.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        bake(p)
        p.data.materials.append(material(key))
        pieces.append(p)
    return pieces


# --- Güç paketi (kaynakta yok) ---------------------------------------------
#
# Motor bölmesi gövdenin arkasında, kaynak ölçeğinde y = 4,6 ... 10,4.
# Şanzıman arka yürütücü dişlilerin hizasında (y = 8,6); fanlar motor
# güvertesindeki iki yuvarlak ızgaranın altında.

def powerpack():
    nodes = {}
    # V12 motor: karter, blok, açılı iki silindir sırası, turbolar, kasnak.
    banks = [solid('box', (side * 0.62, 6.3, 2.75), (0.85, 3.0, 0.75),
                   rotation=(0, side * math.radians(30), 0))
             for side in (1, -1)]
    heads = [solid('box', (side * 0.85, 6.3, 3.12), (0.55, 3.1, 0.18),
                   rotation=(0, side * math.radians(30), 0), key='alu')
             for side in (1, -1)]
    nodes['engine'] = join([
        solid('box', (0, 6.3, 2.0), (1.3, 3.2, 1.1)),
        solid('box', (0, 6.3, 1.32), (1.05, 3.0, 0.3)),
        *banks, *heads,
        solid('cyl', (0, 4.62, 2.0), (0.45, 0.18), rotation=AXIS_Y,
              key='steel'),
        *[solid('cyl', (side * 1.42, 7.75, 2.95), (0.3, 0.45),
                rotation=AXIS_X, key='steel') for side in (1, -1)],
    ], 'engine')

    # Şanzıman ve iki yanda son dişliler (yürütücü dişlilere bağlanır).
    nodes['transmission'] = join([
        solid('box', (0, 8.65, 2.0), (2.7, 1.15, 1.3), key='alu'),
        solid('box', (0, 8.65, 1.3), (2.2, 1.0, 0.25), key='alu'),
        *[solid('cyl', (side * 1.95, 8.61, 2.09), (0.48, 0.38),
                rotation=AXIS_X, key='alu') for side in (1, -1)],
    ], 'transmission')

    nodes['radiators'] = join([
        solid('box', (side * 1.25, 8.1, 3.15), (1.9, 1.9, 0.28),
              key='radiator') for side in (1, -1)], 'radiators')
    fans = []
    for side in (1, -1):
        fans.append(solid('cyl', (side * 1.25, 8.03, 3.62), (0.95, 0.12),
                          vertices=48, key='steel'))
        fans.append(solid('cyl', (side * 1.25, 8.03, 3.62), (0.22, 0.3),
                          key='engine'))
        for i in range(7):
            angle = i * 2 * math.pi / 7
            fans.append(solid(
                'box', (side * 1.25 + 0.5 * math.cos(angle),
                        8.03 + 0.5 * math.sin(angle), 3.72),
                (0.75, 0.22, 0.03), rotation=(0.35, 0, angle), key='steel'))
    nodes['cooling_fans'] = join(fans, 'cooling_fans')

    nodes['air_filters'] = join([
        solid('box', (side * 1.62, 5.6, 3.1), (0.5, 1.6, 0.7), key='filter')
        for side in (1, -1)], 'air_filters')
    nodes['fuel_tanks'] = join([
        solid('box', (side * 1.85, 6.3, 1.75), (0.55, 2.9, 1.0), key='fuel')
        for side in (1, -1)], 'fuel_tanks')
    # Akü kutuları sürücü bölmesinin solunda.
    nodes['batteries'] = join([
        solid('box', (1.45, y, 1.55), (0.6, 0.55, 0.55), key='battery')
        for y in (-4.9, -4.25)], 'batteries')
    exhaust = []
    for side in (1, -1):
        exhaust += pipe([(side * 1.42, 8.0, 2.95), (side * 1.55, 8.9, 3.05),
                         (side * 1.6, 10.2, 3.05)], 0.13)
        exhaust.append(solid('box', (side * 1.6, 9.6, 3.05),
                             (0.5, 0.9, 0.45), key='steel'))
    nodes['exhaust'] = join(exhaust, 'exhaust')
    return nodes


# --- Kurulum ----------------------------------------------------------------

def main():
    source, out_path = sys.argv[sys.argv.index('--') + 1:]
    bpy.ops.wm.open_mainfile(filepath=source)
    # Kenar bölme modifier'ı her yüzü ayrı adacık yapar; gölgelendirme
    # aşağıda açıdan hesaplanıyor.
    for o in bpy.data.objects:
        for m in getattr(o, 'modifiers', []):
            if m.type == 'EDGE_SPLIT':
                m.show_viewport = False
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()

    sources = {name: evaluated_copy(bpy.data.objects[name], depsgraph)
               for name in [*SOURCE_RULES, DECK_SPLIT[0]]}
    for o in list(bpy.data.objects):
        if o not in sources.values():
            bpy.data.objects.remove(o)

    groups = {}
    for name, rule in SOURCE_RULES.items():
        obj = sources[name]
        faces = {}
        for group, center, size, mats in islands(obj):
            faces.setdefault(rule(center, size, mats), []).extend(group)
        for node, f in faces.items():
            groups.setdefault(node, []).append(take_faces(obj, f, node))
    deck, rule = DECK_SPLIT
    faces = {}
    for i, c in enumerate(face_centers(sources[deck])):
        faces.setdefault(rule(c), []).append(i)
    for node, f in faces.items():
        groups.setdefault(node, []).append(take_faces(sources[deck], f, node))
    for o in sources.values():
        bpy.data.objects.remove(o)

    nodes = {node: join(objs, node) for node, objs in groups.items()}
    for node, obj in nodes.items():
        recolor(obj, NODE_COLORS.get(node, 'armor'))
    nodes.update(powerpack())

    # Gerçek ölçek; paletlerin altı z = 0.
    scale = Matrix.Scale(SCALE, 4)
    ground = min(v.co.z for v in nodes['track_l'].data.vertices) * SCALE
    place = Matrix.Translation((0, 0, -ground)) @ scale

    root = bpy.data.objects.new('Leopard', None)
    bpy.context.scene.collection.objects.link(root)
    total = 0
    for o in nodes.values():
        o.data.transform(place)
        o.data.set_sharp_from_angle(angle=math.radians(35))
        total += sum(len(p.vertices) - 2 for p in o.data.polygons)
        points = [v.co for v in o.data.vertices]
        center = (Vector(map(min, *points)) + Vector(map(max, *points))) / 2
        o.data.transform(Matrix.Translation(-center))
        o.location = center
        o.parent = root

    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format='GLB',
        export_draco_mesh_compression_enable=True,
        export_draco_mesh_compression_level=7,
    )
    print('DÜĞÜM', len(nodes), sorted(nodes), 'ÜÇGEN', total)


main()
