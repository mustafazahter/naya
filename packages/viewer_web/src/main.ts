import type { ViewerCommand, ViewerEvent } from "./bridge";
import { NayaViewer } from "./viewer";

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

const status = $("status");
const partBox = $("part");
const partName = $("part-name");

const viewer = new NayaViewer({
  canvas: $<HTMLCanvasElement>("stage"),
  onPartTap(id) {
    partBox.hidden = id === null;
    partName.textContent = id ? readable(id) : "";
    send({ type: "partTap", part: id });
  },
});

/** Flutter tarafına olay gönderir: web'de iframe'in sahibine, Android'de JS kanalına. */
function send(event: ViewerEvent): void {
  const channel = (window as unknown as { NayaBridge?: { postMessage(m: string): void } }).NayaBridge;
  channel?.postMessage(JSON.stringify(event));
  if (window.parent !== window) window.parent.postMessage(event, "*");
}

// Önizleme sayfası için parça adları. Uygulamada adlar map/parts.json'dan gelir.
const names: Record<string, string> = {
  frame: "Kadro",
  fork: "Çatal",
  handlebar: "Gidon",
  saddle: "Sele",
  seatpost: "Sele borusu",
  "drive_chain": "Zincir",
  "drive_crankset": "Aynakol",
  "drive_pedals": "Pedallar",
  "drive_cassette": "Arka dişli",
  "drive_derailleur": "Arka vites değiştirici",
  "brakes_front": "Ön fren",
  "brakes_rear": "Arka fren",
  "wheel_front_tire": "Ön lastik",
  "wheel_front_rim": "Ön jant",
  "wheel_front_spokes": "Ön teller",
  "wheel_front_hub": "Ön göbek",
  "wheel_rear_tire": "Arka lastik",
  "wheel_rear_rim": "Arka jant",
  "wheel_rear_spokes": "Arka teller",
  "wheel_rear_hub": "Arka göbek",
};

function readable(id: string): string {
  return names[id] ?? id.replace(/[_.]+/g, " ").trim();
}

function toggle(button: HTMLButtonElement, apply: (on: boolean) => void): void {
  button.addEventListener("click", () => {
    const on = button.getAttribute("aria-pressed") !== "true";
    button.setAttribute("aria-pressed", String(on));
    apply(on);
  });
}

toggle($("explode"), (on) => viewer.explode(on ? 1 : 0));
toggle($("xray"), (on) => viewer.setXray(on));
$("reset").addEventListener("click", () => {
  for (const id of ["explode", "xray"]) $(id).setAttribute("aria-pressed", "false");
  viewer.setXray(false);
  partBox.hidden = true;
  void viewer.reset();
});

window.addEventListener("message", (e: MessageEvent<ViewerCommand>) => {
  const command = e.data;
  switch (command?.type) {
    case "load":
      void viewer.load(command.url);
      break;
    case "explode":
      viewer.explode(command.amount);
      break;
    case "focus":
      void viewer.focus(command.part);
      break;
    case "xray":
      viewer.setXray(command.enabled);
      break;
    case "isolate":
      viewer.select(command.part);
      break;
    case "reset":
      partBox.hidden = true;
      void viewer.reset();
      break;
  }
});

const params = new URLSearchParams(location.search);
// Uygulamanın içinde düğmeleri ve etiketleri Flutter çiziyor.
if (params.has("embed")) document.body.classList.add("embed");

const model = params.get("model") ?? "./models/bicycle.glb";
viewer
  .load(model)
  .then((parts) => {
    status.textContent = `${parts.length} parça · sürükle: döndür · tekerlek/iki parmak: yakınlaş`;
    send({ type: "ready" });
  })
  .catch((error: unknown) => {
    status.textContent = "Model yüklenemedi";
    console.error(error);
  });
