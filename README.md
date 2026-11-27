# EmsaProxy iOS

EmsaProxy adalah aplikasi iOS proxy & network toolbox modular yang dibangun menggunakan **SwiftUI** dan **NetworkExtension Framework** (`NEPacketTunnelProvider`).

## Fitur Utama

- **Modular Configuration Engine**: Mengimpor, mengaktifkan, dan mengonfigurasi modul proxy kustom (aturan routing, daftar domain, GeoIP).
- **JavaScript Scripting Runtime**: Eksekusi hook skrip dinamis via native `JavaScriptCore` untuk memodifikasi request dan response jaringan.
- **MITM & HTTPS Rewriting**: Dukungan hostname injection untuk dekripsi dan inspeksi lalu lintas lokal.
- **Modern SwiftUI Dashboard**: Tampilan visual status koneksi, mode perutean (Rule / Global / Direct), dan statistik aturan aktif.
- **Virtual TUN Interface**: Menangkap lalu lintas L3 di subnet virtual `198.18.0.1` tanpa membebani memori perangkat.

## Cara Build & Sideload

File `.ipa` dikompilasi secara otomatis melalui **GitHub Actions** (`macos-14` runner):
1. Buka tab **Actions** di repositori ini.
2. Unduh artifact `EmsaProxy-IPA` atau ambil dari tab **Releases**.
3. Sideload ke iPhone menggunakan **TrollStore** (permanen) atau **Sideloadly / AltStore** (self-signed).
