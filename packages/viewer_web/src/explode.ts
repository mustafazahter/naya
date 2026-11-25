import * as THREE from "three";

/**
 * Parçalara ayırma planı: doğrusal, merkezden dışarı, katman katman.
 *
 * Her parça modelin merkezinden kendi merkezine uzanan doğru boyunca dışarı
 * gider. Dış kat (kasa, gövde, lastik) içindekinden eşit bir adım daha uzağa
 * varır: x, 2x, 3x. Açılmış hâlde hiçbir parça başka birine değmez; hepsi
 * birlikte, aynı anda, kendi doğrusunda hareket eder.
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
  /** Uzaklık katsayısı k ve kat adımı Δ (modelin en uzun kenarına oranla). */
  factor: number;
  spacing: number;
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

/**
 * Planı kurar.
 *
 * - Doğru: her parça modelin merkezinden kendi merkezine uzanan doğru
 *   boyunca gider; merkezi modelin merkezine çok yakınsa yukarı. Tekerlek
 *   gibi yuvarlak, yassı bir parça, merkezi onunkine yakın ve kutusu onun
 *   içinde kalan parçalarla (jant, göbek, disk, kaliper) bir takımdır: ortak
 *   merkezlerinin doğrusunda birlikte gider, kendi aralarında aks (takımın
 *   en ince ekseni) boyunca içten dışa, birbirine değmeyecek eşit aralıkla
 *   yan yana dizilir.
 * - Kat: parçayı kutusunun içine alan (kutusunun %85'i onun içinde) daha
 *   büyük parça sayısı d. Kasa 0, döşeme 1, koltuk 2...
 * - Yol: k · r + (L − d + 1) · Δ; r merkeze uzaklığı (doğru boyunca), L en
 *   büyük d. Dış kat içindekinden bir Δ daha uzağa gider: x, 2x, 3x. Bu ilk
 *   yol modelin en uzun kenarının %38'ini geçmez.
 * - k ve Δ: değen en az ikili kalan, eşitse açılmış kutusu en küçük olan.
 * - Kalan değmeler içten dışa çözülür: her takım, kendinden içteki (önce
 *   yerleşen) takımlara değmeyene kadar kendi doğrusunda biraz daha ilerler.
 *   Dış kat içtekinden geri kalmaz; gerekirse sınırı aşar (kasa, içindeki her
 *   şeyin üstüne çıkmak zorunda).
 */
export function planExplode(grid: Grid, shapes: Shape[]): Plan {
  const stages = new Map<string, Stage>();
  for (const s of shapes) stages.set(s.id, { offset: new THREE.Vector3(), moves: [] });
  if (shapes.length < 2) return { stages, layers: 0, factor: 0, spacing: 0 };

  const model = grid.box;
  const center = model.getCenter(new THREE.Vector3());
  const size = model.getSize(new THREE.Vector3());
  const longest = Math.max(size.x, size.y, size.z);
  const cap = longest * 0.38;
  const gap = longest * 0.02;
  const centers = shapes.map((s) => s.box.getCenter(new THREE.Vector3()));
  const volume = (b: THREE.Box3) => {
    const v = b.getSize(new THREE.Vector3());
    return Math.max(v.x, 1e-9) * Math.max(v.y, 1e-9) * Math.max(v.z, 1e-9);
  };

  const depth = shapes.map(
    (s) =>
      shapes.filter((o) => {
        if (o === s || volume(o.box) <= volume(s.box)) return false;
        const common = s.box.clone().intersect(o.box);
        return !common.isEmpty() && volume(common) >= 0.85 * volume(s.box);
      }).length,
  );
  const deepest = Math.max(...depth);

  // Değme: `explodeReport` ile aynı hücreler; ayrı yerlere giden iki parça
  // hiçbir hücrede buluşmamalı.
  const cellOf = (o: THREE.Vector3): [number, number, number] => [
    Math.round(o.x / grid.fine),
    Math.round(o.y / grid.fine),
    Math.round(o.z / grid.fine),
  ];
  const meet = (a: Shape, offA: THREE.Vector3, b: Shape, offB: THREE.Vector3): boolean => {
    if (b.fine.i.length < a.fine.i.length) return meet(b, offB, a, offA);
    const fa = cellOf(offA);
    const fb = cellOf(offB);
    const di = fa[0] - fb[0];
    const dj = fa[1] - fb[1];
    const dk = fa[2] - fb[2];
    const A = a.fine;
    const B = b.fine;
    for (let q = 0; q < A.i.length; q++) {
      const i = A.i[q] + di;
      const j = A.j[q] + dj;
      const k = A.k[q] + dk;
      if (i < B.min[0] || i > B.max[0] || j < B.min[1] || j > B.max[1] || k < B.min[2] || k > B.max[2])
        continue;
      if (B.keys.has(fineKey(i, j, k))) return true;
    }
    return false;
  };
  // Takımlar: tekerlek gibi yuvarlak ve yassı bir parça, merkezi onunkine
  // yakın ve kutusu onun içinde kalan parçalarla (jant, göbek, disk,
  // kaliper) bir takım olur.
  const round = (b: THREE.Box3) => {
    const v = b.getSize(new THREE.Vector3());
    const [s0, s1, s2] = [v.x, v.y, v.z].sort((x, y) => x - y);
    return s0 <= 0.6 * s1 && s1 >= 0.75 * s2;
  };
  const root = shapes.map((_, n) => n);
  const hosts = shapes
    .map((_, n) => n)
    .filter((n) => round(shapes[n].box))
    .sort((a, b) => volume(shapes[b].box) - volume(shapes[a].box));
  const taken = new Set<number>();
  for (const h of hosts) {
    if (taken.has(h)) continue;
    const box = shapes[h].box.clone().expandByScalar(grid.fine * 2);
    shapes.forEach((s, n) => {
      if (n === h || taken.has(n) || volume(s.box) >= volume(shapes[h].box)) return;
      if (centers[n].distanceTo(centers[h]) >= longest * 0.04) return;
      const common = s.box.clone().intersect(box);
      if (common.isEmpty() || volume(common) < 0.85 * volume(s.box)) return;
      root[n] = h;
      taken.add(n);
    });
    taken.add(h);
  }
  const find = (n: number) => root[n];
  interface Team {
    members: number[];
    shift: THREE.Vector3[];
    ray: THREE.Vector3;
    r: number;
    depth: number;
    travel: number;
  }
  const byRoot = new Map<number, number[]>();
  shapes.forEach((_, n) => {
    const list = byRoot.get(find(n)) ?? [];
    list.push(n);
    byRoot.set(find(n), list);
  });
  const teams: Team[] = [...byRoot.values()].map((members) => {
    const middle = members
      .reduce((v, n) => v.add(centers[n]), new THREE.Vector3())
      .divideScalar(members.length);
    const v = middle.clone().sub(center);
    const ray = v.length() < 0.02 * longest ? new THREE.Vector3(0, 1, 0) : v.clone().normalize();
    const shift = members.map(() => new THREE.Vector3());
    const layout = (space: number) => {
      // Aks boyunca içten dışa: içteki (kat derinliği büyük) merkezde,
      // dıştaki en uçta; aralar eşit.
      const box = members.reduce((b, n) => b.union(shapes[n].box), new THREE.Box3());
      const extent = box.getSize(new THREE.Vector3());
      const axis = extent.x <= extent.y && extent.x <= extent.z ? 0 : extent.z <= extent.y ? 2 : 1;
      const axle = new THREE.Vector3().setComponent(axis, 1);
      const sign =
        Math.abs(ray.getComponent(axis)) > 0.2
          ? Math.sign(ray.getComponent(axis))
          : Math.sign(middle.getComponent(axis) - center.getComponent(axis)) || 1;
      const order = members
        .map((n, i) => ({ n, i }))
        .sort((a, b) => depth[b.n] - depth[a.n] || volume(shapes[a.n].box) - volume(shapes[b.n].box));
      const first = centers[order[0].n].getComponent(axis);
      let at = 0;
      order.forEach(({ n, i }, m) => {
        if (m > 0) {
          const before = shapes[order[m - 1].n].box.getSize(new THREE.Vector3()).getComponent(axis);
          at += (before + shapes[n].box.getSize(new THREE.Vector3()).getComponent(axis)) / 2 + space;
        }
        shift[i].copy(axle).multiplyScalar(first + sign * at - centers[n].getComponent(axis));
      });
    };
    if (members.length > 1) {
      // Aralık, takımın üyeleri birbirine değmeyene kadar açılır.
      const clear = () =>
        members.every((a, i) =>
          members.every((b, j) => j <= i || !meet(shapes[a], shift[i], shapes[b], shift[j])),
        );
      for (let space = gap, tries = 0; tries < 40; tries++, space += gap) {
        layout(space);
        if (clear()) break;
      }
    }
    return {
      members,
      shift,
      ray,
      r: Math.max(0, v.dot(ray)),
      depth: Math.min(...members.map((n) => depth[n])),
      travel: 0,
    };
  });
  const teamOf = new Map<number, Team>();
  for (const t of teams) for (const n of t.members) teamOf.set(n, t);

  const offsetOf = (n: number) => {
    const t = teamOf.get(n)!;
    return t.ray.clone().multiplyScalar(t.travel).add(t.shift[t.members.indexOf(n)]);
  };
  /** Birbirine değen ikililer (ayrı takımlardan); [limit]'e varınca durur. */
  const touching = (limit: number) => {
    const moves = shapes.map((_, n) => offsetOf(n));
    const boxes = shapes.map((s, n) => s.box.clone().translate(moves[n]).expandByScalar(grid.fine));
    const out: [number, number][] = [];
    for (let a = 0; a < shapes.length && out.length < limit; a++) {
      for (let b = a + 1; b < shapes.length && out.length < limit; b++) {
        if (teamOf.get(a) === teamOf.get(b) && !teamOf.get(a)!.shift.some((s) => s.lengthSq() > 0)) continue;
        if (!boxes[a].intersectsBox(boxes[b])) continue;
        if (meet(shapes[a], moves[a], shapes[b], moves[b])) out.push([a, b]);
      }
    }
    return out;
  };
  const spread = () =>
    shapes
      .reduce((box, s, n) => box.union(s.box.clone().translate(offsetOf(n))), new THREE.Box3())
      .getSize(new THREE.Vector3())
      .length();
  const apply = (k: number, step: number) => {
    for (const t of teams) t.travel = Math.min(cap, k * t.r + (deepest - t.depth + 1) * step);
  };

  // k ve Δ: en az değen ikili, eşitse en derli toplu.
  let best = { k: 0, step: longest * 0.02, touches: Infinity, size: Infinity };
  for (const k of [0, 0.1, 0.2, 0.35, 0.5]) {
    for (let n = 1; n * longest * 0.02 * (deepest + 1) <= cap * 1.5; n++) {
      const step = n * longest * 0.02;
      apply(k, step);
      const touches = touching(best.touches).length;
      if (touches > best.touches) continue;
      const size = spread();
      if (touches < best.touches || size < best.size) best = { k, step, touches, size };
    }
  }
  apply(best.k, best.step);

  // Kalan değmeler, içten dışa: her takım kendinden önce yerleşenlere
  // değmeyene kadar kendi doğrusunda ilerler. Dış kat sonra gelir, içtekinden
  // geri kalmaz; sıra bozulmaz.
  const order = [...teams].sort((a, b) => b.depth - a.depth || a.r - b.r);
  const settled: Team[] = [];
  const blocked = (t: Team) => {
    for (const n of t.members) {
      const offA = offsetOf(n);
      const boxA = shapes[n].box.clone().translate(offA).expandByScalar(grid.fine);
      for (const o of settled) {
        for (const m of o.members) {
          const offB = offsetOf(m);
          if (!boxA.intersectsBox(shapes[m].box.clone().translate(offB))) continue;
          if (meet(shapes[n], offA, shapes[m], offB)) return true;
        }
      }
    }
    return false;
  };
  for (const t of order) {
    while (t.travel < longest * 2 && blocked(t)) t.travel += longest * 0.005;
    settled.push(t);
  }

  const moves = shapes.map((_, n) => offsetOf(n));
  // Zemin: bütün açılmış parçalar birlikte, en alttaki zemine oturacak kadar
  // kaydırılır (ince hücrenin katı kadar, hücreye yuvarlanınca ilişki
  // bozulmasın); doğrular arasındaki ilişki değişmez.
  const lowest = Math.min(...shapes.map((shape, n) => shape.box.min.y + moves[n].y));
  const lift = new THREE.Vector3(0, Math.ceil((model.min.y - lowest) / grid.fine) * grid.fine, 0);

  shapes.forEach((shape, n) => {
    const offset = moves[n].clone().add(lift);
    const stage = stages.get(shape.id)!;
    stage.offset.copy(offset);
    stage.moves.push({ start: 0, end: 1, points: [new THREE.Vector3(), offset] });
  });
  return { stages, layers: 7, factor: best.k, spacing: best.step / longest };
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
