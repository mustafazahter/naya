import type { ViewerCommand, ViewerEvent, WeightedPart } from "./bridge";
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
  "drive_cassette": "Kaset",
  "drive_derailleur": "Arka vites değiştirici",
  "drive_front_derailleur": "Ön vites değiştirici",
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
// Önizleme sayfasında örnek bir teşhis taraması; uygulamada Flutter gönderir.
$("scan").addEventListener("click", () => {
  partBox.hidden = true;
  void viewer.scan(
    new Map([
      ["drive_chain", 0.62],
      ["drive_derailleur", 0.21],
      ["drive_cassette", 0.09],
    ]),
  );
});
$("reset").addEventListener("click", () => {
  for (const id of ["explode", "xray"]) $(id).setAttribute("aria-pressed", "false");
  viewer.setXray(false);
  partBox.hidden = true;
  void viewer.reset();
});

const weights = (parts: WeightedPart[]) => new Map(parts.map((p) => [p.id, p.weight]));

window.addEventListener("message", (e: MessageEvent<ViewerCommand>) => {
  const command = e.data;
  switch (command?.type) {
    case "load":
      void viewer.load(command.url, command.map);
      break;
    case "scan":
      partBox.hidden = true;
      void viewer.scan(weights(command.parts)).then(() => send({ type: "scanDone", id: command.id }));
      break;
    case "highlight":
      // Süren tarama bitince kendi parlamasını geri yazmasın.
      viewer.finishScan();
      viewer.highlight(weights(command.parts));
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
      void viewer.isolate(command.part);
      break;
    case "reset":
      partBox.hidden = true;
      void viewer.reset();
      break;
  }
});

// Geliştirirken tarayıcı konsolundan denemek için.
if (import.meta.env.DEV) (window as unknown as { viewer: NayaViewer }).viewer = viewer;

const params = new URLSearchParams(location.search);
// Uygulamanın içinde düğmeleri ve etiketleri Flutter çiziyor.
if (params.has("embed")) document.body.classList.add("embed");

const model = params.get("model") ?? "./models/bicycle.glb";
// İlerleme her kare değil, yüzde birlik adımlarla gider.
let sent = -1;
function progress(fraction: number): void {
  const value = Math.round(fraction * 100) / 100;
  if (value <= sent) return;
  sent = value;
  status.textContent = `Model yükleniyor · %${Math.round(value * 100)}`;
  send({ type: "progress", value });
}

viewer
  .load(model, params.get("map") ?? undefined, progress)
  .then(async (parts) => {
    status.textContent = `${parts.length} parça · sürükle: döndür · tekerlek/iki parmak: yakınlaş`;
    send({ type: "ready" });
    await viewer.introduce();
    // Teşhiste bulunan parça adreste gelir: önce bütün model görünsün,
    // sonra kamera o parçaya yaklaşsın. Sayfa yeniden yüklense de tekrarlanır.
    const focus = params.get("focus");
    if (focus && parts.includes(focus)) {
      await new Promise((resolve) => setTimeout(resolve, 900));
      partBox.hidden = false;
      partName.textContent = readable(focus);
      await viewer.focus(focus);
    }
  })
  .catch((error: unknown) => {
    status.textContent = "Model yüklenemedi";
    send({ type: "loadFailed" });
    console.error(error);
  });
