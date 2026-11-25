"""F-16F Block 60 modelini iki kaynak modelden kurar.

Uçak bir uçuş simülatörü modelinden geliyor: hareketli yüzeylerin çoğu
(flaperonlar, hücum kenarı flapları, yatay kuyruklar, dümen, hava frenleri,
iniş takımı kapakları) ayrı nesne, ama gövde ve kanatlar tek parça ve
içinde motor yok. Motor ayrı bir model: her parçası ayrı adlı, genel bir
çift milli turbofan kesiti. Bu betik:

1. Uçağın nesnelerini uygulamanın düğümlerine toplar (`flaperon_l`,
   `main_gear_r`...). Düğüm adı `map/parts.json`'daki `meshNodes` ile aynı.
2. Tek parça gövdeden kanatları, burun konisini (radom), hava alığını ve
   gövdeye gömülü dikey kuyruk yüzlerini ayırır. Sınırlar önce düzlemle
   kesilir; böylece parçaların kenarı testere dişi gibi kalmaz.
3. Küçük ayrıntı nesnesindeki lamba camlarını `lights` düğümüne, HUD camını
   kokpite alır; dış yükleri (füzeler, bombalar, yakıt tankları, pilonlar)
   ve HUD sembol düzlemlerini atar.
4. Turbofanı gövdeye sığacak ölçeğe getirip motor bölmesine yerleştirir;
   gondolunu ve giriş dudağını atar. Kaynakta art yakıcı yok; motorla
   lüle arasına basit bir art yakıcı kanalı yapar.
5. Malzemeleri düğüme göre yeniden renklendirir; kokpitte kaynağın kendi
   panel ve koltuk dokularını kullanır. Gerçek ölçeğe getirir, uçağın önünü
   -Y'ye çevirir ve Draco ile sıkıştırıp yazar.

    blender -b --python build_model.py -- "General Dynamics F-16D Block 60.obj" \
        Turbofan_Engine.obj textures/ ../model/product.glb

`textures/` uçak kaynağıyla gelen doku klasörü (F16D_06_T.png...).

Uçak kaynağında Z yukarı, burun +Y, uçağın solu -X yönünde. Motor
kaynağında birim milimetre, eksen +X (önden arkaya).
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

# Kaynak uçak 13,7 m; F-16'nın boyu yaklaşık 15 m.
SCALE = 1.08

# --- Malzemeler -----------------------------------------------------------

# Renkler doğrusal (linear) değerler; viewer'ın ışığında oldukları gibi değil
# daha açık görünürler, bu yüzden koyu tutuldu. Boya iki tonlu gri: üst
# yüzeyler koyu, alt yüzeyler açık (gölge kamuflajı); kanopinin önünde
# yansıma önleyici koyu panel.
PALETTE = {
    'paint': ((0.075, 0.083, 0.095), 0.55, 0.0),
    'paint_belly': ((0.17, 0.18, 0.195), 0.55, 0.0),
    'paint_dark': ((0.03, 0.033, 0.038), 0.6, 0.0),
    'antiglare': ((0.012, 0.013, 0.015), 0.8, 0.0),
    'radome': ((0.03, 0.032, 0.036), 0.45, 0.0),
    'glass': ((0.30, 0.24, 0.10), 0.05, 0.3),
    'frame': ((0.035, 0.037, 0.04), 0.6, 0.0),
    'interior': ((0.045, 0.047, 0.05), 0.75, 0.0),
    'screen': ((0.006, 0.008, 0.008), 0.15, 0.0),
    'bay': ((0.10, 0.105, 0.11), 0.7, 0.0),
    'gear': ((0.50, 0.51, 0.52), 0.45, 0.1),
    'rubber': ((0.018, 0.018, 0.02), 0.85, 0.0),
    'rim': ((0.42, 0.43, 0.45), 0.35, 0.8),
    'brake': ((0.10, 0.095, 0.09), 0.5, 0.9),
    'steel': ((0.30, 0.31, 0.33), 0.35, 1.0),
    'titanium': ((0.22, 0.19, 0.16), 0.4, 1.0),
    'hot': ((0.20, 0.11, 0.06), 0.5, 1.0),
    'liner': ((0.05, 0.042, 0.036), 0.8, 0.2),
    'alu': ((0.42, 0.43, 0.45), 0.4, 1.0),
    'blade': ((0.38, 0.40, 0.43), 0.3, 1.0),
    'bronze': ((0.45, 0.28, 0.10), 0.35, 1.0),
    'compressor': ((0.10, 0.20, 0.32), 0.35, 1.0),
    'light_red': ((0.60, 0.02, 0.02), 0.2, 0.0),
    'light_green': ((0.02, 0.45, 0.06), 0.2, 0.0),
    'light_white': ((0.80, 0.80, 0.75), 0.2, 0.0),
}

# Lambalar hafifçe kendi ışığını verir; uzaktan da seçilsinler.
EMISSIVE = {'light_red', 'light_green', 'light_white'}

NODE_COLORS = {
    'radome': 'radome', 'canopy': 'frame', 'cockpit': 'interior',
    'nose_gear': 'gear', 'main_gear_l': 'gear', 'main_gear_r': 'gear',
    'tail_hook': 'gear', 'engine_nozzle': 'titanium',
    'afterburner': 'hot', 'engine_casing': 'alu', 'engine_fan': 'blade',
    'engine_lpc': 'compressor', 'engine_hpc': 'compressor',
    'engine_combustor': 'hot', 'engine_hpt': 'hot', 'engine_lpt': 'hot',
    'engine_shafts': 'bronze', 'engine_gearbox': 'alu',
    'speed_brakes': 'paint_dark', 'conformal_tanks': 'paint',
    'lights': 'light_white',
}

# Kaynak malzeme adındaki parça → renk (kanopi camı, kapalı ekranlar).
SOURCE_MATERIALS = [('glass', 'glass')]

# Kokpitte kaynağın kendi dokuları: malzeme adı → doku dosyası. Ekranlar
# (ins.5, ins.6) doku yerine kapalı ekran rengi alır: uçak yerde, bakımda.
COCKPIT_TEXTURES = {
    'cock_2.0': 'F16D_06_T.png',       # koltuklar, kumanda kolları, kaporta
    'cock_2.1': 'F16D_VC_01_C.png',    # konsol gövdeleri
    'cock_2.2': 'F16D_VC_02_C.png',    # yan konsol panelleri
    'cock_2.3': 'F16D_VC_03_C.png',    # panel ayrıntıları
    'cock_2.4': 'F16D_VC_GAU3D_01_C.png',  # göstergeler
    'ins.7': 'F16D_VC_GAU3D_02_C.png',
    'poly_34.0': 'Gauges2.png',        # yapay ufuk küresi
}
COCKPIT_FLAT = {'ins.5': 'screen', 'ins.6': 'screen', 'cock.0': 'interior'}


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
        bsdf.inputs['Alpha'].default_value = 0.3
        m.blend_method = 'BLEND'
    if key in EMISSIVE:
        bsdf.inputs['Emission Color'].default_value = (*color, 1)
        bsdf.inputs['Emission Strength'].default_value = 0.6
    cache[key] = m
    return m


def textured(filename, textures, cache={}):
    """Kokpit dokusu bağlı malzeme."""
    if filename in cache:
        return cache[filename]
    m = bpy.data.materials.new(f'naya_tex_{filename.split(".")[0]}')
    m.use_nodes = True
    tree = m.node_tree
    bsdf = next(n for n in tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Roughness'].default_value = 0.7
    image = tree.nodes.new('ShaderNodeTexImage')
    image.image = bpy.data.images.load(os.path.join(textures, filename))
    tree.links.new(image.outputs['Color'], bsdf.inputs['Base Color'])
    cache[filename] = m
    return m


def recolor(obj, default, textures=None):
    for slot in obj.material_slots:
        name = slot.material.name if slot.material else ''
        if name.startswith('naya_'):
            continue
        if textures and name in COCKPIT_TEXTURES:
            slot.material = textured(COCKPIT_TEXTURES[name], textures)
        elif textures and name in COCKPIT_FLAT:
            slot.material = material(COCKPIT_FLAT[name])
        else:
            slot.material = material(next(
                (k for p, k in SOURCE_MATERIALS if p in name), default))
    if not obj.material_slots:
        obj.data.materials.append(material(default))


def ray_test(mesh):
    """covered(merkez, yön): merkezden o yöne atılan ışın aynı ağın başka
    bir yüzüne çarpıyor mu? Normali ters yüzlerde de doğru sonuç verir."""
    tree = BVHTree.FromPolygons([v.co for v in mesh.vertices],
                                [p.vertices for p in mesh.polygons])

    def covered(c, direction, near=0.002):
        """[near]: bu uzaklıktan yakın çarpmalar sayılmaz."""
        hit = tree.ray_cast(c + direction * near, direction, 3.0)
        return hit[0] is not None
    return covered


def two_tone(obj, fuselage=False):
    """Gövde boyasını iki tona böler: alt yüzeyler açık gri.

    Kaynakta bazı alt yüzlerin normali yukarı bakıyor; normale göre
    boyayınca kanat altları yamalı çıkıyordu. Bunun yerine yüzün
    merkezinden dikey ışın atılır: üstünde aynı parçanın başka bir yüzü
    olan ve altında yüzü olmayan yüz alt yüzeydir. Gövdenin yanları da
    böylece orta hattan ikiye ayrılır.
    [fuselage] gövde için: kanopinin önündeki üst şerit koyulaşır (kaynak
    koordinatlarında, burun +Y). Gövdenin uzun üçgenlerinin merkezi kabuğun
    biraz içinde kalır; aşağı atılan ışın hemen alttaki kabuğa çarpıp yüzü
    üst renkte bırakıyordu, bu yüzden yakın çarpmalar sayılmaz. Kokpit
    açıklığının altında yukarıda yüz olmadığından orada normale de bakılır.
    """
    names = [s.material.name for s in obj.material_slots]
    if 'naya_paint' not in names:
        return
    # Birleştirilen nesnelerden aynı boya birden çok yuvada kalabiliyor;
    # yalnız ilkine bakınca yüzlerin bir kısmı tek tonda kalıyordu.
    paint = {i for i, n in enumerate(names) if n == 'naya_paint'}
    for key in ('paint_belly', 'antiglare'):
        if material(key).name not in names:
            obj.data.materials.append(material(key))
            names.append(material(key).name)
    belly = names.index('naya_paint_belly')
    dark = names.index('naya_antiglare')
    mesh = obj.data
    covered = ray_test(mesh)
    up, down = Vector((0, 0, 1)), Vector((0, 0, -1))

    for p in mesh.polygons:
        if p.material_index not in paint:
            continue
        c = p.center
        above = covered(c, up)
        if fuselage:
            if (4.55 < c.y < 5.6 and abs(c.x) < 0.32 and c.z > 1.9
                    and not above):
                p.material_index = dark
            elif not covered(c, down, 0.12) and (
                    above or p.normal.z < -0.5):
                p.material_index = belly
        elif above and not covered(c, down):
            p.material_index = belly


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
    # Kanopi: cam ve çerçeve (yaylar, kilit rayları).
    'poly_30': 'canopy', 'poly_29': 'canopy',
    # Kokpit: kabin teknesi ve kenarları, koltuklar, paneller, ekranlar.
    'cock': 'cockpit', 'cock_2': 'cockpit', 'ins': 'cockpit',
    'screen1': 'cockpit', 'screen2': 'cockpit', 'screen3': 'cockpit',
    'screen4': 'cockpit', 'poly_19': 'cockpit', 'poly_20': 'cockpit',
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

# Dış yükler, boş nesneler ve HUD'un sembol düzlemleri (simülatörün çizdiği
# göstergeler; donanım değil) atılır.
DROP = ('extra1', 'extra2', 'extra3', 'extra4', 'extra5', 'wheel', 'HUD',
        'velo_vec', 'pitch_ladder')

# İniş takımı kapakları gövde parçası; alt gövde boyasını alır.
DOORS = ('poly_10', 'poly_11', 'poly_12', 'poly_3', 'poly_13', 'poly_14')

# Kaynaktaki tekerlekler 16 kenarlı, dikmeyle aynı renkte. Yerlerine lastik,
# jant, göbek ve (ana tekerleklerde) fren diski yapılır. Kaynak
# koordinatlarında (merkez, yarıçap, jant yarıçapı, genişlik, frenli mi).
WHEELS = {
    'main_gear_l': ((-1.23, -1.15, 0.35), 0.32, 0.19, 0.22, True),
    'main_gear_r': ((1.19, -1.15, 0.32), 0.32, 0.19, 0.22, True),
    'nose_gear': ((0.01, 2.62, 0.22), 0.225, 0.12, 0.13, False),
}

# Gövdeyi bölen düzlemler (kaynak koordinatlarında): radomun arka kenarı ve
# hava alığı kutusu. Yüzler önce bunlarla kesilir, sonra merkezine göre
# düğüme gider.
RADOME_Y = 5.55
WING_BOX = ((1.08, 6.0), (-2.75, 1.3), (1.45, 2.3))  # x yanın mutlak değeri
INTAKE_BOX = ((-0.8, 0.8), (1.6, 3.6), (-1.0, 1.62))

# İniş takımı yuvaları: gövdenin altında kapakların arasında kalan açıklık.
# Alt yüzün bu dikdörtgenlerdeki kısmı koyu yuva rengini alır.
# (x aralığı, y aralığı).
BAYS = [((-0.62, -0.12), (-1.15, 0.38)), ((0.12, 0.62), (-1.15, 0.38)),
        ((-0.16, 0.16), (1.30, 2.55))]


def body_face(c, mat):
    """Tek parça gövdenin bir yüzü hangi düğüme gider. [mat] kaynak
    malzemesi: kaynakta kanatların ve dikey kuyruğun dokusu aynı
    (`body.1`)."""
    if c.y > RADOME_Y:
        return 'radome'
    if mat == 'body.1' and abs(c.x) < 0.25 and c.z > 2.6:
        # Gövdenin üstünde kalan kanat dokulu yüzler dikey kuyruğun
        # gövdeye gömülü kökü ve ucu; önceden gövdeye düşüyordu.
        return 'vertical_tail'
    (x0, x1), (y0, y1), (z0, z1) = WING_BOX
    if (x0 < abs(c.x) < x1 and y0 < c.y < y1 and z0 < c.z < z1) or (
            mat == 'body.3' and abs(c.x) > 4.2):
        # Kanat ve kanat ucu rayları.
        return 'wing_l' if c.x < 0 else 'wing_r'
    (x0, x1), (y0, y1), (z0, z1) = INTAKE_BOX
    if x0 < c.x < x1 and y0 < c.y < y1 and z0 < c.z < z1:
        return 'intake'
    return 'fuselage'


def parts_face(c, mat):
    """Küçük ayrıntılar nesnesinin (`parts`) yüzleri: lamba camları,
    HUD camı, gövde üstü küçük parçalar."""
    if mat == 'cft.0':
        # Konformal tankların üstündeki küçük kapaklar; gövdeye bağlı
        # değil, tankın üstünde duruyorlar.
        return 'conformal_tanks'
    if mat != 'glass':
        return 'fuselage'
    if abs(c.x) < 0.3 and 3.8 < c.y < 4.5 and c.z > 2.3:
        return 'cockpit'
    return 'lights'


def light_color(c):
    """Seyir lambalarının rengi: sol kanat ucu kırmızı, sağ yeşil, gerisi
    (kuyruk, iniş ve taksi lambaları) beyaz. Kaynak koordinatlarında."""
    if c.x < -3:
        return 'light_red'
    if c.x > 3:
        return 'light_green'
    return 'light_white'


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


def cut(obj, planes, near=None):
    """Nesnenin yüzlerini düzlemlerle keser; düzlemi kesen yüz ikiye ayrılır.
    [near] verilirse yalnız merkezi bu kutuya (x, y, z aralıkları) düşen
    yüzler kesilir; kalan yüzlere boşuna kenar eklenmez."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for co, no in planes:
        faces = [f for f in bm.faces if near is None or all(
            lo < v < hi for v, (lo, hi) in zip(f.calc_center_median(), near))]
        geom = list({e for f in faces for e in f.edges}) + faces + list(
            {v for f in faces for v in f.verts})
        bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-5,
                               plane_co=Vector(co), plane_no=Vector(no))
    bm.to_mesh(obj.data)
    bm.free()


def split_by(obj, classify):
    """Nesnenin yüzlerini [classify](merkez, malzeme adı) sonucuna göre
    düğümlere ayırır."""
    mats = [m.name if m else '' for m in obj.data.materials]
    faces = {}
    for p in obj.data.polygons:
        node = classify(p.center, mats[p.material_index] if mats else '')
        faces.setdefault(node, []).append(p.index)
    return {node: take_faces(obj, f, node) for node, f in faces.items()}


def drop_caps(obj, y0, y1):
    """Lülenin ve gövde arkasının içini kapatan düz diskleri siler. Lüleden
    bakınca art yakıcı astarı yerine gri bir kapak görünüyordu. Kaynak
    koordinatlarında, eksen lülenin ekseni."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    doomed = []
    for f in bm.faces:
        c = f.calc_center_median()
        r = math.hypot(c.x, c.z - ENGINE_FRONT.z)
        if y0 < c.y < y1 and r < 0.42 and abs(f.normal.y) > 0.8:
            doomed.append(f)
    bmesh.ops.delete(bm, geom=doomed, context='FACES')
    bm.to_mesh(obj.data)
    bm.free()


def drop_wheel(obj, center, radius, width):
    """Merkezi tekerlek ekseninde olan adacıkları (lastik, jant, göbek)
    siler."""
    center = Vector(center)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    seen, doomed = set(), []
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
        c = (lo + hi) / 2
        if (abs(c.y - center.y) < 0.03 and abs(c.z - center.z) < 0.03
                and abs(c.x - center.x) < width / 2 + 0.04
                and (hi - lo).y < 2 * radius + 0.05):
            doomed += group
    bmesh.ops.delete(bm, geom=doomed, context='FACES')
    bm.to_mesh(obj.data)
    bm.free()


def wheel(center, radius, rim, width, brake):
    """Ekseni X olan tekerlek: lastik, jant, göbek, fren diski."""
    tube = (radius - rim) / 2
    pieces = []
    bpy.ops.mesh.primitive_torus_add(
        major_segments=64, minor_segments=16, major_radius=rim + tube,
        minor_radius=tube, location=center, rotation=(0, math.pi / 2, 0))
    tire = bpy.context.active_object
    tire.scale = (1, 1, width / (2 * tube))
    pieces.append((tire, 'rubber'))
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=48, radius=rim * 1.02, depth=width * 0.82, location=center,
        rotation=(0, math.pi / 2, 0))
    pieces.append((bpy.context.active_object, 'rim'))
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=24, radius=rim * 0.35, depth=width * 0.95, location=center,
        rotation=(0, math.pi / 2, 0))
    pieces.append((bpy.context.active_object, 'steel'))
    if brake:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=48, radius=rim * 0.8, depth=width * 0.9,
            location=center, rotation=(0, math.pi / 2, 0))
        pieces.append((bpy.context.active_object, 'brake'))
    bpy.context.view_layer.update()
    objects = []
    for obj, key in pieces:
        bake(obj)
        obj.data.materials.append(material(key))
        objects.append(obj)
    return objects


def paint_bays(obj):
    """Gövde altındaki iniş takımı yuvalarını koyu yuva rengine boyar.
    Yuva sınırları önce düzlemle kesilir ki kenar düz olsun."""
    for (x0, x1), (y0, y1) in BAYS:
        near = ((x0 - 0.3, x1 + 0.3), (y0 - 0.3, y1 + 0.3), (-1, 1.6))
        cut(obj, [((x0, 0, 0), (1, 0, 0)), ((x1, 0, 0), (1, 0, 0)),
                  ((0, y0, 0), (0, 1, 0)), ((0, y1, 0), (0, 1, 0))], near)
    obj.data.materials.append(material('bay'))
    bay = len(obj.data.materials) - 1
    covered = ray_test(obj.data)
    down = Vector((0, 0, -1))
    for p in obj.data.polygons:
        c = p.center
        if c.z < 1.6 and not covered(c, down) and any(
                x0 < c.x < x1 and y0 < c.y < y1 for (x0, x1), (y0, y1) in BAYS):
            p.material_index = bay


def paint_tunnel(obj):
    """Gövdenin lüleye uzanan iç kabuğu (egzoz tüneli) dış boyayla
    boyanmıştı; lüleden bakınca gri bir boru görünüyordu. Art yakıcı
    astarıyla aynı koyu renge boyanır. Kaynak koordinatlarında."""
    obj.data.materials.append(material('liner'))
    liner = len(obj.data.materials) - 1
    for p in obj.data.polygons:
        c = p.center
        if c.y < -3.3 and math.hypot(c.x, c.z - ENGINE_FRONT.z) < 0.5:
            p.material_index = liner


def color_lights(obj):
    names = [m.name for m in obj.data.materials]
    for key in ('light_red', 'light_green', 'light_white'):
        if material(key).name not in names:
            obj.data.materials.append(material(key))
            names.append(material(key).name)
    for p in obj.data.polygons:
        p.material_index = names.index(material(light_color(p.center)).name)


def afterburner():
    """Motorun arkasından lüleye uzanan kanal, alev tutucu halkaları ve
    yakıt püskürtme halkası. Kanalın içi koyu astar rengi; lüleden
    bakınca boşluk değil astar görünür."""
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
    # Türbin çıkış konisi: lüleden bakınca kanalın dibini kapatır.
    bpy.ops.mesh.primitive_cone_add(
        vertices=32, radius1=0.3, radius2=0.06, depth=0.35,
        location=(0, front - 0.17, ENGINE_FRONT.z),
        rotation=(math.pi / 2, 0, 0))
    pieces.append(bpy.context.active_object)
    bpy.context.view_layer.update()
    for p in pieces:
        bake(p)
    pieces[0].data.materials.append(material('liner'))
    for p in pieces[1:]:
        p.data.materials.append(material('hot'))
    return join(pieces, 'afterburner')


# --- Kurulum ----------------------------------------------------------------

def main():
    (aircraft_path, engine_path, textures,
     out_path) = sys.argv[sys.argv.index('--') + 1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=aircraft_path)
    bpy.context.view_layer.update()
    source = {o.name: bake(o) for o in bpy.data.objects if o.type == 'MESH'}

    groups = {}
    for name, obj in source.items():
        if name.startswith(DROP) or not obj.data.polygons:
            bpy.data.objects.remove(obj)
            continue
        if name == 'engines':
            drop_caps(obj, -5.8, -5.3)
        if name == 'body':
            drop_caps(obj, -3.9, -3.5)
            cut(obj, [((0, RADOME_Y, 0), (0, 1, 0))],
                ((-1, 1), (RADOME_Y - 0.6, RADOME_Y + 0.6), (0, 4)))
            (x0, x1), (y0, y1), (z0, z1) = WING_BOX
            for side in (-1, 1):
                xs = sorted((side * (x0 - 0.4), side * x1))
                cut(obj, [((side * x0, 0, 0), (1, 0, 0)),
                          ((0, y0, 0), (0, 1, 0)), ((0, y1, 0), (0, 1, 0)),
                          ((0, 0, z0), (0, 0, 1)), ((0, 0, z1), (0, 0, 1))],
                    (xs, (y0 - 0.4, y1 + 0.4), (z0 - 0.4, z1 + 0.4)))
            (x0, x1), (y0, y1), (z0, z1) = INTAKE_BOX
            cut(obj, [((x0, 0, 0), (1, 0, 0)), ((x1, 0, 0), (1, 0, 0)),
                      ((0, y0, 0), (0, 1, 0)), ((0, y1, 0), (0, 1, 0)),
                      ((0, 0, z1), (0, 0, 1))],
                ((x0 - 0.4, x1 + 0.4), (y0 - 0.4, y1 + 0.4), (0, z1 + 0.4)))
        if name in ('body', 'parts'):
            classify = body_face if name == 'body' else parts_face
            for node, piece in split_by(obj, classify).items():
                groups.setdefault(node, []).append(piece)
            bpy.data.objects.remove(obj)
            continue
        if name in DOORS:
            obj.data.materials.clear()
            obj.data.materials.append(material('paint_belly'))
        groups.setdefault(AIRCRAFT_PARTS.get(name, 'fuselage'), []).append(obj)
    nodes = {node: join(objs, node) for node, objs in groups.items()}
    for node, (center, radius, rim, width, brake) in WHEELS.items():
        drop_wheel(nodes[node], center, radius, width)
        nodes[node] = join([nodes[node], *wheel(center, radius, rim, width,
                                                brake)], node)
    for node, obj in nodes.items():
        recolor(obj, NODE_COLORS.get(node, 'paint'),
                textures if node == 'cockpit' else None)
        # Dikey kuyruk ve dümen tümüyle üst renkte.
        if node not in ('vertical_tail', 'rudder'):
            two_tone(obj, fuselage=node == 'fuselage')
    paint_bays(nodes['fuselage'])
    paint_tunnel(nodes['fuselage'])
    color_lights(nodes['lights'])

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
        export_image_format='JPEG',
        export_jpeg_quality=80,
        export_draco_mesh_compression_enable=True,
        export_draco_mesh_compression_level=7,
    )
    print('DÜĞÜM', len(nodes), sorted(nodes), 'ÜÇGEN', total)


main()
