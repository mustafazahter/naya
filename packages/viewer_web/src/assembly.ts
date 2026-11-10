import * as THREE from "three";

/** `map/parts.json` içinden viewer'ın kullandığı kısım. */
export interface PartsMap {
  parts: { id: string; parent?: string; meshNodes?: string[] }[];
}

/**
 * Model düğümlerini montaj gruplarına ayırır: düğüm, onu listeleyen en üst
 * seviyedeki parçanın kök atasına bağlanır. Bisiklette `drive_chain` →
 * `drive`, `wheel_front_tire` → `wheel.front`.
 *
 * Haritada geçmeyen düğüm kendi başına bir grup olur.
 */
export function groupNodes(map: PartsMap | null, nodes: string[]): Map<string, string> {
  const groups = new Map<string, string>();
  if (!map) {
    for (const n of nodes) groups.set(n, n);
    return groups;
  }
  const byId = new Map(map.parts.map((p) => [p.id, p]));
  const depth = (id: string): number => {
    let d = 0;
    for (let p = byId.get(id); p?.parent; p = byId.get(p.parent)) d++;
    return d;
  };
  const root = (id: string): string => {
    let current = id;
    for (let p = byId.get(id); p?.parent; p = byId.get(p.parent)) current = p.parent;
    return current;
  };
  for (const node of nodes) {
    const owners = map.parts.filter((p) => p.meshNodes?.includes(node));
    if (owners.length === 0) {
      groups.set(node, node);
      continue;
    }
    owners.sort((a, b) => depth(a.id) - depth(b.id));
    groups.set(node, root(owners[0].id));
  }
  return groups;
}

interface Placed {
  id: string;
  /** Parçanın merkezi, modelin yerel koordinatlarında. */
  center: THREE.Vector3;
}

/**
 * Parçalara ayırırken her parçanın kayacağı yer (yerel koordinatlarda).
 *
 * İki adım: önce her grup modelin merkezinden dışarı kayar, sonra grubun
 * içindeki parçalar grubun merkezinden açılır. Tekerlek gibi iç içe
 * parçaların merkezleri aynı olduğunda açılma yönü grubun en ince ekseni
 * (tekerlekte aks) olur ve parçalar o eksen boyunca sıralanır.
 */
export function explodeOffsets(
  parts: Placed[],
  groups: Map<string, string>,
  modelCenter: THREE.Vector3,
  modelSize: number,
  boxes: Map<string, THREE.Box3>,
): Map<string, THREE.Vector3> {
  const members = new Map<string, Placed[]>();
  for (const part of parts) {
    const group = groups.get(part.id) ?? part.id;
    if (!members.has(group)) members.set(group, []);
    members.get(group)!.push(part);
  }

  const offsets = new Map<string, THREE.Vector3>();
  for (const list of members.values()) {
    const groupBox = new THREE.Box3();
    for (const p of list) groupBox.union(boxes.get(p.id)!);
    const groupCenter = groupBox.getCenter(new THREE.Vector3());
    const groupSize = groupBox.getSize(new THREE.Vector3());

    const out = groupCenter.clone().sub(modelCenter);
    if (out.lengthSq() < 1e-8) out.set(0, 1, 0);
    const groupMove = out.clone().normalize().multiplyScalar(out.length() * 0.55 + modelSize * 0.04);

    const thin = thinnestAxis(groupSize);
    const span = groupSize.length();
    list.forEach((part, i) => {
      const inside = part.center.clone().sub(groupCenter);
      let move: THREE.Vector3;
      if (list.length === 1) {
        move = new THREE.Vector3();
      } else if (inside.length() < span * 0.12) {
        // İç içe parça: ince eksen boyunca sıraya diz.
        move = thin.clone().multiplyScalar((i - (list.length - 1) / 2) * span * 0.18);
      } else {
        move = inside.clone().normalize().multiplyScalar(inside.length() * 0.5 + span * 0.05);
      }
      offsets.set(part.id, groupMove.clone().add(move));
    });
  }
  return offsets;
}

function thinnestAxis(size: THREE.Vector3): THREE.Vector3 {
  if (size.x <= size.y && size.x <= size.z) return new THREE.Vector3(1, 0, 0);
  if (size.y <= size.z) return new THREE.Vector3(0, 1, 0);
  return new THREE.Vector3(0, 0, 1);
}
