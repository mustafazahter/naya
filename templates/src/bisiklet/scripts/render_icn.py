"""DM'lerdeki çizimleri (ICN) modelden üretir.

Teknik çizim görünümü: beyaz zemin, tek renk gri, kontur ve boşluk gölgesi.
Konusu olan parçalar turuncu.

    blender -b --python render_icn.py -- ../model/product.glb cikti/

Çıkan PNG'ler JPEG'e çevrilip csdb/ altına ICN adıyla konur:

    sips -s format jpeg -s formatOptions 82 00001.png --out \
        ../csdb/ICN-NAYABIKE-AAA-D000000-0-NAYA0-00001-A-001-01.JPG
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts'))

from icn_render import render  # noqa: E402

# Görünüş biçimi templates/scripts/icn_render.py'de.
VIEWS = [
    ('00001', None, 3.2, (0, -1, 0.12), (), None, ()),
    ('00002', (-0.3, -0.1, 0.33), 1.15, (0.1, -1, 0.15),
     ('drive_chain', 'drive_crankset', 'drive_cassette', 'drive_derailleur',
      'drive_front_derailleur', 'drive_pedals'), None, ()),
    ('00003', ['brakes_front'], 0.55, (0.15, 1, 0.15), ('brakes_front',),
     None, ()),
    ('00004', ['drive_derailleur'], 0.55, (0.2, -1, 0.1),
     ('drive_derailleur',), None, ()),
    ('00005', ['wheel_rear_tire'], 1.6, (0.05, -1, 0.1),
     ('wheel_rear_tire', 'wheel_rear_rim', 'wheel_rear_spokes',
      'wheel_rear_hub'), None, ()),
]

argv = sys.argv[sys.argv.index('--') + 1:]
render(argv[0], argv[1], VIEWS)
