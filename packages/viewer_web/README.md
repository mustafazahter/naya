# viewer_web

NAYA'nın 3D görüntüleyicisi: three.js, camera-controls ve Vite. Flutter uygulaması bunu kendi içine gömer: web'de bir iframe, Android'de bir WebView içinde açılır. İki ortamda da aynı derleme ve aynı mesajlar kullanılır.

## Komutlar

```bash
npm install        # bir kez; Draco çözücüsünü ve bisiklet modelini public/'e kopyalar
npm run dev        # http://localhost:5173, önizleme sayfası
npm run check      # TypeScript tip kontrolü
npm run bundle     # derler ve apps/naya/assets/viewer'a kopyalar
```

Uygulama varsayılan olarak gömülü viewer'ı (`npm run bundle` çıktısını) kullanır. Viewer üzerinde çalışırken `tools/dev.sh` geliştirme sunucusunu açar ve uygulamaya `NAYA_VIEWER_URL=http://localhost:5173` verir; değişiklik sayfa yenilenince görünür.

## Nasıl açılıyor

| Ortam | Taşıyıcı | Adres |
| --- | --- | --- |
| Web | iframe | `assets/assets/viewer/index.html?…` (uygulamayla aynı sunucu) |
| Android | WebView (`webview_flutter`) | `http://127.0.0.1:<port>/?…`, uygulamanın içinde açılan küçük sunucu |

Android'de `file://` kullanılmıyor, çünkü viewer ES modülü olarak derleniyor ve modeli `fetch` ile indiriyor; ikisi de `file://` adreslerinde engelleniyor. Sunucu (`apps/naya/lib/shared/platform/viewer_asset_server.dart`) yalnız 127.0.0.1'de dinliyor ve yalnız `assets/viewer` altındaki asset'leri veriyor. Release derlemesinde şifresiz HTTP yalnız bu adres için açık (`android/app/src/main/res/xml/network_security_config.xml`).

## Adres parametreleri

| Parametre | Anlamı |
| --- | --- |
| `embed` | Uygulama içi görünüm: düğmeler ve etiketler gizlenir, onları Flutter çizer. |
| `model=<yol>` | Yüklenecek `.glb`. Varsayılan `./models/bicycle.glb`. |
| `map=<yol>` | Montaj ağacı (`map/parts.json`). Verilmezse modelin yanında aynı adla `.parts.json` aranır (`bicycle.glb` → `bicycle.parts.json`); yoksa parçalar merkezden açılır. |
| `focus=<düğüm>` | Model yüklenince kamera bu parçaya yaklaşır, diğerleri saydamlaşır. Teşhiste kullanılıyor. |

## Köprü

Mesajların tipleri `src/bridge.ts` dosyasında; Flutter tarafı `apps/naya/lib/widgets/viewer_panel/model_frame_controller.dart`. Biri değişirse diğeri de değişmeli.

**Flutter → viewer (komutlar).** Web'de `iframe.contentWindow.postMessage(komut)`, Android'de `runJavaScript("window.postMessage(komut)")`.

| Komut | Alanlar | Ne yapar |
| --- | --- | --- |
| `load` | `url`, isteğe bağlı `map` | Başka bir modeli yükler. |
| `explode` | `amount` (0-1) | Parçaları montaj ağacına göre açar: önce gruplar (aktarma organları, tekerlekler...) modelin merkezinden, sonra grubun içindeki parçalar grubun merkezinden ayrılır. İç içe parçalar (lastik, jant, göbek) aks boyunca sıralanır. Kamera açılmış modele göre geri çekilir. |
| `focus` | `part` | Kamerayı parçaya yaklaştırır, diğerlerini saydam gri yapar. |
| `isolate` | `part` ya da `null` | Yalnız parçayı gösterir, kamera ona uçar; `null` bütün modeli geri getirir. |
| `xray` | `enabled` | Bütün modeli yarı saydam yapar. |
| `reset` | | Kamerayı, seçimi ve parçalamayı başa alır. |
| `scan` | `parts: [{id, weight}]` | Teşhis taraması (3,4 sn): ışık bandı modelin boyunca geçer, geçtiği parçalar `weight` (0-1) ile orantılı parlar. Sonunda ağırlığı olanlar parlar, diğerleri CAD grisine geçer. Bitince `scanDone` gelir. |
| `highlight` | `parts: [{id, weight}]` | Taramasız, doğrudan olasılığa göre parlama. Boş liste vurguyu kaldırır. |

**Viewer → Flutter (olaylar).** Web'de `window.parent.postMessage(olay)`, Android'de `NayaBridge` JavaScript kanalına JSON metni.

| Olay | Alanlar | Ne zaman |
| --- | --- | --- |
| `ready` | | Model yüklendi, komut alınabilir. |
| `partTap` | `part` (düğüm adı ya da `null`) | Kullanıcı bir parçaya dokundu ya da boşluğa dokunup seçimi kaldırdı. |
| `scanDone` | | Tarama animasyonu bitti. |

Düğüm adlarında nokta yok (three.js siliyor); parça kimliğiyle eşleşme `map/parts.json`'daki `meshNodes` alanıyla yapılır.

## Efektler nasıl çiziliyor

- **Parlama:** her parçanın malzemesinin kopyasına küçük bir shader eki (`src/glow.ts`). Kenara yaklaştıkça artan mavi ışık; güç 0 iken görünüm değişmez. Tam ekran son işleme (bloom, outline pass) kullanılmadı: telefonda her karede fazladan geçiş olmasın. Bütün kopyalar aynı shader'ı paylaşıyor.
- **Tarama bandı:** dört kenarı sönen, toplamalı (additive) karışımlı tek bir dörtgen. Model yüklenirken kurulur ve saydam bekler; böylece shader taramanın ilk karesinde derlenmez.
- **CAD görünümü:** öne çıkmayan parçalar ortak, yarı saydam gri tek bir malzemeye geçer.

Mac'te (Chrome, 2x ekran) tarama boyunca 60 fps ölçüldü. Önizleme sayfasındaki **Tara** düğmesi örnek bir teşhisle taramayı gösterir.
