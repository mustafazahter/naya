// Viewer'ın public/ klasörünü hazırlar: Draco çözücüsü ve şablon modelleri.
// npm install sonrası kendiliğinden çalışır; ikisi de git'e girmez.
import { cpSync, mkdirSync } from "node:fs";

// Yalnız çözücü; kodlayıcı (draco_encoder.js) viewer'da kullanılmıyor.
cpSync("node_modules/three/examples/jsm/libs/draco/gltf", "public/draco", {
  recursive: true,
  filter: (src) => !src.endsWith("draco_encoder.js"),
});

mkdirSync("public/models", { recursive: true });
cpSync("../../templates/src/bisiklet/model/product.glb", "public/models/bicycle.glb");
// Montaj ağacı: parçalara ayırma gruplara göre yapılsın.
cpSync("../../templates/src/bisiklet/map/parts.json", "public/models/bicycle.parts.json");
