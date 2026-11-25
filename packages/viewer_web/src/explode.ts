import * as THREE from "three";

/**
 * Parçalara ayırma planı.
 *
 * En büyük parça (kasa, gövde, kadro) yerinde kalır; diğer her parça
 * modelin merkezinden dışarı doğru, kendi boyuyla orantılı bir mesafe gider:
 * küçük parça az, büyük parça çok. Böylece açılmış model dengeli görünür ve
 * büyük parçalar komşularından kurtulur.
 *
 * - Yön: parçanın merkezinin modelin merkezine göre durduğu yan (gövdenin
 *   yarı boyuna bölünerek); zayıf bileşenler atılır, parça çoğunlukla bir
 *   eksen boyunca açılır. Merkeze çok yakın duran parça yukarı çıkar.
 * - Takımlar: montaj ağacında bir arada duran grup (bisiklet tekerleği) ve
 *   kutusu başka bir parçanın kutusunun içinde kalan parçalar (jant içindeki
 *   disk, kaliper, göbek) takımlarıyla birlikte dışarı çıkar, sonra takımın
 *   en ince ekseni (aks) boyunca içten dışa sıralanır.
 * - Açılmış hâlde hiçbir parça başka bir parçaya değmez: değen iki parçadan
 *   biri kendi yönünde biraz daha ileri itilir, değme kalmayana kadar. Aynı
 *   yöne gidenlerden dıştaki itilir (sıra bozulmasın), ayrı yönlere
 *   gidenlerden küçük olan. Hiçbir parça zeminin altına inmez.
 *
 * Animasyon sırasında parçalar birbirinin içinden geçebilir; dıştakiler önce
 * kalkar.
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

/** Birlikte dışarı çıkan parçalar; tek parça da bir takımdır. */
interface Team {
  members: Shape[];
  box: THREE.Box3;
}

/**
 * Planı kurar. [groups]: düğüm → montaj grubu (`groupNodes`).
 */
export function planExplode(grid: Grid, shapes: Shape[], groups: Map<string, string>): Plan {
  const stages = new Map<string, Stage>();
  for (const s of shapes) stages.set(s.id, { offset: new THREE.Vector3(), moves: [] });
  if (shapes.length < 2) return { stages, layers: 0 };

  const size = grid.box.getSize(new THREE.Vector3());
  const longest = Math.max(size.x, size.y, size.z);
  const ground = grid.box.min.y;

  // Sabit parça: hem yüzeyi geniş hem kutusu büyük olan. Kasa, gövde ya da
  // kadro; bisiklette dişli lastik değil, kadro.
  const weight = (s: Shape) => s.fine.i.length * Math.cbrt(volume(s.box));
  const anchor = shapes.reduce((a, b) => (weight(b) > weight(a) ? b : a));
  const center = anchor.box.getCenter(new THREE.Vector3());
  const halfOf = (box: THREE.Box3) =>
    box
      .getSize(new THREE.Vector3())
      .multiplyScalar(0.5)
      .max(new THREE.Vector3(1, 1, 1).multiplyScalar(longest * 0.05));
  const half = halfOf(anchor.box);
  // Kablo gibi ince uzun parçalar (modelin bir ucundan öbürüne uzanan,
  // yüzeyi boyuna göre çok küçük) kadroyla birlikte yerinde kalır; açılınca
  // havada asılı çizgiler gibi okunuyorlardı.
  const wires = shapes.filter((s) => {
    if (s === anchor) return false;
    const across = diagonal(s.box) / grid.fine;
    const cells = s.fine.i.length;
    return diagonal(s.box) >= 0.3 * longest && cells < 0.045 * across * across && cells > 3 * across;
  });
  const fixed = [anchor, ...wires];
  const rest = shapes.filter((s) => !fixed.includes(s));

  /**
   * Bir parçanın uzaklaşma mesafesi: çoğunlukla kendi boyu, en çok da
   * gittiği yöndeki kalınlığı (kapı az, kule çok); merkezden uzaklığın payı
   * sınırlı, uçtaki parçalar savrulmasın.
   */
  const reach = (box: THREE.Box3, dir: THREE.Vector3, along: number) => {
    const extent = box.getSize(new THREE.Vector3());
    const thick = Math.abs(extent.x * dir.x) + Math.abs(extent.y * dir.y) + Math.abs(extent.z * dir.z);
    return longest * 0.04 + 0.7 * thick + 0.2 * diagonal(box) + Math.min(longest * 0.05, 0.1 * along);
  };

  /**
   * Modelin merkezinden dışarı yön. Gövdenin dışına taşan ya da dış yüzünde
   * duran parça (kapı, kanat, tekerlek) o eksen boyunca açılır: zayıf
   * bileşenler atılır. Gövdenin içindeki parça (motor, koltuk) yukarı ve
   * biraz dışarı çıkar, yelpaze gibi açılır. Zemine doğru gidilmez.
   */
  const outward = (box: THREE.Box3) => {
    const rel = box.getCenter(new THREE.Vector3()).sub(center).divide(half);
    // Gövdenin kutusunun dışına kendi boyunun dörtte birinden fazla taşan eksen.
    const extent = box.getSize(new THREE.Vector3());
    let out = -1;
    let most = 0.25;
    for (let a = 0; a < 3; a++) {
      if (a === 1 && rel.y < 0) continue;
      const over =
        Math.max(
          box.max.getComponent(a) - anchor.box.max.getComponent(a),
          anchor.box.min.getComponent(a) - box.min.getComponent(a),
        ) / Math.max(extent.getComponent(a), 1e-6);
      if (over > most) {
        most = over;
        out = a;
      }
    }
    if (rel.y < 0) rel.y = 0;
    const top = Math.max(Math.abs(rel.x), Math.abs(rel.y), Math.abs(rel.z));
    if (out < 0 && top < INSIDE) {
      return new THREE.Vector3(rel.x * FAN, rel.y + 1, rel.z * FAN).normalize();
    }
    if (out >= 0 && Math.abs(rel.getComponent(out)) < 0.4 * top) {
      return new THREE.Vector3().setComponent(out, Math.sign(rel.getComponent(out)) || 1);
    }
    if (top < 0.2) return new THREE.Vector3(0, 1, 0);
    for (const axis of ["x", "y", "z"] as const) if (Math.abs(rel[axis]) < 0.4 * top) rel[axis] = 0;
    return rel.normalize();
  };

  // Takımlar: montaj ağacında bir arada duran küçük gruplar (tekerlek).
  const teams: Team[] = [];
  const taken = new Set<Shape>();
  const byGroup = new Map<string, Shape[]>();
  for (const s of rest) {
    const g = groups.get(s.id) ?? s.id;
    if (!byGroup.has(g)) byGroup.set(g, []);
    byGroup.get(g)!.push(s);
  }
  const anchorGroup = groups.get(anchor.id) ?? anchor.id;
  // Büyük gruplarda (iç döşeme, kule) en büyük üye ev sahibidir. Onun
  // kutusunun içinde kalan üye (kabindeki koltuk) ev sahibinin merkezinden
  // dışarı açılır; ona değip dışarı taşan üye (kuledeki top) ev sahibiyle
  // birlikte gider, sonra kendi yönünde biraz kayar.
  // Ev sahibine bağlı parçalar, ev sahibi önce gelecek sırayla.
  const dependents: { shape: Shape; host: Shape; inside: boolean }[] = [];
  for (const [g, list] of byGroup) {
    if (g === anchorGroup || list.length < 2) continue;
    if (compact(list) && diagonal(union(list)) < 0.6 * diagonal(grid.box)) {
      teams.push({ members: list, box: union(list) });
      for (const s of list) taken.add(s);
      continue;
    }
    // Her üyenin ev sahibi: onu içine alan en büyük üye; yoksa ona değen ya
    // da kutusu hemen yanında duran en büyük üye (sağ palet sağdaki
    // tekerleklerin, kule toplarla nişangâhların).
    const sorted = [...list].sort((a, b) => weight(b) - weight(a));
    sorted.forEach((s, n) => {
      const heavier = sorted.slice(0, n);
      const container = heavier.find((host) => {
        const common = s.box.clone().intersect(host.box);
        return !common.isEmpty() && volume(common) >= 0.7 * volume(s.box);
      });
      const near = container
        ? undefined
        : heavier.find(
            (host) =>
              host.box
                .clone()
                .expandByScalar(longest * 0.02)
                .intersectsBox(s.box) &&
              (touches(s, host) || volume(host.box) > 4 * volume(s.box)),
          );
      const host = container ?? near;
      if (!host) return;
      dependents.push({ shape: s, host, inside: container !== undefined });
      taken.add(s);
    });
  }
  // Sonra kutusu başka bir küçük parçanın kutusunun içinde kalanlar: en
  // büyük kap önce, içindekiler onunla (jant, disk, kaliper, göbek).
  const loose = rest.filter((s) => !taken.has(s)).sort((a, b) => volume(b.box) - volume(a.box));
  for (const host of loose) {
    if (taken.has(host)) continue;
    taken.add(host);
    // Yalnız küçük ve yassı olmayan kap (tekerlek); kanat gibi yassı ya da
    // gövdeyi saran büyük parçanın kutusu komşularını da içine alır.
    const extent = host.box.getSize(new THREE.Vector3());
    const flat = Math.min(extent.x, extent.y, extent.z) < 0.25 * Math.max(extent.x, extent.y, extent.z);
    if (flat || diagonal(host.box) >= 0.3 * diagonal(grid.box)) {
      teams.push({ members: [host], box: host.box.clone() });
      continue;
    }
    const box = host.box.clone().expandByScalar(grid.fine * 2);
    const inner = loose.filter((s) => {
      if (taken.has(s) || volume(s.box) >= volume(host.box)) return false;
      const common = s.box.clone().intersect(box);
      return !common.isEmpty() && volume(common) >= 0.85 * volume(s.box);
    });
    for (const s of inner) taken.add(s);
    teams.push({ members: [host, ...inner], box: union([host, ...inner]) });
  }

  // Her parçanın açılmış yeri ve gittiği yön (itmek için).
  interface Placed {
    shape: Shape;
    /** Önce gittiği ara yer (takımla ya da ev sahibiyle birlikte). */
    team: THREE.Vector3;
    offset: THREE.Vector3;
    dir: THREE.Vector3;
    /** Dıştan içe sıra: merkezden uzaklığı. */
    outer: number;
  }
  const placed: Placed[] = [];
  /**
   * [s]'nin [host] kutusunun merkezinden kendi yanına, boyu kadar kayması;
   * motorun çevresindeki parçalar yelpaze gibi açılır. [away] ev sahibinin
   * gittiği yön: merkezdeki parça o yönde açılır, geri, modelin içine doğru
   * kayılmaz.
   */
  const slide = (s: Shape, host: THREE.Box3, away: THREE.Vector3, axial = false) => {
    const rel = s.box
      .getCenter(new THREE.Vector3())
      .sub(host.getCenter(new THREE.Vector3()))
      .divide(halfOf(host));
    if (rel.y < 0) rel.y = 0;
    if (axial) {
      // Yalnız en güçlü eksen: koltuk tam yana, panel tam öne.
      const a = [0, 1, 2].reduce((b, c) =>
        Math.abs(rel.getComponent(c)) > Math.abs(rel.getComponent(b)) ? c : b,
      );
      const v = rel.getComponent(a);
      rel.set(0, 0, 0);
      if (Math.abs(v) > 0.05) rel.setComponent(a, Math.sign(v));
    }
    const toward = away.clone().normalize();
    let dir = rel.length() < (axial ? 0.25 : 0.15) ? toward : rel.normalize();
    if (dir.dot(toward) < -0.1) dir = toward;
    const extent = s.box.getSize(new THREE.Vector3());
    const thick = Math.abs(extent.x * dir.x) + Math.abs(extent.y * dir.y) + Math.abs(extent.z * dir.z);
    return { dir, move: dir.clone().multiplyScalar(longest * 0.03 + 0.25 * thick + 0.1 * diagonal(s.box)) };
  };
  const outerOf = (box: THREE.Box3) => box.getCenter(new THREE.Vector3()).sub(center).divide(half).length();
  for (const team of teams) {
    const dir = outward(team.box);
    const from = team.box.getCenter(new THREE.Vector3()).sub(center);
    const move = dir.clone().multiplyScalar(reach(team.box, dir, Math.max(0, from.dot(dir))));
    const outer = outerOf(team.box);
    if (team.members.length === 1) {
      placed.push({ shape: team.members[0], team: move, offset: move.clone(), dir, outer });
      continue;
    }
    // Merkezleri dağınık takım (motor, aktarma) birlikte çıkar, sonra her
    // üye takımın merkezinden kendi yanına kayar.
    const middle = team.box.getCenter(new THREE.Vector3());
    const coaxial = team.members.every(
      (s) => s.box.getCenter(new THREE.Vector3()).distanceTo(middle) < 0.15 * diagonal(team.box),
    );
    if (!coaxial) {
      for (const s of team.members) {
        const { dir: own, move: shift } = slide(s, team.box, dir);
        placed.push({ shape: s, team: move, offset: move.clone().add(shift), dir: own, outer });
      }
      continue;
    }
    // Takım içinde: aks boyunca, içten dışa sıralı. Aks, üyelerin
    // merkezlerinin dizildiği eksen (motorun kademeleri); merkezler üst üste
    // ise en ince eksen (tekerlekte jant, disk, göbek).
    const extent = team.box.getSize(new THREE.Vector3());
    const spreadOf = (a: number) => {
      const values = team.members.map((m) => m.box.getCenter(new THREE.Vector3()).getComponent(a));
      return Math.max(...values) - Math.min(...values);
    };
    const spreads = [0, 1, 2].map(spreadOf);
    const widest = spreads.indexOf(Math.max(...spreads));
    const axis =
      spreads[widest] > 0.05 * diagonal(team.box)
        ? widest
        : extent.x <= extent.y && extent.x <= extent.z
          ? 0
          : extent.z <= extent.y
            ? 2
            : 1;
    const axle = new THREE.Vector3().setComponent(axis, 1);
    let sign = Math.sign(dir.getComponent(axis)) || Math.sign(from.getComponent(axis)) || 1;
    if (axis === 1) sign = 1;
    const unit = Math.max(diagonal(team.box) * 0.02, grid.fine);
    const rank = (s: Shape) =>
      Math.round((s.box.getCenter(new THREE.Vector3()).getComponent(axis) * sign) / unit) * 1e6 +
      diagonal(s.box);
    const order = [...team.members].sort((a, b) => rank(a) - rank(b));
    let at = 0;
    const gap = longest * 0.02;
    order.forEach((s, n) => {
      const thick = s.box.getSize(new THREE.Vector3()).getComponent(axis);
      if (n > 0) {
        const before = order[n - 1].box.getSize(new THREE.Vector3()).getComponent(axis);
        at += (before + thick) / 2 + gap;
      }
      const offset = move.clone().addScaledVector(axle, sign * at);
      placed.push({ shape: s, team: move, offset, dir: offset.clone().normalize(), outer });
    });
  }
  // Büyük ev sahibinin (kabin döşemesi) içindekiler kendi başına onun
  // merkezinden dışarı açılır: koltuklar yana, tavan döşemesi yukarı.
  // Küçük ev sahibinin (motor gövdesi) içindekiler onunla çıkar, sonra
  // kayar.
  for (const { shape: s, host, inside } of dependents) {
    const parent = placed.find((p) => p.shape === host)!;
    // Gövdenin içinde, büyük bir kabuğun (kabin döşemesi) içindeki parça
    // kabukla gitmez, kendi yanına açılır: koltuklar yana, tavan döşemesi
    // yukarı, gösterge paneli öne.
    const enclosed = anchor.box.containsPoint(s.box.getCenter(new THREE.Vector3()));
    if (inside && enclosed && diagonal(host.box) >= 0.5 * diagonal(grid.box)) {
      const { dir, move } = slide(s, host.box, parent.dir, true);
      placed.push({ shape: s, team: move, offset: move.clone(), dir, outer: outerOf(s.box) });
      continue;
    }
    const base = parent.offset.clone();
    const { dir, move } = slide(s, host.box, base);
    placed.push({ shape: s, team: base, offset: base.clone().add(move), dir, outer: parent.outer });
  }

  // Zeminin altına inen parça yukarı alınır.
  const lift = (p: Placed) => {
    const bottom = p.shape.box.min.y + p.offset.y;
    if (bottom < ground) p.offset.y += ground - bottom;
  };
  placed.forEach(lift);

  // Açılmış hâlde değen parçaları ayır.
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
  /** İki parça, bir hücre payla değiyor mu. */
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
  const still = new THREE.Vector3();
  const boxOf = (p: Placed) =>
    p.shape.box
      .clone()
      .translate(p.offset)
      .expandByScalar(grid.fine * 2);
  const step = longest * 0.02;
  // Birbirine değmediği bilinen ikililer; biri itilince yeniden bakılır.
  const clean = new Set<string>();
  const key = (a: Placed, b: Placed) => `${a.shape.id}|${b.shape.id}`;
  for (let round = 0; round < 400; round++) {
    let pushed = false;
    for (let n = 0; n < placed.length; n++) {
      const a = placed[n];
      const boxA = boxOf(a);
      // Önce yerinde kalanlar (gövde, kablolar).
      let hit = false;
      for (const f of fixed) {
        if (clean.has(`${a.shape.id}|${f.id}`) || !boxA.intersectsBox(f.box)) continue;
        if (touch(a.shape, a.offset, f, still)) {
          hit = true;
          break;
        }
        clean.add(`${a.shape.id}|${f.id}`);
      }
      if (hit) {
        push(a);
        pushed = true;
        continue;
      }
      for (let m = n + 1; m < placed.length; m++) {
        const b = placed[m];
        if (clean.has(key(a, b)) || !boxA.intersectsBox(boxOf(b))) continue;
        if (a.offset.equals(b.offset) || !touch(a.shape, a.offset, b.shape, b.offset)) {
          clean.add(key(a, b));
          continue;
        }
        // Aynı yöne gidenlerden dıştaki, ayrı yönlere gidenlerden küçük olan itilir.
        let mover: Placed;
        if (a.dir.dot(b.dir) > 0.7) {
          const ca = a.shape.box.getCenter(new THREE.Vector3()).add(a.offset).dot(a.dir);
          const cb = b.shape.box.getCenter(new THREE.Vector3()).add(b.offset).dot(a.dir);
          mover = ca >= cb ? a : b;
        } else mover = volume(a.shape.box) <= volume(b.shape.box) ? a : b;
        push(mover);
        pushed = true;
        break;
      }
    }
    if (!pushed) break;
  }
  function push(p: Placed): void {
    p.offset.addScaledVector(p.dir, step);
    lift(p);
    for (const k of [...clean]) {
      const [x, y] = k.split("|");
      if (x === p.shape.id || y === p.shape.id) clean.delete(k);
    }
  }

  // Zamanlama: dıştakiler önce kalkar; takım üyeleri önce takımla gider,
  // sonra aks boyunca açılır.
  const order = [...placed].sort((a, b) => b.outer - a.outer);
  const spread = 0.45;
  order.forEach((p, n) => {
    const start = order.length > 1 ? (spread * n) / (order.length - 1) : 0;
    const points = [new THREE.Vector3()];
    if (!p.team.equals(p.offset) && p.team.lengthSq() > 0) points.push(p.team.clone());
    points.push(p.offset.clone());
    const stage = stages.get(p.shape.id)!;
    stage.offset.copy(p.offset);
    stage.moves.push({ start, end: start + (1 - spread), points });
  });
  return { stages, layers: 7 };
}

/** Bu kadar içteki (gövdenin yarı boyuna göre) parça yukarı açılır. */
const INSIDE = 0.75;
/** İçerdeki parçanın yana açılma payı. */
const FAN = 3;

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
