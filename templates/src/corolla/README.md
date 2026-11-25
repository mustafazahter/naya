# Corolla şablonu

Toyota Corolla E100 (1991-1997) dört kapılı sedan. Gövde ve şasi E100 kasaya ait; motor 1,8 litrelik 1ZZ-FE olarak gösterilir. AE101'in kendi motoru (4A-FE) için açık lisanslı ayrıntılı bir model bulunamadı. 1ZZ-FE bir sonraki nesil Corolla'nın motoru ama yapısı aynı: enine, dört silindirli, çift eksantrikli. Motorla ilgili bütün değerler (kompresyon, buji, supap boşluğu, sensörler, yakıt basıncı) 1ZZ-FE'ye göre yazıldı.

```
corolla/
├── naya.json      manifest (bütünlük özetleri paketlerken eklenir)
├── csdb/          S1000D Issue 5.0: 208 DM, PM, DML, 11 çizim
├── map/           parts.json (145 parça), faults.json (117 arıza, 386 belirti), zones.json
├── model/         product.glb (90 düğüm)
└── scripts/       modeli kuran, içeriği ve çizimleri üreten betikler
```

Paket yaklaşık 3,8 MB.

Paketleme ve doğrulama (repo kökünden):

```bash
dart run tools/naya_cli/bin/naya.dart pack templates/src/corolla -o templates/dist/corolla.naya
dart run tools/naya_cli/bin/naya.dart validate templates/dist/corolla.naya
```

`tools/naya_cli/test/templates_test.dart` şablonu her çalıştırmada paketleyip kabul kriterine göre kontrol eder.

## S1000D içeriği

Model kodu `NAYACAR`, sorumlu firma kodu `NAYA0`, dil `tr-TR`. Bütün dosyalar resmi S1000D 5.0 XML şemalarından geçiyor.

DM'ler, PM, DML ve `map/` altındaki dosyalar `scripts/make_content.py` ile tek bir tablodan üretilir; DMC'ler, parça haritası ve arızalar böylece birbiriyle tutarlı kalır. XML'i yazan kod tank ve uçak şablonlarıyla ortak: `templates/scripts/s1000d_content.py`. İçeriği değiştirmek için XML'leri değil betiği düzenleyip yeniden çalıştırın:

```bash
cd templates/src/corolla/scripts && python3 make_content.py
```

Betik çalışırken şunları da denetler: her DMC başvurusu tanımlı bir DM'e gidiyor, aynı DMC iki kez tanımlanmıyor, her belirti bir arızada kullanılıyor, her arızanın arıza bulma DM'i onarım DM'ine götürüyor, iki arıza aynı belirti kümesini taşımıyor ve modeldeki her düğüme dokununca o düğümün kendi parçası açılıyor. Var olan DMC'ler korunur; teşhis geçmişi ve testler onlara bağlı.

| SNS | Sistem |
| --- | --- |
| `D00` | Araç (genel tanım, periyodik bakım, bakım takvimi, sıvılar ve kapasiteler, terimler sözlüğü, parça kataloğu, iş kuralları) |
| `DA0` | Gövde (`-10` kapılar, `-20` kaput ve bagaj, `-30` tamponlar ve ızgara, `-40` camlar ve silecekler, `-50` aynalar, `-60` koltuklar, kemerler ve hava yastığı, `-70` iç döşeme) |
| `DA1` | Motor (`-10` blok, kapak ve pistonlar, `-20` triger, `-30` yağlama, `-40` soğutma, `-50` ateşleme, `-60` emme ve egzoz, `-70` yakıt, `-80` motor yönetimi, `-90` emisyon kontrolü) |
| `DA2` | Güç aktarma (`-10` şanzıman ve debriyaj, `-20` aks milleri) |
| `DA3` | Fren sistemi (`-10` ön, `-20` arka, `-30` servo ve hidrolik, `-40` el freni) |
| `DA4` | Süspansiyon ve direksiyon (`-10` ön, `-20` arka, `-30` direksiyon) |
| `DA5` | Tekerlekler (`-10` lastikler, `-20` tekerlek rulmanları) |
| `DA6` | Elektrik ve aydınlatma (`-10` akü, `-20` lambalar, `-30` şarj, `-40` marş, `-50` gösterge paneli, `-60` sigortalar ve demet, `-70` camlar ve kilitler, `-80` korna) |
| `DA7` | Isıtma ve klima (`-10` kalorifer ve fan, `-20` klima) |

Teşhiste sorulan sistemler parça ağacının kökleridir: gövde, kabin, motor, soğutma, yakıt, emme-egzoz-emisyon, ateşleme, motor yönetimi, elektrik, aydınlatma, ısıtma-klima, güç aktarma, fren, süspansiyon-direksiyon, tekerlekler. Her arızanın belirtileri, bir arıza bulma DM'i (evet/hayır adımlı) ve bir onarım ya da değiştirme DM'i vardır; prosedürlerde alet, sarf malzemesi ve yedek parça listeleri, uyarılar ve sıkma torkları yer alır. Yedek parçalar IPD'deki parça numarasıyla eşleşir. Miktarı bilinmeyen sarf malzemeleri "Gerektiği kadar" yazılır.

Her kök sistemin bir "Nasıl çalışır" DM'i (bilgi kodu 040) var; sistemde zaten bir tanım DM'i varsa anlatım onun yanına `01` sökme koduyla eklenir. Arızaların belirtilerine, sürücünün arızayı kendi sözleriyle anlatışı da eklenir ("kaputtan tatlı bir koku geliyor", "frenden demir sesi geliyor"); teşhis serbest metni bu söyleyişlerle eşleştirir. Söyleyişler betikteki `PHRASINGS` tablosunda, her biri arızaya ayrı bir belirti olarak yazılır. Kesin değerinden emin olunmayan miktarlar için "üretici değerine bakın" yazılır.

Veriler yayımlanmış 1ZZ-FE ve E100 servis bilgilerinden (servis el kitabı alıntıları, kullanıcı el kitapları, motor teknik veri sayfaları) derlendi. Değerler eğitim ve teşhis amaçlıdır; gerçek bir araçta üreticinin el kitabına bakılmalıdır. Bu donanımda ABS yok; 1ZZ-FE'de EGR valfi bulunmaz.

Çizimler (`ICN-…-0000N-…JPG`) modelden `scripts/render_icn.py` ile üretilir; konusu olan parçalar turuncu.

## Model

`model/product.glb`: 90 düğüm, Draco sıkıştırmalı (~2,6 MB, ~530 bin üçgen).

Kaynaklar, ikisi de **CC BY 4.0**. Uygulamada ve `.naya` manifestinin `credits` alanında bu atıflar gösterilir:

- Gövde ve şasi: "Toyota Corolla MK7 (E100) 1992-1997", Merc_TV ([sketchfab.com/szymonpasterczyk](https://sketchfab.com/3d-models/toyota-corolla-mk7-e100-1992-1997-c5ca8d403fbe40a1a438e1cb59d0469c))
- Motor: "Car Engine 4 Cylinder - Toyota 1ZZ-FE", Zarrar Abbas ([sketchfab.com/zarrarabbas73](https://sketchfab.com/3d-models/car-engine-4-cylinder-toyota-1zz-fe-3442d69b82b6416389eff8e961dfe333))

Kaynak dosyalar repoya girmiyor; Sketchfab'dan GLB olarak indirilip şu komutla birleştirilir:

```bash
cd templates/src/corolla/scripts
blender -b --python build_model.py -- corolla-e100.glb engine-1zz-fe.glb ../model/product.glb
blender -b --python render_icn.py -- ../model/product.glb cikti/
```

Kütüphane kartındaki resim (repo kökünden):

```bash
blender -b --python templates/scripts/render_thumbnail.py -- templates/src/corolla/model/product.glb apps/naya/assets/templates/corolla.webp -1,-0.55,0.42
```

`build_model.py` sırasıyla:

1. Gövde modelindeki seçenekli parçalardan (tampon, ızgara, fren) fabrika çıkışı olanı alır.
2. Parçaları uygulamanın düğümlerine toplar (`door_fl`, `strut_front`...).
3. Gövdeyi, kabini ve motor bölmesini birbirine değmeyen parçalarına (adacık) ayırır; her adacık malzemesine ve konumuna göre düğümüne gider: silecekler, koltuklar, gösterge paneli, gösterge kadranı, pedallar, halı, iç döşeme, genleşme kabı, cam suyu deposu, hidrolik direksiyon deposu, radyatör hortumları... Motor bölmesindeki eski egzoz ön borusu atılır: kaynakta tek yüzlü şeritlerden yapılmış, aracın altında iğne demeti gibi görünüyor.
4. Kabinden görünen boyalı sacın 4 mm içine döşeme renginde bir kopya koyar (tavanda açık renk tavan döşemesi, belin altında koyu döşeme, kapılarda kapı döşemesi); camdan bakınca içerisi kırmızı görünmez.
5. Eski düşük ayrıntılı motordan yalnız şanzımanı tutar; 1ZZ-FE'yi enine, volanı şanzımana bakacak şekilde yerleştirir.
6. Kaynakta olmayan parçaları basit biçimlerle yapar: lastik ve jant, egzoz hattı (ön boru, katalitik konvertör, susturucu), yakıt deposu (taban sacına gömülü, yandan bakınca marşpiyelin altından sarkmaz), radyatör fanı, alternatör, marş motoru, klima kompresörü ve kondenseri, tekerlek davlumbazı iç kaplamaları. Göbek kapağını her tekerleğe kopyalar.
7. Malzemeleri düğüme ve adlarına göre yeniden renklendirir; kaynakta hiçbir malzemenin rengi yok. glTF temel renkleri doğrusal olduğu ve görüntüleyicide (RoomEnvironment + ACES) açık göründüğü için değerler koyu seçildi.

Motor sadeleştirilmiyor: ince parçalarda sadeleştirme sivri üçgenler bırakıyor. Kaynakta silindir kafasının bir köşesi kafanın çok altında kalmıştı; X-ışınında "V" çiziyordu, betik bu köşeyi siler. Arka disklerin merkezi öndekilerden 2 cm alçak; arka lastiklerin yere giren kısmı basılmış gibi düzlenir.

## Parçalar

Düğüm adlarında nokta yerine alt çizgi var, çünkü three.js düğüm adındaki noktaları siliyor.

| Düğüm | Parça |
| --- | --- |
| `body` | Gövde kabuğu (tavan, direkler, taban, iç çamurluklar, radyatör traversi) |
| `hood`, `trunk`, `door_fl`, `door_fr`, `door_rl`, `door_rr` | Kaput, bagaj kapağı, kapılar (camı ve döşemesiyle) |
| `fender_l`, `fender_r`, `bumper_front`, `bumper_rear`, `grille` | Çamurluklar (yan sinyalle), tamponlar, ızgara |
| `windshield`, `rear_window`, `wipers`, `washer_tank`, `mirror_l`, `mirror_r` | Camlar, silecekler, cam suyu deposu, aynalar |
| `headlight_*`, `foglight_*`, `taillight_*` | Farlar, sis lambaları, arka lambalar |
| `seat_front_l`, `seat_front_r`, `seat_rear`, `dashboard`, `instrument_cluster`, `steering_wheel`, `pedals`, `carpet`, `headliner`, `interior_trim` | Kabin |
| `engine_*` | 1ZZ-FE: blok, kafa, conta, supap kapağı, eksantrikler, triger zinciri ve kapağı, krank, krank kasnağı, krank konum sensörü, piston, biyel, karter, yağ pompası ve filtresi, su pompası, manifoldlar, bobinler, bujiler |
| `air_filter`, `battery`, `alternator`, `starter`, `brake_booster`, `ps_reservoir` | Motor bölmesi |
| `radiator`, `radiator_fan`, `radiator_hoses`, `coolant_tank`, `ac_condenser`, `ac_compressor` | Soğutma ve klima |
| `fuel_tank`, `exhaust_pipe`, `catalytic_converter`, `muffler` | Yakıt deposu ve egzoz hattı |
| `transaxle`, `driveshaft_front` | Şanzıman, aks milleri |
| `brake_caliper_front`, `brake_disc_front`, `brake_caliper_rear`, `brake_disc_rear` | Kaliperler ve diskler |
| `strut_front`, `control_arm_front`, `hub_front`, `subframe_front`, `steering_rack` | Ön süspansiyon ve direksiyon |
| `strut_rear`, `arms_rear`, `stabilizer_rear`, `subframe_rear`, `hub_rear` | Arka süspansiyon |
| `wheel_fl`, `wheel_fr`, `wheel_rl`, `wheel_rr` | Lastik, jant, göbek kapağı |

Ayrı düğümü olmayan parçalar (balatalar, debriyaj, enjektörler, sensörler, motor beyni, kalorifer peteği, yakıt pompası...) içinde bulundukları düğüme bağlı; seçilince o düğüm vurgulanır. Bir düğüme dokununca her zaman o düğümün kendi parçası açılır (örneğin gövdeye dokununca "Gövde kabuğu", silecek kollarına dokununca "Silecekler").
