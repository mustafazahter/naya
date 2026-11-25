import * as THREE from "three";

import { makeGrid, planExplode, shapeOf } from "./explode";

/**
 * Parçalara ayırma planını ayrı bir iş parçacığında kurar: büyük modelde
 * birkaç saniye sürebilir, sayfa bu sırada donmasın.
 */

export interface PlanRequest {
  box: [number, number, number, number, number, number];
  pieces: { id: string; tris: Float32Array }[];
  groups: [string, string][];
}

/** Planın aktarılabilir hâli. */
export interface PlanReply {
  stages: [string, { offset: number[]; moves: { start: number; end: number; points: number[][] }[] }][];
  layers: number;
}

self.onmessage = (e: MessageEvent<PlanRequest & { id: number }>) => {
  const { id, box, pieces, groups } = e.data;
  const grid = makeGrid(
    new THREE.Box3(new THREE.Vector3(box[0], box[1], box[2]), new THREE.Vector3(box[3], box[4], box[5])),
  );
  const shapes = pieces.map((p) => shapeOf(p.id, p.tris, grid));
  const plan = planExplode(grid, shapes, new Map(groups));
  const reply: PlanReply = {
    layers: plan.layers,
    stages: [...plan.stages].map(([id, stage]) => [
      id,
      {
        offset: stage.offset.toArray(),
        moves: stage.moves.map((m) => ({
          start: m.start,
          end: m.end,
          points: m.points.map((p) => p.toArray()),
        })),
      },
    ]),
  };
  self.postMessage({ ...reply, id });
};
