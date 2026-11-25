# syntax=docker/dockerfile:1
#
# Komuta bu dosyayla derler; yerelde Docker kullanmıyoruz.
# Tek servis: API hem /api isteklerini hem de Flutter web derlemesini sunar.
# Veriler (SQLite, .naya dosyaları, yedekler) /data'ya bağlanan kalıcı
# diskte durur. Ayrıntı: apps/naya_api/README.md → "Yayın".

# Proje Dart ^3.13 istiyor; hazır Flutter imajları bu sürümde değil.
# Flutter resmî git etiketinden kuruluyor (yereldeki sürümle aynı).
ARG FLUTTER_VERSION=3.47.5

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
FROM debian:bookworm-slim AS build
ARG FLUTTER_VERSION
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git /sdks/flutter
# Komuta'nın derleme ortamında root, dosya sahipliğini değiştiremiyor;
# Flutter'ın indirdiği arşivler sahipliği korumadan açılsın.
ENV PATH=/sdks/flutter/bin:/sdks/flutter/bin/cache/dart-sdk/bin:$PATH \
    TAR_OPTIONS=--no-same-owner
RUN flutter config --no-analytics --enable-web \
 && flutter precache --web \
 && flutter --version
WORKDIR /src
COPY . .
COPY --from=viewer /src/apps/naya/assets/viewer apps/naya/assets/viewer
RUN flutter pub get
# API adresi boş: uygulama açıldığı adresle konuşur (aynı servis).
RUN cd apps/naya && flutter build web --release --dart-define=NAYA_API_URL=
# Komuta'nın önündeki önbellek .js ve resim dosyalarını tarayıcıda saatlerce
# tutuyor; index.html önbelleğe girmez. Derlemenin bütün dosyalarından bir
# sürüm üretilir: bootstrap ve main.dart.js sürüm ekiyle istenir, assets/
# klasörünün bir kopyası v<sürüm>/assets altına konur ve Flutter
# (assetBase) resimleri, fontları oradan yükler. Her imaj sıfırdan
# derlendiği için içinde yalnız o sürümün tek kopyası olur, birikmez.
# assets/ eski yerinde de kalır: gömülü viewer o yoldan açılıyor.
RUN cd apps/naya/build/web \
 && v="$(find . -type f ! -name index.html -print0 | sort -z | xargs -0 sha1sum | sha1sum | cut -c1-10)" \
 && mkdir "v$v" && cp -r assets "v$v/assets" \
 && sed -i "s/flutter_bootstrap\.js/flutter_bootstrap.js?v=$v/" index.html \
 && sed -i "s/\"main\.dart\.js\"/\"main.dart.js?v=$v\"/g" flutter_bootstrap.js \
 && sed -i "s|_flutter.loader.load({|_flutter.loader.load({ config: { assetBase: \"v$v/\" },|" flutter_bootstrap.js \
 && grep -q "flutter_bootstrap.js?v=$v" index.html \
 && grep -q "main.dart.js?v=$v" flutter_bootstrap.js \
 && grep -q "assetBase: \"v$v/\"" flutter_bootstrap.js \
 && test -f "v$v/assets/AssetManifest.bin.json"
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
