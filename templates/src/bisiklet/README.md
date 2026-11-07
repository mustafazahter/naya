# Bisiklet şablonu

Önden süspansiyonlu dağ bisikleti: üç aynalı aynakol ve ön vites değiştirici, 8 dişli kaset ve arka vites değiştirici (3 × 8 = 24 vites), iki tekerlekte telle çalışan disk fren, çabuk sökme mandallı göbekler. DM'ler ve parça haritası bu modele göre yazıldı.

```
bisiklet/
├── naya.json      manifest (bütünlük özetleri paketlerken eklenir)
├── csdb/          S1000D Issue 5.0: 26 DM, PM, DML, 5 çizim
├── map/           parts.json (39 parça), faults.json (29 arıza), zones.json, hotspots.json
├── model/         product.glb
└── scripts/       modeli hazırlayan ve çizimleri üreten betikler
```

Paketleme ve doğrulama (repo kökünden):

```bash
dart run tools/naya_cli/bin/naya.dart pack templates/src/bisiklet -o templates/dist/bisiklet.naya
dart run tools/naya_cli/bin/naya.dart validate templates/dist/bisiklet.naya
```

`tools/naya_cli/test/templates_test.dart` aynı kontrolü her CI çalışmasında yapar.

## S1000D içeriği

Model kodu `NAYABIKE`, sorumlu firma kodu `NAYA0`, dil `tr-TR`. Dosyalar resmi S1000D 5.0 XML şemalarından geçiyor.

| SNS | Sistem |
| --- | --- |
| `D00` | Bisiklet (genel tanım, parça kataloğu, iş kuralları) |
| `DA0` | Kadro, çatal ve kumanda (`-20` çatal ve furç, `-40` sele) |
| `DA1` | Aktarma organları (`-10` zincir, `-20` aynakol ve ön vites, `-30` kaset, `-40` arka vites, `-50` pedallar) |
| `DA2` | Fren sistemi (`-10` balatalar, `-20` diskler) |
| `DA3` | Tekerlekler (`-10` lastik ve iç lastik) |

Kullanılan bilgi kodları (S1000D Chap 8.4):

| Kod | Anlamı |
| --- | --- |
| `022` | İş kuralları (BREX); SNS başlıkları burada |
| `040` | Tanım |
| `241` | Yağlama |
| `271` | Ayar |
| `300` | Muayene ve kontrol |
| `310` | Gözle muayene |
| `361` | Ölçü kontrolü |
| `421` | Arıza bulma |
| `520` / `720` | Sökme / takma |
| `920` | Değiştirme (sökme ve takma) |
| `921` | Yenisiyle değiştirme |
| `941` | Resimli parça verisi (IPD) |

Çizimler (`ICN-…-0000N-…JPG`) modelden `scripts/render_icn.py` ile üretilir; konusu olan parçalar turuncu.

## Parça haritası

`map/parts.json`'daki her parçanın `meshNodes` alanı modeldeki düğümleri gösterir. Modelde ayrı düğümü olmayan parçalar (balata, disk, furç, iç lastik, vites ve fren telleri, ön vites değiştirici) içinde bulundukları düğüme bağlı; seçilince o düğüm vurgulanır. `procedures` ve `ipd` alanları CSDB'deki DM'leri, `faults.json`'daki `isolation` ve `repair` alanları arıza bulma ve onarım DM'lerini gösterir.

## Model

`model/product.glb`: dağ bisikleti, 20 parça, Draco sıkıştırmalı (~8 MB, ~695 bin üçgen).

Kaynak: "Bike", T-FLEX CAD ST (Free), [sketchfab.com/tflexcad](https://sketchfab.com/tflexcad), lisans **CC BY 4.0**. Uygulamada ve `.naya` manifestinin `credits` alanında bu atıf gösterilir.

Kaynak modelde geometri malzemeye göre birleştirilmiş geliyor (bir nesne bisikletin her yerindeki aynı renkli yüzeyleri içeriyor). Parçalara ayırabilmek için şu adımlarla yeniden gruplandı:

```bash
cd templates/src/bisiklet/scripts
blender -b --python split_islands.py -- kaynak.glb islands.json islands.blend
python3 classify.py islands.json groups.json
blender -b islands.blend --python assemble.py -- groups.json gruplu.glb
blender -b --python optimize.py -- gruplu.glb ../model/product.glb
```

1. `split_islands.py`: her nesneyi kopuk parçalara böler (~14 bin adacık).
2. `classify.py`: her adacığı konumuna göre bir parçaya atar. Referans noktaları tekerlek göbekleri ve orta göbek.
3. `assemble.py`: aynı parçaya düşen adacıkları birleştirir, bisikleti zemine oturtur.
4. `optimize.py`: 40 binden fazla yüzü olan parçaları sadeleştirir, Draco ile sıkıştırır.

## Parçalar

Düğüm adlarında nokta yerine alt çizgi var, çünkü three.js düğüm adındaki noktaları siliyor.

| Düğüm | Parça |
| --- | --- |
| `frame` | Kadro |
| `fork` | Amortisörlü çatal |
| `handlebar` | Gidon, elcikler, fren ve vites kolları |
| `saddle` | Sele |
| `seatpost` | Sele borusu |
| `drive_chain` | Zincir |
| `drive_crankset` | Aynakol ve pedal kolları |
| `drive_pedals` | Pedallar |
| `drive_cassette` | Arka dişli (kaset) |
| `drive_derailleur` | Arka vites değiştirici |
| `brakes_front`, `brakes_rear` | Disk ve kaliper |
| `wheel_front_*`, `wheel_rear_*` | Lastik, jant, teller, göbek |
