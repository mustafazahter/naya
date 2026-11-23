"""DM'lerdeki çizimleri (ICN) modelden üretir.

    blender -b --python render_icn.py -- ../model/product.glb cikti/

Çıkan PNG'ler JPEG'e çevrilip csdb/ altına ICN adıyla konur:

    sips -s format jpeg -s formatOptions 82 cikti/00001.png --out \\
        ../csdb/ICN-NAYAJET-AAA-D000000-0-NAYA0-00001-A-001-01.JPG
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts'))

from icn_render import render  # noqa: E402

ENGINE = ['engine_fan', 'engine_casing', 'engine_lpc', 'engine_hpc',
          'engine_combustor', 'engine_hpt', 'engine_lpt', 'engine_shafts',
          'engine_gearbox']
SURFACES = ['lef_l', 'lef_r', 'flaperon_l', 'flaperon_r',
            'horizontal_tail_l', 'horizontal_tail_r', 'rudder',
            'speed_brakes']
LEFT = ['wing_l', 'lef_l', 'flaperon_l', 'horizontal_tail_l']

# Blender'da uçağın burnu -Y, solu +X yönünde.
VIEWS = [
    ('00001', None, 27, (1, 0.05, 0.18), (), None, ()),
    ('00002', [*ENGINE, 'afterburner', 'engine_nozzle'], 14, (1, 0.25, 0.55),
     (*ENGINE, 'afterburner', 'engine_nozzle'), None,
     ('fuselage', 'conformal_tanks', 'intake', *LEFT)),
    ('00003', ['main_gear_l'], 6, (1, -0.35, 0.08), ('main_gear_l',), None,
     ()),
    ('00004', None, 37, (0.35, 0.45, 1), SURFACES, None, ()),
    ('00005', ['canopy'], 9.5, (1, -0.7, 0.8), ('canopy', 'cockpit'), None,
     ()),
    ('00006', ENGINE, 5.5, (1, -0.6, 0.45), ('engine_combustor',),
     [e for e in ENGINE if e != 'engine_casing'], ()),
]

argv = sys.argv[sys.argv.index('--') + 1:]
render(argv[0], argv[1], VIEWS)
