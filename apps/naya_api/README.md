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
| `NAYA_ADMIN_EMAIL`, `NAYA_ADMIN_PASSWORD` | | İkisi de varsa admin hesabı açılır. Bu e-postayla hesap zaten varsa yalnız şifre de tutuyorsa admin yapılır; tutmuyorsa günlüğe uyarı yazılır |
| `NAYA_MASTER_KEY` | | Kullanıcıların OpenRouter anahtarlarını şifreleyen 32 bayt, base64 (`openssl rand -base64 32`). Yoksa yapay zekâ kapalı. `tools/dev.sh` yerelde kendisi üretir. Değişirse kayıtlı anahtarlar çözülemez, kullanıcılar yeniden girer |
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
| `POST /` | kullanıcı | Gövde ham `.naya` (en fazla 50 MB, kişi başına toplam 500 MB). 201; doğrulamadan geçmezse 422 ve `problems` listesi, sınır aşılırsa 413 |
| `DELETE /<id>` | sahibi, admin | 204. Şablonları yalnız admin siler |

Şablonları herkes, kullanıcı dosyalarını yalnız sahibi ve admin görür. Başkasının dosyası 404 döner. Dosya ve içerik cevaplarında `ETag` var; `If-None-Match` eşleşirse 304 döner. İçerik kullanıcıdan geldiği için bu cevaplar `Content-Security-Policy: sandbox` ve `nosniff` ile döner; adres doğrudan açılsa da içindeki betik çalışmaz.

### Yapay zekâ: `/api/ai`

Hepsi giriş ister. Kullanıcı kendi OpenRouter anahtarını girer; sunucu doğrular (`GET /api/v1/key`), AES-GCM ile şifreleyip saklar ve bir daha istemciye göndermez.

| | | |
| --- | --- | --- |
| `GET /key` | | `{configured, hasKey, hint: "…a1b2", updatedAt}` |
| `PUT /key` | `{key}` | Doğrular ve kaydeder. 400 `invalid_key`, 503 `not_configured` (`NAYA_MASTER_KEY` yok) |
| `DELETE /key` | | 204 |
| `GET /models` | | `{models: [{id, name, kind: chat/decision, contextLength, inputPrice, outputPrice}]}`; fiyat milyon token başına dolar, liste 24 saat önbellekte |
| `GET /roles`, `PUT /roles` | `{chat?, decision?}` | Seçilen modeller. Varsayılan `chat` = `deepseek/deepseek-v4.1-flash`, `decision` = `~typesafe/jev-latest` |
| `POST /diagnose` | `{item, message, earlier?}` | 201 `{id, item, message, result, explanation, sources, createdAt}` |
| `GET /diagnoses?item=` | | Teşhis geçmişi, en yeni önce. `GET /diagnoses/<id>` tek kayıt |
| `POST /chat` | `{item, message, conversation?, part?}` | Cevap SSE ile akar: `event: delta` `{text}`, sonda `event: done` `{conversation, message, sources}`, sorun olursa `event: error` `{code, message}` |
| `GET /conversations?item=` | | Sohbetler. `GET /conversations/<id>` mesajlarıyla |

Anahtar yoksa teşhis ve sohbet 409 `no_key` döner; kredi bittiyse 402 `no_credit`, OpenRouter yoğunsa 429 `rate_limited`.

**Teşhis sonucu (`result`):**

- `intent`: `diagnose`, `repair`, `partInfo`, `general`.
- `decision`: `focus` (kamera parçaya gider), `ambiguous` (ilk iki aday yakın), `uncertain` (en yüksek %35 altında ya da "hiçbiri" önde), `needsInfo` (belirti yetmiyor), `notDiagnosis`.
- `systems`, `candidates` (`{part, system, probability}`, en olası önce), `fault`, `procedure` (DMC), `danger`, `model`.

Akış `packages/naya_diagnosis` içinde: niyet ve yeterlilik, sistem turu, parça turu, arıza ve güvenlik. Jev'e `POST https://openrouter.ai/api/alpha/decisions` ile gidilir. Açıklamayı sohbet modeli yazar; bağlama önerilen prosedürün metni ve DM arama sonuçları girer (en fazla ~24 bin karakter).

**DM araması:** kütüphaneye eklenen her `.naya`'nın DM'leri adım ve bölüm bazında `dm_chunks` (SQLite FTS5) tablosuna yazılır, silinince çıkar. Dizinde olmayan eski dosyalar açılışta eklenir.

## Yedek

Günde bir kez `VACUUM INTO` ile `STORAGE_DIR/backups/naya-YYYY-AA-GG.db` alınır, son 7 kopya kalır. Sunucu saatte bir kontrol eder.

## Şema değişince

```bash
cd apps/naya_api && dart run build_runner build
```

`database.g.dart` repoda duruyor; CI'da üretilmiyor.
