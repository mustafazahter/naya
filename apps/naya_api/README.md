# naya_api

NAYA sunucusu: hesaplar, kütüphane ve `.naya` dosyaları. Dart + shelf, veritabanı SQLite (drift, WAL modu).

## Çalıştırma

```bash
# Şablonları paketle (tools/dev.sh bunu kendisi yapar)
dart run tools/naya_cli/bin/naya.dart pack templates/src/bisiklet -o templates/dist/bisiklet.naya

cd apps/naya_api
dart run bin/server.dart
```

Veritabanı `data/naya.db`, dosyalar `data/storage` altında oluşur. Açılışta `templates/dist` içindeki şablonlar kütüphaneye eklenir, bugünün yedeği yoksa alınır.

Telefondan yerel sunucuya bağlanmak için: `adb reverse tcp:8080 tcp:8080`.

## Ortam değişkenleri

| Değişken | Varsayılan | Açıklama |
| --- | --- | --- |
| `PORT` | `8080` | |
| `DATABASE_PATH` | `data/naya.db` | |
| `STORAGE_DIR` | `data/storage` | `.naya` dosyaları (`library/`) ve yedekler (`backups/`) |
| `TEMPLATES_DIR` | `../../templates/dist` | Açılışta eklenen şablonlar |
| `NAYA_ADMIN_EMAIL`, `NAYA_ADMIN_PASSWORD` | | İkisi de varsa admin hesabı açılır; hesap varsa yalnız rolü admin yapılır |
| `NAYA_SECURE_COOKIES` | | `1` ise çerezde `Secure` (HTTPS arkasında) |
| `CORS_ORIGINS` | | Virgülle ayrılmış ek web adresleri; `localhost` her zaman açık |

## Uçlar

Hatalar her zaman `{"error": {"code": "...", "message": "..."}}` biçiminde döner; `message` doğrudan gösterilebilir.

### Hesap: `/api/auth`

| | | |
| --- | --- | --- |
| `POST /register` | `{email, password}` | 201, oturum da açılır. 409 `email_taken`, 400 `weak_password` / `invalid_email` |
| `POST /login` | `{email, password}` | 200. 401 `invalid_credentials`, 429 `locked` (`Retry-After` başlığıyla) |
| `POST /logout` | | 204 |
| `GET /me` | | 200 `{user}` ya da 401 |

Web'de token httpOnly `naya_session` çerezinde durur, JavaScript göremez. Android `X-Naya-Client: app` başlığı gönderir; ona token gövdede de döner, sonraki isteklerde `Authorization: Bearer <token>` ile gönderir.

- Şifreler Argon2id (19 MiB, 2 tur), en az 8 karakter.
- 5 hatalı girişte hesap 15 dakika kilitlenir.
- Oturum 30 gün geçerli, kullanıldıkça uzar. Veritabanında token'ın yalnız SHA-256 özeti durur.

### Kütüphane: `/api/library`

| | Kim | |
| --- | --- | --- |
| `GET /` | herkes | `{templates, userFiles}`; misafirde `userFiles` boş |
| `GET /<id>` | görebilen | Öğenin bilgisi |
| `GET /<id>/file` | görebilen | `.naya` dosyasının kendisi |
| `GET /<id>/entries/<yol>` | görebilen | Dosyanın içinden tek kayıt: `map/parts.json`, `csdb/DMC-….XML`, `model/product.glb`, `naya.json` |
| `POST /` | kullanıcı | Gövde ham `.naya` (en fazla 50 MB). 201; doğrulamadan geçmezse 422 ve `problems` listesi |
| `DELETE /<id>` | sahibi, admin | 204. Şablonları yalnız admin siler |

Şablonları herkes, kullanıcı dosyalarını yalnız sahibi ve admin görür. Başkasının dosyası 404 döner. Dosya ve içerik cevaplarında `ETag` var; `If-None-Match` eşleşirse 304 döner.

## Yedek

Günde bir kez `VACUUM INTO` ile `STORAGE_DIR/backups/naya-YYYY-AA-GG.db` alınır, son 7 kopya kalır. Sunucu saatte bir kontrol eder.

## Şema değişince

```bash
cd apps/naya_api && dart run build_runner build
```

`database.g.dart` repoda duruyor; CI'da üretilmiyor.
