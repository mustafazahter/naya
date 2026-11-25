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
| `explode` | `amount` (0-1) | Gövde dışındaki bütün parçaları dışarı açar; açılmış hâlde hiçbiri birbirine değmez (bkz. [Parçalara ayırma](#parçalara-ayırma)). Kamera açılmış modele göre geri çekilir. |
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

## Parçalara ayırma

Plan model yüklenirken bir kez kurulur (`src/explode.ts`), ayrı bir iş parçacığında (`src/explodeWorker.ts`; açılamazsa sayfanın kendisinde). Plan kurulurken eski model ekranda kalır.

- **Her parça açılır.** Yalnız en büyük kabuk (kasa, gövde, kadro) yerinde kalır; bisikletin kabloları da kadroyla birlikte durur (havada asılı çizgiler gibi okunuyorlardı). Diğer her parça kendi boyuyla orantılı bir mesafe gider: modelin boyunun %4'ü, artı gittiği yöndeki kalınlığının 0,7'si, artı köşegeninin 0,2'si; merkezden uzaklığın payı küçük ve sınırlı, uçtaki parçalar savrulmasın. Kapı az, kule çok gider; açılmış model dengeli durur.
- **Yön.** Gövdenin dışına taşan ya da dış yüzündeki parça (kapı, tekerlek, palet) çoğunlukla tek eksen boyunca açılır. Gövdenin içindeki parça (motor) yukarı ve dışarı, yelpaze gibi açılır. Hiçbir parça aşağı gitmez, zeminin altına inmez.
- **Ev sahipleri.** Montaj ağacındaki büyük grupta her üyenin ev sahibi, onu içine alan ya da ona değen en büyük üyedir. Gövdenin içinde büyük bir kabuğun (kabin döşemesi) içindeki parça kendi yanına açılır: koltuklar yana, tavan döşemesi yukarı. Diğerleri ev sahibiyle birlikte gider, sonra kendi yanına biraz kayar: top kuleyle kalkıp öne çıkar, tekerlekler kendi paletinin yanında durur.
- **Takımlar.** Küçük ve bir arada duran grup (bisiklet tekerleği, aktarma) ve kutusu bir tekerleğin içinde kalan parçalar (disk, kaliper, göbek) önce birlikte çıkar. Merkezleri üst üste ise aks boyunca içten dışa sıralanır (göbek, jant, iç lastik, dış lastik); dağınıksa her üye takımın merkezinden kendi yanına kayar.
- **Sağ ve sol kısımlar ayrı açılır.** Modelde tek düğüm olan sağ ve sol amortisör, iki ön disk gibi aralarında boşluk olan parçalar yüklenirken kısımlarına bölünür (`src/pieces.ts`); her kısım kendi yanına gider. Seçme, parlama ve ad parçanın kendisinde kalır.
- **Açılmış hâlde hiçbir parça başka bir parçaya değmez.** Değen iki parçadan biri kendi yönünde biraz daha ileri itilir, değme kalmayana kadar: aynı yöne gidenlerden dıştaki (sıra bozulmasın), ayrı yönlere gidenlerden küçük olan. Animasyon sırasında parçalar birbirinin içinden geçebilir.
- **Animasyon.** Dıştakiler önce kalkar, içtekiler arkadan gelir; yaklaşık 2,5 sn sürer. Kamera açılmış modelin tamamını kadraja alır.

Geliştirirken tarayıcı konsolunda `await explodeReport()` açılmış hâlde birbirine giren ya da değen parçaları listeler (yalnız `npm run dev`'de). Toplu hâlde zaten birbirine değen iki parça, değdikleri hücre sayısı artmadıkça sayılmaz. Boş liste beklenir.

## Efektler nasıl çiziliyor

- **Parlama:** her parçanın malzemesinin kopyasına küçük bir shader eki (`src/glow.ts`). Kenara yaklaştıkça artan mavi ışık; güç 0 iken görünüm değişmez. Tam ekran son işleme (bloom, outline pass) kullanılmadı: telefonda her karede fazladan geçiş olmasın. Bütün kopyalar aynı shader'ı paylaşıyor.
- **Tarama bandı:** dört kenarı sönen, toplamalı (additive) karışımlı tek bir dörtgen. Model yüklenirken kurulur ve saydam bekler; böylece shader taramanın ilk karesinde derlenmez.
- **CAD görünümü:** öne çıkmayan parçalar ortak, yarı saydam gri tek bir malzemeye geçer.
- **Fareyle üstüne gelme:** yalnız fare olaylarında (`pointerType === "mouse"`, `(any-hover: hover)`); parça soluk gri bir ışıkla belli belirsiz parlar, imleç el olur. Parlama yalnız normal görünümde; X-ışını ya da seçim varken (CAD grisi) yalnız imleç değişir. Işın izleme en çok 20 kez/sn; sürüklerken, tarama ve açılış sırasında yapılmaz, kamera fare kıpırdamadan hareket ederse durunca yeniden yapılır. Dokunmatik ekranda çalışmaz.

Mac'te (Chrome, 2x ekran) tarama boyunca 60 fps ölçüldü. Önizleme sayfasındaki **Tara** düğmesi örnek bir teşhisle taramayı gösterir.
