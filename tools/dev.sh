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
mkdir -p "$STORAGE_DIR"

flutter pub get >/dev/null

(cd apps/naya_api && PORT="$port" exec dart run bin/server.dart) &
pids=($!)

# 3D viewer (three.js). Bağımlılıklar kurulu değilse atlanır:
# cd packages/viewer_web && npm install
if [[ -d packages/viewer_web/node_modules ]]; then
  (cd packages/viewer_web && exec npx vite --port 5173 --strictPort) &
  pids+=($!)
fi
trap 'kill "${pids[@]}" 2>/dev/null || true' EXIT

device="${1:-chrome}"
extra=()
if [[ "$device" == "web-server" ]]; then
  extra=(--web-port "${WEB_PORT:-5050}")
fi

cd apps/naya
flutter run -d "$device" "${extra[@]}" --dart-define=NAYA_API_URL="http://localhost:$port"
