# EVRRY brand assets

Brand colours: navy `#0A1A3F`, blue `#2F6BFF` / `#1F4FE0`, accent cyan `#3DDCFF`.
Every image is generated from the vector masters in `source/`. To regenerate after editing an SVG, run:
`powershell -ExecutionPolicy Bypass -File tools\build.ps1` (requires Chrome or Edge).

| # | Asset | File |
|---|-------|------|
| 1 | Adaptive foreground 432 (E inside the centre 264 px) | `android/ic_launcher_foreground.png` / `.svg` |
| 2 | Adaptive background 432 | `android/ic_launcher_background.png` / `.svg` |
| 3 | Monochrome themed icon 432 | `android/ic_launcher_monochrome.png` / `.svg` |
| 4 | Notification icon 24 dp | `android/res/drawable/ic_stat_evrry.xml` (vector) + `drawable-{m,h,xh,xxh,xxxh}dpi/ic_stat_evrry.png` (24/36/48/72/96) |
| 5 | Play icon 512, opaque, square | `playstore/play-icon-512.png` |
| 6 | Play feature graphic 1024×500 | `playstore/feature-graphic-1024x500.png` |
| 7 | iOS master 1024, 24-bit, no alpha | `ios/AppIcon.appiconset/AppIcon-1024.png` |
| 8 | iOS 18 dark + tinted | `ios/AppIcon.appiconset/AppIcon-1024-dark.png`, `-tinted.png` |
| 9 | Favicon 16/32/48 | `web/favicon.ico` (+ `favicon.svg`, individual PNGs) |
| 10 | Apple touch 180 | `web/apple-touch-icon.png` |
| 11 | PWA 192 / 512 | `web/icon-192.png`, `web/icon-512.png` |
| 12 | Maskable 512 (E inside the 80% safe zone) | `web/icon-maskable-512.png` |
| 13 | Open Graph 1200×630, < 300 KB | `marketing/og-image-1200x630.jpg` |
| 14 | Story / referral card 1080×1920 | `marketing/story-referral-card-1080x1920.png` (template: `source/story-card.svg`, replace `YOURCODE`) |
| 15 | Horizontal logo, navy + white | `marketing/evrry-logo-{navy,white}.svg` and `-1200.png` |

Drop-in config:
- Android: copy `android/res/` into `app/src/main/res/`. Set `android:icon="@mipmap/ic_launcher"` and `android:roundIcon="@mipmap/ic_launcher_round"`.
- iOS: replace the project's `AppIcon.appiconset` with `ios/AppIcon.appiconset`.
- Web: upload `web/` to the site root and paste `web/head-snippet.html` into `<head>`.
