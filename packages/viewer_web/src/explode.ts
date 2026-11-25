import * as THREE from "three";

/**
 * Parçalara ayırma planı: soğan gibi, katman katman.
 *
 * - Yön: parça yüzünün baktığı yönde açılır. Modelin bir yanına dayanan ve o
 *   yönde ince olan parça (kapı, çamurluk, tampon, tekerlek, kanat) o yana;
 *   diğerleri yukarı (kaput, kanopi, kasa, döşeme, koltuk).
 * - Kat sırası: aynı yöne giden ve izdüşümleri örtüşen iki parçadan dıştaki
 *   şöyle bulunur: öbürünü kutusunun içine alan (kasa döşemeyi); biri
 *   öbürünün izdüşümünde kalıyorsa o yönde ucu ileride olan (kaput motoru,
 *   kanopi kokpiti, sele kadroyu); yoksa örtüşen sütunların çoğunda ileride
 *   olan.
 * - Mesafe: içten dışa yerleştirilir. Her parça içindekilerden en az onlar
 *   kadar gider (dış kat içtekinin önüne geçemez) ve yerleşmiş parçalara
 *   değmeyene kadar ilerler; bundan fazla gitmez. Taban yerde kalır,
 *   koltuklar biraz, döşeme daha çok, kasa en üste çıkar.
 * - Takım: tekerlek ve içindekiler (disk, kaliper, göbek), bisiklet
 *   tekerleği gibi üst üste duran gruplar aks boyunca içten dışa dizilip tek
 *   parça gibi açılır. Kuledeki top gibi büyük parçaya takılı küçük parçalar
 *   onunla gider; kablolar kadroyla.
 * - Açılmış hâlde hiçbir parça başka birine değmez, hiçbiri zeminin altına
 *   inmez. Animasyonda dış katlar önce kalkar; parçalar yolda birbirinin
 *   içinden geçebilir.
 */

export interface Grid {
  /** Modelin toplu hâldeki kutusu, yerel koordinatlarda. */
  box: THREE.Box3;
  /** İnce hücre: modelin en uzun kenarının 1/220'si, `explodeReport` ile aynı. */
  fine: number;
}

export interface Shape {
  id: string;
  /** Yüzeyin değdiği ince hücreler. */
  fine: Fine;
  /** Toplu hâldeki kutusu, modelin yerel koordinatlarında. */
  box: THREE.Box3;
}

interface Fine {
  i: Int16Array;
  j: Int16Array;
  k: Int16Array;
  keys: Set<number>;
  min: [number, number, number];
  max: [number, number, number];
}

export interface Move {
  /** Parçalara ayırma ilerlemesinin (0-1) hangi aralığında. */
  start: number;
  end: number;
  /** Yolun köşeleri (yer değiştirme, yerel koordinatlarda); ilki başlangıç. */
  points: THREE.Vector3[];
}

export interface Stage {
  /** Açılmış hâldeki yer değiştirme. */
  offset: THREE.Vector3;
  /** Sırayla oynayan hareketler; yerinde kalan parçada boş. */
  moves: Move[];
}

export interface Plan {
  stages: Map<string, Stage>;
  /** Animasyonun süresini belirleyen adım sayısı. */
  layers: number;
}

/** İnce hücre bölüneni; `explodeCheck` de aynısını kullanır. */
export const FINE = 220;
/** İnce hücre anahtarı. */
export const fineKey = (i: number, j: number, k: number) =>
  (i + 2048) * 4096 * 4096 + (j + 2048) * 4096 + (k + 2048);

export function makeGrid(box: THREE.Box3): Grid {
  const size = box.getSize(new THREE.Vector3());
  return { box: box.clone(), fine: Math.max(size.x, size.y, size.z, 1e-6) / FINE };
}

/** Üçgenleri ([triangles]) ince hücrelere çevirir. */
export function shapeOf(id: string, tris: Float32Array, grid: Grid): Shape {
  const box = new THREE.Box3();
  const p = new THREE.Vector3();
  for (let i = 0; i < tris.length; i += 3) box.expandByPoint(p.set(tris[i], tris[i + 1], tris[i + 2]));
  return { id, fine: fineOf(tris, grid.fine), box };
}

/** Düğümün üçgen köşeleri, [toLocal] ile modelin yerel koordinatlarında, art arda. */
export function triangles(node: THREE.Object3D, toLocal: THREE.Matrix4): Float32Array {
  const meshes: THREE.Mesh[] = [];
  node.updateWorldMatrix(true, true);
  node.traverse((child) => {
    if (child instanceof THREE.Mesh && child.geometry.getAttribute("position")) meshes.push(child);
  });
  const count = (mesh: THREE.Mesh) => {
    const index = mesh.geometry.getIndex();
    const n = index ? index.count : mesh.geometry.getAttribute("position").count;
    return n - (n % 3);
  };
  const out = new Float32Array(3 * meshes.reduce((n, mesh) => n + count(mesh), 0));
  const matrix = new THREE.Matrix4();
  const v = new THREE.Vector3();
  let o = 0;
  for (const mesh of meshes) {
    const position = mesh.geometry.getAttribute("position");
    const index = mesh.geometry.getIndex();
    matrix.multiplyMatrices(toLocal, mesh.matrixWorld);
    const n = count(mesh);
    for (let k = 0; k < n; k++) {
      v.fromBufferAttribute(position, index ? index.getX(k) : k).applyMatrix4(matrix);
      out[o++] = v.x;
      out[o++] = v.y;
      out[o++] = v.z;
    }
  }
  return out;
}

/** Yüzeyin değdiği ince hücreler; üçgenler hücreden sık örneklenir. */
function fineOf(tris: Float32Array, size: number): Fine {
  const seen = new Set<number>();
  const a = new THREE.Vector3();
  const b = new THREE.Vector3();
  const c = new THREE.Vector3();
  const p = new THREE.Vector3();
  for (let t = 0; t < tris.length; t += 9) {
    a.fromArray(tris, t);
    b.fromArray(tris, t + 3);
    c.fromArray(tris, t + 6);
    const edge = Math.max(a.distanceTo(b), b.distanceTo(c), c.distanceTo(a));
    const n = Math.max(1, Math.ceil(edge / (size * 0.5)));
    b.sub(a);
    c.sub(a);
    for (let u = 0; u <= n; u++) {
      for (let v = 0; u + v <= n; v++) {
        p.copy(a)
          .addScaledVector(b, u / n)
          .addScaledVector(c, v / n);
        seen.add(fineKey(Math.floor(p.x / size), Math.floor(p.y / size), Math.floor(p.z / size)));
      }
    }
  }
  const i = new Int16Array(seen.size);
  const j = new Int16Array(seen.size);
  const k = new Int16Array(seen.size);
  const min: [number, number, number] = [Infinity, Infinity, Infinity];
  const max: [number, number, number] = [-Infinity, -Infinity, -Infinity];
  let n = 0;
  for (const key of seen) {
    i[n] = Math.floor(key / (4096 * 4096)) - 2048;
    j[n] = (Math.floor(key / 4096) % 4096) - 2048;
    k[n] = (key % 4096) - 2048;
    min[0] = Math.min(min[0], i[n]);
    min[1] = Math.min(min[1], j[n]);
    min[2] = Math.min(min[2], k[n]);
    max[0] = Math.max(max[0], i[n]);
    max[1] = Math.max(max[1], j[n]);
    max[2] = Math.max(max[2], k[n]);
    n++;
  }
  return { i, j, k, keys: seen, min, max };
}

const volume = (b: THREE.Box3) => {
  const s = b.getSize(new THREE.Vector3());
  return Math.max(s.x, 1e-9) * Math.max(s.y, 1e-9) * Math.max(s.z, 1e-9);
};
const diagonal = (b: THREE.Box3) => b.getSize(new THREE.Vector3()).length();

/** Birlikte, aynı yere giden parçalar; her birinin birim içindeki kayması. */
interface Unit {
  members: { shape: Shape; shift: THREE.Vector3 }[];
  /** Kaymalarla birlikte, toplu hâldeki kutusu. */
  box: THREE.Box3;
  /** Kablolar hariç kutusu: kat sırası buna göre bulunur. */
  core: THREE.Box3;
  dir: THREE.Vector3;
  /** Gittiği yönde ne kadar dışta: büyük olan dış kattır. */
  key: number;
  /** Gittiği mesafe. */
  t: number;
  placed: boolean;
}

/**
 * Planı kurar. [groups]: düğüm → montaj grubu (`groupNodes`).
 */
export function planExplode(grid: Grid, shapes: Shape[], groups: Map<string, string>): Plan {
  const stages = new Map<string, Stage>();
  for (const s of shapes) stages.set(s.id, { offset: new THREE.Vector3(), moves: [] });
  if (shapes.length < 2) return { stages, layers: 0 };

  const model = grid.box;
  const middle = model.getCenter(new THREE.Vector3());
  const half = model
    .getSize(new THREE.Vector3())
    .multiplyScalar(0.5)
    .max(new THREE.Vector3(1e-6, 1e-6, 1e-6));
  const longest = 2 * Math.max(half.x, half.y, half.z);
  const gap = longest * 0.015;
  const weight = (s: Shape) => s.fine.i.length * Math.cbrt(volume(s.box));
  const insideOf = (s: Shape, host: Shape, share: number) => {
    const common = s.box.clone().intersect(host.box);
    return !common.isEmpty() && volume(common) >= share * volume(s.box);
  };

  // Kablo gibi ince uzun parçalar, değdikleri en ağır parçayla (kadro)
  // birlikte durur; açılınca havada asılı çizgiler gibi okunuyorlardı.
  const wires = shapes.filter((s) => {
    const across = diagonal(s.box) / grid.fine;
    const cells = s.fine.i.length;
    return diagonal(s.box) >= 0.3 * longest && cells < 0.045 * across * across && cells > 3 * across;
  });
  const rest = shapes.filter((s) => !wires.includes(s));

  const units: Unit[] = [];
  const unitOf = new Map<Shape, Unit>();
  const add = (members: Unit["members"]) => {
    const box = new THREE.Box3();
    for (const m of members) box.union(m.shape.box.clone().translate(m.shift));
    const unit: Unit = {
      members,
      box,
      core: box.clone(),
      dir: new THREE.Vector3(0, 1, 0),
      key: 0,
      t: 0,
      placed: false,
    };
    units.push(unit);
    for (const m of members) unitOf.set(m.shape, unit);
    return unit;
  };
  const taken = new Set<Shape>();

  // Tekerlek gibi bir arada, üst üste duran küçük takımlar: aks boyunca
  // içten dışa sıralanır (göbek, disk, jant, lastik), sonra bir birim olarak
  // açılır.
  const stack = (list: Shape[]) => {
    const box = union(list);
    const extent = box.getSize(new THREE.Vector3());
    // Aks: üyelerin merkezlerinin dizildiği eksen (motorun kademeleri);
    // merkezler üst üste ise en ince eksen (tekerlek).
    const spreads = [0, 1, 2].map((a) => {
      const values = list.map((m) => m.box.getCenter(new THREE.Vector3()).getComponent(a));
      return Math.max(...values) - Math.min(...values);
    });
    const widest = spreads.indexOf(Math.max(...spreads));
    const axis =
      spreads[widest] > 0.05 * diagonal(box)
        ? widest
        : extent.x <= extent.y && extent.x <= extent.z
          ? 0
          : extent.z <= extent.y
            ? 2
            : 1;
    const dir = directionOf(box);
    let sign = Math.sign(dir.getComponent(axis));
    if (sign === 0)
      sign =
        Math.sign(box.getCenter(new THREE.Vector3()).getComponent(axis) - middle.getComponent(axis)) || 1;
    const unit = Math.max(diagonal(box) * 0.02, grid.fine);
    const rank = (s: Shape) =>
      Math.round((s.box.getCenter(new THREE.Vector3()).getComponent(axis) * sign) / unit) * 1e6 +
      diagonal(s.box);
    const order = [...list].sort((a, b) => rank(a) - rank(b));
    let at = 0;
    const members = order.map((s, n) => {
      if (n > 0) {
        const before = order[n - 1].box.getSize(new THREE.Vector3()).getComponent(axis);
        at += (before + s.box.getSize(new THREE.Vector3()).getComponent(axis)) / 2 + gap;
      }
      return { shape: s, shift: new THREE.Vector3().setComponent(axis, sign * at) };
    });
    for (const s of list) taken.add(s);
    add(members).dir = dir;
  };

  const byGroup = new Map<string, Shape[]>();
  for (const s of rest) {
    const g = groups.get(s.id) ?? s.id;
    if (!byGroup.has(g)) byGroup.set(g, []);
    byGroup.get(g)!.push(s);
  }
  for (const list of byGroup.values()) {
    if (list.length < 2 || !compact(list) || diagonal(union(list)) >= 0.6 * diagonal(model)) continue;
    const box = union(list);
    const center = box.getCenter(new THREE.Vector3());
    const coaxial = list.every(
      (s) => s.box.getCenter(new THREE.Vector3()).distanceTo(center) < 0.15 * diagonal(box),
    );
    if (coaxial) stack(list);
  }
  // Kutusu bir tekerleğin içinde kalanlar
  // (disk, kaliper, göbek) onunla takım olur.
  const loose = rest.filter((s) => !taken.has(s)).sort((a, b) => volume(b.box) - volume(a.box));
  for (const host of loose) {
    if (taken.has(host)) continue;
    // Yalnız tekerlek gibi kap: yanı ince, öbür iki kenarı birbirine yakın.
    const extent = host.box.getSize(new THREE.Vector3());
    const sides = [extent.x, extent.y, extent.z].sort((a, b) => a - b);
    const wheel =
      extent.y > Math.min(extent.x, extent.z) && sides[1] > 0.8 * sides[2] && sides[0] < 0.7 * sides[1];
    if (!wheel || diagonal(host.box) >= 0.3 * diagonal(model)) continue;
    const inner = loose.filter(
      (s) => s !== host && !taken.has(s) && volume(s.box) < volume(host.box) && insideOf(s, host, 0.85),
    );
    if (inner.length > 0) stack([host, ...inner]);
  }
  // Büyük grupta, ev sahibine (grubun en ağır üyesi) değen ya da hemen
  // yanında duran, ondan çok küçük ve onun dışında kalan üye onunla birlikte
  // gider: kuledeki top, makineli tüfek, nişangâhlar.
  const rigid = new Map<Shape, Shape[]>();
  for (const list of byGroup.values()) {
    const free = list.filter((s) => !taken.has(s));
    if (free.length < 2) continue;
    const host = free.reduce((a, b) => (weight(b) > weight(a) ? b : a));
    for (const s of free) {
      if (s === host || insideOf(s, host, 0.7) || volume(s.box) >= 0.3 * volume(host.box)) continue;
      // Kendi yanına açılan parça (yan etek) ev sahibine bağlanmaz.
      if (directionOf(s.box).y === 0) continue;
      const near = host.box
        .clone()
        .expandByScalar(longest * 0.02)
        .intersectsBox(s.box);
      if (!near && !touches(s, host)) continue;
      if (!rigid.has(host)) rigid.set(host, []);
      rigid.get(host)!.push(s);
      taken.add(s);
    }
  }
  for (const s of rest) {
    if (taken.has(s)) continue;
    const extra = rigid.get(s) ?? [];
    add([s, ...extra].map((shape) => ({ shape, shift: new THREE.Vector3() })));
    for (const x of [s, ...extra]) taken.add(x);
  }
  for (const w of wires) {
    const host = rest
      .filter((s) => touches(w, s))
      .reduce<Shape | null>((a, b) => (!a || weight(b) > weight(a) ? b : a), null);
    const unit = host ? unitOf.get(host)! : add([]);
    unit.members.push({ shape: w, shift: new THREE.Vector3() });
    unit.box.union(w.box);
    unitOf.set(w, unit);
  }

  /**
   * Yön. Modelin bir yanına (sağ, sol, ön, arka) dayanan ve o yönde ince olan
   * parça o yana açılır: kapı, çamurluk, tampon, tekerlek, kanat. Diğerleri
   * yukarı: kasa en üste, altında döşeme, koltuklar, en altta taban.
   */
  function directionOf(box: THREE.Box3): THREE.Vector3 {
    // Parça yüzünün baktığı yönde açılır. Yatay yassı parça (kaput, bagaj
    // kapağı, kanopi) yukarı; ancak modelin bir yanından dışarı uzanan
    // kanat gibi yassı parça o yana.
    const extent = box.getSize(new THREE.Vector3());
    const flat = extent.y < 0.3 * Math.min(extent.x, extent.z);
    const tol = longest * 0.05;
    let best: THREE.Vector3 | null = null;
    let score = -1;
    for (const a of [0, 2]) {
      if (box.getSize(new THREE.Vector3()).getComponent(a) > 0.7 * half.getComponent(a)) continue;
      const low = box.min.getComponent(a) - model.min.getComponent(a) <= tol;
      const high = model.max.getComponent(a) - box.max.getComponent(a) <= tol;
      if (low === high) continue;
      // Yassı parça ancak o yanın en ucuna dayanıyorsa (kanat ucu) o yana.
      if (
        flat &&
        Math.min(
          box.min.getComponent(a) - model.min.getComponent(a),
          model.max.getComponent(a) - box.max.getComponent(a),
        ) >
          longest * 0.015
      )
        continue;
      const rel =
        Math.abs(box.getCenter(new THREE.Vector3()).getComponent(a) - middle.getComponent(a)) /
        half.getComponent(a);
      if (rel > score) {
        score = rel;
        best = new THREE.Vector3().setComponent(a, high ? 1 : -1);
      }
    }
    return best ?? new THREE.Vector3(0, 1, 0);
  }

  for (const u of units) {
    if (u.members.length === 0) continue;
    if (!u.members.some((m) => m.shift.lengthSq() > 0)) u.dir = directionOf(u.box);
    const a = u.dir.x !== 0 ? 0 : u.dir.y !== 0 ? 1 : 2;
    const sign = u.dir.getComponent(a);
    const far = sign > 0 ? u.core.max.getComponent(a) : u.core.min.getComponent(a);
    u.key = (sign * (far - middle.getComponent(a))) / half.getComponent(a);
  }
  const live = units.filter((u) => u.members.length > 0);

  // Değme: iki birimin parçaları bir ince hücre payla değiyor mu.
  const fineOff = (o: THREE.Vector3): [number, number, number] => [
    Math.round(o.x / grid.fine),
    Math.round(o.y / grid.fine),
    Math.round(o.z / grid.fine),
  ];
  const NEAR: [number, number, number][] = [
    [0, 0, 0],
    [1, 0, 0],
    [-1, 0, 0],
    [0, 1, 0],
    [0, -1, 0],
    [0, 0, 1],
    [0, 0, -1],
  ];
  const touch = (a: Shape, offA: THREE.Vector3, b: Shape, offB: THREE.Vector3): boolean => {
    if (b.fine.i.length < a.fine.i.length) return touch(b, offB, a, offA);
    const fa = fineOff(offA);
    const fb = fineOff(offB);
    const di = fa[0] - fb[0];
    const dj = fa[1] - fb[1];
    const dk = fa[2] - fb[2];
    const A = a.fine;
    const B = b.fine;
    for (let q = 0; q < A.i.length; q++) {
      const i = A.i[q] + di;
      const j = A.j[q] + dj;
      const k = A.k[q] + dk;
      if (i < B.min[0] - 1 || i > B.max[0] + 1 || j < B.min[1] - 1 || j > B.max[1] + 1) continue;
      if (k < B.min[2] - 1 || k > B.max[2] + 1) continue;
      for (const [x, y, z] of NEAR) if (B.keys.has(fineKey(i + x, j + y, k + z))) return true;
    }
    return false;
  };
  /** [u] [t] kadar gidince yerleşmiş bir birime değiyor mu. */
  const blocked = (u: Unit, t: number): boolean => {
    const move = u.dir.clone().multiplyScalar(t);
    const box = u.box
      .clone()
      .translate(move)
      .expandByScalar(grid.fine * 2);
    for (const v of live) {
      if (v === u || !v.placed) continue;
      const other = v.dir.clone().multiplyScalar(v.t);
      if (!box.intersectsBox(v.box.clone().translate(other))) continue;
      for (const a of u.members) {
        const offA = move.clone().add(a.shift);
        for (const b of v.members) {
          if (touch(a.shape, offA, b.shape, other.clone().add(b.shift))) return true;
        }
      }
    }
    return false;
  };
  /**
   * [inner], [outer]'ın içinde mi: aynı yöne gidiyorlar, toplu hâlde dıştaki
   * o yönde daha ileride ve gidiş yönüne dik izdüşümleri büyük ölçüde örtüşüyor.
   */
  const covers = (outer: Unit, inner: Unit) => {
    if (!outer.dir.equals(inner.dir)) return false;
    let shared = 1;
    let small = 1;
    for (let a = 0; a < 3; a++) {
      if (outer.dir.getComponent(a) !== 0) continue;
      const lo = Math.max(outer.core.min.getComponent(a), inner.core.min.getComponent(a));
      const hi = Math.min(outer.core.max.getComponent(a), inner.core.max.getComponent(a));
      if (hi <= lo) return false;
      shared *= hi - lo;
      small *= Math.min(
        outer.core.max.getComponent(a) - outer.core.min.getComponent(a),
        inner.core.max.getComponent(a) - inner.core.min.getComponent(a),
      );
    }
    return shared >= 0.5 * small;
  };
  const step = longest * 0.01;

  // Kat sırası: aynı yöne giden ve izdüşümleri örtüşen iki birimden,
  // örtüşen sütunların çoğunda o yönde daha ileride olanı dış kattır
  // (kaput motorun, kasa döşemenin dışında).
  const columns = new Map<Unit, Map<number, number>>();
  const columnsOf = (u: Unit) => {
    let map = columns.get(u);
    if (map) return map;
    map = new Map();
    const a = u.dir.x !== 0 ? 0 : u.dir.y !== 0 ? 1 : 2;
    const [p, q] = a === 0 ? [1, 2] : a === 1 ? [0, 2] : [0, 1];
    const sign = u.dir.getComponent(a);
    for (const m of u.members) {
      const shift = fineOff(m.shift);
      const cells = [m.shape.fine.i, m.shape.fine.j, m.shape.fine.k];
      for (let n = 0; n < cells[0].length; n++) {
        const key = (cells[p][n] + shift[p] + 2048) * 4096 + cells[q][n] + shift[q] + 2048;
        const value = sign * (cells[a][n] + shift[a]);
        const was = map.get(key);
        if (was === undefined || value > was) map.set(key, value);
      }
    }
    columns.set(u, map);
    return map;
  };
  /** [a]'nın kutusu [b]'nin kutusunun büyük ölçüde içinde mi (izdüşümde de olabilir). */
  const within = (a: THREE.Box3, b: THREE.Box3, axis = -1) => {
    let shared = 1;
    let own = 1;
    for (let c = 0; c < 3; c++) {
      if (c === axis) continue;
      const lo = Math.max(a.min.getComponent(c), b.min.getComponent(c));
      const hi = Math.min(a.max.getComponent(c), b.max.getComponent(c));
      if (hi <= lo) return false;
      shared *= hi - lo;
      own *= Math.max(a.max.getComponent(c) - a.min.getComponent(c), 1e-9);
    }
    return shared >= 0.7 * own;
  };
  /**
   * [u], [v]'nin dışında mı. Önce kutular: içine alan dıştadır (kasa
   * döşemenin). Sonra izdüşüm: biri öbürünün izdüşümünde kalıyorsa o yönde
   * ucu ileride olan dıştadır (kaput motorun; modelde motor kaputu biraz
   * delse de).
   * Yoksa örtüşen sütunların çoğunda o yönde ileride olan.
   */
  const beyond = (u: Unit, v: Unit) => {
    const a = u.dir.x !== 0 ? 0 : u.dir.y !== 0 ? 1 : 2;
    const sign = u.dir.getComponent(a);
    const bigger = volume(u.core) >= volume(v.core);
    // İçine alma: küçüğün kutusu büyüğünkünün içinde ve o yönde dışarı
    // taşmıyor (kadronun içinden çıkan sele taşar, sayılmaz).
    const far = (b: THREE.Box3) => (sign > 0 ? b.max.getComponent(a) : -b.min.getComponent(a));
    if (bigger && within(v.core, u.core) && far(v.core) <= far(u.core)) return true;
    if (!bigger && within(u.core, v.core) && far(u.core) <= far(v.core)) return false;
    // Biri öbürünün izdüşümünde kalıyorsa o yönde ucu ileride olan dıştadır:
    // kaput motorun, sele kadronun, kanopi kokpitin üstünde.
    const ahead =
      far(u.core) - far(v.core) ||
      sign *
        (u.core.getCenter(new THREE.Vector3()).getComponent(a) -
          v.core.getCenter(new THREE.Vector3()).getComponent(a));
    if (within(v.core, u.core, a) || within(u.core, v.core, a)) return ahead > 0;
    const cu = columnsOf(u);
    const cv = columnsOf(v);
    let more = 0;
    let less = 0;
    for (const [key, value] of cu) {
      const other = cv.get(key);
      if (other === undefined) continue;
      if (value > other) more++;
      else if (value < other) less++;
    }
    return more > less || (more === less && u.key > v.key);
  };
  const inner = new Map<Unit, Unit[]>(live.map((u) => [u, []]));
  for (let x = 0; x < live.length; x++) {
    for (let y = x + 1; y < live.length; y++) {
      const u = live[x];
      const v = live[y];
      if (!covers(u, v)) continue;
      if (beyond(u, v)) inner.get(u)!.push(v);
      else inner.get(v)!.push(u);
    }
  }

  // İçten dışa: içteki kat yerinde kalır ya da ancak kendinden içtekilerden
  // kurtulacak kadar gider. Dıştaki kat, içindekinden az gidemez (sıra
  // bozulmasın) ve içerdekilerin hepsinden kurtulana kadar ilerler. Kasa
  // böylece en üste çıkar, taban yerde kalır.
  const order: Unit[] = [];
  const waiting = new Set(live);
  while (waiting.size > 0) {
    let next: Unit | null = null;
    for (const u of waiting) {
      if (inner.get(u)!.some((v) => waiting.has(v))) continue;
      if (!next || u.key < next.key) next = u;
    }
    // Döngü varsa (birbirini kısmen örten iki parça) en içteki seçilir.
    if (!next) next = [...waiting].reduce((a, b) => (b.key < a.key ? b : a));
    waiting.delete(next);
    order.push(next);
  }
  for (const u of order) {
    let t = 0;
    for (const v of inner.get(u)!) if (v.placed) t = Math.max(t, v.t);
    if (blocked(u, t)) {
      let low = t;
      while (t < longest * 3 && blocked(u, t)) {
        low = t;
        t += step;
      }
      // İnceltme: değmediği en yakın yer, bir ince hücre duyarlılıkla.
      while (t - low > grid.fine) {
        const mid = (low + t) / 2;
        if (blocked(u, mid)) low = mid;
        else t = mid;
      }
    }
    u.t = t;
    u.placed = true;
  }
  // İç içe döngü yüzünden sırası bozulan çift kaldıysa dıştakini ileri al:
  // dış kat içindekinden az gidemez.
  for (let round = 0; round < 20; round++) {
    let changed = false;
    for (const u of order) {
      let t = u.t;
      for (const v of inner.get(u)!) t = Math.max(t, v.t);
      if (t === u.t) continue;
      while (t < longest * 3 && blocked(u, t)) t += grid.fine;
      u.t = t;
      changed = true;
    }
    if (!changed) break;
  }
  order.reverse();

  // Zamanlama: dıştakiler önce kalkar.
  const spread = 0.45;
  order.forEach((u, n) => {
    const start = order.length > 1 ? (spread * n) / (order.length - 1) : 0;
    const move = u.dir.clone().multiplyScalar(u.t);
    for (const m of u.members) {
      const offset = move.clone().add(m.shift);
      const stage = stages.get(m.shape.id)!;
      stage.offset.copy(offset);
      if (offset.lengthSq() === 0) continue;
      const points = [new THREE.Vector3()];
      if (m.shift.lengthSq() > 0 && u.t > 0) points.push(move.clone());
      points.push(offset);
      stage.moves.push({ start, end: start + (1 - spread), points });
    }
  });
  return { stages, layers: 7 };
}

/** İki parça toplu hâlde birbirine değiyor mu (bir ince hücre payla). */
function touches(a: Shape, b: Shape): boolean {
  if (b.fine.i.length < a.fine.i.length) return touches(b, a);
  for (let q = 0; q < a.fine.i.length; q++) {
    const i = a.fine.i[q];
    const j = a.fine.j[q];
    const k = a.fine.k[q];
    for (let x = -1; x <= 1; x++) {
      for (let y = -1; y <= 1; y++) {
        for (let z = -1; z <= 1; z++) if (b.fine.keys.has(fineKey(i + x, j + y, k + z))) return true;
      }
    }
  }
  return false;
}

function union(list: Shape[]): THREE.Box3 {
  return list.reduce((a, s) => a.union(s.box), new THREE.Box3());
}

/** En büyük üyesi grubun kutusunun büyük kısmını kaplıyorsa grup bir arada duruyor. */
function compact(list: Shape[]): boolean {
  const all = union(list);
  return Math.max(...list.map((s) => diagonal(s.box))) >= 0.6 * diagonal(all);
}

/** [value] ilerlemesinde parçanın yer değiştirmesi. */
export function offsetAt(stage: Stage, value: number, out: THREE.Vector3): THREE.Vector3 {
  out.set(0, 0, 0);
  for (const move of stage.moves) {
    if (value <= move.start) break;
    const t = (value - move.start) / Math.max(move.end - move.start, 1e-6);
    alongPath(move.points, easeInOut(Math.min(1, t)), out);
    if (t < 1) break;
  }
  return out;
}

const easeInOut = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

/** Kırık çizgi üzerinde, uzunluğunun [t] kesrindeki nokta. */
function alongPath(points: THREE.Vector3[], t: number, out: THREE.Vector3): void {
  let total = 0;
  for (let i = 1; i < points.length; i++) total += points[i].distanceTo(points[i - 1]);
  let left = t * total;
  for (let i = 1; i < points.length; i++) {
    const length = points[i].distanceTo(points[i - 1]);
    if (left <= length || i === points.length - 1) {
      out.lerpVectors(points[i - 1], points[i], length > 0 ? Math.min(1, left / length) : 1);
      return;
    }
    left -= length;
  }
  out.copy(points[0]);
}
