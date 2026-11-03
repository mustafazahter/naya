"""Kopuk parçaları (adacıkları) bisiklet parçalarına atar.

Parça adları düğüm adı olarak kullanılıyor; three.js düğüm adlarındaki
noktaları sildiği için alt çizgi ile yazılır (drive_chain).

Koordinatlar Blender'daki gibi: x yan, y boy (ön -y), z yukarı.
Zincir tarafı x < 0.153.
"""
import json, math, sys
from collections import Counter

MID_X = 0.153
FRONT = (-0.713, -0.125)   # (y, z)
REAR = (0.375, -0.112)
BB = (-0.02, -0.17)

def radial(c, hub):
    return math.hypot(c[1] - hub[0], c[2] - hub[1])

def classify(o):
    c, s, m = o['c'], o['s'], o['m']
    size = max(s)
    df, dr = radial(c, FRONT), radial(c, REAR)
    db = radial(c, BB)

    if m == 'App302':
        return 'drive.chain'
    if m == 'App234' and c[2] > 0.4:
        return 'handlebar'
    if m == 'App234':
        return 'wheel.front.tire' if df < dr else 'wheel.rear.tire'

    # Kokpit: gidon, gidon boğazı, fren kolları ve vites kolları.
    if c[2] > 0.3 and c[1] < -0.45:
        return 'handlebar'
    # Sele ve sele borusu.
    if c[2] > 0.29 and -0.2 < c[1] < 0.25:
        return 'saddle'
    if m in ('AppAD2', 'AppBD3', 'AppFD') or (m == 'App4E' and -0.05 < c[1] < 0.1 and c[2] > 0.05):
        return 'seatpost'
    if m == 'App923':
        return 'frame'  # kadro üstündeki kablolar

    for hub, name, d in ((FRONT, 'front', df), (REAR, 'rear', dr)):
        if d > 0.37 or (name == 'front' and df > dr) or (name == 'rear' and dr >= df):
            continue
        in_plane = abs(c[0] - MID_X) < 0.035
        if m in ('AppC8', 'AppB7') or (in_plane and size > 0.45):
            return f'wheel.{name}.rim'
        if in_plane and d > 0.06 and size > 0.12:
            return f'wheel.{name}.spokes'
        if in_plane and d > 0.25:
            return f'wheel.{name}.spokes'
        if name == 'rear' and c[0] < MID_X - 0.02 and d < 0.075:
            return 'drive.cassette'
        if name == 'rear' and c[0] < MID_X - 0.02 and c[2] < hub[1] and d < 0.24:
            return 'drive.derailleur'
        # Disk ve kaliper: tekerlek düzleminin dışında, göbeğe yakın, kısa.
        if c[0] > MID_X + 0.025 and d < 0.13 and s[2] < 0.2:
            return f'brakes.{name}'
        if d < 0.06:
            return f'wheel.{name}.hub'
        if name == 'front' and c[2] > -0.16:
            return 'fork'
        if name == 'rear':
            return 'frame'
        return f'wheel.{name}.hub'

    # Orta göbek çevresi: aynakol, pedal kolları ve pedallar.
    if db < 0.13 and c[2] < -0.03:
        return 'drive.crankset'
    if c[2] < -0.1 and (c[0] > 0.25 or c[0] < 0.06) and db < 0.32:
        return 'drive.pedals'
    # Çatal: baş borusunun önü ve altı.
    if c[1] < -0.55 and c[2] < 0.3:
        return 'fork'
    return 'frame'

def main():
    islands = json.load(open(sys.argv[1]))
    out = {}
    for o in islands:
        o['c'] = [(a + b) / 2 for a, b in zip(o['min'], o['max'])]
        o['s'] = [b - a for a, b in zip(o['min'], o['max'])]
        out[o['n']] = classify(o).replace('.', '_')
    json.dump(out, open(sys.argv[2], 'w'))
    faces = Counter()
    for o in islands:
        faces[out[o['n']]] += o['f']
    for k, v in sorted(Counter(out.values()).items()):
        print(f'{k:22} {v:5} ada  {faces[k]:7} yüz')

main()
