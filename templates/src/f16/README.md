# F-16D Block 60 şablonu

İki kişilik F-16D Block 60, konformal yakıt tanklarıyla. İçerik yalnız genel bakım bilgisidir: uçuş öncesi ve sonrası kontroller, ikmal, seviye kontrolleri, gözle muayene, teker değişimi ve arıza bulma. Silah, aviyonik, elektronik harp ve performans bilgisi yok. Ölçü, basınç ve tork değerleri de verilmiyor; DM'ler değer gereken yerde uçağın kendi teknik el kitabına yönlendiriyor.

```
f16/
├── naya.json      manifest (bütünlük özetleri paketlerken eklenir)
├── csdb/          S1000D Issue 5.0: 33 DM, PM, DML, 6 çizim
├── map/           parts.json (50 parça), faults.json (22 arıza), zones.json
├── model/         product.glb
└── scripts/       modeli kuran, içeriği ve çizimleri üreten betikler
```

Paketleme ve doğrulama (repo kökünden):

```bash
dart run tools/naya_cli/bin/naya.dart pack templates/src/f16 -o templates/dist/f16.naya
dart run tools/naya_cli/bin/naya.dart validate templates/dist/f16.naya
```

## S1000D içeriği

Model kodu `NAYAJET`, sorumlu firma kodu `NAYA0`, dil `tr-TR`. Bütün dosyalar resmi S1000D 5.0 XML şemalarından geçiyor.

DM'ler, PM, DML ve `map/` altındaki dosyalar `scripts/make_content.py` ile tek bir tablodan üretilir; XML'i yazan kod ortak (`templates/scripts/s1000d_content.py`):

```bash
cd templates/src/f16/scripts && python3 make_content.py
```

Sistem kodları ATA 100 bölüm numaralarına benzer:

| SNS | Sistem |
| --- | --- |
| `00` | Uçak (genel tanım, uçuş öncesi ve sonrası kontrol, parça kataloğu, iş kuralları) |
| `25` | Kokpit donanımı (fırlatma koltuğu emniyet kontrolü) |
| `27` | Uçuş kumandaları (`-10` flaperonlar, `-20` dümen, `-30` yatay kuyruklar, `-40` hücum kenarı flapları, `-50` hava frenleri) |
| `28` | Yakıt sistemi (`-10` gövde içi tanklar, `-20` konformal tanklar) |
| `29` | Hidrolik güç |
| `32` | İniş takımı (`-10` ana, `-20` burun, `-40` tekerlekler ve frenler, `-50` kuyruk kancası) |
| `53` | Gövde (`-20` radom, `-30` hava alığı) |
| `56` | Kanopi |
| `57` | Kanatlar ve kuyruk |
| `72` | Motor (`-10` fan ve kompresörler, `-20` yanma odası, `-30` türbinler, `-50` art yakıcı ve lüle) |
| `79` | Motor yağı |

Çizimler (`ICN-…-0000N-…JPG`) modelden `scripts/render_icn.py` ile üretilir; konusu olan parçalar turuncu.

## Model

`model/product.glb`: 32 düğüm, Draco sıkıştırmalı (~3,7 MB, ~420 bin üçgen).

Kaynaklar, ikisi de **CC BY 4.0**. Uygulamada ve `.naya` manifestinin `credits` alanında bu atıflar gösterilir:

- Uçak: "General Dynamics F-16D Block 60", Muhamad Mirza Arrafi ([sketchfab.com/MirzaArrafiERV_45](https://sketchfab.com/3d-models/general-dynamics-f-16d-block-60-ea8edb08d79e4eafa9c794c581f88cf3))
- Motor: "Turbofan Engine Cutaway (Aerospace 3D Model)", bagsantanu1109 ([sketchfab.com/bagsantanu1109](https://sketchfab.com/3d-models/turbofan-engine-cutaway-aerospace-3d-model-2bfdca9d3d144969883543287039a1d5))

Motor modeli genel bir çift milli turbofan; Block 60'ın gerçek motoru (General Electric F110-GE-132) değil. Ana bölümleri aynı: fan, alçak ve yüksek basınç kompresörleri, yanma odası, türbinler. DM'ler de bunu söylüyor.

Kaynak dosyalar repoya girmiyor. Sketchfab'dan orijinal kaynaklar (OBJ) indirilip şu komutla birleştirilir:

```bash
cd templates/src/f16/scripts
blender -b --python build_model.py -- "General Dynamics F-16D Block 60.obj" Turbofan_Engine.obj ../model/product.glb
blender -b --python render_icn.py -- ../model/product.glb cikti/
```

Kütüphane kartındaki resim (repo kökünden):

```bash
blender -b --python templates/scripts/render_thumbnail.py -- templates/src/f16/model/product.glb apps/naya/assets/templates/f16.webp -1,-0.55,0.42
```

`build_model.py` sırasıyla:

1. Uçağın ayrı nesne olan parçalarını (flaperonlar, yatay kuyruklar, dümen, hava frenleri, iniş takımları, kanopi) düğümlere toplar.
2. Tek parça gövdeden kanatları, burun konisini ve hava alığını yüz yüz ayırır.
3. Dış yükleri (füzeler, bombalar, dış tanklar, pilonlar) atar.
4. Turbofanın gondolunu ve giriş dudağını atar; motoru 1,6 m'lik fan çapından gövdeye sığan 1,02 m'ye küçültüp motor bölmesine yerleştirir. Kaynakta art yakıcı yok; motorla lüle arasına basit bir art yakıcı kanalı yapar.
5. Kaynaktaki 16 kenarlı tekerlekleri siler; yerlerine lastik, jant, göbek ve ana tekerleklerde fren diski yapar.
6. Malzemeleri düğüme göre yeniden renklendirir: üst yüzeyler mavi-gri, aşağı bakan yüzler açık gri, kanopinin önünde koyu yansıma önleyici şerit, koyu radom; iniş takımı kapakları alt gövde rengi.
7. Uçağı 15 m boya ölçekler ve burnunu -Y'ye çevirir.

## Parçalar

Blender'da uçağın burnu -Y, solu +X.

| Düğüm | Parça |
| --- | --- |
| `fuselage`, `radome`, `intake`, `canopy`, `cockpit`, `conformal_tanks` | Gövde, radom, hava alığı, kanopi, kokpit, konformal tanklar |
| `wing_l`, `wing_r`, `lef_l`, `lef_r`, `flaperon_l`, `flaperon_r` | Kanatlar, hücum kenarı flapları, flaperonlar |
| `vertical_tail`, `rudder`, `horizontal_tail_l`, `horizontal_tail_r`, `speed_brakes` | Kuyruk ve hava frenleri |
| `nose_gear`, `main_gear_l`, `main_gear_r`, `tail_hook` | İniş takımı ve kuyruk kancası |
| `engine_fan`, `engine_casing`, `engine_lpc`, `engine_hpc`, `engine_combustor`, `engine_hpt`, `engine_lpt`, `engine_shafts`, `engine_gearbox` | Turbofan motor |
| `afterburner`, `engine_nozzle` | Art yakıcı (temsili) ve lüle |

Ayrı düğümü olmayan parçalar (fırlatma koltukları, frenler, lastikler, yakıt enjektörleri) içinde bulundukları düğüme bağlı; seçilince o düğüm vurgulanır.
