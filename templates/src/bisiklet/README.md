# Bisiklet şablonu

Önden süspansiyonlu dağ bisikleti: üç aynalı aynakol ve ön vites değiştirici, 8 dişli kaset ve arka vites değiştirici (3 × 8 = 24 vites), iki tekerlekte telle çalışan disk fren, çabuk sökme mandallı göbekler, iç lastikli 27,5" tekerlekler. DM'ler ve parça haritası bu modele göre yazıldı.

```
bisiklet/
├── naya.json      manifest (bütünlük özetleri paketlerken eklenir)
├── csdb/          S1000D Issue 5.0: 97 DM, PM, DML, 14 çizim
├── map/           parts.json (68 parça), faults.json (74 arıza, 194 belirti), zones.json, hotspots.json
├── model/         product.glb
└── scripts/       içeriği, modeli ve çizimleri üreten betikler
```

Paketleme ve doğrulama (repo kökünden):

```bash
dart run tools/naya_cli/bin/naya.dart pack templates/src/bisiklet -o templates/dist/bisiklet.naya
dart run tools/naya_cli/bin/naya.dart validate templates/dist/bisiklet.naya
```

`tools/naya_cli/test/templates_test.dart` aynı kontrolü her CI çalışmasında yapar.

## S1000D içeriği

Model kodu `NAYABIKE`, sorumlu firma kodu `NAYA0`, dil `tr-TR`. Dosyalar resmi S1000D 5.0 XML şemalarından geçiyor.

DM, PM, DML ve `map/` altındaki parts, faults ve zones dosyaları `scripts/make_content.py` ile ortak `templates/scripts/s1000d_content.py`'den üretilir. Elle düzenlemeyin; tabloları değiştirip betiği çalıştırın:

```bash
cd templates/src/bisiklet/scripts
python3 make_content.py
```

`map/hotspots.json` elle tutulur. İlk 26 DM elle yazılmıştı; üreticiye taşınırken kodları, parça kimlikleri ve uygulama testlerinde geçen metinler korundu.

| SNS | Sistem |
| --- | --- |
| `D00` | Bisiklet: genel tanım, sıkma torkları, sürüş öncesi kontrol, periyodik bakım çizelgesi, bakım takvimi ve değiştirme ölçütleri, yağlar ve basınçlar, terimler sözlüğü, temizlik, yağlama, sesler için arıza bulma, parça kataloğu, iş kuralları |
| `DA0` | Kadro, çatal ve kumanda (`-10` kadro, `-20` çatal ve furç, `-30` gidon ve kumanda, `-40` sele) |
| `DA1` | Aktarma organları (`-10` zincir, `-20` aynakol, orta göbek ve ön vites, `-30` kaset, `-40` arka vites, `-50` pedallar, `-60` vites kolları ve telleri) |
| `DA2` | Fren sistemi (`-10` balatalar ve kaliperler, `-20` diskler, `-30` fren kolları ve telleri) |
| `DA3` | Tekerlekler (`-10` lastik ve iç lastik, `-20` jant ve teller, `-30` göbekler) |

Kullanılan bilgi kodları (S1000D Chap 8.4):

| Kod | Anlamı |
| --- | --- |
| `022` | İş kuralları (BREX); SNS başlıkları burada |
| `030` | Teknik veriler (sıkma torkları) |
| `040` | Tanım |
| `210` | İkmal (lastik şişirme, koruyucu sıvı) |
| `241` | Yağlama ve bakım |
| `250` | Temizlik |
| `271` | Ayar |
| `300` | Muayene ve kontrol |
| `310` | Gözle muayene |
| `361` | Ölçüm |
| `421` | Arıza bulma |
| `520` / `720` | Sökme / takma |
| `920` | Değiştirme (sökme ve takma) |
| `921` | Yenisiyle değiştirme |
| `941` | Resimli parça verisi (IPD) |

Aynı alt sistemde aynı bilgi kodundan ikinci bir DM gerektiğinde sökme kodu (`disassyCode`) `01`, `02` diye artar; örneğin `DA0-20 271` furç ayarı, `DA0-20 271 01` çatal ön yük ayarı.

Her kök sistemin bir "Çalışma ilkesi" DM'i (bilgi kodu 040) var. Arızaların belirtilerine sürücünün arızayı kendi sözleriyle anlatışı da eklenir ("ön frenden demir sürtme sesi geliyor", "pedal boşa dönüyor"); teşhis serbest metni bu söyleyişlerle eşleştirir ve ön ile arka parçadaki aynı arıza ancak bunlarla ayrılır. Söyleyişler betikteki `PHRASINGS` tablosundadır. Betik, her arızanın arıza bulma DM'inin onarım DM'ine götürdüğünü ve iki arızanın aynı belirti kümesini taşımadığını denetler.

Değerler (tork, aşınma sınırları, basınç) bu sınıftaki parçalar için yaygın üretici değerleridir: Shimano bayi el kitapları (balata en az 0,5 mm, disk en az 1,5 mm), Park Tool tork tablosu ve zincir aşınma sınırları (8 vites için %0,75). Parçanın üzerinde ya da kendi el kitabında farklı bir değer varsa o geçerlidir; çatal yağı miktarı gibi modele özgü değerler için DM'ler çatalın el kitabına yönlendirir.

Çizimler (`ICN-…-0000N-…JPG`) modelden `scripts/render_icn.py` ile üretilir; konusu olan parçalar turuncu. Başlıklar `make_content.py`'deki `FIGURES` tablosunda.

## Parça haritası

`map/parts.json`'daki her parçanın `meshNodes` alanı modeldeki düğümleri gösterir. Modelde ayrı düğümü olmayan parçalar (balata, aynalar, makaralar, sibop, göbek rulmanları, çabuk sökme mandalı, çatal keçeleri gibi) içinde bulundukları düğüme bağlı; seçilince o düğüm vurgulanır. `procedures` ve `ipd` alanları CSDB'deki DM'leri, `faults.json`'daki `isolation` ve `repair` alanları arıza bulma ve onarım DM'lerini gösterir.

## Model

`model/product.glb`: dağ bisikleti, 28 düğüm, Draco sıkıştırmalı (~7,8 MB, ~690 bin üçgen).

Kaynak: "Bike", T-FLEX CAD ST (Free), [sketchfab.com/tflexcad](https://sketchfab.com/tflexcad), lisans **CC BY 4.0**. Uygulamada ve `.naya` manifestinin `credits` alanında bu atıf gösterilir.

Kaynak modelde geometri malzemeye göre birleştirilmiş geliyor (bir nesne bisikletin her yerindeki aynı renkli yüzeyleri içeriyor). Parçalara ayırabilmek için şu adımlarla yeniden gruplandı:

```bash
cd templates/src/bisiklet/scripts
blender -b --python split_islands.py -- kaynak.glb islands.json islands.blend
python3 classify.py islands.json groups.json
blender -b islands.blend --python assemble.py -- groups.json gruplu.glb
blender -b --python optimize.py -- gruplu.glb ../model/product.glb
blender -b --python regroup.py -- ../model/product.glb ../model/product.glb
blender -b --python fix_nodes.py -- ../model/product.glb ../model/product.glb
```

1. `split_islands.py`: her nesneyi kopuk parçalara böler (~14 bin adacık).
2. `classify.py`: her adacığı konumuna göre bir parçaya atar. Referans noktaları tekerlek göbekleri ve orta göbek.
3. `assemble.py`: aynı parçaya düşen adacıkları birleştirir, bisikleti zemine oturtur.
4. `optimize.py`: 40 binden fazla yüzü olan parçaları sadeleştirir, Draco ile sıkıştırır.
5. `regroup.py`: orta göbek çevresinde yanlış gruba düşen adacıkları düzeltir (sağ pedal, sağ pedal kolu, aynakol cıvataları) ve ön vites değiştiriciyi kendi düğümüne ayırır.
6. `fix_nodes.py`: model incelemesinde bulunan yanlış atamaları düzeltir. Her düğüm tek başına turuncu çizilerek bakıldı; çabuk sökme mandalları fren düğümlerinde, vites askısı kasette, ön vites değiştiricinin gövdesi kadroda, bir aynakol cıvatası ön vites değiştiricide, sele borusu kelepçesinin cıvatası kadrodaydı. Betik bunları doğru düğüme taşır; kabloları, iç lastikleri, fren disklerini ve orta göbeği kendi düğümlerine ayırır; kaynak modelde iki kez bulunan ve titreşen yüzleri ve alanı olmayan kılcal yüzleri siler.

## Parçalar

Düğüm adlarında nokta yerine alt çizgi var, çünkü three.js düğüm adındaki noktaları siliyor.

| Düğüm | Parça |
| --- | --- |
| `frame` | Kadro |
| `fork` | Yaylı çatal (iç borular, alt bacaklar, keçeler, yay) ve furç |
| `handlebar` | Gidon, gidon boğazı, elcikler, fren ve vites kolları |
| `saddle` | Sele |
| `seatpost` | Sele borusu, başlığı ve kelepçesi |
| `drive_chain` | Zincir |
| `drive_crankset` | Aynalar ve pedal kolları |
| `drive_bottom_bracket` | Orta göbek |
| `drive_pedals` | Pedallar |
| `drive_cassette` | Kaset ve kilit somunu |
| `drive_derailleur` | Arka vites değiştirici, makaralar ve vites askısı |
| `drive_front_derailleur` | Ön vites değiştirici ve kelepçesi |
| `cables_shift` | Ön ve arka vites telleri ve kılıfları |
| `cables_brake` | Ön ve arka fren telleri ve kılıfları |
| `brakes_front`, `brakes_rear` | Kaliper, adaptör ve balatalar |
| `brakes_front_rotor`, `brakes_rear_rotor` | Fren diski |
| `wheel_front_*`, `wheel_rear_*` | `tire` lastik, `tube` iç lastik ve sibop, `rim` jant ve jant bandı, `spokes` teller, `hub` göbek, rulmanlar, çabuk sökme mandalı (arkada serbest çark) |
