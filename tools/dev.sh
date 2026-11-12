#!/usr/bin/env bash
# Yerelde API'yi ve web uygulamasını birlikte başlatır.
# Kullanım: tools/dev.sh            (Chrome'da açar)
#           tools/dev.sh web-server  (tarayıcı açmadan, http://localhost:5050)
# 3D viewer de kuruluysa 5173'te açılır. Ctrl+C hepsini kapatır.
set -euo pipefail

cd "$(dirname "$0")/.."
root="$PWD"

port="${PORT:-8080}"
export DATABASE_PATH="${DATABASE_PATH:-$root/data/naya.db}"
export STORAGE_DIR="${STORAGE_DIR:-$root/data/storage}"
export TEMPLATES_DIR="${TEMPLATES_DIR:-$root/templates/dist}"
mkdir -p "$STORAGE_DIR"

flutter pub get >/dev/null

# Şablonlar her açılışta yeniden paketlenir; API açılırken bunları
# kütüphaneye ekler (değişmeyen şablona dokunmaz).
for template in templates/src/*/; do
  name="$(basename "$template")"
  dart run tools/naya_cli/bin/naya.dart pack "$template" -o "$TEMPLATES_DIR/$name.naya"
done

(cd apps/naya_api && PORT="$port" exec dart run bin/server.dart) &
pids=($!)

# 3D viewer (three.js). Bağımlılıklar kurulu değilse atlanır:
# cd packages/viewer_web && npm install
# Çalışıyorsa uygulama gömülü viewer yerine bunu kullanır; viewer'da yapılan
# değişiklik sayfa yenilenince görünür.
defines=(--dart-define=NAYA_API_URL="http://localhost:$port")
if [[ -d packages/viewer_web/node_modules ]]; then
  (cd packages/viewer_web && exec npx vite --port 5173 --strictPort) &
  pids+=($!)
  defines+=(--dart-define=NAYA_VIEWER_URL=http://localhost:5173)
fi
trap 'kill "${pids[@]}" 2>/dev/null || true' EXIT

device="${1:-chrome}"
extra=()
if [[ "$device" == "web-server" ]]; then
  extra=(--web-port "${WEB_PORT:-5050}")
fi

cd apps/naya
flutter run -d "$device" "${extra[@]}" "${defines[@]}"
