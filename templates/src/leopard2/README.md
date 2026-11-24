# Leopard 2A6 şablonu

Leopard 2A6 ana muharebe tankı. İçerik yalnız genel bakım bilgisidir: periyodik kontroller, seviye kontrolleri, yağlama, temizlik, sarf parça değişimleri, gözle muayene ve arıza bulma. Zırh, mühimmat, atış, atış kontrol sistemi ve araç başarım bilgisi yok. Silahların yalnız dış muayenesi, optiklerin yalnız temizliği var. Ölçü, basınç ve tork değerleri de verilmiyor; DM'ler değer gereken yerde aracın kendi teknik el kitabına yönlendiriyor.

```
leopard2/
├── naya.json      manifest (bütünlük özetleri paketlerken eklenir)
├── csdb/          S1000D Issue 5.0: 138 DM, PM, DML, 16 çizim
├── map/           parts.json (108 parça), faults.json (73 arıza, 67 belirti), zones.json
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
| `D00` | Araç (genel tanım, güvenlik uyarıları, günlük kontrol, parça kataloğu, iş kuralları; `-10` periyodik bakım: görev öncesi, sırası ve sonrası, haftalık, aylık, soğuk hava; `-20` yağlama çizelgesi ve gresleme; `-30` yıkama, iç temizlik, korozyon koruma; `-40` alet ve teçhizat) |
| `DA0` | Gövde ve kule (`-10` gövde ve kapaklar, `-20` kule, `-30` motor güvertesi, `-40` çekme ve kurtarma, `-50` yan etekler ve çamurluklar, `-60` kule yatağı ve tahrik) |
| `DA1` | Güç paketi (`-10` motor, `-20` yağlama, `-30` soğutma, `-40` hava emme ve egzoz, `-50` yakıt) |
| `DA2` | Güç aktarma (`-10` şanzıman, `-20` son dişliler, `-30` frenler, `-40` sürüş kumandaları) |
| `DA3` | Yürüyen takım (`-10` paletler, `-20` yol tekerlekleri ve süspansiyon, `-30` avara ve yürütücü dişliler) |
| `DA4` | Elektrik sistemi (`-10` aküler, `-20` aydınlatma, `-30` şarj ve marş, `-40` kablo demetleri ve sigortalar, `-50` iç haberleşme) |
| `DA5` | Silah ve optikler (yalnız dış muayene ve optik temizliği; `-10` ana top, `-20` optikler, `-30` makineli tüfekler, `-40` sis bombası atıcıları) |
| `DA6` | Hidrolik sistem (genel: seviye, filtre, hortumlar) |
| `DA7` | Mürettebat bölmesi donanımı (`-10` havalandırma ve NBC koruma, `-20` yangın söndürme, `-30` ısıtıcı) |

Her arızanın belirtileri, bir arıza bulma DM'i (`421`) ve bir onarım ya da bakım DM'i var. Mevcut DM'lerin kodları değişmez; aynı sistem, alt sistem ve bilgi kodunda ikinci bir DM ayrıştırma koduyla (`01`, `02`…) ayrılır.

Çizimler (`ICN-…-0000N-…JPG`) modelden `scripts/render_icn.py` ile üretilir; konusu olan parçalar turuncu. PNG'ler `sips` ile JPEG'e çevrilir (betiğin başındaki komut).

## Model

`model/product.glb`: 29 düğüm, Draco sıkıştırmalı (~2,1 MB, ~425 bin üçgen).

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
2. Kaynaktaki büyük nesneleri birbirine değmeyen parçalara ayırır, konumlarına göre düğümlere toplar: namlu ve top kalkanı kulenin önünde ortada, sis bombası atıcıları kulenin iki yanında, makineli tüfek yükleyici kapağında, komutan periskobu kulenin sağ arkasında. Yan etek panelleri, lamba gövdeleri ve motor güvertesi parçaları ayrı kurallarla kendi düğümlerine gider; kaynakta iki kez bulunan parçalar bir kez alınır.
3. Kaynakta olmayan güç paketini basit şekillerle modeller: V12 motor, şanzıman ve son dişliler, radyatörler, iki fan, hava filtreleri, yakıt tankları, aküler, egzoz. Bunlar temsilidir; yerleri ve görevleri doğru, biçimleri ve ölçüleri gerçek değildir.
4. Malzemeleri düğüme göre yeniden renklendirir. Renkler doğrusal ve koyu; görüntüleyicinin ortam ışığı onları açar. Lamba camları altındaki ampulün rengini alır.
5. Kaynak model gerçeğin 2,26 katı; tankı 3,75 m'lik genişliğe göre ölçekler ve yere oturtur.

## Parçalar

Blender'da tankın önü -Y, solu +X.

| Düğüm | Parça |
| --- | --- |
| `hull`, `engine_deck`, `side_skirt_l`, `side_skirt_r` | Gövde, motor güvertesi (ızgaralar, erişim kapakları, korkuluk), yan etekler (paneller, üst şerit, havalandırma panjuru) |
| `headlights`, `taillights` | Farlar ve ön köşe lambaları, arka lambalar (gövde ve koruyucularıyla) |
| `turret`, `main_gun`, `optics`, `machine_gun`, `smoke_dischargers` | Kule ve üstündeki donanım |
| `engine`, `transmission`, `radiators`, `cooling_fans`, `air_filters`, `fuel_tanks`, `batteries`, `exhaust` | Güç paketi ve yardımcıları (temsili) |
| `track_l`, `track_r`, `road_wheels_l`, `road_wheels_r`, `suspension_l`, `suspension_r` | Paletler, yol tekerlekleri, salıncak kolları |
| `idler_l`, `idler_r`, `sprocket_l`, `sprocket_r` | Avaralar, yürütücü dişliler |

Ayrı düğümü olmayan parçalar (turboşarjlar, son dişliler, palet tabanları, amortisörler, kule yatağı, hidrolik ünite, NBC ünitesi, yangın söndürme, ısıtıcı...) içinde bulundukları düğüme bağlı; seçilince o düğüm vurgulanır.

Teşhiste sistemler (parça ağacının kökleri): gövde, kule, güç paketi, yakıt sistemi, yürüyen takım, elektrik sistemi, hidrolik sistem, mürettebat bölmesi donanımı, alet ve teçhizat.
