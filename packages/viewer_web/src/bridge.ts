// Flutter ile viewer arasındaki mesajlar. İki taraf da bu şekle uyar;
// biri değişirse diğeri de değişmeli (apps/naya/.../model_frame_controller.dart).

/** Parça (düğüm adı) ve 0-1 arası olasılık. */
export interface WeightedPart {
  id: string;
  weight: number;
}

export type ViewerCommand =
  | { type: "load"; url: string; map?: string }
  | { type: "scan"; parts: WeightedPart[] }
  | { type: "highlight"; parts: WeightedPart[] }
  | { type: "explode"; amount: number }
  | { type: "focus"; part: string }
  | { type: "isolate"; part: string | null }
  | { type: "xray"; enabled: boolean }
  | { type: "reset" };

export type ViewerEvent =
  | { type: "ready" }
  | { type: "partTap"; part: string | null }
  | { type: "scanDone" };
