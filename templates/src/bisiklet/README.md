# Bisiklet şablonu

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
