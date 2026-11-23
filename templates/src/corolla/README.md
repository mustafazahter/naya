# Corolla şablonu

Toyota Corolla E100 (1991-1997) dört kapılı sedan. Gövde ve şasi E100 kasaya ait; motor 1,8 litrelik 1ZZ-FE olarak gösterilir. AE101'in kendi motoru (4A-FE) için açık lisanslı ayrıntılı bir model bulunamadı. 1ZZ-FE bir sonraki nesil Corolla'nın motoru ama yapısı aynı: enine, dört silindirli, çift eksantrikli.

```
corolla/
├── naya.json      manifest (bütünlük özetleri paketlerken eklenir)
├── csdb/          S1000D Issue 5.0: 40 DM, PM, DML, 6 çizim
├── map/           parts.json (60 parça), faults.json (24 arıza), zones.json
├── model/         product.glb
└── scripts/       modeli kuran, içeriği ve çizimleri üreten betikler
```

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

| SNS | Sistem |
| --- | --- |
| `D00` | Araç (genel tanım, periyodik kontrol, parça kataloğu, iş kuralları) |
| `DA0` | Gövde (`-10` kapılar, `-20` kaput ve bagaj, `-30` tamponlar, `-40` camlar ve silecekler) |
| `DA1` | Motor (`-10` blok, kapak ve pistonlar, `-20` triger, `-30` yağlama, `-40` soğutma, `-50` ateşleme, `-60` emme ve egzoz) |
| `DA2` | Güç aktarma (`-10` şanzıman ve debriyaj, `-20` aks milleri) |
| `DA3` | Fren sistemi (`-10` ön, `-20` arka, `-30` servo ve hidrolik) |
| `DA4` | Süspansiyon ve direksiyon (`-10` ön, `-20` arka, `-30` direksiyon) |
| `DA5` | Tekerlekler (`-10` lastikler) |
| `DA6` | Elektrik ve aydınlatma (`-10` akü, `-20` farlar) |

İçerik genel bakım bilgisidir (seviye kontrolleri, sarf parça değişimleri, arıza bulma). Tork ve ölçü değerleri bu sınıf araçlar için yaygın değerlerdir; gerçek bir araçta üreticinin el kitabına bakılmalıdır.

Çizimler (`ICN-…-0000N-…JPG`) modelden `scripts/render_icn.py` ile üretilir; konusu olan parçalar turuncu.

## Model

`model/product.glb`: 57 düğüm, Draco sıkıştırmalı (~2,5 MB, ~530 bin üçgen).

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
3. Motor bölmesindeki karışık parçayı konumlara göre aküye, hava filtresine, genleşme kabına, fren servosuna ayırır.
4. Eski düşük ayrıntılı motordan yalnız şanzımanı tutar; 1ZZ-FE'yi enine, volanı şanzımana bakacak şekilde yerleştirir.
5. Kaynakta olmayan lastik, jant ve egzozu yapar; göbek kapağını her tekerleğe kopyalar.
6. Malzemeleri adlarına göre yeniden renklendirir; kaynakta hiçbir malzemenin rengi yok.

Motor sadeleştirilmiyor: ince parçalarda sadeleştirme sivri üçgenler bırakıyor. Kaynakta silindir kafasının bir köşesi kafanın çok altında kalmıştı; X-ışınında "V" çiziyordu, betik bu köşeyi siler.

## Parçalar

Düğüm adlarında nokta yerine alt çizgi var, çünkü three.js düğüm adındaki noktaları siliyor.

| Düğüm | Parça |
| --- | --- |
| `body` | Gövde kabuğu, camlar, iç döşeme |
| `hood`, `trunk` | Kaput, bagaj kapağı |
| `door_fl`, `door_fr`, `door_rl`, `door_rr` | Kapılar |
| `fender_l`, `fender_r`, `bumper_front`, `bumper_rear`, `grille` | Çamurluklar, tamponlar, ızgara |
| `headlight_*`, `taillight_*`, `mirror_*` | Farlar, stop lambaları, aynalar |
| `engine_*` | 1ZZ-FE: blok, kafa, conta, külbütör kapağı, eksantrikler, triger, krank, piston, biyel, karter, yağ pompası ve filtresi, su pompası, manifoldlar, bobinler, bujiler |
| `air_filter`, `battery`, `coolant_tank`, `radiator`, `brake_booster` | Motor bölmesi |
| `transaxle`, `driveshaft_front` | Şanzıman, aks milleri |
| `brake_front`, `brake_rear` | Diskler ve kaliperler |
| `strut_front`, `control_arm_front`, `subframe_front`, `suspension_rear`, `steering_rack`, `steering_wheel` | Süspansiyon ve direksiyon |
| `wheel_fl`, `wheel_fr`, `wheel_rl`, `wheel_rr` | Lastik, jant, göbek kapağı |
| `exhaust` | Egzoz borusu ve susturucu |

Ayrı düğümü olmayan parçalar (balatalar, debriyaj, silecekler) içinde bulundukları düğüme bağlı; seçilince o düğüm vurgulanır.
