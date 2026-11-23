# Leopard 2A6 şablonu

Leopard 2A6 ana muharebe tankı. İçerik yalnız genel bakım bilgisidir: seviye kontrolleri, temizlik, sarf parça değişimleri, gözle muayene ve arıza bulma. Zırh, mühimmat, atış ve atış kontrol sistemi bilgisi yok. Ölçü ve ayar değerleri de verilmiyor; DM'ler değer gereken yerde aracın kendi teknik el kitabına yönlendiriyor.

```
leopard2/
├── naya.json      manifest (bütünlük özetleri paketlerken eklenir)
├── csdb/          S1000D Issue 5.0: 37 DM, PM, DML, 7 çizim
├── map/           parts.json (45 parça), faults.json (22 arıza), zones.json
├── model/         product.glb
└── scripts/       modeli kuran, içeriği ve çizimleri üreten betikler
```

Paketleme ve doğrulama (repo kökünden):

```bash
dart run tools/naya_cli/bin/naya.dart pack templates/src/leopard2 -o templates/dist/leopard2.naya
dart run tools/naya_cli/bin/naya.dart validate templates/dist/leopard2.naya
```

## S1000D içeriği

Model kodu `NAYATANK`, sorumlu firma kodu `NAYA0`, dil `tr-TR`. Bütün dosyalar resmi S1000D 5.0 XML şemalarından geçiyor.

DM'ler, PM, DML ve `map/` altındaki dosyalar `scripts/make_content.py` ile tek bir tablodan üretilir. XML'i yazan kod üç şablonda ortak: `templates/scripts/s1000d_content.py`. İçeriği değiştirmek için XML'leri değil betiği düzenleyip yeniden çalıştırın:

```bash
cd templates/src/leopard2/scripts && python3 make_content.py
```

| SNS | Sistem |
| --- | --- |
| `D00` | Araç (genel tanım, günlük kontrol, parça kataloğu, iş kuralları) |
| `DA0` | Gövde ve kule (`-10` gövde ve kapaklar, `-20` kule, `-30` motor güvertesi) |
| `DA1` | Güç paketi (`-10` motor, `-20` yağlama, `-30` soğutma, `-40` hava emme ve egzoz, `-50` yakıt) |
| `DA2` | Güç aktarma (`-10` şanzıman, `-20` son dişliler) |
| `DA3` | Yürüyen takım (`-10` paletler, `-20` yol tekerlekleri ve süspansiyon, `-30` avara ve yürütücü dişliler) |
| `DA4` | Elektrik sistemi (`-10` aküler, `-20` aydınlatma) |
| `DA5` | Silah ve optikler (yalnız dış muayene ve optik temizliği) |

Çizimler (`ICN-…-0000N-…JPG`) modelden `scripts/render_icn.py` ile üretilir; konusu olan parçalar turuncu.

## Model

`model/product.glb`: 29 düğüm, Draco sıkıştırmalı (~2,1 MB, ~430 bin üçgen).

Kaynak **CC BY 4.0**. Uygulamada ve `.naya` manifestinin `credits` alanında bu atıf gösterilir:

- "Leopard 2A6 [Free]", Quasar ([sketchfab.com/mansoorsajidp](https://sketchfab.com/3d-models/leopard-2a6-free-b62ba39ae5584b768b53d58803c3cc4b))

Kaynak dosya repoya girmiyor. Sketchfab'dan orijinal kaynak (`.rar` içinde `.blend`) indirilip şu komutla kurulur:

```bash
cd templates/src/leopard2/scripts
blender -b --python build_model.py -- Leopard_2A6.blend ../model/product.glb
blender -b --python render_icn.py -- ../model/product.glb cikti/
```

Kütüphane kartındaki resim (repo kökünden):

```bash
blender -b --python templates/scripts/render_thumbnail.py -- templates/src/leopard2/model/product.glb apps/naya/assets/templates/leopard2.webp -1,-0.55,0.42
```

`build_model.py` sırasıyla:

1. Paletleri, yol tekerleklerini ve avaraları çoğaltan modifier'ları (array, curve, mirror) uygular.
2. Kaynaktaki büyük nesneleri birbirine değmeyen parçalara ayırır, konumlarına göre düğümlere toplar: namlu kulenin önünde ortada, sis bombası atıcıları kulenin iki yanında, makineli tüfek yükleyici kapağında...
3. Kaynakta olmayan güç paketini basit şekillerle modeller: V12 motor, şanzıman ve son dişliler, radyatörler, iki fan, hava filtreleri, yakıt tankları, aküler, egzoz. Bunlar temsilidir; yerleri ve görevleri doğru, biçimleri ve ölçüleri gerçek değildir.
4. Malzemeleri düğüme göre yeniden renklendirir.
5. Kaynak model gerçeğin 2,26 katı; tankı 3,75 m'lik genişliğe göre ölçekler ve yere oturtur.

## Parçalar

Blender'da tankın önü -Y, solu +X.

| Düğüm | Parça |
| --- | --- |
| `hull`, `engine_deck`, `side_skirt_l`, `side_skirt_r` | Gövde, motor güvertesi, yan etekler |
| `headlights`, `taillights` | Farlar, arka lambalar |
| `turret`, `main_gun`, `optics`, `machine_gun`, `smoke_dischargers` | Kule ve üstündeki donanım |
| `engine`, `transmission`, `radiators`, `cooling_fans`, `air_filters`, `fuel_tanks`, `batteries`, `exhaust` | Güç paketi ve yardımcıları (temsili) |
| `track_l`, `track_r`, `road_wheels_l`, `road_wheels_r`, `suspension_l`, `suspension_r` | Paletler, yol tekerlekleri, salıncak kolları |
| `idler_l`, `idler_r`, `sprocket_l`, `sprocket_r` | Avaralar, yürütücü dişliler |

Ayrı düğümü olmayan parçalar (turboşarjlar, son dişliler, palet tabanları, amortisörler) içinde bulundukları düğüme bağlı; seçilince o düğüm vurgulanır.
