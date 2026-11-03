// Viewer'ın public/ klasörünü hazırlar: Draco çözücüsü ve şablon modelleri.
// npm install sonrası kendiliğinden çalışır; ikisi de git'e girmez.
import { cpSync, mkdirSync } from "node:fs";

cpSync("node_modules/three/examples/jsm/libs/draco/gltf", "public/draco", { recursive: true });

mkdirSync("public/models", { recursive: true });
cpSync("../../templates/src/bisiklet/model/product.glb", "public/models/bicycle.glb");
