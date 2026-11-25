import * as THREE from "three";

/**
 * Parçalara ayırma planı.
 *
 * En büyük parça (kasa, gövde, kadro) yerinde kalır; diğerleri dıştan içe,
 * sırayla sökülür. Bir parça eksen yönlerinden birine gider; önü kapalıysa
 * önce kısa bir adım atar (biraz kalkıp yana kayar), sonra çıkar. Daha önce
 * aynı yöne gitmiş parçalar yolunu kesiyorsa onları önüne katıp ileri iter;
 * böylece kapak, eksantrik mili, silindir kapağı sırası korunur.
 *
 * Bir parçanın yolu üç ayrı yolla denetlenir:
 * - Işınlar: her parça için x, y ve z boyunca, her pikselden geçen ışının
 *   yüzeyi kestiği derinlikler. Kayan parça, aynı ışında önünde duran bir
 *   noktaya varınca durur. İç içe ama birbirine değmeyen parçalar (jant
 *   içindeki disk, gömlekteki piston) birbirini kilitlemez.
 * - Değme sayısı: modellerde birçok parça toplu hâlde birbirine biraz girer
 *   (kapı kasaya, döşeme tavana). Işınlar bu kesişmelerin çevresini saymaz;
 *   onun yerine iki parçanın ince hücrelerde kaç yerde değdiği sayılır. Yol
 *   boyunca bu sayı yola çıkılan yerdekini aşamaz: parça ancak kesiştiği
 *   yerden kayarak çıkabilir, öteki parçanın içine dalamaz. Sayım
 *   `explodeReport` ile aynı hücrelerle yapılır.
 * - Vardığı yer için kaba hücreler: açılmış hâlde her parçanın çevresinde en
 *   az bir hücre boşluk kalır; hiçbir parça zeminin altına inmez.
 *
 * Hiçbir yoldan çıkamayan parça (kabinin içindeki koltuk, tekerleğin
 * çevresindeki zincir) yerinde kalır; toplu hâlde zaten bir arada durduğu
 * için yerinde kalması da temizdir.
 *
 * Zamanlama: her hareket bir dilim sürer. Süpürdüğü alan daha önce planlanmış
 * bir hareketinkine değen hareket, o bitince başlar; değmeyenler aynı anda
 * oynar.
 */

/** Izgara: hem ışın pikselleri hem hücreler aynı köşeden sayılır. */
export interface Grid {
  origin: THREE.Vector3;
  /** Işın pikseli. Hareketler bu birimin katlarıyla yapılır. */
  px: number;
  /** Hücre: [CELL] piksel. */
  cell: number;
  /**
   * İnce hücre: modelin en uzun kenarının 1/220'si, `explodeReport` ile aynı.
   * Parçaların değdiği hücreler bununla sayılır.
   */
  fine: number;
  nx: number;
  ny: number;
  nz: number;
}

const CELL = 3;

/** Bir eksen boyunca ışın örnekleri; her pikselin derinlikleri artan sırada. */
interface Raster {
  u0: number;
  v0: number;
  w: number;
  h: number;
  start: Uint32Array;
  depth: Float32Array;
}

export interface Shape {
  id: string;
  /** Dolu hücreler. */
  x: Int16Array;
  y: Int16Array;
  z: Int16Array;
  /** x, y ve z boyunca ışın örnekleri. */
  rays: Raster[];
  /** İnce hücreler: iki parçanın kaç hücrede değdiği bunlarla sayılır. */
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
  /** Art arda oynayan hareket sayısı; animasyonun süresi buna bağlı. */
  layers: number;
}

/** Işın ekseninin yanal eksenleri. */
const LAT: [number, number][] = [
  [1, 2],
  [0, 2],
  [0, 1],
];

/** Altı eksen yönü: +x, -x, +y, -y, +z, -z. */
const DIRS: [number, number, number][] = [
  [1, 0, 0],
  [-1, 0, 0],
  [0, 1, 0],
  [0, -1, 0],
  [0, 0, 1],
  [0, 0, -1],
];
const DOWN = 3;

type Off = [number, number, number];

/**
 * Model için ızgara. Piksel modelin en uzun kenarının 1/400'ü. Parçaların
 * açılınca gideceği yer için yanlarda ve üstte boşluk bırakılır; altta zemin
 * sınırdır, hiçbir parça zeminin altına inmez.
 */
export function makeGrid(box: THREE.Box3): Grid {
  const size = box.getSize(new THREE.Vector3());
  const longest = Math.max(size.x, size.y, size.z, 1e-6);
  const px = longest / 400;
  const cell = px * CELL;
  const side = longest * 0.6;
  const top = longest * 0.8;
  return {
    origin: new THREE.Vector3(box.min.x - side, box.min.y, box.min.z - side),
    px,
    cell,
    fine: longest / FINE,
    nx: Math.ceil((size.x + 2 * side) / cell) + 1,
    ny: Math.ceil((size.y + top) / cell) + 1,
    nz: Math.ceil((size.z + 2 * side) / cell) + 1,
  };
}

/** Üçgenleri ([triangles]) hücrelere ve ışın örneklerine çevirir. */
export function shapeOf(id: string, tris: Float32Array, grid: Grid): Shape {
  const box = new THREE.Box3();
  const p = new THREE.Vector3();
  for (let i = 0; i < tris.length; i += 3) box.expandByPoint(p.set(tris[i], tris[i + 1], tris[i + 2]));
  const { x, y, z } = cellsOf(tris, grid);
  return {
    id,
    x,
    y,
    z,
    rays: [0, 1, 2].map((axis) => raster(tris, grid, axis)),
    fine: fineOf(tris, grid),
    box,
  };
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

/** İnce hücre bölüneni; `explodeCheck` de aynısını kullanır. */
export const FINE = 220;
/** İnce hücre anahtarı. */
export const fineKey = (i: number, j: number, k: number) =>
  (i + 2048) * 4096 * 4096 + (j + 2048) * 4096 + (k + 2048);

/** İnce hücreler: modelin yerel koordinatlarının başlangıcından sayılır. */
function fineOf(tris: Float32Array, grid: Grid): Fine {
  const size = grid.fine;
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

/** Yüzeyin değdiği hücreler. Üçgenler hücreden sık örneklenir. */
function cellsOf(tris: Float32Array, grid: Grid) {
  const seen = new Set<number>();
  const { origin, cell, nx, ny, nz } = grid;
  const a = new THREE.Vector3();
  const b = new THREE.Vector3();
  const c = new THREE.Vector3();
  const p = new THREE.Vector3();
  for (let t = 0; t < tris.length; t += 9) {
    a.fromArray(tris, t);
    b.fromArray(tris, t + 3);
    c.fromArray(tris, t + 6);
    const edge = Math.max(a.distanceTo(b), b.distanceTo(c), c.distanceTo(a));
    const n = Math.max(1, Math.ceil(edge / (cell * 0.5)));
    b.sub(a);
    c.sub(a);
    for (let u = 0; u <= n; u++) {
      for (let v = 0; u + v <= n; v++) {
        p.copy(a)
          .addScaledVector(b, u / n)
          .addScaledVector(c, v / n);
        const i = Math.floor((p.x - origin.x) / cell);
        const j = Math.floor((p.y - origin.y) / cell);
        const k = Math.floor((p.z - origin.z) / cell);
        if (i < 0 || j < 0 || k < 0 || i >= nx || j >= ny || k >= nz) continue;
        seen.add(i + nx * (j + ny * k));
      }
    }
  }
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
  return { x, y, z };
}

/**
 * [axis] boyunca ışın örnekleri: her pikselin merkezinden geçen ışının
 * üçgenleri kestiği derinlikler. Işına paralel yüzeyler (silindirin yan
 * yüzü) iz bırakmaz; zaten o yönde kayan bir parçaya engel olmazlar.
 */
function raster(tris: Float32Array, grid: Grid, axis: number): Raster {
  const [l0, l1] = LAT[axis];
  const ou = grid.origin.getComponent(l0);
  const ov = grid.origin.getComponent(l1);
  const px = grid.px;
  const is: number[] = [];
  const js: number[] = [];
  const ds: number[] = [];
  for (let t = 0; t < tris.length; t += 9) {
    const u0 = (tris[t + l0] - ou) / px;
    const v0 = (tris[t + l1] - ov) / px;
    const u1 = (tris[t + 3 + l0] - ou) / px;
    const v1 = (tris[t + 3 + l1] - ov) / px;
    const u2 = (tris[t + 6 + l0] - ou) / px;
    const v2 = (tris[t + 6 + l1] - ov) / px;
    const area = (u1 - u0) * (v2 - v0) - (u2 - u0) * (v1 - v0);
    if (Math.abs(area) < 1e-9) continue;
    const d0 = tris[t + axis];
    const d1 = tris[t + 3 + axis];
    const d2 = tris[t + 6 + axis];
    const before = is.length;
    const iMin = Math.ceil(Math.min(u0, u1, u2) - 0.5);
    const iMax = Math.floor(Math.max(u0, u1, u2) - 0.5);
    const jMin = Math.ceil(Math.min(v0, v1, v2) - 0.5);
    const jMax = Math.floor(Math.max(v0, v1, v2) - 0.5);
    for (let j = jMin; j <= jMax; j++) {
      const v = j + 0.5;
      for (let i = iMin; i <= iMax; i++) {
        const u = i + 0.5;
        const w0 = ((u1 - u) * (v2 - v) - (u2 - u) * (v1 - v)) / area;
        const w1 = ((u2 - u) * (v0 - v) - (u0 - u) * (v2 - v)) / area;
        const w2 = 1 - w0 - w1;
        if (w0 < -1e-7 || w1 < -1e-7 || w2 < -1e-7) continue;
        is.push(i);
        js.push(j);
        ds.push(w0 * d0 + w1 * d1 + w2 * d2);
      }
    }
    // Hiçbir pikselin ortasına denk gelmeyen ince üçgen (contanın kenarı):
    // üzerinden örnek alınır, yoksa ince parça o yönde görünmez olur.
    if (is.length === before) {
      const corners = [
        [u0, v0, d0],
        [u1, v1, d1],
        [u2, v2, d2],
      ];
      for (let e = 0; e < 3; e++) {
        const [ua, va, da] = corners[e];
        const [ub, vb, db] = corners[(e + 1) % 3];
        const n = Math.max(1, Math.ceil(2 * Math.hypot(ub - ua, vb - va)));
        for (let k = 0; k < n; k++) {
          is.push(Math.floor(ua + ((ub - ua) * k) / n));
          js.push(Math.floor(va + ((vb - va) * k) / n));
          ds.push(da + ((db - da) * k) / n);
        }
      }
    }
  }
  if (is.length === 0) {
    return { u0: 0, v0: 0, w: 0, h: 0, start: new Uint32Array(1), depth: new Float32Array(0) };
  }
  let iLo = Infinity;
  let iHi = -Infinity;
  let jLo = Infinity;
  let jHi = -Infinity;
  for (let n = 0; n < is.length; n++) {
    iLo = Math.min(iLo, is[n]);
    iHi = Math.max(iHi, is[n]);
    jLo = Math.min(jLo, js[n]);
    jHi = Math.max(jHi, js[n]);
  }
  const w = iHi - iLo + 1;
  const h = jHi - jLo + 1;
  const count = new Uint32Array(w * h + 1);
  for (let n = 0; n < is.length; n++) count[is[n] - iLo + w * (js[n] - jLo) + 1]++;
  for (let n = 1; n <= w * h; n++) count[n] += count[n - 1];
  const fill = count.slice(0, w * h);
  const raw = new Float32Array(is.length);
  for (let n = 0; n < is.length; n++) raw[fill[is[n] - iLo + w * (js[n] - jLo)]++] = ds[n];
  // Her pikselin derinliklerini sırala, çok yakın olanları teke indir.
  const start = new Uint32Array(w * h + 1);
  const depth = new Float32Array(is.length);
  let out = 0;
  const near = px * 0.05;
  for (let p = 0; p < w * h; p++) {
    start[p] = out;
    const list = raw.subarray(count[p], count[p + 1]).sort();
    for (let k = 0; k < list.length; k++) {
      if (k > 0 && list[k] - depth[out - 1] < near) continue;
      depth[out++] = list[k];
    }
  }
  start[w * h] = out;
  return { u0: iLo, v0: jLo, w, h, start, depth: depth.slice(0, out) };
}

/**
 * [a] parçası [sign] yönünde kayarken [b] parçasının yüzeyine kaç birim
 * sonra değer (en çok [best]). Aynı ışında [tau]'dan yakın duran noktalar
 * sayılmaz: toplu hâlde zaten birbirine dayanan yüzeyler. [ignore] b'nin
 * pikselinde [delta] kadar öndeki bir noktayı saymamak için.
 */
function reach(
  a: Raster,
  offA: Off,
  b: Raster,
  offB: Off,
  axis: number,
  sign: number,
  px: number,
  tau: number,
  best: number,
  ignore: ((i: number, j: number, delta: number) => boolean) | null,
): number {
  const [l0, l1] = LAT[axis];
  const di = a.u0 + offA[l0] - b.u0 - offB[l0];
  const dj = a.v0 + offA[l1] - b.v0 - offB[l1];
  const i0 = Math.max(0, -di);
  const i1 = Math.min(a.w, b.w - di);
  const j0 = Math.max(0, -dj);
  const j1 = Math.min(a.h, b.h - dj);
  if (i0 >= i1 || j0 >= j1) return best;
  const shift = (offA[axis] - offB[axis]) * px;
  const A = a.depth;
  const B = b.depth;
  for (let j = j0; j < j1; j++) {
    for (let i = i0; i < i1; i++) {
      const pa = i + a.w * j;
      const as = a.start[pa];
      const ae = a.start[pa + 1];
      if (as === ae) continue;
      const pb = i + di + b.w * (j + dj);
      const bs = b.start[pb];
      const be = b.start[pb + 1];
      if (bs === be) continue;
      if (sign > 0) {
        // Her b için, b'nin gerisindeki en yakın a.
        let k = as;
        for (let m = bs; m < be; m++) {
          const limit = B[m] - tau;
          while (k < ae && A[k] + shift < limit) k++;
          if (k === as) continue;
          const d = B[m] - A[k - 1] - shift;
          if (d < best && !ignore?.(i + di, j + dj, d)) best = d;
        }
      } else {
        let k = ae - 1;
        for (let m = be - 1; m >= bs; m--) {
          const limit = B[m] + tau;
          while (k >= as && A[k] + shift > limit) k--;
          if (k === ae - 1) continue;
          const d = A[k + 1] + shift - B[m];
          if (d < best && !ignore?.(i + di, j + dj, d)) best = d;
        }
      }
    }
  }
  return best;
}

/**
 * Toplu hâlde (ikisi de yerinde) [a] ile [b]'nin yüzeylerinin kesiştiği ya da
 * değdiği pikseller (aynı ışında [touch]'tan yakın iki nokta), [spread] piksel
 * yana yayılmış olarak; b'nin piksel numarasıyla. Birbirini eğik kesen
 * yüzeyler kesişme çizgisinden uzaklaştıkça açılır; bu bant o açılmayı örter.
 */
function tangle(a: Raster, b: Raster, touch: number, spread: number): Uint8Array | null {
  const di = a.u0 - b.u0;
  const dj = a.v0 - b.v0;
  let mask: Uint8Array | null = null;
  for (let j = Math.max(0, -dj); j < Math.min(a.h, b.h - dj); j++) {
    for (let i = Math.max(0, -di); i < Math.min(a.w, b.w - di); i++) {
      const pa = i + a.w * j;
      const pb = i + di + b.w * (j + dj);
      if (a.start[pa] === a.start[pa + 1] || b.start[pb] === b.start[pb + 1]) continue;
      let hit = false;
      for (let p = a.start[pa]; !hit && p < a.start[pa + 1]; p++) {
        for (let q = b.start[pb]; q < b.start[pb + 1]; q++) {
          if (Math.abs(a.depth[p] - b.depth[q]) <= touch) {
            hit = true;
            break;
          }
        }
      }
      if (!hit) continue;
      mask ??= new Uint8Array(b.w * b.h);
      mask[pb] = 1;
    }
  }
  if (!mask) return null;
  // Yana yayma: önce satırlar, sonra sütunlar boyunca.
  const { w, h } = b;
  const row = new Uint8Array(w * h);
  for (let y = 0; y < h; y++) {
    let last = -Infinity;
    for (let x = 0; x < w; x++) {
      if (mask[x + w * y]) last = x;
      if (x - last <= spread) row[x + w * y] = 1;
    }
    last = Infinity;
    for (let x = w - 1; x >= 0; x--) {
      if (mask[x + w * y]) last = x;
      if (last - x <= spread) row[x + w * y] = 1;
    }
  }
  const out = new Uint8Array(w * h);
  for (let x = 0; x < w; x++) {
    let last = -Infinity;
    for (let y = 0; y < h; y++) {
      if (row[x + w * y]) last = y;
      if (y - last <= spread) out[x + w * y] = 1;
    }
    last = Infinity;
    for (let y = h - 1; y >= 0; y--) {
      if (row[x + w * y]) last = y;
      if (last - y <= spread) out[x + w * y] = 1;
    }
  }
  return out;
}

/** Birlikte hareket eden parçalar: tek bir parça ya da toplu taşınan bir grup. */
interface Unit {
  shapes: Shape[];
  x: Int16Array;
  y: Int16Array;
  z: Int16Array;
  /** Toplu hâldeki kutusu. */
  box: THREE.Box3;
  /** Şu anki yer değiştirme, piksel cinsinden. */
  off: Off;
  /** Grup olarak taşınıyorsa grubun adı; sonra içindekiler ayrıca açılır. */
  group: string | null;
  /** Son gittiği yön (DIRS sırası); hiç gitmediyse -1. */
  dir: number;
}

interface Step {
  unit: Unit;
  from: Off;
  via: Off | null;
  to: Off;
}

function unitOf(shapes: Shape[], group: string | null, off: Off = [0, 0, 0]): Unit {
  const total = shapes.reduce((n, s) => n + s.x.length, 0);
  const x = new Int16Array(total);
  const y = new Int16Array(total);
  const z = new Int16Array(total);
  const box = new THREE.Box3();
  let n = 0;
  for (const s of shapes) {
    x.set(s.x, n);
    y.set(s.y, n);
    z.set(s.z, n);
    n += s.x.length;
    box.union(s.box);
  }
  return { shapes, x, y, z, box, off: [...off], group, dir: -1 };
}

const add = (o: Off, dir: number, s: number): Off => [
  o[0] + DIRS[dir][0] * s,
  o[1] + DIRS[dir][1] * s,
  o[2] + DIRS[dir][2] * s,
];

/**
 * Planı kurar. [groups]: düğüm → montaj grubu (`groupNodes`).
 *
 * Gruplar iki türlü: tekerlek gibi bir arada duran grup (en büyük üyesi
 * grubun neredeyse tamamını kaplıyor) önce bütün olarak dışarı çıkar, sonra
 * üyeleri grubun en ince ekseni (tekerlekte aks) boyunca açılır. Bütün olarak
 * çıkamayan ya da modelin her yanına dağılmış grubun her üyesi kendi başına
 * sökülür.
 */
export function planExplode(grid: Grid, shapes: Shape[], groups: Map<string, string>): Plan {
  const { nx, ny, nz, px } = grid;
  const stages = new Map<string, Stage>();
  for (const s of shapes) stages.set(s.id, { offset: new THREE.Vector3(), moves: [] });
  if (shapes.length < 2) return { stages, layers: 0 };

  const occ = new Uint8Array(nx * ny * nz);
  const cellOff = (o: Off): Off => [
    Math.round(o[0] / CELL),
    Math.round(o[1] / CELL),
    Math.round(o[2] / CELL),
  ];
  const stamp = (u: Unit, delta: 1 | -1) => {
    const [ox, oy, oz] = cellOff(u.off);
    for (let i = 0; i < u.x.length; i++) {
      const idx = u.x[i] + ox + nx * (u.y[i] + oy + ny * (u.z[i] + oz));
      occ[idx] = Math.max(0, Math.min(255, occ[idx] + delta));
    }
  };
  /** [u] [off]'ta ızgaranın içinde ve çevresinde bir hücre boşlukla duruyor mu. */
  const NEAR: Off[] = [[0, 0, 0], ...DIRS];
  const clear = (u: Unit, off: Off): boolean => {
    const [ox, oy, oz] = cellOff(off);
    for (let i = 0; i < u.x.length; i++) {
      const x = u.x[i] + ox;
      const y = u.y[i] + oy;
      const z = u.z[i] + oz;
      if (x < 1 || y < 0 || z < 1 || x >= nx - 1 || y >= ny - 1 || z >= nz - 1) return false;
      for (const [dx, dy, dz] of NEAR) {
        if (y + dy < 0) continue;
        if (occ[x + dx + nx * (y + dy + ny * (z + dz))] > 0) return false;
      }
    }
    return true;
  };
  const inside = (u: Unit, off: Off): boolean => {
    const [ox, oy, oz] = cellOff(off);
    const lo = u.box.min;
    const hi = u.box.max;
    const o = grid.origin;
    const c = grid.cell;
    return (
      (lo.x - o.x) / c + ox >= 0 &&
      (lo.y - o.y) / c + oy >= 0 &&
      (lo.z - o.z) / c + oz >= 0 &&
      (hi.x - o.x) / c + ox < nx &&
      (hi.y - o.y) / c + oy < ny &&
      (hi.z - o.z) / c + oz < nz
    );
  };

  const boxAt = (u: Unit, off: Off) =>
    u.box.clone().translate(new THREE.Vector3(off[0] * px, off[1] * px, off[2] * px));

  // Sabit parça: en çok hücresi olan. Kasa, gövde ya da kadro.
  const anchorShape = shapes.reduce((a, b) => (b.x.length > a.x.length ? b : a));
  const anchor = unitOf([anchorShape], null);
  const anchorCenter = anchor.box.getCenter(new THREE.Vector3());
  const anchorHalf = anchor.box
    .getSize(new THREE.Vector3())
    .multiplyScalar(0.5)
    .max(new THREE.Vector3(px, px, px));
  const size = new THREE.Box3()
    .setFromPoints(shapes.flatMap((s) => [s.box.min, s.box.max]))
    .getSize(new THREE.Vector3());
  const longest = Math.max(size.x, size.y, size.z);
  const tau = px * 1.5;
  const margin = grid.cell;
  const reachMax = longest * 1.5;
  const travelMax = Math.round((longest * 0.9) / px);
  const lifts = [0.03, 0.1, 0.25].map((f) => Math.max(1, Math.round((longest * f) / px)));

  const members = new Map<string, Shape[]>();
  for (const s of shapes) {
    if (s === anchorShape) continue;
    const g = groups.get(s.id) ?? s.id;
    if (!members.has(g)) members.set(g, []);
    members.get(g)!.push(s);
  }
  const anchorGroup = groups.get(anchorShape.id) ?? anchorShape.id;
  const pending: Unit[] = [];
  for (const [g, list] of members) {
    if (g !== anchorGroup && list.length > 1 && compact(list)) pending.push(unitOf(list, g));
    else for (const s of list) pending.push(unitOf([s], null));
  }

  const all: Unit[] = [anchor, ...pending];
  const gone = new Set<Unit>();
  for (const u of all) stamp(u, 1);
  // Toplu hâlde birbirine dolanmış yüzeyler: modelde birbirini kesen ya da
  // birbirine değen iki parça. Kesiştikleri yerin çevresinde, kayan parçanın
  // [close]'dan az önünde kalan noktalar engel sayılmaz: orada zaten iç
  // içeydiler. Kesişmeden uzakta (tavanın altındaki döşeme gibi) her nokta
  // yine engeldir; aradan kayarak çıkarken değdikleri yerin büyümediğini de
  // ince hücrelerle sayılan değme denetler.
  const index = new Map(shapes.map((s, i) => [s, i]));
  const close = grid.cell * 4;
  const spread = 12;
  const touch = px * 3;
  const near = new Set<number>();
  {
    const owners = new Map<number, number[]>();
    shapes.forEach((s, n) => {
      for (let i = 0; i < s.x.length; i++) {
        const key = s.x[i] + nx * (s.y[i] + ny * s.z[i]);
        const list = owners.get(key);
        if (list) list.push(n);
        else owners.set(key, [n]);
      }
    });
    // Birbirine bir hücreden yakın geçen parçalar.
    for (const [key, list] of owners) {
      for (const [dx, dy, dz] of NEAR) {
        const other = owners.get(key + dx + nx * (dy + ny * dz));
        if (!other) continue;
        for (const a of list) for (const b of other) if (a !== b) near.add(a * shapes.length + b);
      }
    }
  }
  const tangles = new Map<number, Uint8Array | null>();
  /** İkisi de yerindeyken [a] kayarken [b]'nin hangi noktalarını saymayacak. */
  const touching = (a: Shape, offA: Off, b: Shape, offB: Off, axis: number) => {
    const home = (o: Off) => o[0] === 0 && o[1] === 0 && o[2] === 0;
    if (!home(offA) || !home(offB)) return null;
    const pair = index.get(a)! * shapes.length + index.get(b)!;
    if (!near.has(pair)) return null;
    const key = pair * 3 + axis;
    let mask = tangles.get(key);
    if (mask === undefined) {
      mask = tangle(a.rays[axis], b.rays[axis], touch, spread);
      tangles.set(key, mask);
    }
    if (!mask) return null;
    const m = mask;
    const w = b.rays[axis].w;
    return (i: number, j: number, delta: number) => delta <= close && m[i + w * j] === 1;
  };

  const steps: Step[] = [];
  /** Hareketin süpürdüğü alan. */
  const sweep = (step: Step) => {
    const box = boxAt(step.unit, step.from).union(boxAt(step.unit, step.to));
    if (step.via) box.union(boxAt(step.unit, step.via));
    return box.expandByScalar(margin);
  };

  /**
   * [u] [from]'dan [dir] yönünde kayarken bir parçaya kaç birim sonra değer.
   * [skip] içindekiler sayılmaz.
   */
  const reachOf = (u: Unit, from: Off, dir: number, skip: Set<Unit>, limit = reachMax): number => {
    const axis = DIRS[dir].findIndex((v) => v !== 0);
    const sign = DIRS[dir][axis];
    const swept = boxAt(u, from);
    if (sign > 0) swept.max.setComponent(axis, swept.max.getComponent(axis) + limit);
    else swept.min.setComponent(axis, swept.min.getComponent(axis) - limit);
    swept.expandByScalar(px);
    let best = limit;
    for (const w of all) {
      if (w === u || gone.has(w) || skip.has(w)) continue;
      if (!swept.intersectsBox(boxAt(w, w.off))) continue;
      for (const a of u.shapes) {
        for (const b of w.shapes) {
          best = reach(
            a.rays[axis],
            from,
            b.rays[axis],
            w.off,
            axis,
            sign,
            px,
            tau,
            best,
            touching(a, from, b, w.off, axis),
          );
        }
      }
    }
    return best;
  };

  /**
   * [u]'nun [from]'dan [dir] yönünde, en az [min] piksel gidip boş bir yerde
   * durabileceği mesafe; yoksa null. [fronts] yok sayılır (ileri itilecekler).
   */
  const travel = (u: Unit, from: Off, dir: number, min: number, fronts: Unit[]): number | null => {
    if (!inside(u, from)) return null;
    const free = reachOf(u, from, dir, new Set(fronts));
    const most = Math.min(travelMax, Math.floor((free - margin) / px));
    if (most < min) return null;
    for (const p of fronts) stamp(p, -1);
    let found: number | null = null;
    for (let s = min; s <= most; s += CELL) {
      if (clear(u, add(from, dir, s))) {
        found = s;
        break;
      }
    }
    for (const p of fronts) stamp(p, 1);
    return found;
  };

  /** Aynı yöne daha önce gitmiş parçalar: [u] onları önüne katıp ileri itebilir. */
  const frontsOf = (u: Unit, dir: number) => all.filter((w) => w !== u && !gone.has(w) && w.dir === dir);

  // Değme sayısı: toplu hâlde zaten birbirine değen iki parça (koltuk ve
  // halı) ayrılırken değdikleri hücre sayısı artmamalı. Işınlar yalnız
  // toplu hâlde değmeyen yüzeyleri sıkı tutuyor; değenlerin arasından
  // kayarak çıkmaya bu sayı izin verir ya da vermez.
  const fineOff = (o: Off): Off => [
    Math.round((o[0] * px) / grid.fine),
    Math.round((o[1] * px) / grid.fine),
    Math.round((o[2] * px) / grid.fine),
  ];
  const overlap = (a: Shape, offA: Off, b: Shape, offB: Off): number => {
    const fa = fineOff(offA);
    const fb = fineOff(offB);
    const di = fa[0] - fb[0];
    const dj = fa[1] - fb[1];
    const dk = fa[2] - fb[2];
    const A = a.fine;
    const B = b.fine;
    if (A.max[0] + di < B.min[0] || A.min[0] + di > B.max[0]) return 0;
    if (A.max[1] + dj < B.min[1] || A.min[1] + dj > B.max[1]) return 0;
    if (A.max[2] + dk < B.min[2] || A.min[2] + dk > B.max[2]) return 0;
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
  const baseline = new Map<number, number>();
  const ZERO: Off = [0, 0, 0];
  const homeOverlap = (a: Shape, b: Shape) => {
    const key = index.get(a)! * shapes.length + index.get(b)!;
    let n = baseline.get(key);
    if (n === undefined) {
      n = overlap(a, ZERO, b, ZERO);
      baseline.set(key, n);
    }
    return n;
  };
  /**
   * [u] [points] köşeli yol boyunca giderken hiçbir parçaya toplu hâldekinden
   * ve yola çıktığı yerdekinden fazla değmiyor mu. [skip] içindekiler sayılmaz.
   */
  const fits = (u: Unit, points: Off[], skip: Set<Unit>): boolean => {
    const before = new Map<string, number>();
    const allowed = (sa: Shape, sb: Shape, w: Unit) => {
      const key = `${index.get(sa)}|${index.get(sb)}`;
      let n = before.get(key);
      if (n === undefined) {
        n = Math.min(homeOverlap(sa, sb), overlap(sa, points[0], sb, w.off));
        before.set(key, n);
      }
      return n;
    };
    for (let n = 1; n < points.length; n++) {
      const a = points[n - 1];
      const b = points[n];
      const length = Math.max(...[0, 1, 2].map((c) => Math.abs(b[c] - a[c])));
      const count = Math.max(1, Math.ceil((length * px) / grid.fine));
      for (let t = 1; t <= count; t++) {
        const o: Off = [0, 1, 2].map((c) => Math.round(a[c] + ((b[c] - a[c]) * t) / count)) as Off;
        const box = boxAt(u, o).expandByScalar(grid.fine);
        for (const w of all) {
          if (w === u || gone.has(w) || skip.has(w)) continue;
          if (!box.intersectsBox(boxAt(w, w.off))) continue;
          for (const sa of u.shapes) {
            for (const sb of w.shapes) {
              const base = allowed(sa, sb, w);
              if (overlap(sa, o, sb, w.off) - base >= 2 + 0.06 * base) return false;
            }
          }
        }
      }
    }
    return true;
  };

  /**
   * [u]'yu [to]'ya yerleştirir; yolunu kesen öndekileri ileri iter. Olmazsa
   * her şeyi eski hâline getirip false döner.
   */
  const place = (u: Unit, from: Off, via: Off | null, dir: number, s: number, fronts: Unit[]): boolean => {
    const axis = DIRS[dir].findIndex((v) => v !== 0);
    const sign = DIRS[dir][axis];
    const saved = new Map(fronts.map((p) => [p, [...p.off] as Off]));
    const start = via ?? from;
    for (const p of fronts) stamp(p, -1);
    u.off = add(start, dir, s);
    stamp(u, 1);

    // Arkadan öne: her öndeki, arkasındakilerin yeni yerinden bir hücre
    // uzak durana kadar ilerler.
    const along = (p: Unit) => boxAt(p, p.off).min.getComponent(axis) * sign;
    const order = [...fronts].sort((a, b) => along(a) - along(b));
    const pushed: Unit[] = [];
    let ok = true;
    for (let n = 0; n < order.length; n++) {
      const p = order[n];
      if (clear(p, p.off)) {
        stamp(p, 1);
        continue;
      }
      const free = reachOf(p, p.off, dir, new Set([...order.slice(n + 1), u, ...pushed]));
      const most = Math.min(travelMax, Math.floor((free - margin) / px));
      let e = CELL;
      while (e <= most && !clear(p, add(p.off, dir, e))) e += CELL;
      if (e > most) {
        for (const q of order.slice(n)) stamp(q, 1);
        ok = false;
        break;
      }
      p.off = add(p.off, dir, e);
      stamp(p, 1);
      pushed.push(p);
    }

    // Önden arkaya oynarlar: en öndeki önce kalkar. Her itilenin yolu,
    // önündekilerin yeni, arkasındakilerin (u dahil) eski yerine göre denenir.
    const moving = [...pushed].reverse();
    for (let n = 0; ok && n < moving.length; n++) {
      const p = moving[n];
      const behind = [...moving.slice(n + 1), u];
      const now = behind.map((q) => q.off);
      behind.forEach((q) => (q.off = q === u ? from : saved.get(q)!));
      const to = p.off;
      const length = Math.max(...[0, 1, 2].map((c) => Math.abs(to[c] - saved.get(p)![c])));
      p.off = saved.get(p)!;
      ok = reachOf(p, p.off, dir, new Set()) >= length * px + margin * 0.5 && fits(p, [p.off, to], new Set());
      p.off = to;
      behind.forEach((q, i) => (q.off = now[i]));
    }
    // u'nun yolu, ileri itilenlerin yeni yerinden geçmesin.
    if (ok) ok = reachOf(u, start, dir, new Set()) >= s * px + margin * 0.5;
    if (ok) ok = fits(u, via ? [from, via, u.off] : [from, u.off], new Set());
    if (!ok) {
      stamp(u, -1);
      for (const p of fronts) {
        stamp(p, -1);
        p.off = saved.get(p)!;
        stamp(p, 1);
      }
      u.off = from;
      return false;
    }
    for (const p of moving) {
      const step: Step = { unit: p, from: saved.get(p)!, via: null, to: [...p.off] };
      steps.push(step);
    }
    u.dir = dir;
    steps.push({ unit: u, from, via, to: [...u.off] });
    return true;
  };

  /** [u]'yu söker: önce doğrudan, olmazsa kısa bir adımın ardından. */
  const move = (
    u: Unit,
    ref: THREE.Vector3,
    half: THREE.Vector3,
    axisHint: number | null,
    minMove: number,
  ): boolean => {
    stamp(u, -1);
    const from: Off = [...u.off];
    const rel = boxAt(u, from).getCenter(new THREE.Vector3()).sub(ref).divide(half);
    const pref = rel.length() < 0.25 ? null : rel.normalize();
    const bend = (dir: number) => {
      const d = DIRS[dir];
      if (pref) return 1 - (d[0] * pref.x + d[1] * pref.y + d[2] * pref.z);
      return axisHint === null || d[axisHint] !== 0 ? 0 : 1;
    };
    type Option = { via: Off | null; dir: number; s: number; cost: number; fronts: Unit[] };
    const options: Option[] = [];
    const consider = (start: Off, via: Off | null, dir: number, extra: number) => {
      const fronts = frontsOf(u, dir);
      const s = travel(u, start, dir, minMove, fronts);
      if (s === null) return;
      // Aşağı ancak başka yol yoksa: zemine doğru açılan parça okunmuyor.
      const down = dir === DOWN ? 1.5 : 0;
      options.push({ via, dir, s, fronts, cost: (s * px) / longest + 0.6 * bend(dir) + down + extra });
    };
    for (let dir = 0; dir < 6; dir++) consider(from, null, dir, 0);
    if (options.every((o) => o.dir === DOWN)) {
      for (let first = 0; first < 6; first++) {
        if (first === DOWN) continue;
        const free = reachOf(u, from, first, new Set(), lifts[lifts.length - 1] * px + margin);
        const axis = DIRS[first].findIndex((v) => v !== 0);
        for (const h of lifts) {
          if (h * px > free - margin) break;
          const via = add(from, first, h);
          if (!inside(u, via)) break;
          for (let dir = 0; dir < 6; dir++) {
            if (DIRS[dir][axis] !== 0) continue;
            consider(via, via, dir, 0.3 + (h * px) / longest);
          }
        }
      }
    }
    options.sort((a, b) => a.cost - b.cost);
    for (const o of options) {
      if (place(u, from, o.via, o.dir, o.s, o.fronts)) return true;
    }
    stamp(u, 1);
    return false;
  };

  /**
   * Çıkamayan parçalardan, kutusu başka bir çıkamayanın kutusunun içinde
   * kalanları onunla birleştirir: tekerlek, içindeki disk, kaliper ve göbekle
   * birlikte çıkar, sonra kendi aralarında açılırlar. Her parça bir kez
   * denenir. Yeni bir küme kurulduysa true.
   */
  const clustered = new Set<Shape>();
  const cluster = (rest: Unit[]): boolean => {
    const volume = (b: THREE.Box3) => {
      const s = b.getSize(new THREE.Vector3());
      return s.x * s.y * s.z;
    };
    const singles = rest.filter((u) => u.shapes.length === 1 && !clustered.has(u.shapes[0]));
    singles.sort((a, b) => volume(boxAt(b, b.off)) - volume(boxAt(a, a.off)));
    let formed = false;
    for (const host of singles) {
      if (clustered.has(host.shapes[0])) continue;
      const box = boxAt(host, host.off).expandByScalar(grid.cell * 2);
      const inner = singles.filter((u) => {
        if (u === host || clustered.has(u.shapes[0])) return false;
        const b = boxAt(u, u.off);
        const common = b.clone().intersect(box);
        return (
          !common.isEmpty() && volume(common) >= 0.7 * volume(b) && volume(b) < volume(boxAt(host, host.off))
        );
      });
      clustered.add(host.shapes[0]);
      if (inner.length === 0) continue;
      for (const u of inner) clustered.add(u.shapes[0]);
      const members = [host, ...inner];
      for (const u of members) {
        stamp(u, -1);
        gone.add(u);
        rest.splice(rest.indexOf(u), 1);
      }
      const unit = unitOf(
        members.map((u) => u.shapes[0]),
        `~${host.shapes[0].id}`,
        host.off,
      );
      all.push(unit);
      stamp(unit, 1);
      rest.push(unit);
      formed = true;
    }
    return formed;
  };

  // Çıkamayan parça, yollarından birine değen bir hareket olmadıkça yeniden
  // denenmez. Yolları üç eksen boyunca uzanır; kısa bir ilk adım kadar
  // yana da kayabilir.
  const failed = new Map<Unit, number>();
  const liftMax = lifts[lifts.length - 1] * px;
  const changedNear = (u: Unit): boolean => {
    const since = failed.get(u);
    if (since === undefined) return true;
    const box = boxAt(u, u.off).expandByScalar(liftMax + margin);
    for (let k = since; k < steps.length; k++) {
      const c = sweep(steps[k]);
      let axes = 0;
      for (let a = 0; a < 3; a++) {
        if (
          c.max.getComponent(a) >= box.min.getComponent(a) &&
          c.min.getComponent(a) <= box.max.getComponent(a)
        )
          axes++;
      }
      if (axes >= 2) return true;
    }
    return false;
  };

  /** Dıştan içe sırayla söker; bir turda hiçbir şey çıkamazsa durur. */
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
      const r = boxAt(u, u.off).getCenter(new THREE.Vector3()).sub(ref(u)).divide(half);
      return Math.max(Math.abs(r.x), Math.abs(r.y), Math.abs(r.z));
    };
    const moved: Unit[] = [];
    for (;;) {
      rest.sort((a, b) => outer(b) - outer(a));
      const next: Unit[] = [];
      for (const u of rest) {
        if (!changedNear(u)) next.push(u);
        else if (move(u, ref(u), half, axisHint, minMove)) moved.push(u);
        else {
          failed.set(u, steps.length);
          next.push(u);
        }
      }
      const any = next.length < rest.length;
      rest = next;
      if (any) continue;
      // Bütün olarak çıkamayan grupları üyelerine böl.
      const stuck = dissolve ? rest.filter((u) => u.group !== null) : [];
      if (stuck.length === 0) {
        if (dissolve && cluster(rest)) continue;
        break;
      }
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
    return moved;
  };

  const minMove = Math.max(CELL, Math.round((longest * 0.04) / px));
  const moved = peel(pending, () => anchorCenter, anchorHalf, null, minMove, true);

  // Bütün olarak çıkan grupların üyeleri grubun içinde açılır.
  for (const g of moved.filter((u) => u.group !== null)) {
    stamp(g, -1);
    gone.add(g);
    const parts = g.shapes.map((s) => {
      const single = unitOf([s], null, g.off);
      single.dir = g.dir;
      all.push(single);
      stamp(single, 1);
      return single;
    });
    const box = boxAt(g, g.off);
    const size = box.getSize(new THREE.Vector3());
    const thin = size.x <= size.z ? 0 : 2;
    const center = box.getCenter(new THREE.Vector3());
    const half = size
      .clone()
      .multiplyScalar(0.5)
      .max(new THREE.Vector3(px, px, px));
    const spread = Math.max(CELL, Math.round((size.length() * 0.08) / px));
    peel(parts, () => center, half, thin, spread, false);
  }

  // İtilen parçanın ayrı hareketi, aradaki hareketlerden hiçbiri yoluna
  // değmiyorsa önceki hareketine eklenir: iki kez durup kalkmasın.
  const same = (a: Off, b: Off) => a[0] === b[0] && a[1] === b[1] && a[2] === b[2];
  const heading = (a: Off, b: Off) =>
    DIRS.findIndex((d) => [0, 1, 2].every((c) => Math.sign(b[c] - a[c]) === d[c]));
  for (let k = 1; k < steps.length; k++) {
    const t = steps[k];
    if (t.via) continue;
    const box = sweep(t);
    for (let q = k - 1; q >= 0; q--) {
      const e = steps[q];
      if (e.unit === t.unit) {
        const last = e.via ?? e.from;
        if (same(e.to, t.from) && heading(last, e.to) === heading(t.from, t.to)) {
          e.to = t.to;
          steps.splice(k, 1);
          k--;
        }
        break;
      }
      if (sweep(e).intersectsBox(box)) break;
    }
  }

  // Zamanlama: yolu bir öncekinin süpürdüğü alana değen hareket onun
  // bitmesini bekler.
  const timed = steps.map((step) => ({ step, box: sweep(step), start: 0, end: 1 }));
  timed.forEach((t, i) => {
    for (let k = 0; k < i; k++) {
      if (timed[k].box.intersectsBox(t.box)) t.start = Math.max(t.start, timed[k].end);
    }
    t.end = t.start + 1;
  });
  const layers = Math.max(1, ...timed.map((t) => t.end));
  const toVector = (o: Off) => new THREE.Vector3(o[0] * px, o[1] * px, o[2] * px);
  for (const t of timed) {
    const { unit, from, via, to } = t.step;
    const points = [toVector(from), ...(via ? [toVector(via)] : []), toVector(to)];
    for (const s of unit.shapes) {
      const stage = stages.get(s.id)!;
      stage.moves.push({ start: t.start / layers, end: t.end / layers, points });
    }
  }
  for (const stage of stages.values()) {
    stage.moves.sort((a, b) => a.start - b.start);
    const last = stage.moves[stage.moves.length - 1];
    if (last) stage.offset.copy(last.points[last.points.length - 1]);
  }
  return { stages, layers };
}

/** En büyük üyesi grubun kutusunun büyük kısmını kaplıyorsa grup bir arada duruyor. */
function compact(list: Shape[]): boolean {
  const all = list.reduce((a, s) => a.union(s.box), new THREE.Box3());
  const diag = (b: THREE.Box3) => b.getSize(new THREE.Vector3()).length();
  return Math.max(...list.map((s) => diag(s.box))) >= 0.6 * diag(all);
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
