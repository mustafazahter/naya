"""F-16D Block 60 modelini iki kaynak modelden kurar.

Uçak bir uçuş simülatörü modelinden geliyor: hareketli yüzeylerin çoğu
(flaperonlar, hücum kenarı flapları, yatay kuyruklar, dümen, hava frenleri,
iniş takımı kapakları) ayrı nesne, ama gövde ve kanatlar tek parça ve
içinde motor yok. Motor ayrı bir model: her parçası ayrı adlı, genel bir
çift milli turbofan kesiti. Bu betik:

1. Uçağın nesnelerini uygulamanın düğümlerine toplar (`flaperon_l`,
   `main_gear_r`...). Düğüm adı `map/parts.json`'daki `meshNodes` ile aynı.
2. Tek parça gövdeden kanatları, burun konisini (radom) ve hava alığını
   yüz yüz ayırır.
3. Dış yüklerin (füzeler, bombalar, yakıt tankları, pilonlar) hepsini atar.
4. Turbofanı gövdeye sığacak ölçeğe getirip motor bölmesine yerleştirir;
   gondolunu ve giriş dudağını atar. Kaynakta art yakıcı yok; motorla
   lüle arasına basit bir art yakıcı kanalı yapar.
5. Malzemeleri düğüme göre yeniden renklendirir, gerçek ölçeğe getirir,
   uçağın önünü -Y'ye çevirir ve Draco ile sıkıştırıp yazar.

    blender -b --python build_model.py -- f16d.obj turbofan.obj ../model/product.glb

Uçak kaynağında Z yukarı, burun +Y, uçağın solu -X yönünde. Motor
kaynağında birim milimetre, eksen +X (önden arkaya).
"""
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

# Kaynak uçak 13,7 m; F-16'nın boyu yaklaşık 15 m.
SCALE = 1.08

# --- Malzemeler -----------------------------------------------------------

PALETTE = {
    'paint': ((0.33, 0.36, 0.40), 0.55, 0.0),
    'paint_dark': ((0.22, 0.24, 0.27), 0.6, 0.0),
    'radome': ((0.28, 0.30, 0.33), 0.5, 0.0),
    'glass': ((0.55, 0.50, 0.25), 0.05, 0.0),
    'interior': ((0.10, 0.10, 0.11), 0.8, 0.0),
    'gear': ((0.85, 0.86, 0.87), 0.4, 0.2),
    'rubber': ((0.03, 0.03, 0.03), 0.9, 0.0),
    'steel': ((0.45, 0.46, 0.48), 0.35, 1.0),
    'titanium': ((0.38, 0.36, 0.33), 0.4, 1.0),
    'hot': ((0.30, 0.25, 0.20), 0.5, 1.0),
    'alu': ((0.66, 0.67, 0.69), 0.4, 1.0),
    'blade': ((0.20, 0.21, 0.23), 0.35, 1.0),
    'bronze': ((0.70, 0.55, 0.25), 0.35, 1.0),
}

NODE_COLORS = {
    'radome': 'radome', 'canopy': 'glass', 'cockpit': 'interior',
    'nose_gear': 'gear', 'main_gear_l': 'gear', 'main_gear_r': 'gear',
    'tail_hook': 'gear', 'engine_nozzle': 'titanium',
    'afterburner': 'hot', 'engine_casing': 'alu', 'engine_fan': 'blade',
    'engine_lpc': 'steel', 'engine_hpc': 'steel',
    'engine_combustor': 'hot', 'engine_hpt': 'hot', 'engine_lpt': 'hot',
    'engine_shafts': 'steel', 'engine_gearbox': 'alu',
    'speed_brakes': 'paint_dark', 'conformal_tanks': 'paint',
}

# Kaynak malzeme adındaki parça → renk (kanopi camı, tekerlekler).
SOURCE_MATERIALS = [('glass', 'glass')]


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
    if key == 'glass':
        bsdf.inputs['Alpha'].default_value = 0.35
        m.blend_method = 'BLEND'
    cache[key] = m
    return m


def recolor(obj, default):
    for slot in obj.material_slots:
        name = slot.material.name if slot.material else ''
        slot.material = material(next(
            (k for p, k in SOURCE_MATERIALS if p in name), default))
    if not obj.material_slots:
        obj.data.materials.append(material(default))


# --- Uçağın düğümleri ---------------------------------------------------------
#
# Kaynak nesne adı → düğüm. `_l`/`_r` ile biten düğümler iki yanı ayrı
# nesne olan parçalar; listede olmayan nesne gövdeye (`fuselage`) gider.
# Uçağın solu kaynakta -X.

AIRCRAFT_PARTS = {
    'poly_22': 'lef_l', 'poly_21': 'lef_r',
    'poly_25': 'flaperon_l', 'poly_26': 'flaperon_r',
    'poly_23': 'horizontal_tail_l', 'poly_24': 'horizontal_tail_r',
    'tail': 'vertical_tail', 'poly_18': 'rudder',
    'poly_16': 'speed_brakes', 'poly_17': 'speed_brakes',
    'engines': 'engine_nozzle', 'hook': 'tail_hook', 'cft': 'conformal_tanks',
    'poly_30': 'canopy', 'cock': 'canopy',
    'cock_2': 'cockpit', 'ins': 'cockpit', 'poly_29': 'cockpit',
    'screen1': 'cockpit', 'screen2': 'cockpit', 'screen3': 'cockpit',
    'screen4': 'cockpit', 'HUD': 'cockpit', 'pitch_ladder': 'cockpit',
    'velo_vec': 'cockpit', 'poly_19': 'cockpit', 'poly_20': 'cockpit',
    'poly_27': 'cockpit', 'poly_28': 'cockpit', 'poly_31': 'cockpit',
    'poly_32': 'cockpit', 'poly_33': 'cockpit', 'poly_34': 'cockpit',
    # Burun iniş takımı: dikme ve teker, kapaklar.
    'poly': 'nose_gear', 'poly_2': 'nose_gear', 'poly_3': 'nose_gear',
    'poly_12': 'nose_gear', 'poly_15': 'nose_gear',
    # Ana iniş takımı: dikme ve teker, yan dikme, kapaklar.
    'poly_8': 'main_gear_l', 'poly_6': 'main_gear_l',
    'poly_11': 'main_gear_l', 'poly_14': 'main_gear_l', 'poly_4': 'main_gear_l',
    'poly_9': 'main_gear_r', 'poly_7': 'main_gear_r',
    'poly_10': 'main_gear_r', 'poly_13': 'main_gear_r', 'poly_5': 'main_gear_r',
}

# Dış yükler ve boş nesneler atılır.
DROP = ('extra1', 'extra2', 'extra3', 'extra4', 'extra5', 'wheel')


def body_face(c):
    """Tek parça gövdenin bir yüzü hangi düğüme gider."""
    if c.y > 5.55:
        return 'radome'
    if abs(c.x) > 1.08 and -2.75 < c.y < 1.3 and 1.45 < c.z < 2.3:
        return 'wing_l' if c.x < 0 else 'wing_r'
    if abs(c.x) < 0.8 and 1.6 < c.y < 4.1 and c.z < 1.35:
        return 'intake'
    return 'fuselage'


# --- Motor ------------------------------------------------------------------

# Turbofan nesneleri, adlarının başına göre. İlk eşleşen alır.
ENGINE_PARTS = [
    ('engine_fan', ['Spinner', 'Fan_Blades', 'Fan_Hub']),
    ('engine_casing', ['Fan_Case', 'Core_Cowl']),
    ('engine_lpc', ['LPC_']),
    ('engine_hpc', ['HPC_']),
    ('engine_combustor', ['Diffuser', 'Combustor', 'Fuel_Nozzles',
                          'Igniters']),
    ('engine_hpt', ['HPT_']),
    ('engine_lpt', ['LPT_', 'Exhaust_']),
    ('engine_shafts', ['LP_Shaft', 'HP_Shaft', 'Front_Bearing',
                       'Middle_Bearing', 'Rear_Bearing']),
    ('engine_gearbox', ['Gearbox', 'Radial_Drive']),
]
ENGINE_DROP = ('Outer_Nacelle', 'Intake_Cowl')

# Fan kasası 1,6 m çaplı; gövdeye 1,02 m olarak sığar. Motorun önü
# y = -1,06'da, ekseni lülenin ekseninde (z = 1,86). Kaynak eksen +X,
# uçakta arkaya (-Y) döner.
ENGINE_SCALE = 0.64 / 1000
ENGINE_FRONT = Vector((0, -1.06, 1.86))
ENGINE_PLACE = (Matrix.Translation(ENGINE_FRONT)
                @ Matrix.Rotation(-math.pi / 2, 4, 'Z')
                @ Matrix.Scale(ENGINE_SCALE, 4))
ENGINE_LENGTH = 3.08 * 0.64
NOZZLE_FRONT = -5.07


# --- Yardımcılar ------------------------------------------------------------

def bake(obj):
    obj.data = obj.data.copy()
    obj.data.transform(obj.matrix_world)
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    return obj


def join(objects, name):
    objects = [o for o in objects if o and o.type == 'MESH']
    with bpy.context.temp_override(active_object=objects[0],
                                   selected_editable_objects=objects):
        bpy.ops.object.join()
    result = objects[0]
    result.name = name
    result.data.name = name
    return result


def take_faces(obj, faces, name):
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


def afterburner():
    """Motorun arkasından lüleye uzanan kanal, alev tutucu halkaları ve
    yakıt püskürtme halkası."""
    front = ENGINE_FRONT.y - ENGINE_LENGTH
    length = front - NOZZLE_FRONT
    center = (0, (front + NOZZLE_FRONT) / 2, ENGINE_FRONT.z)
    pieces = []
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=48, radius=0.5, depth=length, location=center,
        rotation=(math.pi / 2, 0, 0), end_fill_type='NOTHING')
    pieces.append(bpy.context.active_object)
    for offset, radius in ((0.35, 0.30), (0.55, 0.18), (0.25, 0.42)):
        bpy.ops.mesh.primitive_torus_add(
            major_segments=48, minor_segments=8, major_radius=radius,
            minor_radius=0.025, location=(0, front - offset, ENGINE_FRONT.z),
            rotation=(math.pi / 2, 0, 0))
        pieces.append(bpy.context.active_object)
    bpy.context.view_layer.update()
    for p in pieces:
        bake(p)
    return join(pieces, 'afterburner')


# --- Kurulum ----------------------------------------------------------------

def main():
    aircraft_path, engine_path, out_path = sys.argv[sys.argv.index('--') + 1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=aircraft_path)
    bpy.context.view_layer.update()
    source = {o.name: bake(o) for o in bpy.data.objects if o.type == 'MESH'}

    groups = {}
    for name, obj in source.items():
        if name.startswith(DROP) or not obj.data.polygons:
            bpy.data.objects.remove(obj)
            continue
        if name == 'body':
            faces = {}
            for p in obj.data.polygons:
                faces.setdefault(body_face(p.center), []).append(p.index)
            for node, f in faces.items():
                groups.setdefault(node, []).append(take_faces(obj, f, node))
            bpy.data.objects.remove(obj)
            continue
        groups.setdefault(AIRCRAFT_PARTS.get(name, 'fuselage'), []).append(obj)
    nodes = {node: join(objs, node) for node, objs in groups.items()}
    for node, obj in nodes.items():
        recolor(obj, NODE_COLORS.get(node, 'paint'))

    # Motor.
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=engine_path)
    engine = [o for o in bpy.data.objects if o not in before]
    engine_groups = {}
    for o in engine:
        if o.type != 'MESH' or o.name.startswith(ENGINE_DROP):
            bpy.data.objects.remove(o)
            continue
        bake(o)
        o.data.transform(ENGINE_PLACE)
        node = next(n for n, prefixes in ENGINE_PARTS
                    if any(o.name.startswith(p) for p in prefixes))
        engine_groups.setdefault(node, []).append(o)
    for node, objs in engine_groups.items():
        nodes[node] = join(objs, node)
        recolor(nodes[node], NODE_COLORS[node])
    nodes['afterburner'] = afterburner()
    recolor(nodes['afterburner'], 'hot')

    # Gerçek ölçek, burun -Y'ye; tekerleklerin altı z = 0.
    turn = Matrix.Rotation(math.pi, 4, 'Z') @ Matrix.Scale(SCALE, 4)
    for o in nodes.values():
        o.data.transform(turn)
    ground = min(v.co.z for name in ('nose_gear', 'main_gear_l')
                 for v in nodes[name].data.vertices)
    shift = Matrix.Translation((0, 0, -ground))

    root = bpy.data.objects.new('F16', None)
    bpy.context.scene.collection.objects.link(root)
    total = 0
    for o in nodes.values():
        o.data.transform(shift)
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
