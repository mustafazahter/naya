// Flutter ile viewer arasındaki mesajlar. İki taraf da bu şekle uyar;
// biri değişirse diğeri de değişmeli (apps/naya/.../model_frame_controller.dart).

/** Parça (düğüm adı) ve 0-1 arası olasılık. */
export interface WeightedPart {
  id: string;
  weight: number;
}

export type ViewerCommand =
  | { type: "load"; url: string; map?: string }
  | { type: "scan"; id: number; parts: WeightedPart[] }
  | { type: "highlight"; parts: WeightedPart[] }
  | { type: "explode"; amount: number }
  | { type: "focus"; part: string }
  | { type: "isolate"; part: string | null }
  | { type: "xray"; enabled: boolean }
  | { type: "reset" };

export type ViewerEvent =
  | { type: "ready" }
  /** Model inerken 0-1 arası ilerleme. */
  | { type: "progress"; value: number }
  | { type: "loadFailed" }
  | { type: "partTap"; part: string | null }
  /** Yarıda kesilen tarama da biter; [id] hangi taramanın bittiğini söyler. */
  | { type: "scanDone"; id: number };
