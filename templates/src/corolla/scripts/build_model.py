"""Corolla modelini iki kaynak modelden kurar.

Gövde ve şasi bir sürüş oyunu modundan (E100 Corolla) geliyor: her parçanın
birkaç seçeneği var (tampon, ızgara, fren...), lastikler yok ve hiçbir
malzemenin rengi yok. Motor ayrı bir model (1ZZ-FE); her parçası ayrı
nesne. Bu betik:

1. Her parça için tek bir seçeneği alır, gerisini atar.
2. Uygulamadaki parça haritasına göre düğümlere toplar (`door_fl`,
   `engine_head`...). Düğüm adı `map/parts.json`'daki `meshNodes` ile aynı.
3. Eski düşük ayrıntılı motoru (4A-GE) çıkarır, şanzımanı ondan ayırıp
   tutar, yerine 1ZZ-FE'yi koyar.
4. Lastik, jant ve susturucuyu kendisi yapar.
5. Malzemeleri adlarına göre yeniden renklendirir.
6. Draco ile sıkıştırıp yazar.

    blender -b --python build_model.py -- govde.glb motor.glb ../model/product.glb

Blender'da Z yukarı, aracın önü -Y yönünde; dışa aktarırken glTF'nin Y
yukarı düzenine çevrilir.
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
    'body': ['body', 'body2', 'windshield', 'backlight', 'chmsl', 'skirts',
             'trunkmid', 'lettering_DX', 'antenna_close', 'needle_speedo',
             'needle_tacho', 'console5', 'mudflaps', 'mudflap_FL',
             'mudflap_FR', 'fenderplastic_L', 'fenderplastic_R'],
    'hood': ['hood'],
    'trunk': ['trunk'],
    'door_fl': ['door_FL', 'doorglass_FL', 'doorpanel_FL',
                'basedoorpanel_FL', 'doorplastic_FL'],
    'door_fr': ['door_FR', 'doorglass_FR', 'doorpanel_FR',
                'basedoorpanel_FR', 'doorplastic_FR'],
    'door_rl': ['door_RL', 'doorglass_RL', 'doorplastic_RL'],
    'door_rr': ['door_RR', 'doorglass_RR', 'doorplastic_RR'],
    'fender_l': ['fender_L'],
    'fender_r': ['fender_R'],
    'bumper_front': ['bumper_F'],
    'bumper_rear': ['bumper_R'],
    'grille': ['grille', 'logo_F_grille'],
    'headlight_l': ['headlightframe_L', 'headlightglass_L'],
    'headlight_r': ['headlightframe_R', 'headlightglass_R'],
    'taillight_l': ['taillight_L'],
    'taillight_r': ['taillight_R'],
    'mirror_l': ['mirror_L'],
    'mirror_r': ['mirror_R'],
    'steering_wheel': ['steer'],
    'radiator': ['radiator', 'radsupport'],
    'strut_front': ['strut_F', 'hub_F'],
    'control_arm_front': ['lowerarm_F'],
    'driveshaft_front': ['halfshaft_F'],
    'brake_front': ['brake_F', 'brakedisc_FL', 'brakedisc_FR'],
    'brake_rear': ['brake_R', 'brakedisc_RL', 'brakedisc_RR'],
    'suspension_rear': ['coilover_R', 'trailingarm_R', 'lowerarm_R',
                        'upperarm_R', 'swaybar_R', 'tierod_R',
                        'armbracket_R', 'subframe_R', 'hub_R'],
}

# Motor bölmesindeki karışık parçadan (`engbaycrap`) kümeler, konumlarına
# göre. (merkez, yarı boyut) kutusuna düşen adacıklar o düğüme gider.
BAY_PARTS = {
    'battery': ((0.43, -1.67, 0.65), (0.16, 0.12, 0.13)),
    'steering_rack': ((0.01, -1.33, 0.41), (0.72, 0.06, 0.08)),
    'subframe_front': ((0.0, -1.44, 0.27), (0.51, 0.54, 0.06)),
    'coolant_tank': ((-0.43, -1.71, 0.71), (0.24, 0.23, 0.10)),
    'brake_booster': ((0.45, -1.15, 0.78), (0.20, 0.20, 0.20)),
    'air_filter': ((0.10, -1.45, 0.77), (0.42, 0.40, 0.17)),
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
    ('engine_pistons', ['piston_']),
    ('engine_rods', ['connecting_rod', 'rod_cap']),
    ('engine_crankshaft', ['crankshaft', 'crank_sensor', 'crank_position']),
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

# --- Malzemeler -----------------------------------------------------------

PALETTE = {
    'paint': ((0.42, 0.04, 0.05), 0.35, 0.0),
    'trim': ((0.03, 0.03, 0.035), 0.6, 0.0),
    'rubber': ((0.025, 0.025, 0.025), 0.9, 0.0),
    'chrome': ((0.85, 0.86, 0.88), 0.12, 1.0),
    'glass': ((0.55, 0.62, 0.66), 0.05, 0.0),
    'lens': ((0.9, 0.92, 0.95), 0.05, 0.0),
    'tail': ((0.55, 0.02, 0.02), 0.15, 0.0),
    'amber': ((0.9, 0.45, 0.05), 0.2, 0.0),
    'interior': ((0.16, 0.16, 0.17), 0.8, 0.0),
    'chassis': ((0.12, 0.12, 0.13), 0.55, 0.6),
    'steel': ((0.5, 0.51, 0.53), 0.35, 1.0),
    'alu': ((0.66, 0.67, 0.69), 0.4, 1.0),
    'battery': ((0.05, 0.05, 0.06), 0.6, 0.0),
    'reservoir': ((0.85, 0.85, 0.8), 0.5, 0.0),
}

# Gövde malzeme adı → paletteki renk. Listede olmayan `trim` olur.
CAR_MATERIALS = [
    ('glass', 'glass'), ('headlight', 'lens'), ('highbeam', 'lens'),
    ('signal', 'amber'), ('taillight', 'tail'), ('reverselight', 'lens'),
    ('chmsl', 'tail'), ('lights', 'tail'), ('chrome', 'chrome'),
    ('silver', 'chrome'), ('badge', 'chrome'), ('wheel', 'alu'),
    ('body2', 'alu'), ('velur', 'interior'), ('lether', 'interior'),
    ('floor', 'interior'), ('mats', 'interior'), ('dashboard', 'interior'),
    ('detail', 'interior'), ('misc', 'interior'), ('plastic', 'interior'),
    ('pessima', 'chassis'), ('engine', 'steel'), ('undercarriage', 'chassis'),
    ('CorollaDX_body', 'paint'), ('doorshut', 'paint'), ('dark', 'trim'),
    ('black', 'trim'), ('nodamage', 'trim'), ('CorollaDX-', 'paint'),
    ('CorollaDX.', 'paint'), ('CorollaDX', 'paint'),
]

# Motor malzemeleri zaten anlamlı adlı; yalnız renkleri düzeltilir.
ENGINE_MATERIALS = [
    ('paint_black', 'trim'), ('black_plastic', 'trim'), ('rubber', 'rubber'),
    ('sensor_plastic', 'trim'), ('paint_blue', 'battery'),
    ('nylon', 'reservoir'), ('alu', 'alu'), ('gasket', 'steel'),
]


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


def recolor(obj, rules, default):
    for slot in obj.material_slots:
        name = slot.material.name if slot.material else ''
        key = next((k for pattern, k in rules if pattern in name), default)
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


def islands(obj):
    """Mesh'in birbirine değmeyen parçalarının yüz listeleri."""
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
            group.append(f.index)
            for edge in f.edges:
                for other in edge.link_faces:
                    if other.index not in seen:
                        seen.add(other.index)
                        stack.append(other)
        center = sum((bm.faces[i].calc_center_median() for i in group),
                     Vector()) / len(group)
        result.append((group, center))
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


def exhaust():
    """Motor altından arka tampona egzoz borusu ve susturucu."""
    path = [(-0.10, -1.05, 0.24), (-0.10, 0.20, 0.22), (-0.35, 1.25, 0.24),
            (-0.52, 1.95, 0.27)]
    pieces = []
    for a, b in zip(path, path[1:]):
        a, b = Vector(a), Vector(b)
        d = b - a
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.025, depth=d.length, location=(a + b) / 2)
        pipe = bpy.context.active_object
        pipe.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
        pieces.append(pipe)
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=24, radius=0.11, depth=0.45, location=(-0.36, 1.5, 0.26))
    muffler = bpy.context.active_object
    muffler.rotation_euler = (Vector((-0.17, 0.7, 0.03))).to_track_quat(
        'Z', 'Y').to_euler()
    muffler.scale = (1, 0.6, 1)
    pieces.append(muffler)
    # Döndürme ve ölçek matrix_world'e ancak sahne güncellenince yansır.
    bpy.context.view_layer.update()
    for p in pieces:
        p.data.materials.append(material('steel'))
        bake(p)
    return join(pieces, 'exhaust')


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

    # Motor bölmesindeki karışık parça kutulara göre bölünür.
    bay = join([bake(m) for m in meshes_under(car['engbaycrap'])], 'bay')
    taken = {name: [] for name in BAY_PARTS}
    for faces, center in islands(bay):
        for name, box in BAY_PARTS.items():
            if inside(center, box):
                taken[name] += faces
                break
    for name, faces in taken.items():
        nodes[name] = take_faces(bay, faces, name)

    # Göbek kapağı tekerleklerde kullanılır.
    hubcap = join([bake(m) for m in meshes_under(car['hubcap'])], 'hubcap')

    # 3. Eski motordan yalnız şanzıman (+X tarafı) kalır.
    old = join([bake(m) for m in meshes_under(car['4AGE'])], 'old_engine')
    gearbox = [i for faces, c in islands(old) if c.x > 0.16 for i in faces]
    nodes['transaxle'] = take_faces(old, gearbox, 'transaxle')

    # Seçilmeyen her şey silinir.
    keep = {*nodes.values(), hubcap}
    for o in list(bpy.data.objects):
        if o not in keep:
            bpy.data.objects.remove(o)

    for o in nodes.values():
        recolor(o, CAR_MATERIALS, 'trim')
    # Kaynakta kapaklar pembe; gümüş olsun.
    recolor(hubcap, [], 'alu')
    recolor(nodes['battery'], [], 'battery')
    recolor(nodes['coolant_tank'], [], 'reservoir')
    recolor(nodes['transaxle'], [], 'alu')
    recolor(nodes['air_filter'], [], 'trim')
    recolor(nodes['steering_wheel'], [], 'interior')

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

    # 4. Tekerlekler ve egzoz.
    for name, center in WHEELS.items():
        nodes[name] = tire_and_rim(name, center, 1 if center[0] > 0 else -1,
                                   hubcap)
    bpy.data.objects.remove(hubcap)
    nodes['exhaust'] = exhaust()

    # Aracı yere oturt: lastiklerin altı z = 0.
    ground = min((nodes['wheel_fl'].matrix_world @ v.co).z
                 for v in nodes['wheel_fl'].data.vertices)
    shift = Matrix.Translation((0, 0, -ground))

    # 6. Sadeleştirme yok: motorun ince parçalarında (kafa, karter)
    # sadeleştirme sivri üçgenler bırakıyor. Toplam ~530 bin üçgen,
    # bisikletle aynı düzeyde; Draco dosyayı küçültüyor.
    root = bpy.data.objects.new('Corolla', None)
    bpy.context.scene.collection.objects.link(root)
    total = 0
    for o in nodes.values():
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
