# SIMasjid - Sistem Informasi Masjid Digital

**SIMasjid** adalah aplikasi *Digital Signage* berbasis Flutter yang dirancang khusus untuk menampilkan informasi penting di layar TV Masjid. Aplikasi ini menggabungkan fungsi jadwal sholat akurat, media informasi visual, dan integrasi *Smart System* untuk memodernisasi manajemen informasi masjid.

Dibuat oleh: **YUSUF FAISAL | DEVLOVER | KORNET INTER MEDIA | 2026**

---

## 🌟 Fitur Unggulan (Versi Terbaru)

### 1. 🌐 Kontrol & Aksesibilitas Total
*   **Web Admin Intuitif:** Kontrol penuh aplikasi melalui browser di HP/Laptop. Cukup hubungkan ke WiFi yang sama dengan TV (`http://<ip-tv>:8088`).
*   **Akses Remote (SSH Tunnel):** Kelola konten masjid dari mana saja di seluruh dunia. Fitur ini membuat *tunnel* aman dari TV ke server (VPS) Anda, memungkinkan akses ke Web Admin melalui alamat publik.
*   **Smart IoT:** Integrasi dengan perangkat seperti ESP32/Arduino untuk mengontrol perangkat eksternal (misal: otomatis menyalakan & mematikan amplifier saat Murottal atau kajian diputar).
*   **Jadwal Power TV:** Atur TV untuk menyala dan masuk mode *sleep* secara otomatis sesuai jadwal untuk menghemat energi.

### 2. 🎵 Automasi Audio & Media Cerdas
*   **Jadwal Murottal Lanjutan:**
    *   Putar Murottal otomatis sebelum waktu sholat.
    *   **Sumber Fleksibel:** Pilih dari file lokal di playlist, atau streaming surah dari internet (API).
    *   **Acak & Ulang:** Opsi untuk memutar file/surah secara acak atau mengulanginya.
*   **Automasi Tarhim & Adzan:** Putar audio Tarhim dan Adzan secara otomatis pada jadwal yang ditentukan sebelum waktu sholat.
*   **Playlist Media Cerdas:**
    *   Buat playlist berisi video, gambar, dan audio.
    *   **Impor Otomatis dari Folder:** Tambahkan semua media dari sebuah folder ke playlist hanya dengan satu klik, baik dari Web Admin maupun langsung di perangkat.
*   **Jadwal Tayang Media:** Jadwalkan pemutaran video (kajian, dll.) atau gambar (poster) pada jam dan hari tertentu.

### 3.  Manajemen Konten Dinamis
*   **Jadwal Petugas:** Tampilkan profil (foto, nama, peran) dan jadwal untuk Imam, Khatib, Muadzin, dll. Layar akan otomatis menampilkan petugas yang terjadwal pada hari itu.
*   **Slide Informasi:** Tampilkan pengumuman, laporan kas, atau info lainnya dalam bentuk slide yang menarik dan berganti otomatis.
*   **Agenda Kegiatan:** Informasikan acara mendatang dengan tampilan kalender yang jelas.
*   **Hadis & Teks Berjalan:** Tampilkan hadis harian (dari API atau input manual) dan running text yang mudah diubah melalui Web Admin.

### 4. 🎨 Kustomisasi Tampilan Penuh
*   **Tema & Warna:** Pilih dari preset tema yang indah (misal: Emerald Gold, Sapphire Cyan) atau tentukan warna primer dan aksen Anda sendiri.
*   **Logo Masjid:** Tampilkan logo masjid Anda di pojok layar, lengkap dengan opsi animasi.
*   **Kustomisasi Font & Teks:** Ubah jenis font, ukuran, dan warna untuk setiap elemen teks di layar.
*   **Efek Transisi:** Pilih efek transisi antar layar (Fade, Slide, Zoom) untuk pengalaman visual yang lebih halus.

### 5. 🕌 Jadwal Sholat & Kalender Akurat
*   **Sumber API:** Jadwal sholat akurat berdasarkan lokasi dari API Kemenag (MyQuran) atau Al-Adhan.
*   **Mode Offline:** Dukungan input jadwal manual jika tidak ada koneksi internet.
*   **Kalender Hijriyah & Imsakiyah:** Tampilan tanggal Hijriyah dengan koreksi, serta layar khusus Imsakiyah Ramadhan.
*   **Notifikasi Waktu Sholat:** Overlay layar penuh saat Adzan, hitung mundur menuju Iqomah, dan mode khusus Khutbah Jumat.

---

## 📺 Tampilan Layar (Screen Flow)

Aplikasi berjalan dalam sebuah siklus rotasi layar yang cerdas untuk menjaga konten tetap segar dan relevan.

1.  **Dashboard Utama:** Tampilan default yang menampilkan jam, tanggal Masehi & Hijriyah, jadwal sholat 5 waktu, dan teks berjalan.
2.  **Layar Informasi:** Rotasi otomatis antara:
    *   **Slide Informasi:** Pengumuman dan info umum.
    *   **Agenda Kegiatan:** Jadwal acara mendatang.
    *   **Jadwal Petugas:** Profil Imam/Khatib/Muadzin yang bertugas hari itu.
    *   **Hadis Harian:** Tampilan hadis dengan auto-scroll.
    *   **Imsakiyah:** Layar khusus yang aktif selama bulan Ramadhan.
    *   **Media Slideshow:** Memutar item dari playlist media (gambar/video singkat).
3.  **Layar Prioritas (Otomatis):**
    *   **Media Terjadwal:** Memutar video/gambar kajian pada waktunya.
    *   **Murottal/Tarhim:** Memutar audio secara otomatis sebelum adzan.
    *   **Notifikasi Adzan & Iqomah:** Overlay layar penuh yang akan menimpa semua tampilan lain saat waktu sholat tiba.

---

## 🛠️ Perangkat yang Didukung

Aplikasi ini dioptimalkan untuk layar besar (TV) dengan orientasi **Landscape**.

*   **Perangkat Utama:** Android TV / Google TV (Sony, TCL, Xiaomi TV, dll).
*   **Alternatif:** Android TV Box (STB) untuk mengubah TV biasa menjadi smart display.
*   **Lainnya:** Tablet atau Smartphone Android (wajib dalam mode landscape).

**Spesifikasi Minimum:**
*   OS: Android 5.0 (Lollipop) ke atas.
*   RAM: 2GB (Disarankan).
*   Penyimpanan: 100MB (plus ruang untuk aset video/gambar).
*   Koneksi: WiFi/LAN (diperlukan untuk Web Admin dan fitur online lainnya).

---

## 🚀 Cara Instalasi & Penggunaan

1.  **Instalasi:** Pasang file `.apk` pada perangkat Android TV/Box.
2.  **Koneksi:** Pastikan perangkat TV terhubung ke jaringan WiFi/LAN yang sama dengan HP atau Laptop Anda.
3.  **Pengaturan Awal:**
    *   Buka Aplikasi.
    *   Masuk ke menu pengaturan rahasia dengan menekan tombol **OK / D-Pad Center** pada remote sebanyak **3 kali**.
    *   Lakukan pengaturan dasar seperti Lokasi untuk jadwal sholat.
4.  **Akses Web Admin:**
    *   Di menu pengaturan, lihat **IP Address** perangkat TV Anda (misal: `192.168.1.10`).
    *   Buka browser di HP/Laptop Anda, lalu ketik alamat `http://<ip-address-tv>:8088` (contoh: `http://192.168.1.10:8088`).
    *   Sekarang Anda bisa mengelola semua konten dari antarmuka web yang nyaman.

---

*© 2026 YUSUF FAISAL | DEVLOVER | KORNET INTER MEDIA. Free for non-commercial use in Mosques.*
"# simasjid" 
"# simasjid" 
