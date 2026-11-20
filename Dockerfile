# syntax=docker/dockerfile:1
#
# Komuta bu dosyayla derler; yerelde Docker kullanmıyoruz.
# Tek servis: API hem /api isteklerini hem de Flutter web derlemesini sunar.
# Veriler (SQLite, .naya dosyaları, yedekler) /data'ya bağlanan kalıcı
# diskte durur. Ayrıntı: naya-notlar/nasil-yapildi/komuta.md

ARG FLUTTER_VERSION=3.47.6

# 1) 3D viewer (three.js). Uygulamanın içine gömülür; web'de iframe.
FROM node:20-bookworm-slim AS viewer
WORKDIR /src
# Kurulumdan sonra prepare.mjs bisiklet modelini viewer'a kopyalıyor.
COPY templates/src/bisiklet/model/product.glb templates/src/bisiklet/model/
COPY templates/src/bisiklet/map/parts.json templates/src/bisiklet/map/
COPY packages/viewer_web/package.json packages/viewer_web/package-lock.json packages/viewer_web/
COPY packages/viewer_web/scripts packages/viewer_web/scripts
RUN cd packages/viewer_web && npm ci
COPY packages/viewer_web packages/viewer_web
RUN mkdir -p apps/naya/assets/viewer && cd packages/viewer_web && npm run bundle

# 2) Flutter web, şablonlar ve API.
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build
WORKDIR /src
COPY . .
COPY --from=viewer /src/apps/naya/assets/viewer apps/naya/assets/viewer
RUN flutter pub get
# API adresi boş: uygulama açıldığı adresle konuşur (aynı servis).
RUN cd apps/naya && flutter build web --release --dart-define=NAYA_API_URL=
RUN mkdir -p /out/templates \
 && for template in templates/src/*/; do \
      name="$(basename "$template")"; \
      dart run tools/naya_cli/bin/naya.dart pack "$template" -o "/out/templates/$name.naya"; \
    done
# sqlite3 paketi build hook kullandığı için `dart compile exe` değil
# `dart build cli`: çıktı bin/server ve lib/libsqlite3.so.
RUN cd apps/naya_api && dart build cli -o /out/api

# 3) Çalışma imajı: derlenmiş API, web dosyaları ve şablonlar.
FROM ubuntu:24.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /data
WORKDIR /app
COPY --from=build /out/api/bundle ./
COPY --from=build /src/apps/naya/build/web ./web
COPY --from=build /out/templates ./templates

ENV PORT=8080 \
    STORAGE_DIR=/data/storage \
    DATABASE_PATH=/data/naya.db \
    TEMPLATES_DIR=/app/templates \
    WEB_DIR=/app/web \
    NAYA_SECURE_COOKIES=1
EXPOSE 8080
# NAYA_MASTER_KEY, NAYA_ADMIN_EMAIL ve NAYA_ADMIN_PASSWORD Komuta'da gizli
# değişken olarak verilir; imaja girmez.
CMD ["/app/bin/server"]
