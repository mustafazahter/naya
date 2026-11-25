"""DM'lerdeki çizimleri (ICN) modelden üretir.

Bisiklettekiyle aynı teknik çizim görünümü: beyaz zemin, gri, kontur ve
boşluk gölgesi; konusu olan parçalar turuncu. Bir görünüşte araya giren
parçalar (kaput, tekerlek) gizlenir.

    blender -b --python render_icn.py -- ../model/product.glb cikti/

Çıkan PNG'ler JPEG'e çevrilip csdb/ altına ICN adıyla konur:

    sips -s format jpeg -s formatOptions 82 cikti/00001.png --out \
        ../csdb/ICN-NAYACAR-AAA-D000000-0-NAYA0-00001-A-001-01.JPG
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts'))

from icn_render import render  # noqa: E402

ENGINE = [
    'engine_block', 'engine_head', 'engine_head_gasket', 'engine_head_cover',
    'engine_camshafts', 'engine_timing_chain', 'engine_timing_cover',
    'engine_crankshaft', 'engine_pistons', 'engine_rods', 'engine_oil_pan',
    'engine_oil_pump', 'engine_oil_filter', 'engine_water_pump',
    'engine_crank_pulley', 'engine_intake', 'engine_exhaust_manifold',
    'engine_coils', 'engine_spark_plugs', 'engine_crank_sensor',
]

# Görünüş biçimi templates/scripts/icn_render.py'de.
# Blender'da aracın önü -Y, solu +X yönünde.
VIEWS = [
    ('00001', None, 8.5, (1, 0.05, 0.12), (), None, ()),
    ('00002', ['radiator', 'battery', 'brake_booster'], 2.9,
     (0.35, -0.7, 1), ('battery', 'air_filter', 'coolant_tank',
                       'engine_oil_filter', 'brake_booster'),
     None, ('hood', 'body', 'fender_l', 'fender_r')),
    ('00003', ENGINE, 1.25, (0.6, -1, 0.55), (), ENGINE, ()),
    ('00004', (0.62, -1.29, 0.36), 1.3, (1, -0.3, 0.3),
     ('brake_caliper_front', 'brake_disc_front', 'strut_front',
      'control_arm_front', 'driveshaft_front', 'hub_front'),
     None, ('wheel_fl', 'fender_l', 'bumper_front', 'door_fl', 'body')),
    ('00005', ['engine_coils'], 0.75, (0.4, -1, 0.9),
     ('engine_coils', 'engine_spark_plugs'), ENGINE, ('engine_head_cover',)),
    ('00006', ['wheel_fl'], 1.3, (1, -0.15, 0.12), ('wheel_fl',), None, ()),
    # Kabin: tavan, sol kapılar ve sol koltuk gizli, yukarıdan çapraz.
    ('00007', ['dashboard', 'seat_front_r', 'pedals'], 2.4,
     (0.9, 0.7, 0.9), ('dashboard', 'instrument_cluster', 'steering_wheel',
                       'pedals', 'seat_front_r'),
     None, ('body', 'headliner', 'door_fl', 'door_rl', 'windshield',
            'rear_window', 'seat_front_l', 'hood', 'fender_l', 'mirror_l',
            'interior_trim')),
    # Arka süspansiyon ve fren: sol arka tekerlek ve gövde gizli.
    ('00008', (0.55, 1.33, 0.34), 1.5, (1, 0.35, 0.35),
     ('strut_rear', 'arms_rear', 'stabilizer_rear', 'hub_rear',
      'brake_caliper_rear', 'brake_disc_rear'),
     None, ('wheel_rl', 'body', 'door_rl', 'bumper_rear', 'trunk',
            'interior_trim', 'seat_rear', 'carpet', 'taillight_l')),
    # Araç altı, alttan bakış.
    ('00009', None, 9.5, (0.12, 0.08, -1),
     ('exhaust_pipe', 'catalytic_converter', 'muffler', 'fuel_tank'),
     None, ()),
    # Soğutma: kaput ve ön panel gizli.
    ('00010', ['radiator', 'radiator_fan', 'coolant_tank'], 2.2,
     (0.5, -1, 0.9), ('radiator', 'radiator_fan', 'radiator_hoses',
                      'coolant_tank', 'engine_water_pump'),
     None, ('hood', 'body', 'fender_l', 'fender_r', 'bumper_front',
            'grille', 'headlight_l', 'headlight_r', 'ac_condenser')),
    # Şarj ve marş: motor bölmesine önden ve alttan.
    ('00011', ['alternator', 'starter', 'battery'], 2.1,
     (0.1, -1, -0.35), ('alternator', 'starter', 'battery',
                       'ac_compressor'),
     None, ('hood', 'body', 'fender_l', 'fender_r', 'bumper_front',
            'grille', 'headlight_l', 'headlight_r', 'radiator',
            'radiator_fan', 'ac_condenser', 'foglight_l', 'foglight_r')),
]

argv = sys.argv[sys.argv.index('--') + 1:]
render(argv[0], argv[1], VIEWS)
