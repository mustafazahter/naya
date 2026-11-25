"""Corolla modelini iki kaynak modelden kurar.

Gövde ve şasi bir sürüş oyunu modundan (E100 Corolla) geliyor: her parçanın
birkaç seçeneği var (tampon, ızgara, fren...), lastikler yok ve hiçbir
malzemenin rengi yok. Motor ayrı bir model (1ZZ-FE); her parçası ayrı
nesne. Bu betik:

1. Her parça için tek bir seçeneği alır, gerisini atar.
2. Uygulamadaki parça haritasına göre düğümlere toplar (`door_fl`,
   `engine_head`...). Düğüm adı `map/parts.json`'daki `meshNodes` ile aynı.
3. Gövdeyi, iç döşemeyi ve motor bölmesini birbirine değmeyen parçalarına
   (adacık) ayırır; her adacık malzemesine ve konumuna göre kendi düğümüne
   gider (silecekler, koltuklar, gösterge paneli, genleşme kabı...).
4. Kabin içinden görünen boyalı sac yüzlerin birkaç milimetre içine döşeme
   renginde bir kopya koyar; camdan bakınca içerisi boyalı görünmez.
5. Eski düşük ayrıntılı motoru (4A-GE) çıkarır, şanzımanı ondan ayırıp
   tutar, yerine 1ZZ-FE'yi koyar.
6. Kaynakta olmayan lastik, jant, egzoz, katalitik konvertör, yakıt deposu,
   radyatör fanı, alternatör, marş motoru ve klima parçalarını basit
   biçimlerle yapar.
7. Malzemeleri düğüme ve adlarına göre yeniden renklendirir.
8. Draco ile sıkıştırıp yazar.

    blender -b --python build_model.py -- govde.glb motor.glb ../model/product.glb

Blender'da Z yukarı, aracın önü -Y, solu +X yönünde; dışa aktarırken glTF'nin
Y yukarı düzenine çevrilir.
"""
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

# --- Seçimler -------------------------------------------------------------

# Düğüm adı → kaynak modeldeki parçalar (`CorollaDX_` öneki olmadan).
# Seçenekli parçalarda (tampon, ızgara...) fabrika çıkışı olanı alındı.
CAR_PARTS = {
    'windshield': ['windshield'],
    'rear_window': ['backlight'],
    'hood': ['hood'],
    'trunk': ['trunk', 'trunkmid', 'lettering_DX'],
    'door_fl': ['door_FL', 'doorglass_FL', 'doorpanel_FL',
                'basedoorpanel_FL', 'doorplastic_FL'],
    'door_fr': ['door_FR', 'doorglass_FR', 'doorpanel_FR',
                'basedoorpanel_FR', 'doorplastic_FR'],
    'door_rl': ['door_RL', 'doorglass_RL', 'doorplastic_RL'],
    'door_rr': ['door_RR', 'doorglass_RR', 'doorplastic_RR'],
    # Yan sinyal lambası çamurluğun üstünde; gövdede kalırsa çamurlukta delik
    # görünür.
    'fender_l': ['fender_L', 'fenderplastic_L'],
    'fender_r': ['fender_R', 'fenderplastic_R'],
    'bumper_front': ['bumper_F'],
    'bumper_rear': ['bumper_R'],
    'grille': ['grille', 'logo_F_grille'],
    # Tampon köşelerindeki boşluklara oturan sis lambaları.
    'foglight_l': ['foglight_L'],
    'foglight_r': ['foglight_R'],
    'headlight_l': ['headlightframe_L', 'headlightglass_L'],
    'headlight_r': ['headlightframe_R', 'headlightglass_R'],
    'taillight_l': ['taillight_L'],
    'taillight_r': ['taillight_R'],
    'mirror_l': ['mirror_L'],
    'mirror_r': ['mirror_R'],
    'steering_wheel': ['steer'],
    'radiator': ['radiator'],
    'strut_front': ['strut_F'],
    'hub_front': ['hub_F'],
    'control_arm_front': ['lowerarm_F'],
    'driveshaft_front': ['halfshaft_F'],
    'brake_caliper_front': ['brake_F'],
    'brake_disc_front': ['brakedisc_FL', 'brakedisc_FR'],
    'brake_caliper_rear': ['brake_R'],
    'brake_disc_rear': ['brakedisc_RL', 'brakedisc_RR'],
    'strut_rear': ['coilover_R'],
    'arms_rear': ['trailingarm_R', 'lowerarm_R', 'upperarm_R', 'tierod_R',
                  'armbracket_R'],
    'stabilizer_rear': ['swaybar_R'],
    'subframe_rear': ['subframe_R'],
    'hub_rear': ['hub_R'],
}

# Gövde, iç döşeme ve camlar dışındaki kabin parçaları bu kaynaklarda karışık
# duruyor; adacık adacık ayrılır.
BODY_SOURCES = ['body', 'body2', 'radsupport', 'chmsl', 'skirts',
                'antenna_close', 'needle_speedo', 'needle_tacho', 'console5',
                'mudflaps', 'mudflap_FL', 'mudflap_FR']

# (düğüm, malzemeler, kutu (merkez, yarı boy), en büyük adacık boyu).
# İlk eşleşen kural alır; hiçbiri eşleşmezse adacık `body`'de kalır.
# Malzeme adı `CorollaDX_` öneki ve `.001` gibi sonekler atılmış haliyle
# karşılaştırılır.
FABRIC = ('velur', 'lether')
BODY_RULES = [
    # Silecek kolları ön camın altında; altlarındaki torpido sacı (geniş
    # adacık) gövdede kalır.
    ('wipers', ('nodamage',), ((0, -0.93, 0.955), (0.75, 0.05, 0.03)), 0.7),
    ('instrument_cluster', ('detail', 'detail_light', 'dashboard_check',
                            'dashboard_far', 'dashboard_fog',
                            'dashboard_near', 'dashboard_sl', 'dashboard_sr',
                            'dashboard_stop'), None, None),
    ('instrument_cluster', ('dark',),
     ((-0.42, -0.68, 0.9), (0.16, 0.04, 0.06)), None),
    ('seat_front_l', FABRIC, ((0.40, 0.10, 0.70), (0.32, 0.45, 0.55)), None),
    ('seat_front_r', FABRIC, ((-0.40, 0.10, 0.70), (0.32, 0.45, 0.55)), None),
    ('seat_rear', FABRIC, ((0, 1.00, 0.75), (0.80, 0.45, 0.50)), None),
    ('pedals', ('body',), ((-0.40, -0.84, 0.38), (0.25, 0.08, 0.10)), None),
    ('carpet', ('floor', 'mats'), None, None),
    # İç dikiz aynası tavanda; gösterge panelinden ayrı tutulur.
    ('interior_trim', None, ((0, -0.35, 1.2), (0.2, 0.2, 0.12)), None),
    # Panelin gövdesi kaynakta döşeme malzemesinde.
    ('dashboard', ('plastic', 'dark', 'body', 'chrome'),
     ((0, -0.72, 0.75), (0.76, 0.26, 0.30)), None),
    ('dashboard', ('plastic_detailed', 'misc', 'misc_light',
                   'YotaDigiClock'), None, None),
    ('interior_trim', ('plastic', 'dark', 'body', 'chrome', *FABRIC), None,
     None),
]

# Motor bölmesindeki karışık parçadan (`engbaycrap`) kümeler, konumlarına
# göre. (merkez, yarı boyut) kutusuna düşen adacıklar o düğüme gider; sıra
# önemli, ilk eşleşen alır. Hiçbir kutuya düşmeyenler atılır.
BAY_PARTS = {
    'battery': ((0.43, -1.67, 0.65), (0.16, 0.12, 0.13)),
    'steering_rack': ((0.01, -1.33, 0.41), (0.72, 0.06, 0.08)),
    'subframe_front': ((0.0, -1.44, 0.27), (0.51, 0.54, 0.06)),
    'coolant_tank': ((-0.56, -1.54, 0.72), (0.115, 0.07, 0.085)),
    'ps_reservoir': ((-0.61, -1.41, 0.75), (0.07, 0.07, 0.07)),
    'washer_tank': ((-0.56, -1.77, 0.67), (0.065, 0.055, 0.065)),
    'radiator_hoses': ((-0.43, -1.71, 0.71), (0.24, 0.23, 0.10)),
    'brake_booster': ((0.42, -1.16, 0.78), (0.17, 0.17, 0.17)),
    'air_filter': ((0.14, -1.45, 0.77), (0.52, 0.40, 0.17)),
}

# 1ZZ-FE nesneleri, adlarının başına göre. Sıra önemli: ilk eşleşen alır.
ENGINE_PARTS = [
    ('engine_head_cover', ['head_cover', 'oil_filler_cap']),
    ('engine_head_gasket', ['head_gasket']),
    ('engine_camshafts', ['camshaft_', 'cam_cap', 'lifter_']),
    ('engine_head', ['cylinder_head', 'head_bolt']),
    ('engine_timing_chain', ['timing_chain', 'chain_', 'crank_sprocket',
                             'slipper_bolt', 'damper_bolt',
                             'tensioner_nut']),
    ('engine_timing_cover', ['timing_cover']),
    ('engine_water_pump', ['water_pump']),
    ('engine_crank_pulley', ['crank_pulley']),
    ('engine_crank_sensor', ['crank_position', 'crank_sensor']),
    ('engine_pistons', ['piston_']),
    ('engine_rods', ['connecting_rod', 'rod_cap']),
    ('engine_crankshaft', ['crankshaft']),
    ('engine_oil_pump', ['oil_pump', 'oil_strainer', 'strainer_nut']),
    ('engine_oil_pan', ['oil_pan', 'drain_plug']),
    ('engine_oil_filter', ['oil_filter']),
    ('engine_intake', ['intake_manifold']),
    ('engine_exhaust_manifold', ['exhaust_manifold']),
    ('engine_coils', ['ignition_coil', 'coil_bolt']),
    ('engine_spark_plugs', ['spark_plug']),
    ('engine_block', ['block', 'bearing_cap_ladder', 'ladder_bolt',
                      'main_cap_bolt']),
]

# Motorun araçtaki yeri: enine, volan tarafı şanzımana (+X) bakar,
# egzoz manifoldu torpido duvarına (+Y). Taban yerden 0,19 m yukarıda.
ENGINE_PLACE = Matrix.Translation((-0.12, -1.42, 0.19)) @ Matrix.Rotation(
    math.pi, 4, 'Z')

# Tekerlek merkezleri (fren disklerinin merkezinden) ve ölçüler:
# 175/65 R14 lastik.
WHEELS = {
    'wheel_fl': (0.735, -1.29, 0.31),
    'wheel_fr': (-0.735, -1.29, 0.31),
    'wheel_rl': (0.735, 1.33, 0.29),
    'wheel_rr': (-0.735, 1.33, 0.29),
}
TIRE_RADIUS = 0.292
TIRE_WIDTH = 0.175
RIM_RADIUS = 0.178

# Kabin: içinden görünen boyalı yüzlere döşeme kopyası konan bölge ve
# kopyanın içe doğru kaydırıldığı merkez.
CABIN_CENTER = Vector((0, 0.3, 0.8))
INNER_OFFSET = 0.004
BELT_LINE = 0.88  # bunun üstü tavan döşemesi, altı yan döşeme

# --- Malzemeler -----------------------------------------------------------

# glTF temel renkleri doğrusal; görüntüleyicide (RoomEnvironment + ACES)
# açık görünür. Bu yüzden değerler gerçek renklerden koyu seçildi.
# anahtar: (renk, pürüzlülük, metal, saydamlık)
PALETTE = {
    'paint': ((0.40, 0.32, 0.20), 0.32, 0.0, 1),  # bej
    'trim': ((0.018, 0.018, 0.02), 0.6, 0.0, 1),
    'rubber': ((0.014, 0.014, 0.014), 0.9, 0.0, 1),
    'chrome': ((0.8, 0.81, 0.83), 0.12, 1.0, 1),
    'glass': ((0.26, 0.30, 0.32), 0.05, 0.0, 0.3),
    'lens': ((0.8, 0.83, 0.86), 0.05, 0.0, 0.25),
    'reflector': ((0.75, 0.76, 0.78), 0.15, 1.0, 1),
    'fog_lens': ((0.62, 0.58, 0.32), 0.1, 0.0, 1),
    'reverse': ((0.55, 0.56, 0.58), 0.1, 0.0, 1),
    'tail': ((0.32, 0.004, 0.004), 0.2, 0.0, 1),
    'amber': ((0.62, 0.20, 0.012), 0.2, 0.0, 1),
    'chassis': ((0.035, 0.035, 0.04), 0.6, 0.3, 1),
    'steel': ((0.42, 0.43, 0.45), 0.38, 1.0, 1),
    'alu': ((0.55, 0.56, 0.58), 0.42, 1.0, 1),
    'cast': ((0.12, 0.12, 0.13), 0.7, 0.6, 1),
    'battery': ((0.02, 0.02, 0.025), 0.6, 0.0, 1),
    'reservoir': ((0.30, 0.30, 0.27), 0.5, 0.0, 1),
    'washer_fluid': ((0.06, 0.16, 0.35), 0.4, 0.0, 1),
    # Kabin
    'dash': ((0.016, 0.016, 0.018), 0.65, 0.0, 1),
    'gauge': ((0.006, 0.006, 0.007), 0.4, 0.0, 1),
    'gauge_mark': ((0.12, 0.12, 0.11), 0.4, 0.0, 1),
    'fabric': ((0.040, 0.043, 0.052), 1.0, 0.0, 1),
    'vinyl': ((0.022, 0.023, 0.026), 0.55, 0.0, 1),
    'door_card': ((0.032, 0.033, 0.037), 0.8, 0.0, 1),
    'trim_int': ((0.026, 0.027, 0.03), 0.7, 0.0, 1),
    'headliner': ((0.20, 0.19, 0.165), 1.0, 0.0, 1),
    'carpet': ((0.014, 0.014, 0.016), 1.0, 0.0, 1),
    'wheel_grip': ((0.012, 0.012, 0.012), 0.75, 0.0, 1),
}

# Gövde malzeme adı → paletteki renk. Listede olmayan `trim` olur.
CAR_MATERIALS = [
    ('glass', 'glass'), ('headlight', 'lens'), ('highbeam', 'lens'),
    ('signal', 'amber'), ('taillight', 'tail'), ('reverselight', 'reverse'),
    ('chmsl', 'tail'), ('lights', 'tail'), ('chrome', 'chrome'),
    ('silver', 'chrome'), ('badge', 'chrome'), ('wheel', 'alu'),
    ('body2', 'alu'), ('velur', 'fabric'), ('lether', 'vinyl'),
    ('floor', 'carpet'), ('mats', 'carpet'), ('dashboard', 'gauge_mark'),
    ('detail', 'dash'), ('misc', 'dash'), ('plastic', 'trim_int'),
    ('pessima', 'chassis'), ('engine', 'steel'), ('undercarriage', 'chassis'),
    ('CorollaDX_body', 'door_card'), ('doorshut', 'paint'), ('dark', 'trim'),
    ('black', 'trim'), ('nodamage', 'trim'), ('CorollaDX-', 'paint'),
    ('CorollaDX.', 'paint'), ('CorollaDX', 'paint'),
]

# Düğüme özel renkler; önce bunlara, sonra CAR_MATERIALS'a bakılır.
# ('*', anahtar) düğümdeki her malzemeyi o renge çevirir.
NODE_MATERIALS = {
    'headlight_l': [('lights', 'reflector'), ('headlight', 'lens'),
                    ('highbeam', 'lens'), ('signal', 'amber')],
    'foglight_l': [('*', 'fog_lens')],
    'fender_l': [('nodamage', 'amber')],
    'taillight_l': [('reverselight', 'reverse')],
    'seat_front_l': [('velur', 'fabric'), ('lether', 'vinyl')],
    'dashboard': [('chrome', 'chrome'), ('*', 'dash')],
    'instrument_cluster': [('detail_light', 'gauge_mark'),
                           ('dashboard', 'amber'), ('*', 'gauge')],
    'carpet': [('*', 'carpet')],
    'pedals': [('*', 'rubber')],
    'interior_trim': [('chrome', 'chrome'), ('velur', 'fabric'),
                      ('lether', 'vinyl'), ('dark', 'trim_int'),
                      ('*', 'trim_int')],
    'door_fl': [('CorollaDX_body', 'door_card'), ('dark', 'trim_int'),
                ('dinghyblack', 'trim')],
    'steering_wheel': [('*', 'wheel_grip')],
    'wipers': [('*', 'trim')],
    'battery': [('*', 'battery')],
    'coolant_tank': [('*', 'reservoir')],
    'washer_tank': [('*', 'reservoir')],
    'ps_reservoir': [('*', 'reservoir')],
    'radiator_hoses': [('*', 'rubber')],
    'transaxle': [('*', 'alu')],
    'air_filter': [('*', 'trim')],
    'brake_booster': [('*', 'cast')],
    'steering_rack': [('*', 'cast')],
    'subframe_front': [('*', 'chassis')],
    'radiator': [('*', 'cast')],
}
for left, right in (('headlight_l', 'headlight_r'), ('foglight_l',
                    'foglight_r'), ('fender_l', 'fender_r'),
                    ('taillight_l', 'taillight_r'),
                    ('seat_front_l', 'seat_front_r'),
                    ('seat_front_l', 'seat_rear')):
    NODE_MATERIALS[right] = NODE_MATERIALS[left]
for door in ('door_fr', 'door_rl', 'door_rr'):
    NODE_MATERIALS[door] = NODE_MATERIALS['door_fl']

# Motor malzemeleri zaten anlamlı adlı; yalnız renkleri düzeltilir.
ENGINE_MATERIALS = [
    ('paint_black', 'trim'), ('black_plastic', 'trim'), ('rubber', 'rubber'),
    ('sensor_plastic', 'trim'), ('paint_blue', 'battery'),
    ('nylon', 'reservoir'), ('alu', 'alu'), ('gasket', 'steel'),
]


def material(key, cache={}):
    if key in cache:
        return cache[key]
    color, roughness, metallic, alpha = PALETTE[key]
    m = bpy.data.materials.new(f'naya_{key}')
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    if alpha < 1:
        bsdf.inputs['Alpha'].default_value = alpha
        m.blend_method = 'BLEND'
    cache[key] = m
    return m


def recolor(obj, rules, default):
    for slot in obj.material_slots:
        name = slot.material.name if slot.material else ''
        key = next((k for pattern, k in rules
                    if pattern == '*' or pattern in name), default)
        slot.material = material(key)


# --- Yardımcılar ------------------------------------------------------------

def meshes_under(obj):
    return [o for o in [obj, *obj.children_recursive] if o.type == 'MESH']


def bake(obj):
    """Nesneyi dünya koordinatlarına sabitler; üst düğümden ayırır."""
    obj.data = obj.data.copy()
    obj.data.transform(obj.matrix_world)
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    return obj


def join(objects, name):
    """Nesneleri tek bir mesh'te birleştirir ve adını verir."""
    objects = [o for o in objects if o.type == 'MESH']
    with bpy.context.temp_override(
        active_object=objects[0],
        selected_editable_objects=objects,
    ):
        bpy.ops.object.join()
    result = objects[0]
    result.name = name
    result.data.name = name
    return result


def material_key(obj, index):
    """Kaynak malzeme adının kural tablolarında kullanılan kısa hali."""
    if index >= len(obj.material_slots) or not obj.material_slots[index].material:
        return ''
    name = obj.material_slots[index].material.name
    return name.removeprefix('CorollaDX_').split('.')[0]


def islands(obj):
    """Mesh'in birbirine değmeyen parçaları: (yüzler, merkez, boy, malzeme)."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
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
        center = sum((f.calc_center_median() for f in group),
                     Vector()) / len(group)
        points = [v.co for f in group for v in f.verts]
        size = Vector(map(max, *points)) - Vector(map(min, *points))
        counts = {}
        for f in group:
            counts[f.material_index] = counts.get(f.material_index, 0) + 1
        mat = material_key(obj, max(counts, key=counts.get))
        result.append(([f.index for f in group], center, size, mat))
    bm.free()
    return result


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
    copy.data.name = name
    return copy


def drop_below(obj, z):
    """[z]'nin altındaki köşeleri ve onlara bağlı yüzleri siler."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < z],
                     context='VERTS')
    bm.to_mesh(obj.data)
    bm.free()


def inside(point, box):
    center, half = box
    return all(abs(point[i] - center[i]) <= half[i] for i in range(3))


def split(obj, rules, default):
    """Adacıkları kurallara göre düğümlere dağıtır: {düğüm: [yüz...]}."""
    taken = {}
    for faces, center, size, mat in islands(obj):
        node = default
        for name, mats, box, longest in rules:
            if mats and mat not in mats:
                continue
            if box and not inside(center, box):
                continue
            if longest and max(size) > longest:
                continue
            node = name
            break
        if node:
            taken.setdefault(node, []).extend(faces)
    return taken


def inner_copy(obj, keep, name, key):
    """[obj]'nin [keep(yüz)] yüzlerini kabine doğru [INNER_OFFSET] kadar
    kaydırıp [key] renginde yeni bir nesne yapar.

    Kaynakta sac tek katlı; kabinden bakınca boyanın arka yüzü görünüyor.
    Kopya, boyanın kabin tarafında durduğu için içeriden o görünür,
    dışarıdan boyanın arkasında kalır.
    """
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    paint = {i for i, slot in enumerate(obj.material_slots)
             if slot.material and slot.material.name == 'naya_paint'}
    bmesh.ops.delete(bm, geom=[
        f for f in bm.faces
        if f.material_index not in paint or not keep(f)],
        context='FACES')
    if not bm.faces:
        bm.free()
        return None
    for f in bm.faces:
        if f.normal.dot(CABIN_CENTER - f.calc_center_median()) < 0:
            f.normal_flip()
        f.material_index = 0
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * INNER_OFFSET
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(material(key))
    copy = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(copy)
    return copy


def finish(obj, key):
    """Yeni yapılan basit parçayı dünya koordinatına sabitleyip boyar."""
    bpy.context.view_layer.update()
    obj.data.materials.clear()
    obj.data.materials.append(material(key))
    return bake(obj)


def cylinder(a, b, radius, key, vertices=24, scale=(1, 1)):
    """[a] ile [b] noktaları arasında silindir; kesit [scale] ile basılır."""
    a, b = Vector(a), Vector(b)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius,
                                        depth=d.length, location=(a + b) / 2)
    obj = bpy.context.active_object
    obj.scale = (*scale, 1)
    obj.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    return finish(obj, key)


def box(center, size, key, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.active_object
    obj.scale = size
    obj = finish(obj, key)
    if bevel:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=3,
                        affect='EDGES')
        bm.to_mesh(obj.data)
        bm.free()
    return obj


def tire_and_rim(name, center, side, hubcap):
    """Lastik (halka), çelik jant ve kaynak modelin göbek kapağı.

    [side] +1 sol, -1 sağ tekerlek. [hubcap] orijinde, X ekseni boyunca
    duran kapak; her tekerleğe bir kopyası konur.
    """
    tube = (TIRE_RADIUS - RIM_RADIUS) / 2
    bpy.ops.mesh.primitive_torus_add(
        major_segments=48, minor_segments=12,
        major_radius=RIM_RADIUS + tube, minor_radius=tube,
        location=center, rotation=(0, math.pi / 2, 0))
    tire = bpy.context.active_object
    # Torus yuvarlak kesitli; lastik daha geniş.
    tire.scale = (1, 1, TIRE_WIDTH / (2 * tube))
    tire.data.materials.append(material('rubber'))

    bpy.ops.mesh.primitive_cylinder_add(
        vertices=32, radius=RIM_RADIUS, depth=TIRE_WIDTH * 0.8,
        location=center, rotation=(0, math.pi / 2, 0))
    rim = bpy.context.active_object
    rim.data.materials.append(material('steel'))

    cap = hubcap.copy()
    cap.data = hubcap.data.copy()
    bpy.context.scene.collection.objects.link(cap)
    # Kapak jantın dış yüzüne oturur; sağdakiler Z ekseninde döner.
    turn = Matrix.Rotation(0 if side > 0 else math.pi, 4, 'Z')
    cap.data.transform(turn)
    cap.location = (center[0] + side * TIRE_WIDTH * 0.42, center[1],
                    center[2])

    bpy.context.view_layer.update()
    for o in (tire, rim, cap):
        bake(o)
    return join([tire, rim, cap], name)


def exhaust(tip):
    """Manifolddan arka tampona egzoz hattı: ön boru, katalitik konvertör,
    orta boru ve susturucu. [tip] kaynak modelin egzoz ucu."""
    def pipe(points):
        return [cylinder(a, b, 0.024, 'steel', 16)
                for a, b in zip(points, points[1:])]

    nodes = {}
    nodes['exhaust_pipe'] = join(
        pipe([(-0.09, -1.24, 0.37), (-0.10, -1.08, 0.26),
              (-0.10, -0.80, 0.225)])
        + pipe([(-0.10, -0.38, 0.225), (-0.10, 0.20, 0.22),
                (-0.32, 1.14, 0.24)]), 'exhaust_pipe')
    nodes['catalytic_converter'] = join([
        cylinder((-0.10, -0.80, 0.225), (-0.10, -0.38, 0.225), 0.065,
                 'steel', 24, (1, 0.62)),
        # Isı kalkanı
        cylinder((-0.10, -0.76, 0.232), (-0.10, -0.42, 0.232), 0.072,
                 'alu', 24, (1, 0.6))], 'catalytic_converter')
    muffler = cylinder((-0.32, 1.14, 0.25), (-0.43, 1.66, 0.26), 0.11,
                       'steel', 24, (1, 0.55))
    tail = pipe([(-0.43, 1.66, 0.26), (-0.52, 1.95, 0.265)])
    nodes['muffler'] = join([muffler, *tail, tip], 'muffler')
    return nodes


def arch_liner(center, side):
    """Tekerlek davlumbazının iç kaplaması: lastiğin üstünde yay biçimli
    plastik. Kaynakta yok; yoksa davlumbazdan arkası görünüyor."""
    radius, width = 0.345, 0.21
    x = center[0] - side * 0.03
    bm = bmesh.new()
    rings = []
    for x0 in (x - width / 2, x + width / 2):
        ring = []
        for i in range(25):
            # Önde ve arkada tekerlek merkezinin biraz altına iner.
            a = math.radians(-20 + i * 220 / 24)
            ring.append(bm.verts.new((x0, center[1] + radius * math.cos(a),
                                      center[2] + radius * math.sin(a))))
        rings.append(ring)
    for i in range(24):
        bm.faces.new((rings[0][i], rings[0][i + 1], rings[1][i + 1],
                      rings[1][i]))
    mesh = bpy.data.meshes.new('liner')
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(material('trim'))
    obj = bpy.data.objects.new('liner', mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def fuel_tank():
    """Arka koltuğun altında, taban sacının altında."""
    tank = box((0.30, 0.32, 0.145), (0.66, 0.46, 0.09), 'chassis', 0.02)
    neck = cylinder((0.58, 0.50, 0.17), (0.72, 0.95, 0.40), 0.022,
                    'rubber', 12)
    return join([tank, neck], 'fuel_tank')


def radiator_fan():
    """Radyatörün arkasında elektrikli fan, davlumbazıyla."""
    y, x, z = -1.86, -0.12, 0.46
    parts = [box((x, y - 0.012, z), (0.36, 0.012, 0.32), 'trim', 0.004),
             cylinder((x, y + 0.01, z), (x, y + 0.075, z), 0.05, 'cast')]
    for i in range(5):
        a = i * 2 * math.pi / 5
        blade = box((0, 0, 0), (0.035, 0.006, 0.13), 'trim')
        blade.data.transform(Matrix.Translation((0, 0, 0.075)))
        blade.data.transform(Matrix.Rotation(a, 4, 'Y'))
        blade.data.transform(Matrix.Translation((x, y + 0.02, z)))
        parts.append(blade)
    return join(parts, 'radiator_fan')


def alternator():
    """Kayış tarafında (sağ, -X), emme manifoldunun altında."""
    return join([
        cylinder((-0.31, -1.625, 0.36), (-0.19, -1.625, 0.36), 0.064,
                 'alu', 24),
        cylinder((-0.345, -1.625, 0.36), (-0.31, -1.625, 0.36), 0.028,
                 'steel', 20)], 'alternator')


def starter():
    """Şanzıman çan muhafazasında, arka tarafta."""
    return join([
        cylinder((0.09, -1.22, 0.33), (0.21, -1.22, 0.33), 0.042, 'cast', 20),
        cylinder((0.11, -1.22, 0.385), (0.19, -1.22, 0.385), 0.022, 'cast',
                 16)], 'starter')


def ac_compressor():
    """Klima kompresörü, alternatörün altında kayışla döner."""
    return join([
        cylinder((-0.31, -1.61, 0.22), (-0.17, -1.61, 0.22), 0.058, 'alu',
                 24),
        cylinder((-0.345, -1.61, 0.22), (-0.31, -1.61, 0.22), 0.05, 'steel',
                 24)], 'ac_compressor')


def ac_condenser():
    """Radyatörün önünde ince peteği."""
    return box((0.0, -1.985, 0.50), (0.72, 0.012, 0.38), 'cast')


# --- Kurulum ----------------------------------------------------------------

def main():
    car_path, engine_path, out_path = sys.argv[sys.argv.index('--') + 1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)

    bpy.ops.import_scene.gltf(filepath=car_path)
    car = {o.name.removeprefix('CorollaDX_'): o for o in bpy.data.objects}
    nodes = {}

    # 1-2. Seçilen parçalar düğümlere.
    for node, sources in CAR_PARTS.items():
        meshes = [bake(m) for s in sources for m in meshes_under(car[s])]
        nodes[node] = join(meshes, node)

    # 3. Gövde ve kabin adacık adacık.
    shell = join([bake(m) for s in BODY_SOURCES
                  for m in meshes_under(car[s])], 'shell')
    for name, faces in split(shell, BODY_RULES, 'body').items():
        nodes[name] = take_faces(shell, faces, name)

    # Motor bölmesindeki karışık parça kutulara göre bölünür.
    bay = join([bake(m) for m in meshes_under(car['engbaycrap'])], 'bay')
    rules = [(name, None, b, None) for name, b in BAY_PARTS.items()]
    for name, faces in split(bay, rules, None).items():
        nodes[name] = take_faces(bay, faces, name)

    # Göbek kapağı ve egzoz ucu kaynaktan alınır.
    hubcap = join([bake(m) for m in meshes_under(car['hubcap'])], 'hubcap')
    tip = join([bake(m) for m in meshes_under(car['exhausttip'])], 'tip')

    # 5. Eski motordan yalnız şanzıman (+X tarafı) kalır.
    old = join([bake(m) for m in meshes_under(car['4AGE'])], 'old_engine')
    gearbox = [i for faces, c, _, _ in islands(old) if c.x > 0.16
               for i in faces]
    nodes['transaxle'] = take_faces(old, gearbox, 'transaxle')

    # Seçilmeyen her şey silinir.
    keep = {*nodes.values(), hubcap, tip}
    for o in list(bpy.data.objects):
        if o not in keep:
            bpy.data.objects.remove(o)

    for name, o in nodes.items():
        recolor(o, NODE_MATERIALS.get(name, []) + CAR_MATERIALS, 'trim')
    # Kaynakta kapaklar pembe; gümüş olsun.
    recolor(hubcap, [], 'alu')
    recolor(tip, [], 'steel')

    # 4. Kabinden görünen boyalı sacın içine döşeme. Kabin kutusu: ön camın
    # altından arka camın üstüne; arka camın gerisinde yalnız tavan.
    def cabin(f):
        c = f.calc_center_median()
        if abs(c.x) > 0.9 or c.z < 0.2 or not -1.05 <= c.y <= 1.75:
            return False
        return c.y <= 1.25 or c.z > 1.0

    def high(f):
        return f.calc_center_median().z > BELT_LINE

    for key, node, test in (
            ('headliner', 'headliner', lambda f: cabin(f) and high(f)),
            ('trim_int', 'interior_trim',
             lambda f: cabin(f) and not high(f))):
        lining = inner_copy(nodes['body'], test, node + '_lining', key)
        if node in nodes:
            nodes[node] = join([nodes[node], lining], node)
        else:
            nodes[node] = lining
            lining.name = lining.data.name = node
    for door in ('door_fl', 'door_fr', 'door_rl', 'door_rr'):
        lining = inner_copy(nodes[door], lambda f: True, door + '_lining',
                            'door_card')
        nodes[door] = join([nodes[door], lining], door)

    # 1ZZ-FE.
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=engine_path)
    engine = [o for o in bpy.data.objects if o not in before]
    engine_meshes = [o for o in engine if o.type == 'MESH']
    for o in engine_meshes:
        bake(o)
        o.data.transform(ENGINE_PLACE)
    for o in engine:
        if o.type != 'MESH':
            bpy.data.objects.remove(o)
    # Kaynakta silindir kafasının bir köşesi kafanın çok altında kalmış;
    # bin kadar üçgen ona bağlanıp ince bir "V" çiziyor. Normal görünümde
    # gizli, X-ışınında görünüyor. Kafa contasının altındaki köşeler silinir.
    head = next(o for o in engine_meshes if o.name.startswith('cylinder_head'))
    gasket = next(o for o in engine_meshes if o.name.startswith('head_gasket'))
    drop_below(head, min(v.co.z for v in gasket.data.vertices) - 0.005)
    groups = {name: [] for name, _ in ENGINE_PARTS}
    for o in engine_meshes:
        name = next(n for n, prefixes in ENGINE_PARTS
                    if any(o.name.startswith(p) for p in prefixes))
        groups[name].append(o)
    for name, objects in groups.items():
        nodes[name] = join(objects, name)
        recolor(nodes[name], ENGINE_MATERIALS, 'steel')

    # 6. Tekerlekler, egzoz ve kaynakta olmayan parçalar.
    for name, center in WHEELS.items():
        nodes[name] = tire_and_rim(name, center, 1 if center[0] > 0 else -1,
                                   hubcap)
    bpy.data.objects.remove(hubcap)
    nodes.update(exhaust(tip))
    nodes['body'] = join([nodes['body'], *(
        arch_liner(c, 1 if c[0] > 0 else -1) for c in WHEELS.values())],
        'body')
    nodes['fuel_tank'] = fuel_tank()
    nodes['radiator_fan'] = radiator_fan()
    nodes['alternator'] = alternator()
    nodes['starter'] = starter()
    nodes['ac_compressor'] = ac_compressor()
    nodes['ac_condenser'] = ac_condenser()

    # Aracı yere oturt: ön lastiklerin altı z = 0. Arka disklerin merkezi
    # 2 cm alçak; arka lastiklerin yere giren kısmı basılmış gibi düzlenir.
    ground = min((nodes['wheel_fl'].matrix_world @ v.co).z
                 for v in nodes['wheel_fl'].data.vertices)
    shift = Matrix.Translation((0, 0, -ground))
    for name in ('wheel_rl', 'wheel_rr'):
        for v in nodes[name].data.vertices:
            v.co.z = max(v.co.z, ground)

    # Sadeleştirme yok: motorun ince parçalarında (kafa, karter)
    # sadeleştirme sivri üçgenler bırakıyor. Draco dosyayı küçültüyor.
    root = bpy.data.objects.new('Corolla', None)
    bpy.context.scene.collection.objects.link(root)
    total = 0
    for name, o in nodes.items():
        o.name = o.data.name = name
        o.data.transform(shift)
        total += len(o.data.polygons)
        # Parçalara ayırma düğümün merkezinden çalışsın: orijini kutunun
        # ortasına al.
        # bound_box önbellekte; yukarıdaki kaydırmayı görmez. Köşelerden.
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
    print('DÜĞÜM', len(nodes), 'YÜZ', total)


main()
