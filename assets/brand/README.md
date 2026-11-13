# NAYA marka dosyaları

## Logo

| Dosya | Kullanım |
|---|---|
| `naya-emblem-dark.svg` | Koyu zemin üzerinde amblem |
| `naya-emblem-light.svg` | Açık zemin üzerinde amblem |
| `naya-wordmark.svg` | NAYA yazısı, rengi `currentColor` ile gelir |
| `naya-wordmark-dark.svg` | Koyu zemin üzerinde NAYA yazısı (README gibi `currentColor` çalışmayan yerler için) |
| `naya-wordmark-light.svg` | Açık zemin üzerinde NAYA yazısı |

Renkler: zemin `#0A0C0F`, açık yüz `#ECEFF3`, koyu yüz `#7C838D`, vurgu `#8DB8F2` (açık temada `#3D74C9`).

## Açılış

`splash/naya-splash-1080x1920.mp4` · 4.8 sn, 60 fps, sessiz. Parçalar taranır, tepe bulunur, gövde kilitlenir ve animasyon logoyla biter. Uygulamada `video_player` ile bir kez oynatılır, bitince kütüphane ekranına geçilir. Arka plan rengi `#0A0C0F` olduğu için Android'in yerel açılış ekranı da bu renkte olmalı.

## Yükleniyor

`loading/` · 1.6 sn kesintisiz döngü, şeffaf arka plan.

| Dosya | Nerede |
|---|---|
| `naya-loading_512x512.webp` | Flutter: `Image.asset` animasyonlu WebP'yi web ve Android'de oynatır |
| `naya-loading_512x512.webm` / `.mov` | Web sayfasında `<video>` ile (Safari için `.mov`) |
| `naya-loading-light_*` | Açık tema |
| `naya-loading-still_512x512.svg` / `.png` | Hareket azaltma açıkken gösterilecek sabit kare |
