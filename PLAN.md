# NAYA proje planı

NAYA, S1000D teknik dokümanlarını 3D modellerle birleştiren bir bakım ve arıza teşhis uygulaması. Kullanıcı bir aracı (örneğin 1996 model bir Corolla) açar, modelin üzerinde parçaları gezer, sorununu sohbet kutusuna yazar. Sistem parçaları tarar, en olası arızalı parçayı bulur, modeli parçalarına ayırıp o parçaya yaklaşır. Parçaya dokununca ne işe yaradığı, neden bozulduğu ve nasıl tamir edildiği açılır.

Uygulamanın iki tarafı var:

- Hazır şablonlar: bizim hazırladığımız araçlar. Corolla 1996 (AE101), bir bisiklet, bir tank ve bir savaş uçağı.
- Dışarıdan içe aktarma: kullanıcı kendi S1000D dosyalarını `.zip` olarak yükler, uygulama tarar ve kütüphaneye ekler. Bu içeriklerin hazır 3D modeli olmadığı için şematik bir görünüm kullanılır.

Her şey kendi dosya formatımız `.naya` ile taşınır.

Son teslim 13 Aralık 2026. Çalışma 2 Kasım'da başlıyor, hedefimiz 20 Kasım'da bitirmek. Kalan süre tampon.

Görevlerin ayrıntısı, sıra takibi ve öğrenme notları Notion'daki NAYA sayfasında tutuluyor. Bu dosya genel çerçeveyi verir.

## Platformlar

Web ve Android. Flutter ile tek kod tabanı.

## Dizin yapısı

```
naya/
├── apps/
│   ├── naya/            Flutter uygulaması (web + Android)
│   └── naya_api/        Dart backend
├── packages/
│   ├── naya_format/     .naya okuma, yazma, doğrulama
│   ├── naya_s1000d/     S1000D ayrıştırıcı (DM, PM, DML, ICN, SNS, IPD)
│   ├── naya_diagnosis/  teşhis akışı ve olasılık birleştirme
│   └── viewer_web/      three.js ile yazılmış 3D görüntüleyici (TypeScript)
├── tools/naya_cli/      naya pack | unpack | validate | import
├── templates/src/       şablonların kaynak dosyaları
├── schemas/             JSON Schema dosyaları
└── docs/
```

Dart paketleri pub workspace olarak tek repoda duruyor. `naya_format` ve `naya_s1000d` saf Dart, yani hem uygulama hem backend hem de CLI aynı kodu kullanıyor.

### Flutter içindeki katmanlar

```
apps/naya/lib/
├── app/        başlangıç, yönlendirme, tema, bağımlılıklar
├── pages/      ekranlar
├── widgets/    ekranları oluşturan büyük bloklar (viewer paneli, sohbet paneli, parça kartı)
├── features/   kullanıcı eylemleri (teşhis et, içe aktar, dışa aktar, soru sor)
├── entities/   ürün, parça, arıza, data module
└── shared/     arayüz bileşenleri, API istemcisi, yardımcılar
```

Bir katman sadece kendinden aşağıdakileri import edebilir. Bu kural lint ile kontrol ediliyor.

## .naya formatı (v1)

`.naya` bir ZIP dosyası. İçinde:

```
araç.naya
├── mimetype             application/vnd.naya+zip (ilk kayıt, sıkıştırılmamış)
├── naya.json            manifest
├── csdb/                orijinal S1000D dosyaları, hiç değiştirilmeden
├── model/
│   ├── product.glb      ana model
│   └── detail/*.glb     ağır iç detaylar, ihtiyaç olunca yüklenir
├── map/
│   ├── parts.json       parça ağacı, mesh eşleşmesi, prosedür bağlantıları
│   ├── faults.json      belirtiler ve arıza modları
│   ├── zones.json       bölgeler
│   └── hotspots.json    2D çizim ile 3D parça eşleşmesi
├── media/               fotoğraf ve videolar
└── ai/chunks.jsonl      arama için bölünmüş metin (isteğe bağlı)
```

Temel kural: S1000D içeriği olduğu gibi kalır, bizim eklediğimiz her şey `map/` altında ayrı durur. Böylece dosya her zaman tekrar saf S1000D olarak dışa aktarılabilir.

`parts.json` içindeki `parent` alanı tek bir montaj ağacı kurar. Aynı ağaç üç yerde kullanılıyor: parçalara ayırma animasyonu, teşhiste sistem ve parça seçimi, tarama sırası.

Modeller glTF (`.glb`), geometri meshopt ile, dokular webp ile sıkıştırılır. Şablon başına hedef 50 MB'ın altı. İçerik dili şimdilik Türkçe.

## Görüntüleyici

Kendi küçük three.js modülümüz. Web'de iframe, Android'de WebView içinde çalışıyor, iki platformda aynı kod. Flutter ile arasında küçük bir mesaj köprüsü var:

- Flutter'dan görüntüleyiciye: `load`, `scan`, `highlight`, `explode`, `focus`, `isolate`, `xray`
- Görüntüleyiciden Flutter'a: `onPartTap`

Model sayfasında üstte model, altta sohbet var. Kullanıcı modeli elle döndürebilir, parçalarına ayırabilir, tek parçayı ayırıp inceleyebilir. Sohbetten bir soru gelince tarama başlar, model açılır ve kamera bulunan parçaya gider.

## Backend

`naya_api`, Dart ile yazılmış küçük bir servis. Görevleri:

- kullanıcı hesapları ve oturumlar
- kütüphane ve `.naya` dosyalarının saklanması
- sohbet ve teşhis geçmişi
- AI isteklerinin aracılığı (anahtar sunucuda şifreli durur)
- Flutter web derlemesini sunmak

Veritabanı SQLite (drift ile), dosyalar kalıcı diskte. Yayın ortamı Komuta. Docker sadece orada derleme için kullanılıyor; yerelde Docker gerekmiyor.

Yerelde çalıştırmak:

```bash
cd apps/naya_api && dart run
```

```bash
cd apps/naya && flutter run -d chrome
```

Ortam değişkenleri: `NAYA_API_URL`, `DATABASE_PATH`, `STORAGE_DIR`, `NAYA_MASTER_KEY`, `NAYA_ADMIN_EMAIL`, `NAYA_ADMIN_PASSWORD`.

## Yapay zekâ ve teşhis

Kullanıcı kendi OpenRouter anahtarını uygulama içinden girer. Model listesi otomatik çekilir, her rol için farklı model seçilebilir.

- Sohbet: varsayılan DeepSeek Flash
- Karar: varsayılan Jev (TypeSafe). Metin üretmez, seçeneklere kalibre olasılık döndürür.

Teşhis adımları:

1. Jev mesajın niyetini sınıflar (teşhis, tamir, parça bilgisi, genel soru).
2. Belirtiler yeterli mi diye sorar. Yetersizse sohbet modeli netleştirici soru sorar.
3. Önce sistem seçilir (motor, fren, şanzıman...), sonra en olası sistemlerin parçaları arasından parça seçilir. Seçeneklerde her zaman "hiçbiri" de var.
4. En olası parçanın arıza modu ve ilgili S1000D prosedürü bulunur.
5. Sonuç görüntüleyicide oynatılır, sohbet modeli açıklar ve kaynak dokümanları gösterir.

En yüksek olasılık %35'in altındaysa yakınlaştırma yapılmaz, ek soru sorulur. Her teşhis kaydedilir.

Doküman araması için SQLite FTS5 kullanılıyor. Parçayla doğrudan bağlantılı prosedürler her zaman önce geliyor.

## Hesaplar

E-posta ve şifre (Argon2id). Oturum için rastgele token, veritabanında özeti tutulur. Giriş yapmadan şablonlar ve 3D model gezilebilir; sohbet, teşhis ve içe aktarma için giriş gerekir.

## Tasarım

Koyu ve açık tema, cihaz ayarına göre. Vurgu renkleri platin ve çelik mavi. Hedef çıta yüksek: her ekran hem tek başına hem de diğer ekranlarla birlikte değerlendirilip iyileştiriliyor. Hareket dili üç şeyden oluşuyor: tarama, parçalara ayrılma ve kamera geçişi.

## Takvim

| Adım | Tarih | Konu |
|---|---|---|
| 1 | 2-4 Kasım | Kurulum, .naya formatı, ilk tasarım taslağı, CI |
| 2 | 5-7 Kasım | S1000D ayrıştırıcı, görüntüleyici, uygulama iskeleti |
| 3 | 9-11 Kasım | Bisiklet şablonu, görüntüleyici efektleri, backend, model ekranı |
| 4 | 12-14 Kasım | Yapay zekâ ve teşhis, ayarlar ve sohbet, yayına alma |
| 5 | 16-18 Kasım | Corolla, tank ve uçak şablonları, içe aktarma |
| 6 | 19-20 Kasım | Cila, performans, test, rapor ve sunum |

21 Kasım ile 13 Aralık arası tampon.

## Çalışma düzeni

İki kişiyiz: Mustafa ve Enes. Sırayla çalışıyoruz. Her adımın görevleri iki kişiye bölünmüş durumda (1A, 1B, 1C...). Biri kendi kısmını bitirince Notion'daki devir sayfasını günceller ve sıra diğerine geçer.

- `main` korumalı. Herkes kendi dalında çalışır (`mustafa/...`, `enes/...`).
- Değişiklikler PR ile gelir, diğer kişi bakıp onaylar.
- PR'larda analiz ve testler otomatik çalışır. `main`'e giren her şey web ve APK olarak derlenir ve yayına alınır.
- İsimler İngilizce, yorumlar ve dokümanlar Türkçe. Önce okunabilirlik.

## Lisanslar

Kod, repo açık olduğunda MIT lisansıyla yayınlanacak. Kullandığımız 3D modellerin çoğu CC-BY; her şablonun `naya.json` dosyasında kaynak ve yazar bilgisi var, uygulama içinde de gösteriliyor.
