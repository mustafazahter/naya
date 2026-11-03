import { defineConfig } from "vite";

// Flutter içinde iframe/WebView'den göreli yolla yüklensin diye base "./".
export default defineConfig({
  base: "./",
  server: { port: 5173, host: true },
  build: { outDir: "dist", target: "es2022" },
});
