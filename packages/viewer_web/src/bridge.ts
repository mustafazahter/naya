// Flutter ile viewer arasındaki mesajlar. İki taraf da bu şekle uyar;
// biri değişirse diğeri de değişmeli.

export type ViewerCommand =
  | { type: "load"; url: string }
  | { type: "scan"; parts: string[] }
  | { type: "highlight"; parts: { id: string; weight: number }[] }
  | { type: "explode"; amount: number }
  | { type: "focus"; part: string }
  | { type: "isolate"; part: string | null }
  | { type: "xray"; enabled: boolean }
  | { type: "reset" };

export type ViewerEvent =
  | { type: "ready" }
  | { type: "partTap"; part: string | null };
