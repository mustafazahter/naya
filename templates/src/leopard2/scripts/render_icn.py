"""DM'lerdeki çizimleri (ICN) modelden üretir.

    blender -b --python render_icn.py -- ../model/product.glb cikti/

Çıkan PNG'ler JPEG'e çevrilip csdb/ altına ICN adıyla konur:

    sips -s format jpeg -s formatOptions 82 cikti/00001.png --out \\
        ../csdb/ICN-NAYATANK-AAA-D000000-0-NAYA0-00001-A-001-01.JPG
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts'))

from icn_render import render  # noqa: E402

TURRET = ['turret', 'main_gun', 'optics', 'machine_gun', 'smoke_dischargers']
POWERPACK = ['engine', 'transmission', 'radiators', 'cooling_fans',
             'air_filters', 'fuel_tanks', 'exhaust']
LEFT_RUNNING = ['track_l', 'road_wheels_l', 'suspension_l', 'idler_l',
                'sprocket_l']
# Gövdenin içini göstermek için gizlenen dış parçalar.
COVERS = ('hull', 'engine_deck', 'side_skirt_l', 'side_skirt_r', *TURRET)

# Blender'da tankın önü -Y, solu +X yönünde.
VIEWS = [
    ('00001', None, 19, (1, 0.05, 0.15), (), None, ()),
    ('00002', POWERPACK, 8.5, (0.9, 0.7, 0.9), ('engine', 'transmission'),
     None, ('hull', 'engine_deck', 'side_skirt_l', 'side_skirt_r',
            *TURRET)),
    ('00003', ['track_l'], 14, (1, -0.1, 0.12), LEFT_RUNNING, None,
     ('side_skirt_l',)),
    ('00004', ['radiators', 'cooling_fans'], 6.5, (0.5, 0.7, 1),
     ('radiators', 'cooling_fans'), None, ('hull', 'engine_deck', *TURRET)),
    ('00005', ['turret'], 8.5, (0.6, -0.7, 0.9),
     ('optics', 'machine_gun', 'smoke_dischargers'), None, ()),
    ('00006', ['idler_l'], 4.5, (1, -0.7, 0.35), ('idler_l', 'track_l'),
     None, ('side_skirt_l',)),
    ('00007', ['engine_deck'], 7, (0.5, 0.75, 1), ('engine_deck',), None,
     TURRET),
    ('00008', ['batteries'], 5, (0.3, -0.5, 1), ('batteries',), None,
     COVERS),
    ('00009', ['side_skirt_l'], 12, (1, -0.35, 0.3), ('side_skirt_l',),
     None, ()),
    ('00010', ['headlights'], 6.5, (0.45, -1, 0.45), ('headlights',), None,
     ()),
    ('00011', ['taillights'], 5, (0.45, 1, 0.3), ('taillights',), None,
     ()),
    ('00012', ['fuel_tanks'], 8, (0.9, 0.6, 0.9), ('fuel_tanks',), None,
     COVERS),
    ('00013', ['transmission'], 6.5, (0.9, 0.9, 0.8), ('transmission',),
     None, COVERS),
    ('00014', ['air_filters', 'exhaust'], 7.5, (0.9, 0.6, 1),
     ('air_filters', 'exhaust'), None, COVERS),
    ('00015', ['road_wheels_l'], 10, (1, -0.2, 0.15),
     ('road_wheels_l', 'suspension_l'), None, ('side_skirt_l',)),
    ('00016', ['turret'], 10, (-0.6, 0.7, 0.8), ('turret',), None, ()),
]

argv = sys.argv[sys.argv.index('--') + 1:]
render(argv[0], argv[1], VIEWS)
