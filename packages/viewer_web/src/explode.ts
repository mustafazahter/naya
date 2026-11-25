import * as THREE from "three";

/**
 * Parçalara ayırma planı.
 *
 * Her parça küçük küplerden (hücre) oluşan kaba bir kopyaya çevrilir. En
 * büyük parça (kasa, gövde, kadro) yerinde kalır; diğerleri dıştan içe,
 * katman katman sökülür. Bir parça yalnız eksen yönlerinden birine, yolu ve
 * vardığı yer boşsa gider: yolda başka bir parça ya da kabuk varsa o yön
 * kapalıdır. Önceki katmandaki parçalar yerlerine varmış, sonrakiler daha
 * yerinde sayılır; animasyon da katmanları bu sırayla oynatır. Böylece
 * hiçbir parça başka bir parçanın içinden geçmez, açılmış hâlde de
 * birbirine değmez.
 *
 * Hiçbir yönden çıkamayan parça (kapalı kabindeki koltuk gibi) yerinde
 * kalır; yerinde kalması da temizdir, çünkü toplu hâlde zaten çakışmıyor.
 */

export interface Grid {
  /** (0,0,0) hücresinin köşesi, modelin yerel koordinatlarında. */
  origin: THREE.Vector3;
  cell: number;
  nx: number;
  ny: number;
  nz: number;
}

/** Bir parçanın dolu hücreleri. */
export interface Shape {
  id: string;
  x: Int16Array;
  y: Int16Array;
  z: Int16Array;
}

export interface Stage {
  /** Parçanın yer değiştirmesi, modelin yerel koordinatlarında. */
  offset: THREE.Vector3;
  /** Parçalara ayırma ilerlemesinin (0-1) hangi aralığında hareket ettiği. */
  start: number;
  end: number;
}

export interface Plan {
  stages: Map<string, Stage>;
  /** Kaç katman sökülüyor; animasyonun süresi buna bağlı. */
  layers: number;
}

/**
 * Model için hücre ızgarası. Hücre modelin en uzun kenarının 1/150'si.
 * Parçaların açılınca gideceği yer için yanlarda ve üstte boşluk bırakılır;
 * altta zemin sınırdır, hiçbir parça zeminin altına inmez.
 */
export function makeGrid(box: THREE.Box3): Grid {
  const size = box.getSize(new THREE.Vector3());
  const longest = Math.max(size.x, size.y, size.z);
  const cell = longest / 150;
  const side = longest * 0.5;
  const top = longest * 0.75;
  const origin = new THREE.Vector3(box.min.x - side, box.min.y, box.min.z - side);
  return {
    origin,
    cell,
    nx: Math.ceil((size.x + 2 * side) / cell) + 1,
    ny: Math.ceil((size.y + top) / cell) + 1,
    nz: Math.ceil((size.z + 2 * side) / cell) + 1,
  };
}

/**
 * Düğümün yüzeyini hücrelere çevirir. Üçgenler hücreden sık örneklenir;
 * köşeler [toLocal] ile modelin yerel koordinatlarına taşınır.
 */
export function voxelize(id: string, node: THREE.Object3D, toLocal: THREE.Matrix4, grid: Grid): Shape {
  const seen = new Set<number>();
  const { origin, cell, nx, ny, nz } = grid;
  const a = new THREE.Vector3();
  const b = new THREE.Vector3();
  const c = new THREE.Vector3();
  const p = new THREE.Vector3();
  const ab = new THREE.Vector3();
  const ac = new THREE.Vector3();
  const matrix = new THREE.Matrix4();
  const mark = (v: THREE.Vector3) => {
    const i = Math.floor((v.x - origin.x) / cell);
    const j = Math.floor((v.y - origin.y) / cell);
    const k = Math.floor((v.z - origin.z) / cell);
    if (i < 0 || j < 0 || k < 0 || i >= nx || j >= ny || k >= nz) return;
    seen.add(i + nx * (j + ny * k));
  };
  node.updateWorldMatrix(true, true);
  node.traverse((child) => {
    if (!(child instanceof THREE.Mesh)) return;
    const position = child.geometry.getAttribute("position");
    if (!position) return;
    matrix.multiplyMatrices(toLocal, child.matrixWorld);
    const index = child.geometry.getIndex();
    const count = index ? index.count : position.count;
    const vertex = (n: number, out: THREE.Vector3) =>
      out.fromBufferAttribute(position, index ? index.getX(n) : n).applyMatrix4(matrix);
    for (let t = 0; t + 2 < count; t += 3) {
      vertex(t, a);
      vertex(t + 1, b);
      vertex(t + 2, c);
      const edge = Math.max(a.distanceTo(b), b.distanceTo(c), c.distanceTo(a));
      const n = Math.max(1, Math.ceil(edge / (cell * 0.5)));
      ab.subVectors(b, a);
      ac.subVectors(c, a);
      for (let u = 0; u <= n; u++) {
        for (let v = 0; u + v <= n; v++) {
          mark(p.copy(a).addScaledVector(ab, u / n).addScaledVector(ac, v / n));
        }
      }
    }
  });
  const x = new Int16Array(seen.size);
  const y = new Int16Array(seen.size);
  const z = new Int16Array(seen.size);
  let n = 0;
  for (const key of seen) {
    x[n] = key % nx;
    y[n] = Math.floor(key / nx) % ny;
    z[n] = Math.floor(key / (nx * ny));
    n++;
  }
  return { id, x, y, z };
}

/** Geliştirirken: hangi parça neden çıkamadı. */
export const explodeTrace: { on: boolean; lines: string[] } = { on: false, lines: [] };

/** Altı eksen yönü: +x, -x, +y, -y, +z, -z. */
const DIRS: [number, number, number][] = [
  [1, 0, 0],
  [-1, 0, 0],
  [0, 1, 0],
  [0, -1, 0],
  [0, 0, 1],
  [0, 0, -1],
];

/** Birlikte hareket eden parçalar: tek bir parça ya da toplu taşınan bir grup. */
interface Unit {
  shapes: Shape[];
  x: Int16Array;
  y: Int16Array;
  z: Int16Array;
  /** Şu anki yer değiştirme, hücre cinsinden. */
  off: [number, number, number];
  min: THREE.Vector3;
  max: THREE.Vector3;
  /** Grup olarak taşınıyorsa grubun adı; sonra içindekiler ayrıca açılır. */
  group: string | null;
  /** Gittiği yön (DIRS sırası) ve kaçıncı sırada yerleştiği. */
  dir: number;
  order: number;
  layer: number;
}

function unitOf(shapes: Shape[], group: string | null): Unit {
  const total = shapes.reduce((n, s) => n + s.x.length, 0);
  const x = new Int16Array(total);
  const y = new Int16Array(total);
  const z = new Int16Array(total);
  let n = 0;
  for (const s of shapes) {
    x.set(s.x, n);
    y.set(s.y, n);
    z.set(s.z, n);
    n += s.x.length;
  }
  const min = new THREE.Vector3(Infinity, Infinity, Infinity);
  const max = new THREE.Vector3(-Infinity, -Infinity, -Infinity);
  for (let i = 0; i < total; i++) {
    min.set(Math.min(min.x, x[i]), Math.min(min.y, y[i]), Math.min(min.z, z[i]));
    max.set(Math.max(max.x, x[i]), Math.max(max.y, y[i]), Math.max(max.z, z[i]));
  }
  return { shapes, x, y, z, off: [0, 0, 0], min, max, group, dir: -1, order: -1, layer: -1 };
}

const centerOf = (u: Unit) =>
  u.min
    .clone()
    .add(u.max)
    .multiplyScalar(0.5)
    .add(new THREE.Vector3(...u.off));

/**
 * Planı kurar. [groups]: düğüm → montaj grubu (`groupNodes`).
 *
 * Gruplar iki türlü: tekerlek gibi bir arada duran grup (en büyük üyesi
 * grubun neredeyse tamamını kaplıyor) önce bütün olarak dışarı çıkar, sonra
 * üyeleri grubun en ince ekseni (tekerlekte aks) ya da merkezden dışarı
 * açılır. Bütün olarak çıkamayan ya da modelin her yanına dağılmış grubun
 * (frenler, tekerlekler) her üyesi kendi başına sökülür.
 */
export function planExplode(grid: Grid, shapes: Shape[], groups: Map<string, string>): Plan {
  const { nx, ny, nz } = grid;
  const occ = new Uint8Array(nx * ny * nz);
  const stamp = (u: Unit, delta: 1 | -1) => {
    const [ox, oy, oz] = u.off;
    for (let i = 0; i < u.x.length; i++) {
      const idx = u.x[i] + ox + nx * (u.y[i] + oy + ny * (u.z[i] + oz));
      occ[idx] = Math.max(0, Math.min(255, occ[idx] + delta));
    }
  };

  const stages = new Map<string, Stage>();
  const still = () => ({ offset: new THREE.Vector3(), start: 0, end: 1 });
  if (shapes.length === 0) return { stages, layers: 0 };

  // Sabit parça: en çok hücresi olan. Kasa, gövde ya da kadro.
  const anchorShape = shapes.reduce((a, b) => (b.x.length > a.x.length ? b : a));
  const anchor = unitOf([anchorShape], null);
  const anchorCenter = centerOf(anchor);
  const anchorHalf = anchor.max.clone().sub(anchor.min).multiplyScalar(0.5).max(new THREE.Vector3(1, 1, 1));
  const longest = Math.max(nx, ny, nz);

  // Grupları kur.
  const members = new Map<string, Shape[]>();
  for (const s of shapes) {
    if (s === anchorShape) continue;
    const g = groups.get(s.id) ?? s.id;
    if (!members.has(g)) members.set(g, []);
    members.get(g)!.push(s);
  }
  const anchorGroup = groups.get(anchorShape.id) ?? anchorShape.id;
  let pending: Unit[] = [];
  for (const [g, list] of members) {
    if (g !== anchorGroup && list.length > 1 && compact(list)) pending.push(unitOf(list, g));
    else for (const s of list) pending.push(unitOf([s], null));
  }

  const all: Unit[] = [anchor, ...pending];
  const gone = new Set<Unit>();
  const blockers = (u: Unit, off: [number, number, number], contact: Set<number>): string => {
    const owner = new Map<number, string>();
    for (const w of all) {
      if (w === u || gone.has(w)) continue;
      const [ox, oy, oz] = w.off;
      for (let i = 0; i < w.x.length; i++) owner.set(w.x[i] + ox + nx * (w.y[i] + oy + ny * (w.z[i] + oz)), w.shapes[0].id);
    }
    const count = new Map<string, number>();
    for (let i = 0; i < u.x.length; i++) {
      const x = u.x[i] + off[0];
      const y = u.y[i] + off[1];
      const z = u.z[i] + off[2];
      if (x < 0 || y < 0 || z < 0 || x >= nx || y >= ny || z >= nz) {
        count.set("dış", (count.get("dış") ?? 0) + 1);
        continue;
      }
      const idx = x + nx * (y + ny * z);
      if (occ[idx] > 0 && !contact.has(idx)) {
        const o = owner.get(idx) ?? "?";
        count.set(o, (count.get(o) ?? 0) + 1);
      }
    }
    return [...count].map(([k, v]) => `${k}:${v}`).join(",") + ` /${u.x.length}`;
  };

  for (const u of all) stamp(u, 1);

  let order = 0;
  let layer = 0;

  const NONE = new Set<number>();
  // Kaba ızgarada birbirine sürtünen yüzeyler birkaç hücre çakışır. Yolda
  // hücrelerin %3'ü, vardığı yerde %1,5'i bu payla sayılmaz; bir duvarın
  // içinden geçen parçanın çakışması bundan çok büyük (bütün ön yüzü).
  const pathTol = (u: Unit) => Math.max(1, Math.floor(u.x.length * 0.03));
  const restTol = (u: Unit) => Math.max(1, Math.floor(u.x.length * 0.015));

  /**
   * [u] [off] konumunda başka bir parçaya ya da ızgaranın dışına taşıyor mu.
   * [contact] hücreleri sayılmaz; [tol] kadar hücre kaba ızgaranın payıdır.
   */
  const hits = (u: Unit, off: [number, number, number], contact: Set<number>, tol: number): boolean => {
    const [ox, oy, oz] = off;
    let count = 0;
    for (let i = 0; i < u.x.length; i++) {
      const x = u.x[i] + ox;
      const y = u.y[i] + oy;
      const z = u.z[i] + oz;
      if (x < 0 || y < 0 || z < 0 || x >= nx || y >= ny || z >= nz) return true;
      const idx = x + nx * (y + ny * z);
      if (occ[idx] > 0 && !contact.has(idx) && ++count > tol) return true;
    }
    return false;
  };

  /** Vardığı yerde bir hücre boşluk da kalsın. */
  const clear = (u: Unit, off: [number, number, number], tol: number): boolean => {
    if (hits(u, off, NONE, tol)) return false;
    for (const [dx, dy, dz] of DIRS) {
      if (hits(u, [off[0] + dx, off[1] + dy, off[2] + dz], NONE, tol)) return false;
    }
    return true;
  };

  /**
   * [u]'yu [dir] yönünde en az [min] hücre götürür; yol kapalıysa null.
   * Toplu hâlde zaten değdiği hücreler ([contact]) yolda engel sayılmaz.
   */
  const travel = (u: Unit, dir: number, min: number, contact: Set<number>, from = 1): number | null => {
    const [dx, dy, dz] = DIRS[dir];
    for (let s = from; s <= longest; s++) {
      const off: [number, number, number] = [u.off[0] + dx * s, u.off[1] + dy * s, u.off[2] + dz * s];
      if (hits(u, off, contact, pathTol(u))) {
        if (explodeTrace.on) explodeTrace.lines.push(`${u.shapes.map((x) => x.id).join("+")} ${"+x -x +y -y +z -z".split(" ")[dir]} s=${s}: ${blockers(u, off, contact)}`);
        return null;
      }
      if (s >= min && clear(u, off, restTol(u))) return s;
    }
    return null;
  };

  const contactOf = (u: Unit): Set<number> => {
    const set = new Set<number>();
    const [ox, oy, oz] = u.off;
    for (let i = 0; i < u.x.length; i++) {
      const idx = u.x[i] + ox + nx * (u.y[i] + oy + ny * (u.z[i] + oz));
      if (occ[idx] > 0) set.add(idx);
    }
    return set;
  };

  /** Aynı yöne daha önce gitmiş parçalar: [u] onları önüne katıp ileri itebilir. */
  const ahead = (u: Unit, dir: number): Unit[] => placed.filter((p) => p.dir === dir && p !== u);

  const placed: Unit[] = [];

  /**
   * [u]'yu söker. Aynı yöne önce gitmiş parçalar yolunu kesiyorsa onları
   * daha ileri iter: dıştaki parça en uzakta kalır (kapak, eksantrik mili,
   * silindir kapağı sırası korunur).
   */
  const move = (u: Unit, ref: THREE.Vector3, half: THREE.Vector3, axisHint: number | null, minMove: number): boolean => {
    stamp(u, -1);
    const contact = contactOf(u);
    const rel = centerOf(u).sub(ref).divide(half);
    const pref = rel.length() < 0.25 ? null : rel.normalize();
    const candidates: { dir: number; s: number; cost: number; front: Unit[] }[] = [];
    DIRS.forEach((d, dir) => {
      const front = ahead(u, dir);
      for (const p of front) stamp(p, -1);
      const s = travel(u, dir, minMove, contact);
      for (const p of front) stamp(p, 1);
      if (s === null) return;
      const axis = d.findIndex((v) => v !== 0);
      let bend: number;
      if (pref) bend = 1 - (d[0] * pref.x + d[1] * pref.y + d[2] * pref.z);
      else bend = axisHint === null || axis === axisHint ? 0 : 1;
      // Aşağı ancak başka yol yoksa: zemine doğru açılan parça okunmuyor.
      const down = dir === 3 ? 1.5 : 0;
      candidates.push({ dir, s, cost: s / longest + 0.6 * bend + down, front });
    });
    candidates.sort((a, b) => a.cost - b.cost);
    for (const c of candidates) {
      if (place(u, c.dir, c.s, c.front, contact)) return true;
    }
    stamp(u, 1);
    return false;
  };

  const place = (u: Unit, dir: number, s: number, front: Unit[], contact: Set<number>): boolean => {
    const [dx, dy, dz] = DIRS[dir];
    const axis = DIRS[dir].findIndex((v) => v !== 0);
    const sign = DIRS[dir][axis];
    const saved = front.map((p) => [...p.off] as [number, number, number]);
    for (const p of front) stamp(p, -1);
    const start = [...u.off] as [number, number, number];
    u.off = [start[0] + dx * s, start[1] + dy * s, start[2] + dz * s];

    // İtilen zincir: u ve ileri itilenler. Izgaraya en sonda yazılır; aralarında
    // bir hücre boşluk kalsın diye hücreleri bir hücre şişirilerek tutulur.
    const chain: Unit[] = [u];
    const chainCells = new Set<number>();
    const addCells = (p: Unit) => {
      const [ox, oy, oz] = p.off;
      for (let i = 0; i < p.x.length; i++) {
        for (const [ex, ey, ez] of [[0, 0, 0], ...DIRS]) {
          chainCells.add(p.x[i] + ox + ex + nx * (p.y[i] + oy + ey + ny * (p.z[i] + oz + ez)));
        }
      }
    };
    const overlapsChain = (p: Unit) => {
      const [ox, oy, oz] = p.off;
      for (let i = 0; i < p.x.length; i++) {
        if (chainCells.has(p.x[i] + ox + nx * (p.y[i] + oy + ny * (p.z[i] + oz)))) return true;
      }
      return false;
    };
    addCells(u);
    const along = (p: Unit) => (p.min.getComponent(axis) + p.off[axis]) * sign;

    // Zincire değen her parça, değmeyene kadar ileri gider; o da zincire
    // katılır ve önündekileri iter.
    let waiting = [...front];
    let ok = true;
    for (let changed = true; changed && ok; ) {
      changed = false;
      waiting.sort((a, b) => along(a) - along(b));
      for (const p of waiting) {
        if (!overlapsChain(p)) continue;
        let pushed = false;
        for (let step = 1; step <= longest; step++) {
          p.off = [p.off[0] + dx, p.off[1] + dy, p.off[2] + dz];
          if (hits(p, p.off, NONE, pathTol(p))) break;
          if (!overlapsChain(p) && clear(p, p.off, restTol(p))) {
            pushed = true;
            break;
          }
        }
        if (!pushed) {
          ok = false;
          break;
        }
        chain.push(p);
        addCells(p);
        waiting = waiting.filter((w) => w !== p);
        changed = true;
        break;
      }
    }

    // u'nun yolu, ileri itilenlerin yeni yerinden geçmesin.
    if (ok) {
      for (const p of waiting) stamp(p, 1);
      const end = u.off;
      u.off = start;
      for (const p of chain.slice(1)) stamp(p, 1);
      ok = travel(u, dir, s, contact) === s;
      for (const p of chain.slice(1)) stamp(p, -1);
      u.off = end;
      for (const p of waiting) stamp(p, -1);
    }

    if (!ok) {
      front.forEach((p, i) => {
        p.off = saved[i];
        stamp(p, 1);
      });
      u.off = start;
      return false;
    }
    for (const p of [...chain, ...waiting]) stamp(p, 1);
    u.dir = dir;
    u.order = order++;
    u.layer = layer;
    if (!placed.includes(u)) placed.push(u);
    return true;
  };

  /** Katman katman söker; bir turda hiçbir şey çıkamazsa durur. */
  const peel = (
    units: Unit[],
    ref: (u: Unit) => THREE.Vector3,
    half: THREE.Vector3,
    axisHint: number | null,
    minMove: number,
    dissolve: boolean,
  ): Unit[] => {
    let rest = [...units];
    const outer = (u: Unit) => {
      const r = centerOf(u).sub(ref(u)).divide(half);
      return Math.max(Math.abs(r.x), Math.abs(r.y), Math.abs(r.z));
    };
    const moved: Unit[] = [];
    for (;;) {
      rest.sort((a, b) => outer(b) - outer(a));
      const next: Unit[] = [];
      let any = false;
      for (const u of rest) {
        if (move(u, ref(u), half, axisHint, minMove)) {
          any = true;
          moved.push(u);
        } else next.push(u);
      }
      if (any) layer++;
      rest = next;
      if (!any) {
        // Bütün olarak çıkamayan grupları üyelerine böl.
        const stuck = dissolve ? rest.filter((u) => u.group !== null) : [];
        if (stuck.length === 0) break;
        for (const u of stuck) {
          stamp(u, -1);
          gone.add(u);
          rest.splice(rest.indexOf(u), 1);
          for (const s of u.shapes) {
            const single = unitOf([s], null);
            all.push(single);
            stamp(single, 1);
            rest.push(single);
          }
        }
      }
    }
    return moved;
  };

  const minMove = Math.max(2, Math.round(longest * 0.04));
  const moved = peel(pending, () => anchorCenter, anchorHalf, null, minMove, true);

  // Bütün olarak çıkan grupların üyeleri grubun içinde açılır.
  const singles: Unit[] = [];
  for (const g of moved.filter((u) => u.group !== null)) {
    stamp(g, -1);
    gone.add(g);
    placed.splice(placed.indexOf(g), 1);
    const parts = g.shapes.map((s) => {
      const single = unitOf([s], null);
      all.push(single);
      single.off = [...g.off];
      single.dir = g.dir;
      single.order = g.order;
      single.layer = g.layer;
      stamp(single, 1);
      placed.push(single);
      return single;
    });
    const size = g.max.clone().sub(g.min);
    const thin = size.x <= size.z ? 0 : 2;
    const center = centerOf(g);
    const half = size.clone().multiplyScalar(0.5).max(new THREE.Vector3(1, 1, 1));
    const spread = Math.max(2, Math.round(size.length() * 0.08));
    peel(parts, () => center, half, thin, spread, false);
    singles.push(...parts);
  }

  // Aşamalar: her katman bir öncekinin bitmesine yakın başlar.
  const total = Math.max(1, layer);
  const step = 1 / (total + 0.5);
  const result = (u: Unit, layerOf: number) => {
    const offset = new THREE.Vector3(...u.off).multiplyScalar(grid.cell);
    const start = layerOf < 0 ? 0 : layerOf * step;
    return { offset, start, end: layerOf < 0 ? 1 : Math.min(1, start + step * 1.5) };
  };
  for (const u of [...placed, ...singles]) {
    if (u.group !== null) continue;
    for (const s of u.shapes) stages.set(s.id, result(u, u.layer));
  }
  // Grup olarak çıkıp üyesi yerinde kalanlar grubun aşamasıyla gider.
  for (const u of placed) {
    if (u.group === null) continue;
    for (const s of u.shapes) if (!stages.has(s.id)) stages.set(s.id, result(u, u.layer));
  }
  for (const s of shapes) if (!stages.has(s.id)) stages.set(s.id, still());
  return { stages, layers: total };
}

/** En büyük üyesi grubun kutusunun büyük kısmını kaplıyorsa grup bir arada duruyor. */
function compact(list: Shape[]): boolean {
  const box = (s: Shape) => {
    const b = new THREE.Box3();
    for (let i = 0; i < s.x.length; i++) b.expandByPoint(new THREE.Vector3(s.x[i], s.y[i], s.z[i]));
    return b;
  };
  const boxes = list.map(box);
  const all = boxes.reduce((a, b) => a.clone().union(b));
  const diag = (b: THREE.Box3) => b.getSize(new THREE.Vector3()).length();
  return Math.max(...boxes.map(diag)) >= 0.6 * diag(all);
}
