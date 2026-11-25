# F-16F Block 60 şablonu

İki kişilik F-16F Block 60, konformal yakıt tanklarıyla. Kaynak modelin adı "F-16D Block 60"; Block 60'ın iki kişilik sürümünün adı F-16F (tek kişilik E), şablon bu adı kullanıyor. Manifest kimliği (`f-16d-block-60`) kütüphanede aynı kayıt kalsın diye değişmedi. İçerik yalnız genel bakım bilgisidir: periyodik ve özel muayeneler, yer işlemleri (krikolama, çekme, park, depolama), ikmal ve servis, gözle muayene, çalışma testleri, parça değişimi, temizlik, korozyon kontrolü ve arıza bulma. Silah ve dış yük, aviyonik ve radar iç yapısı, elektronik harp ve performans bilgisi yok. Ölçü, basınç ve tork değerleri de verilmiyor; DM'ler değer gereken yerde uçağın kendi teknik el kitabına yönlendiriyor.

```
f16/
├── naya.json      manifest (bütünlük özetleri paketlerken eklenir)
├── csdb/          S1000D Issue 5.0: 176 DM, PM, DML, 16 çizim
├── map/           parts.json (117 parça), faults.json (95 arıza, 271 belirti), zones.json
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
| `00` | Uçak (genel tanım, genel uyarılar, uçuş öncesi ve sonrası kontrol, bakım takvimi, sıvılar, terimler sözlüğü, parça kataloğu, iş kuralları) |
| `05` | Periyodik muayeneler (`-10` faz muayenesi, `-20` sert iniş, yıldırım, aşırı sıcaklık ve yabancı cisim sonrası) |
| `07`, `09`, `10` | Krikolama; çekme; park, bağlama ve depolama |
| `12` | İkmal ve servis (servis noktaları, uçak yıkama) |
| `20` | Standart uygulamalar (emniyet teli, konnektörler, FOD önleme, korozyon kontrolü) |
| `21` | Klima ve basınçlandırma |
| `24` | Elektrik gücü (jeneratörler, akü, dış güç, acil güç ünitesi, kablolar) |
| `25` | Kokpit donanımı (fırlatma koltuğu emniyet kontrolü, kemerler, kokpit temizliği ve muayenesi) |
| `26` | Yangından korunma |
| `27` | Uçuş kumandaları (`-10` flaperonlar ... `-50` hava frenleri, `-60` kumanda bilgisayarı, `-70` pilot kumandaları) |
| `28` | Yakıt sistemi (tanklar, konformal tanklar, pompalar ve valfler, miktar göstergesi, havada ikmal ağzı) |
| `29` | Hidrolik güç (sistemler, pompalar, akümülatörler) |
| `32` | İniş takımı (`-10` ana, `-20` burun, `-30` açma-kapama, `-40` tekerlekler ve frenler, `-50` kuyruk kancası, `-60` yönlendirme) |
| `33` | Işıklar |
| `34` | Hava verileri (pitot-statik) |
| `35` | Oksijen |
| `36` | Pnömatik (hava alma) |
| `49` | Motor çalıştırma ünitesi (JFS) |
| `52` | Kapaklar (erişim kapakları, iniş takımı kapakları) |
| `53` | Gövde (`-10` yapı, `-20` radom, `-30` hava alığı) |
| `56` | Kanopi |
| `57` | Kanatlar ve kuyruk |
| `72` | Motor (`-10` fan ve kompresörler, `-20` yanma odası, `-30` türbinler, `-40` miller, `-50` art yakıcı ve lüle, `-60` dişli kutusu) |
| `73`, `74`, `77` | Motor yakıtı ve kontrolü; ateşleme; motor göstergeleri |
| `79` | Motor yağı |

Arıza bulma DM'leri belirtiden başlar, her adımda bir soru sorar ve onarım ya da değiştirme DM'ine yönlendirir. Her arızanın `faults.json`'da arıza bulma ve onarım DM'i var. Değiştirme DM'lerindeki yedek parçalar parça kataloğundaki numarayla eşleşir. Betik, her arızanın arıza bulma DM'inin onarım DM'ine götürdüğünü ve iki arızanın aynı belirti kümesini taşımadığını denetler.

Her kök sistemin bir "Çalışma ilkesi" DM'i (bilgi kodu 040) var. Arızaların belirtilerine pilotun ve teknisyenin arızayı kendi sözleriyle anlatışı da eklenir ("talaş ışığı yandı", "taksi sırasında burun tekerleği titriyor"); teşhis serbest metni bu söyleyişlerle eşleştirir. Söyleyişler betikteki `PHRASINGS` tablosundadır. Bakım takvimi ve sıvılar DM'leri yalnız neye, ne zaman ve nasıl bakılacağını anlatır; aralık, tip ve miktar yazılmaz.

Çizimler (`ICN-…-0000N-…JPG`) modelden `scripts/render_icn.py` ile üretilir; konusu olan parçalar turuncu.

## Model

`model/product.glb`: 33 düğüm, Draco sıkıştırmalı (~4,8 MB, ~424 bin üçgen; kokpit dokuları JPEG olarak içinde).

Kaynaklar, ikisi de **CC BY 4.0**. Uygulamada ve `.naya` manifestinin `credits` alanında bu atıflar gösterilir:

- Uçak: "General Dynamics F-16D Block 60", Muhamad Mirza Arrafi ([sketchfab.com/MirzaArrafiERV_45](https://sketchfab.com/3d-models/general-dynamics-f-16d-block-60-ea8edb08d79e4eafa9c794c581f88cf3))
- Motor: "Turbofan Engine Cutaway (Aerospace 3D Model)", bagsantanu1109 ([sketchfab.com/bagsantanu1109](https://sketchfab.com/3d-models/turbofan-engine-cutaway-aerospace-3d-model-2bfdca9d3d144969883543287039a1d5))

Motor modeli genel bir çift milli turbofan; Block 60'ın gerçek motoru (General Electric F110-GE-132) değil. Ana bölümleri aynı: fan, alçak ve yüksek basınç kompresörleri, yanma odası, türbinler. DM'ler de bunu söylüyor.

Kaynak dosyalar repoya girmiyor. Sketchfab'dan orijinal kaynaklar (OBJ ve uçağın doku klasörü) indirilip şu komutla birleştirilir:

```bash
cd templates/src/f16/scripts
blender -b --python build_model.py -- "General Dynamics F-16D Block 60.obj" Turbofan_Engine.obj textures/ ../model/product.glb
blender -b --python render_icn.py -- ../model/product.glb cikti/
```

Kütüphane kartındaki resim (repo kökünden):

```bash
blender -b --python templates/scripts/render_thumbnail.py -- templates/src/f16/model/product.glb apps/naya/assets/templates/f16.webp -1,-0.55,0.42
```

`build_model.py` sırasıyla:

1. Uçağın ayrı nesne olan parçalarını (flaperonlar, yatay kuyruklar, dümen, hava frenleri, iniş takımları, kanopi camı ve çerçevesi, kokpit) düğümlere toplar.
2. Tek parça gövdeden kanatları, burun konisini, hava alığını ve gövdeye gömülü dikey kuyruk yüzlerini ayırır. Sınırlar önce düzlemle kesilir; parçaların kenarı testere dişi gibi kalmaz.
3. Küçük ayrıntı nesnesindeki lamba camlarını `lights` düğümüne, HUD camını kokpite alır. Dış yükleri (füzeler, bombalar, dış tanklar, pilonlar) ve simülatörün HUD sembol düzlemlerini atar.
4. Turbofanın gondolunu ve giriş dudağını atar; motoru 1,6 m'lik fan çapından gövdeye sığan 1,02 m'ye küçültüp motor bölmesine yerleştirir. Kaynakta art yakıcı yok; motorla lüle arasına basit bir art yakıcı kanalı yapar. Lülenin ve gövde arkasının içini kapatan diskleri siler.
5. Kaynaktaki 16 kenarlı tekerlekleri siler; yerlerine lastik, jant, göbek ve ana tekerleklerde fren diski yapar.
6. Malzemeleri düğüme göre yeniden renklendirir: üst yüzeyler koyu gri, alt yüzeyler açık gri (yüzün üstünde ve altında ne olduğuna dikey ışınla bakılır; kaynakta bazı normaller ters), kanopinin önünde koyu yansıma önleyici şerit, koyu radom, iniş takımı yuvaları ve egzoz tüneli koyu. Kokpitte kaynağın kendi panel ve koltuk dokuları kullanılır; ekranlar kapalı ekran renginde. Lambalar sol kırmızı, sağ yeşil, kuyruk ve iniş lambaları beyaz.
7. Uçağı 15 m boya ölçekler ve burnunu -Y'ye çevirir.

Renkler glTF'de doğrusal değer olarak yazılır ve viewer'da açık görünür; bu yüzden koyu tutuldu.

## Parçalar

Blender'da uçağın burnu -Y, solu +X.

| Düğüm | Parça |
| --- | --- |
| `fuselage`, `radome`, `intake`, `canopy`, `cockpit`, `conformal_tanks` | Gövde, radom, hava alığı, kanopi (cam ve çerçeve), kokpit (tekne, koltuklar, paneller), konformal tanklar |
| `wing_l`, `wing_r`, `lef_l`, `lef_r`, `flaperon_l`, `flaperon_r` | Kanatlar, hücum kenarı flapları, flaperonlar |
| `vertical_tail`, `rudder`, `horizontal_tail_l`, `horizontal_tail_r`, `speed_brakes` | Kuyruk ve hava frenleri |
| `nose_gear`, `main_gear_l`, `main_gear_r`, `tail_hook` | İniş takımı ve kuyruk kancası |
| `engine_fan`, `engine_casing`, `engine_lpc`, `engine_hpc`, `engine_combustor`, `engine_hpt`, `engine_lpt`, `engine_shafts`, `engine_gearbox` | Turbofan motor |
| `afterburner`, `engine_nozzle` | Art yakıcı (temsili) ve lüle |
| `lights` | Seyir, kuyruk, iniş ve taksi lambalarının camları |

Ayrı düğümü olmayan parçalar (fırlatma koltukları, frenler, lastikler, yakıt enjektörleri, jeneratör, pompalar, filtreler, algılayıcılar) içinde bulundukları ya da bağlı oldukları düğüme bağlı; seçilince o düğüm vurgulanır.
