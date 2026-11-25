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
