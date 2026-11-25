import * as THREE from "three";

/**
 * Geliştirirken parçalara ayırmayı denetler: parçaların yüzeyini ince
 * hücrelere çevirir, ayırmanın birkaç anında hangi parçaların birbirine
 * girdiğini sayar. Tarayıcı konsolunda `explodeReport()` ile çalışır.
 *
 * Yalnız toplu hâle göre yeni olan değmeler sayılır: modelde zaten birbirine
 * dayanan iki parça (koltuk ve halı) yerinde kaldıkça çakışma sayılmaz.
 */

export interface CheckedPart {
  id: string;
  node: THREE.Object3D;
  home: THREE.Vector3;
  away: THREE.Vector3;
  /** [value] ilerlemesinde parçanın yer değiştirmesi. */
  offsetAt(value: number): THREE.Vector3;
}

export interface Clash {
  a: string;
  b: string;
  /** Ayırmanın hangi anında (0-1) ve kaç ortak hücreyle. */
  at: number;
  cells: number;
}

const key = (i: number, j: number, k: number) => (i + 2048) * 4096 * 4096 + (j + 2048) * 4096 + (k + 2048);

export function explodeReport(parts: CheckedPart[], level: THREE.Object3D, moments = [0.2, 0.4, 0.6, 0.8, 1]): Clash[] {
  // Ölçüm toplu hâlde yapılır.
  const saved = parts.map((p) => p.node.position.clone());
  for (const p of parts) p.node.position.copy(p.home);
  level.updateWorldMatrix(true, true);
  const toLocal = level.matrixWorld.clone().invert();
  const box = new THREE.Box3();
  for (const p of parts) box.union(new THREE.Box3().setFromObject(p.node).applyMatrix4(toLocal));
  const size = box.getSize(new THREE.Vector3());
  const cell = Math.max(size.x, size.y, size.z) / 220;

  const cells = parts.map((p) => surface(p.node, toLocal, cell));
  parts.forEach((p, i) => p.node.position.copy(saved[i]));

  const count = (value: number) => {
    const owners = new Map<number, number>();
    const pairs = new Map<string, number>();
    parts.forEach((p, n) => {
      const o = p.offsetAt(value).divideScalar(cell);
      const [oi, oj, ok] = [Math.round(o.x), Math.round(o.y), Math.round(o.z)];
      const list = cells[n];
      for (let c = 0; c < list.length; c += 3) {
        const k = key(list[c] + oi, list[c + 1] + oj, list[c + 2] + ok);
        const other = owners.get(k);
        if (other === undefined) owners.set(k, n);
        else if (other !== n) {
          const name = other < n ? `${other}|${n}` : `${n}|${other}`;
          pairs.set(name, (pairs.get(name) ?? 0) + 1);
        }
      }
    });
    return pairs;
  };

  const home = count(0);
  const worst = new Map<string, Clash>();
  for (const value of moments) {
    for (const [name, n] of count(value)) {
      const extra = n - (home.get(name) ?? 0);
      if (extra < 3) continue;
      const [a, b] = name.split("|").map(Number);
      const previous = worst.get(name);
      if (!previous || previous.cells < extra) {
        worst.set(name, { a: parts[a].id, b: parts[b].id, at: value, cells: extra });
      }
    }
  }
  return [...worst.values()].sort((x, y) => y.cells - x.cells);
}

/** Düğümün yüzey hücreleri: [i, j, k, i, j, k, ...]. */
function surface(node: THREE.Object3D, toLocal: THREE.Matrix4, cell: number): Int32Array {
  const seen = new Set<number>();
  const out: number[] = [];
  const a = new THREE.Vector3();
  const b = new THREE.Vector3();
  const c = new THREE.Vector3();
  const p = new THREE.Vector3();
  const ab = new THREE.Vector3();
  const ac = new THREE.Vector3();
  const matrix = new THREE.Matrix4();
  node.traverse((child) => {
    if (!(child instanceof THREE.Mesh)) return;
    const position = child.geometry.getAttribute("position");
    if (!position) return;
    matrix.multiplyMatrices(toLocal, child.matrixWorld);
    const index = child.geometry.getIndex();
    const total = index ? index.count : position.count;
    const vertex = (n: number, v: THREE.Vector3) =>
      v.fromBufferAttribute(position, index ? index.getX(n) : n).applyMatrix4(matrix);
    for (let t = 0; t + 2 < total; t += 3) {
      vertex(t, a);
      vertex(t + 1, b);
      vertex(t + 2, c);
      const edge = Math.max(a.distanceTo(b), b.distanceTo(c), c.distanceTo(a));
      const n = Math.max(1, Math.ceil(edge / (cell * 0.5)));
      ab.subVectors(b, a);
      ac.subVectors(c, a);
      for (let u = 0; u <= n; u++) {
        for (let v = 0; u + v <= n; v++) {
          p.copy(a).addScaledVector(ab, u / n).addScaledVector(ac, v / n);
          const i = Math.floor(p.x / cell);
          const j = Math.floor(p.y / cell);
          const k = Math.floor(p.z / cell);
          const id = key(i, j, k);
          if (seen.has(id)) continue;
          seen.add(id);
          out.push(i, j, k);
        }
      }
    }
  });
  return Int32Array.from(out);
}
