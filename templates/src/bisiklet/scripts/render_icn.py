"""DM'lerdeki çizimleri (ICN) modelden üretir.

Teknik çizim görünümü: beyaz zemin, tek renk gri, kontur ve boşluk gölgesi.
Konusu olan parçalar turuncu.

    blender -b --python render_icn.py -- ../model/product.glb cikti/

Çıkan PNG'ler JPEG'e çevrilip csdb/ altına ICN adıyla konur:

    sips -s format jpeg -s formatOptions 82 00001.png --out \
        ../csdb/ICN-NAYABIKE-AAA-D000000-0-NAYA0-00001-A-001-01.JPG

Başlıklar make_content.py'deki FIGURES tablosunda.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts'))

from icn_render import render  # noqa: E402

DRIVE = ('drive_chain', 'drive_crankset', 'drive_bottom_bracket',
         'drive_cassette', 'drive_derailleur', 'drive_front_derailleur',
         'drive_pedals')
REAR_WHEEL = ('wheel_rear_tire', 'wheel_rear_rim', 'wheel_rear_spokes',
              'wheel_rear_hub', 'wheel_rear_tube')

# Görünüş biçimi templates/scripts/icn_render.py'de. Blender'da bisikletin
# önü +X, zincir tarafı (sağ) -Y yönünde.
VIEWS = [
    ('00001', None, 3.2, (0, -1, 0.12), (), None, ()),
    ('00002', (-0.3, -0.1, 0.33), 1.15, (0.1, -1, 0.15), DRIVE, None, ()),
    ('00003', ['brakes_front'], 0.55, (0.15, 1, 0.15),
     ('brakes_front', 'brakes_front_rotor'), None, ()),
    ('00004', ['drive_derailleur'], 0.55, (0.2, -1, 0.1),
     ('drive_derailleur',), None, ()),
    ('00005', ['wheel_rear_tire'], 1.6, (0.05, -1, 0.1), REAR_WHEEL, None,
     ()),
    ('00006', (0.47, 0, 0.7), 1.5, (0.7, -1, 0.1), ('fork',), None, ()),
    ('00007', ['handlebar'], 1.0, (1, -0.55, 0.75), ('handlebar',), None,
     ()),
    ('00008', ['drive_crankset'], 0.75, (0.25, -1, 0.25),
     ('drive_crankset', 'drive_bottom_bracket'), None, ()),
    ('00009', ['drive_cassette'], 0.5, (0.35, -1, 0.25),
     ('drive_cassette', 'wheel_rear_hub'), None, ()),
    ('00010', ['saddle', 'seatpost'], 0.8, (0.3, -1, 0.2),
     ('saddle', 'seatpost'), None, ()),
    ('00011', ['wheel_front_hub'], 0.4, (0.35, 1, 0.2),
     ('wheel_front_hub',), None, ()),
    ('00012', ['brakes_rear'], 0.55, (-0.15, 1, 0.15),
     ('brakes_rear', 'brakes_rear_rotor'), None, ()),
    ('00013', (0, 0, 0.55), 2.6, (0.1, -1, 0.3),
     ('cables_shift', 'cables_brake'), None, ()),
    ('00014', ['drive_front_derailleur'], 0.4, (0.3, -1, 0.2),
     ('drive_front_derailleur',), None, ()),
]

argv = sys.argv[sys.argv.index('--') + 1:]
render(argv[0], argv[1], VIEWS)
