# NAYA

S1000D teknik dokümanlarını 3D modellerle birleştiren bakım ve arıza teşhis uygulaması. Flutter ile yazılıyor, web ve Android'de çalışıyor.

Genel plan için [PLAN.md](PLAN.md) dosyasına bakın.

## Dizinler

| Dizin | İçerik |
| --- | --- |
| `apps/naya` | Flutter uygulaması (web + Android) |
| `apps/naya_api` | Dart sunucusu |
| `packages/naya_format` | `.naya` okuma, yazma, doğrulama |
| `packages/naya_s1000d` | S1000D ayrıştırma |
| `packages/naya_diagnosis` | Teşhis akışı |
| `packages/viewer_web` | three.js görüntüleyici (TypeScript) |
| `templates/src` | Şablon kaynakları: modeller ve onları hazırlayan betikler |
| `tools/naya_cli` | `naya pack / unpack / validate / import` |
| `tools/fsd_lint` | FSD katman kuralını denetleyen analyzer eklentisi |
| `schemas` | JSON Schema dosyaları |

Dart paketleri tek bir pub workspace içinde; bağımlılıklar kökte bir kez çözülür.

## Yerelde çalıştırma

Gerekenler: Flutter (stable), Node.js 20+, Chrome. Docker gerekmez.

```bash
flutter pub get                              # kökte, tüm paketler için
(cd packages/viewer_web && npm install)      # 3D viewer, bir kez
tools/dev.sh                                 # API + viewer + web uygulaması
```

Uygulama Chrome'da açılır. API `http://localhost:8080` (`/health` ile kontrol edilebilir), 3D viewer `http://localhost:5173` adresinde çalışır. Veriler `data/` klasöründe tutulur, git'e girmez.

## Kontroller

```bash
dart analyze             # tüm workspace, FSD kuralı dahil
(cd packages/viewer_web && npm run check)
dart format .
flutter test apps/naya
dart test apps/naya_api
```

Flutter uygulamasında katmanlar `app → pages → widgets → features → entities → shared` sırasındadır. Bir katman yalnız kendinden alttakileri import eder; aykırı bir import `dart analyze`'da hata verir.

## Ekip

- Mustafa Zahter
- Enes Yeniçırak
