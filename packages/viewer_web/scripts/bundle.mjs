// Derlenmiş viewer'ı (dist/) Flutter uygulamasının asset'lerine kopyalar.
// Uygulama viewer'ı kendi içinden açar: web'de iframe, Android'de WebView.
// `npm run bundle` ile çalışır; kopyalanan dosyalar git'e girmez.
import { cpSync, existsSync, readdirSync, rmSync } from "node:fs";
import { join } from "node:path";

const target = "../../apps/naya/assets/viewer";

// Eski derlemeyi sil; klasörleri pubspec'te tanımlı tutan .gitkeep'ler kalsın.
function clean(dir) {
  if (!existsSync(dir)) return;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) clean(path);
    else if (entry.name !== ".gitkeep") rmSync(path);
  }
}

clean(target);
cpSync("dist", target, { recursive: true });
console.log(`viewer → ${target}`);
