import * as THREE from "three";

/**
 * Bir parçayı aralarında boşluk olan kısımlarına böler. Modelde sağ ve sol
 * amortisör, iki ön disk ya da iki yandaki kapı döşemesi çoğu zaman tek bir
 * düğüm; parçalara ayırırken ikisi aynı yöne giderse biri motorun içinden
 * geçer. Bölünen her kısım düğümün altında ayrı bir gruba taşınır ve kendi
 * yönüne açılır; seçme, parlama ve adı parçanın kendisinde kalır.
 *
 * Bir eksen boyunca hiçbir üçgenin uzanmadığı, aşağı yukarı [gap]
 * genişliğinde bir boşluk varsa parça oradan ikiye ayrılır; her yarı yeniden
 * denenir.
 * Bölünmezse null döner.
 */
export function splitPieces(node: THREE.Object3D, gap: number): THREE.Object3D[] | null {
  node.updateWorldMatrix(true, true);
  const toNode = node.matrixWorld.clone().invert();
  const meshes: THREE.Mesh[] = [];
  node.traverse((child) => {
    if (child instanceof THREE.Mesh && child.geometry.getAttribute("position")) meshes.push(child);
  });

  // Üçgenlerin kutuları, düğümün kendi koordinatlarında.
  const total = meshes.reduce((n, mesh) => {
    const index = mesh.geometry.getIndex();
    return n + Math.floor((index ? index.count : mesh.geometry.getAttribute("position").count) / 3);
  }, 0);
  const owner = new Uint16Array(total);
  const triangle = new Uint32Array(total);
  const lo = new Float32Array(3 * total);
  const hi = new Float32Array(3 * total);
  const v = new THREE.Vector3();
  const matrix = new THREE.Matrix4();
  let n = 0;
  meshes.forEach((mesh, m) => {
    const position = mesh.geometry.getAttribute("position");
    const index = mesh.geometry.getIndex();
    matrix.multiplyMatrices(toNode, mesh.matrixWorld);
    const count = Math.floor((index ? index.count : position.count) / 3);
    for (let t = 0; t < count; t++, n++) {
      owner[n] = m;
      triangle[n] = t;
      for (let k = 0; k < 3; k++) {
        v.fromBufferAttribute(position, index ? index.getX(3 * t + k) : 3 * t + k).applyMatrix4(matrix);
        for (let a = 0; a < 3; a++) {
          const c = v.getComponent(a);
          if (k === 0 || c < lo[3 * n + a]) lo[3 * n + a] = c;
          if (k === 0 || c > hi[3 * n + a]) hi[3 * n + a] = c;
        }
      }
    }
  });

  // Boşluk aramak için eksen [gap]'in dörtte biri genişliğinde dilimlere
  // bölünür; hiçbir üçgenin değmediği art arda dilimler boşluktur.
  const split = (list: number[], depth: number): number[][] => {
    if (depth > 3 || list.length < 2) return [list];
    let best: { axis: number; at: number; width: number } | null = null;
    for (let axis = 0; axis < 3; axis++) {
      let min = Infinity;
      let max = -Infinity;
      for (const t of list) {
        min = Math.min(min, lo[3 * t + axis]);
        max = Math.max(max, hi[3 * t + axis]);
      }
      if (max - min < 2 * gap) continue;
      const slice = gap / 4;
      const covered = new Uint8Array(Math.ceil((max - min) / slice) + 1);
      for (const t of list) {
        const a = Math.floor((lo[3 * t + axis] - min) / slice);
        const b = Math.floor((hi[3 * t + axis] - min) / slice);
        for (let k = a; k <= b; k++) covered[k] = 1;
      }
      let run = 0;
      for (let k = 0; k < covered.length; k++) {
        if (covered[k]) {
          run = 0;
          continue;
        }
        run++;
        // Boş dilimler, iki yanındaki dolu dilimlerle birlikte en az [gap].
        const width = (run - 1) * slice;
        if (width >= gap && (!best || width > best.width)) {
          best = { axis, at: min + (k - run / 2 + 0.5) * slice, width };
        }
      }
    }
    if (!best) return [list];
    const { axis, at } = best;
    const below = list.filter((t) => hi[3 * t + axis] < at);
    const above = list.filter((t) => hi[3 * t + axis] >= at);
    return [...split(below, depth + 1), ...split(above, depth + 1)];
  };
  const pieces = split(
    Array.from({ length: total }, (_, i) => i),
    0,
  );
  if (pieces.length < 2) return null;

  const groups = pieces.map((_, k) => {
    const group = new THREE.Group();
    group.name = `${node.name}#${k}`;
    node.add(group);
    return group;
  });
  node.updateWorldMatrix(false, true);
  meshes.forEach((mesh, m) => {
    const parts = pieces
      .map((list, k) => ({ k, tris: list.filter((t) => owner[t] === m).map((t) => triangle[t]) }))
      .filter((p) => p.tris.length > 0);
    if (parts.length === 1) {
      groups[parts[0].k].attach(mesh);
      return;
    }
    for (const { k, tris } of parts) {
      const piece = new THREE.Mesh(subset(mesh.geometry, tris), mesh.material);
      piece.name = mesh.name;
      piece.castShadow = mesh.castShadow;
      piece.receiveShadow = mesh.receiveShadow;
      // Grup düğümle aynı yerde: kısmın konumu düğüme göre konumudur.
      matrix
        .multiplyMatrices(toNode, mesh.matrixWorld)
        .decompose(piece.position, piece.quaternion, piece.scale);
      groups[k].add(piece);
    }
    mesh.removeFromParent();
  });
  return groups;
}

/** [geometry]'nin yalnız [tris] üçgenlerini çizen kopyası; köşe verisi paylaşılır. */
function subset(geometry: THREE.BufferGeometry, tris: number[]): THREE.BufferGeometry {
  const out = new THREE.BufferGeometry();
  for (const [name, attribute] of Object.entries(geometry.attributes)) out.setAttribute(name, attribute);
  const index = geometry.getIndex();
  const at = (n: number) => (index ? index.getX(n) : n);
  // Malzeme grupları korunur: üçgenler gruplarına göre sıralanır.
  const groupOf = (t: number) =>
    geometry.groups.findIndex((g) => 3 * t >= g.start && 3 * t < g.start + g.count);
  const sorted = geometry.groups.length > 0 ? [...tris].sort((a, b) => groupOf(a) - groupOf(b)) : tris;
  const ids: number[] = [];
  let current = -2;
  let start = 0;
  for (const t of sorted) {
    if (geometry.groups.length > 0) {
      const g = groupOf(t);
      if (g !== current) {
        if (current >= 0) out.addGroup(start, ids.length - start, geometry.groups[current].materialIndex);
        current = g;
        start = ids.length;
      }
    }
    ids.push(at(3 * t), at(3 * t + 1), at(3 * t + 2));
  }
  if (current >= 0) out.addGroup(start, ids.length - start, geometry.groups[current].materialIndex);
  out.setIndex(ids);
  return out;
}
