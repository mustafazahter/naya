import * as THREE from "three";

/**
 * Parçalara ayırma planı: doğrusal, merkezden dışarı.
 *
 * Her parça modelin merkezinden kendi merkezine uzanan doğru boyunca dışarı
 * gider; merkezden uzak olan her zaman daha uzağa varır. Açılmış hâlde hiçbir
 * parça başka birine girmez; hepsi birlikte, aynı anda, kendi doğrusunda
 * hareket eder.
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
  /** Uzaklık katsayısı k ve sıra payı s (modelin en uzun kenarına oranla). */
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
 * Planı kurar: her parça modelin merkezinden kendi merkezine uzanan doğru
 * boyunca dışarı gider. Merkeze uzaklığı r olan parça (1 + k)·r + s·sıra
 * uzaklığa varır; sıra parçaların merkeze yakınlıktan uzaklığa dizilişi.
 * Böylece uzaktaki parça her zaman daha uzağa gider, aralar uzaklıkla
 * orantılı kalır. k, açılmış hâlde hiçbir parçanın birbirine girmediği en
 * küçük değerdir.
 */
export function planExplode(grid: Grid, shapes: Shape[]): Plan {
  const stages = new Map<string, Stage>();
  for (const s of shapes) stages.set(s.id, { offset: new THREE.Vector3(), moves: [] });
  if (shapes.length < 2) return { stages, layers: 0, factor: 0, spacing: 0 };

  const model = grid.box;
  const center = model.getCenter(new THREE.Vector3());
  const size = model.getSize(new THREE.Vector3());
  const longest = Math.max(size.x, size.y, size.z);

  // Merkezden her parçanın merkezine: yön ve uzaklık. Merkezdeki parça yukarı.
  const rays = shapes.map((shape) => {
    const v = shape.box.getCenter(new THREE.Vector3()).sub(center);
    const r = v.length();
    return { shape, r, u: r < 0.02 * longest ? new THREE.Vector3(0, 1, 0) : v.divideScalar(r) };
  });
  const order = [...rays].sort((a, b) => a.r - b.r);
  const rank = new Map(order.map((ray, n) => [ray, n / (order.length - 1)]));

  /** k ve s ile her parçanın yer değiştirmesi. */
  const offsets = (k: number, s: number) =>
    rays.map((ray) =>
      ray.u
        .clone()
        .multiplyScalar((1 + k) * ray.r + s * rank.get(ray)!)
        .sub(ray.u.clone().multiplyScalar(ray.r)),
    );

  // Değme: `explodeReport` ile aynı hücreler ve aynı kural, biraz daha sıkı:
  // iki parçanın değdiği hücre sayısı toplu hâldekini aşmamalı.
  const cellOf = (o: THREE.Vector3): [number, number, number] => [
    Math.round(o.x / grid.fine),
    Math.round(o.y / grid.fine),
    Math.round(o.z / grid.fine),
  ];
  const overlap = (a: Shape, offA: THREE.Vector3, b: Shape, offB: THREE.Vector3): number => {
    if (b.fine.i.length < a.fine.i.length) return overlap(b, offB, a, offA);
    const fa = cellOf(offA);
    const fb = cellOf(offB);
    const di = fa[0] - fb[0];
    const dj = fa[1] - fb[1];
    const dk = fa[2] - fb[2];
    const A = a.fine;
    const B = b.fine;
    let n = 0;
    for (let q = 0; q < A.i.length; q++) {
      const i = A.i[q] + di;
      const j = A.j[q] + dj;
      const k = A.k[q] + dk;
      if (i < B.min[0] || i > B.max[0] || j < B.min[1] || j > B.max[1] || k < B.min[2] || k > B.max[2])
        continue;
      if (B.keys.has(fineKey(i, j, k))) n++;
    }
    return n;
  };
  const home = new Map<string, number>();
  const ZERO = new THREE.Vector3();
  const before = (a: number, b: number) => {
    const key = `${a}|${b}`;
    let n = home.get(key);
    if (n === undefined) {
      n = overlap(shapes[a], ZERO, shapes[b], ZERO);
      home.set(key, n);
    }
    return n;
  };
  const clean = (moves: THREE.Vector3[]) => {
    const boxes = shapes.map((s, n) => s.box.clone().translate(moves[n]).expandByScalar(grid.fine));
    for (let a = 0; a < shapes.length; a++) {
      for (let b = a + 1; b < shapes.length; b++) {
        if (!boxes[a].intersectsBox(boxes[b])) continue;
        const base = before(a, b);
        if (overlap(shapes[a], moves[a], shapes[b], moves[b]) - base >= 2 + 0.06 * base) return false;
      }
    }
    return true;
  };

  // En küçük k: 0,1'den 4'e 0,05 adımla taranır (değme k ile tek yönlü
  // değişmiyor: palet tekerlekleri bir k'da paletin dışında, daha büyüğünde
  // yeniden içinde kalabiliyor). 4'te bile değen kalırsa s iki katına çıkar.
  let s = longest * 0.03;
  let k = 4;
  search: for (let attempt = 0; attempt < 10; attempt++, s *= 2) {
    for (let step = 0; step <= 78; step++) {
      const candidate = 0.1 + step * 0.05;
      if (clean(offsets(candidate, s))) {
        k = candidate;
        break search;
      }
    }
  }
  const moves = offsets(k, s);

  // Zemin: bütün açılmış parçalar birlikte, en alttaki zemine oturacak kadar
  // kaydırılır; doğrular arasındaki ilişki bozulmaz.
  const lowest = Math.min(...shapes.map((shape, n) => shape.box.min.y + moves[n].y));
  // Kayma ince hücrenin katı: hücreye yuvarlanınca parçalar arasındaki
  // ilişki değişmesin.
  const lift = new THREE.Vector3(0, Math.ceil((model.min.y - lowest) / grid.fine) * grid.fine, 0);

  shapes.forEach((shape, n) => {
    const offset = moves[n].clone().add(lift);
    const stage = stages.get(shape.id)!;
    stage.offset.copy(offset);
    stage.moves.push({ start: 0, end: 1, points: [new THREE.Vector3(), offset] });
  });
  return { stages, layers: 7, factor: k, spacing: s / longest };
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
