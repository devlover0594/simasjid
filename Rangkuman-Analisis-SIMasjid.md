# ANALISIS LENGKAP APLIKASI "SIMASJID"

**Proyek:** `C:\Users\Yusuf Faisal\Documents\Project\FluterProject\simasjid`
**Tanggal analisis:** 12 November 2026 · **Diperbarui:** 13 November 2026 (pasca perapihan kode)
**Skala:** 50 file Dart, ±14.107 baris di `lib/` (sebelum perapihan: 54 file, ±15.639 baris)

---

## 0. STATUS PERBAIKAN (patokan development)

Proyek kini berada di bawah **Git**. Riwayat & detail perubahan ada di `CHANGELOG.md` (root proyek).
Ringkasan tahap perapihan kode yang sudah dikerjakan dan diverifikasi `flutter analyze` = **0 issue**:

| Tahap | Isi | Dampak analyzer |
|---|---|---|
| A | Hapus dead code (unused import/field/var, `default:` unreachable, `catch(e,st)`) + style lint | 89 → 73 (0 warning) |
| B | Migrasi deprecation: `withOpacity`→`withValues`, `Color.value`→`toARGB32`, `onPopInvoked`→`onPopInvokedWithResult` | 73 → 11 (0 deprecation) |
| C | Guard `context.mounted` pada 11 titik `use_build_context_synchronously` | 11 → 0 (bersih) |
| D | `dispose()` controller pada 6 halaman settings + `TextFormField` untuk field dinamis | 0 (tetap bersih) |
| E | Hapus 5 file yatim `web_admin/` + kelas `ScrollingHadith` | 0 (type-check lolos) |
| F | Mulai restrukturisasi god-class: ekstraksi `HijriCalculator` ke `lib/services/` | 0 (diverifikasi 4.005 kasus) |
| G1 | **Bug P2:** crash-proof `_updateTime` (try/catch per cek) + helper `_minutesFromHm` (ganti `int.parse` rawan) + propagasi `surah_number` murottal | 0 |
| G2 | **Bug P2:** pemicu jadwal → pola *due + `_firedToday`* (bukan `second==0`), pencocokan per-menit, **audio adzan nyata** via `audioplayers` | 0 |
| G3 | **Bug P2:** guard `mounted` pada error callback `MediaOverlay` + dukungan gambar online (`Image.network`) | 0 |

`main.dart` turun dari 4.047 → **±4.000 baris**. **Status P2 (bug audio/media/jadwal): SELESAI** — lihat §11.2 (B1–B7 diperbaiki, B8 dibiarkan). **Belum dikerjakan**: P1 Keamanan Web Admin (ditunda ke akhir sesuai permintaan), lanjutan P3 (pecah god-class penuh, `com.example`→package id, signing release, PIN Settings, `assets/elements/bgnotif.png`).

---

## 1. RINGKASAN EKSEKUTIF

**SIMasjid (Sistem Informasi Masjid Digital)** adalah aplikasi **digital signage / kiosk** berbasis Flutter yang ditargetkan untuk **Android TV / TV Box** (orientasi landscape, kanvas tetap 1280×720). Aplikasi menampilkan siklus layar otomatis di TV masjid: dashboard jam + jadwal sholat, slide informasi, agenda, hadis, jadwal petugas, imsakiyah Ramadhan, dan media — dengan overlay layar penuh saat adzan/iqomah/khutbah serta pemutaran otomatis murottal/tarhim/media terjadwal.

**Cakupan fitur utama:**
1. **Jadwal sholat** — API MyQuran / AlAdhan / EQuran.id, mode manual offline, cache di SharedPreferences, tanggal Hijriah inkremental dari "anchor" + koreksi (`hijri_adjustment`, default −2).
2. **Automasi audio** — Tarhim & Murottal per waktu sholat (file lokal/playlist/streaming CDN equran.id, acak & loop), dihentikan sebelum adzan; adzan memicu rantai notifikasi: `adzan → (countdown → iqomah → sholat)` atau jalur Jumat `adzan → khutbah → sholat`.
3. **Media** — playlist (gambar/video/audio/youtube*) + jadwal tayang per hari/jam (*youtube belum diimplementasi, hanya placeholder).
4. **Konten dinamis** — slide, running text, hadis (API + manual), agenda, profil & jadwal petugas (imam/khatib/muadzin) dengan layar otomatis saat ada acara.
5. **Web Admin** — HTTP server `0.0.0.0:8088` tanpanya tanpa autentikasi; seluruh panel HTML/CSS/JS dibangun dari string Dart (`lib/web_admin/`), 25 rute endpoint untuk CRUD semua konten.
6. **Smart IoT** — trigger relay ESP32/Arduino (`GET http://<ip>/on|/off`) untuk amplifier otomatis, plus polling status.
7. **Power TV** — jadwal nyala/tidur layar via MethodChannel Android (`setScreenPower`), mendukung jendela lintas tengah malam.
8. **Remote access** — modul SSH reverse tunnel (`dartssh2`) sudah ditulis **tapi tidak pernah dirangkai** ke aplikasi (dead feature; form Web Admin-nya selalu berbalas "sukses" palsu).
9. **Akses rahasia** — Settings di TV dibuka dengan menekan OK/D-pad 3× pada header (tanpa PIN).

**Kualitas umum:** aplikasi berfungsi dan kaya fitur, tetapi seluruh logika inti menumpuk di **satu State "god-class" ±3.400 baris** di `main.dart`, persistensi lewat ±45 key SharedPreferences, serialisasi via `Map<String,dynamic>` ad-hoc, dan **temuan keamanan serius** (server admin tanpa auth, mutasi via GET, XSS di panel admin, reboot perangkat). `flutter analyze`: **0 issue** (sebelum perapihan: 0 error, 11 warning, 74 info). Dead code yatim (±7 file/module) sudah dibersihkan — lihat §0.


## 2. STRUKTUR PROYEK & TECH STACK

### 2.1 Peta file `lib/` (baris)

| Kelompok | File | Baris | Peran |
|---|---|---|---|
| **Core** | `main.dart` | 3.595 | Entry point + seluruh state/scheduler/server/web widget (d/hapus dead code & ekstraksi HijriCalculator) |
| | `services/hijri_calculator.dart` | ±60 | Kalkulasi Hijriah inkremental (baru, hasil ekstraksi god-class) |
| | `api_repository.dart` | 525 | 9 endpoint API jadwal/hijriah/hadis/imsakiyah |
| | `ssh_tunnel_manager.dart` | 133 | Reverse SSH tunnel (dartssh2) — **tidak dirangkai** |
| **Layar TV** | `infoscreen.dart` | 285 | Slide informasi (carousel) |
| | `performerscreen.dart` | 509 | Jadwal petugas + datepicker |
| | `hadithscreen.dart` | 440 | `IdleScreen` — hadis auto-scroll |
| | `imsakiyahscreen.dart` | 440 | Tabel imsakiyah Ramadhan |
| | `eventscreen.dart` | 305 | Grid agenda |
| | `notifoverlay.dart` | 111 | Overlay adzan/iqomah fullscreen |
| | `mediaoverlay.dart` | 277 | Pemutar gambar/video/audio |
| **Pengaturan** | `settings.dart` + 16 file `settings/` | ±4.190 | Halaman setup (dibuka via 3× tap) |
| **Web Admin** | `web_admin_html.dart` + 24 file `web_admin/` | ±3.100 | Panel admin HTML/JS per section |
| **Models** | `models/slide_item.dart` (17), `models/murottal_schedule.dart` (±90) | | Class data |

### 2.2 Dependency (pubspec.yaml v0.1.0, SDK Dart ^3.10.8)

| Paket | Versi terkunci | Kegunaan |
|---|---|---|
| `shared_preferences` | 2.5.5 | SATU-SATUNYA persistensi (±45 key) |
| `http` | 1.6.0 | API eksternal + trigger relay IoT |
| `video_player` | 2.11.1 | Pemutaran video media |
| `just_audio` 0.9.46 + `audioplayers` 6.7.1 | **dua engine audio sekaligus** | murottal/streaming vs tarhim/adzan |
| `dartssh2` | 2.22.0 (pin) | SSH tunnel (modul tak terpakai) |
| `mime` | | parsing multipart upload web admin |
| `file_picker`, `path_provider`, `permission_handler`, `device_info_plus`, `uuid`, `intl`, `flutter_analog_clock` | | upload file, izin storage, ID pairing, dsb |

`dependency_overrides: path_provider_android 2.2.23`. Aset: tema default (`assets/themes/default/` 9 gambar) + `assets/audio/tarhim.mp3` (9,3 MB) & `adzan.mp3` (2,3 MB).

### 2.3 Android

- **Package: `com.example.simasjid`** — masih placeholder `com.example` (juga di MethodChannel `com.example.simasjid/power`).
- Izin: `INTERNET, WAKE_LOCK, ACCESS_NETWORK_STATE, READ/WRITE/MANAGE_EXTERNAL_STORAGE`; `usesCleartextTraffic=true`.
- `MainActivity`: landscape, `singleTop`, launcher ganda **LAUNCHER + LEANBACK_LAUNCHER** + `android:banner` (Android TV).
- Release **ditandatangani debug key** — belum siap produksi; ABI hanya `arm64-v8a`.


## 3. ARSITEKTUR & ALUR APLIKASI

### 3.1 Model arsitektur

```
main() ─► MainApp (paksa landscape, MaterialApp id_ID)
            └─► KioskScreen ─► _KioskScreenState  ◄── "god-class" ±3.400 baris
                    ├─ 5 Timer: clock 1 dtk, notif, media-end, hadis, rotasi layar
                    ├─ HttpServer :8088  ─► generateAdminHtml(web_admin/*)
                    ├─ PrayerTimeService ─► ApiRepository (myquran/aladhan/equran)
                    ├─ MethodChannel 'power' (sleep TV)   ├─ http GET relay IoT
                    └─ SharedPreferences ⇄ semua fitur (sumber kebenaran tunggal)

Settings (3× tap header) ─► SettingsScreen (IndexedStack 15 halaman) ─ tulis prefs
Kembali dari settings ─► _loadSettings() penuh ─► restart semua timer/rotasi
```

- **Tidak ada** state management (Provider/Riverpod/Bloc), tidak ada database, tidak ada named routes. Semua layar TV dirender SATU `Stack` 1280×720 yang di-`FittedBox` ke ukuran layar; navigasi antar layar = `_screenIndex` integer + `AnimatedSwitcher` 800 ms (fade/slide/zoom).
- Data antar modul mengalir lewat **prefs** (bukan callback/stream). Perubahan dari Web Admin memicu `_loadSettings()` penuh.

### 3.2 Detak 1 detik (`_updateTime`, main.dart:2384)

Setiap detik: `_checkPrayerTime` → `_checkMediaSchedule` → `_checkMurottalSchedule` → update jam/tanggal/tanggal Hijriah (estimasi inkremental dari anchor: bulan ganjil 30/genap 29 hari).
- Pemicu jadwal (adzan/media/murottal) hanya bereaksi **tepat saat `second == 0`** — bila saat itu overlay notifikasi/media aktif, slot bisa terlewat total.
- Saat `second == 0` (menit ke-0): cek event petugas + Power TV. Saat 00:00: bersihkan event/petugas kedaluwarsa + refresh jadwal API.

### 3.3 Rotasi layar (`_startScreenRotation`, 345)

Daftar layar aktif disusun dinamis: `[0] Dashboard, (1) Hadis, [2] Info, [3] Event, (4) Petugas hanya jika ada acara hari ini, (5) Imsakiyah, (6) Slideshow media` — rotasi tiap `rotation_duration_seconds` (default 90 dtk), **dibekukan** selama `_notifState != none` atau media aktif. Indeks 6 tidak punya `case` di `_buildCurrentScreen` → jatuh ke Dashboard, media tampil sebagai overlay.

### 3.4 Rantai notifikasi sholat (state machine `NotifState`)

```
Waktu sholat (HH:mm == prayer) ─► adzan (180 dtk; relay ON; media dipaksa stop)
   ├─ Dzuhur + Jumat + fridayMode ─► khutbah (30 mnt) ─► sholat (600 dtk) ─► none + relay OFF
   └─ lainnya ─► countdown iqomah (delay 10 mnt, MM:SS) ─► iqomah (60 dtk) ─► sholat ─► none + relay OFF
```

### 3.5 Rantai murottal/tarhim (`_processSingleMurottalSchedule`, 2644)

Per jadwal per waktu sholat: N menit sebelum → putar `tarhim.mp3` (jika aktif) atau murottal (sumber: file playlist / API CDN equran.id per-qari per-surah, opsi acak & loop) → relay ON → stop `stop_before_adzan` menit sebelum waktu sholat; saat satu surah selesai, `MediaOverlay.onFinished` (3177) menaikkan surah berikutnya sampai `stopTime` tiba.


## 4. MAIN.DART — INTI APLIKASI (4.047 BARIS)

### 4.1 Top-level

| Entitas | Baris | Fungsi |
|---|---|---|
| `main()` | 29–35 | `ensureInitialized` → `initializeDateFormatting('id_ID')` → `runApp(MainApp)`. Tidak menyembunyikan system UI. |
| `resolveAppImage(path)` | 38–46 | Path absolut → `FileImage` (fallback bg.jpg asset bila hilang); nama pendek → `AssetImage('assets/themes/default/…')`. |
| `enum NotifState` | 88 | `none, adzan, countdown, khutbah, iqomah, sholat`. |

### 4.2 State utama (`_KioskScreenState`, 90–3670) — ±80 method

**Lifecycle**
- `initState` (268): buat `PrayerTimeService`, AnimationController logo (2 dtk, skala 0.95↔1.05), lalu fire-and-forget: `_initializeDisplay` → `_updateTime` → `_loadSettings` → `_startWebServer` → `_requestStoragePermission` → `Timer.periodic 1 dtk`.
- `_initializeDisplay` (290): ID pairing `SIMASJID-<uuid8>` disimpan prefs `displayId`.
- `_requestStoragePermission` (305): SDK≥30 → `manageExternalStorage`, selain itu `storage`; permanent-denied → `openAppSettings()`.
- `dispose` (331): batalkan 5 timer, tutup web server, dispose controller/focus — lengkap.

**Pengaturan & data**
- `_loadSettings()` (1886–2235, async): **jantung konfigurasi** — baca ±45 key prefs → bangun 15 default `TextStyle` (mosque_name 48pt Cairo, clock 68pt, dst.) dengan override `<elemen>_size/_color/_font` → `setState` raksasa (identitas, 10 aset, slides, prayer, notif, Jumat, hijri, media, murottal, imsakiyah, power TV, hadis, event, petugas) → di luar setState: tunnel (dead), `_cleanupExpiredData`, IoT, custom assets, warna tema, anchor Hijriah → fan-out: `_loadPrayerTimes`, `_loadHijriDate`, `_setupHadithFeature`, `_startScreenRotation`. Dipanggil ulang setiap ada perubahan dari Web Admin/Settings (artinya semua timer rotasi ter-reset).
- `_loadPrayerTimes` (2237): mode API → `fetchApiPrayerTimes` → susun 5 waktu → **simpan hasil API ke key `custom_prayer_times`** (key yang sama dengan jadwal manual — konflik, lihat §11) → fallback cache prefs saat offline.
- `_loadHijriDate` (2323): fetch hijri → simpan anchor (tanggal Masehi + hari/bulan/tahun Hijriah) untuk kalkulasi inkremental.
- `_cleanupExpiredData` (2553): hapus event & jadwal petugas yang tanggalnya lewat.

**Scheduler & automasi**
- `_updateTime` (2384): detak 1 detik (lihat §3.2) + render jam/tanggal/Hijriah.
- `_checkPrayerTime` (2850) → `_startAdzanSequence` (2943): ganti nama Dzuhur→"Jumat" bila mode Jumat; hentikan media paksa; relay ON; cabang khutbah/countdown/iqomah.
- `_startCountdown` (3001), `_startIqomahSequence` (2888), `_startKhutbahSequence` (2877), `_startSholatSequence` (3041): rantai state machine; helper teks `_getNotificationTitle/_getNotificationMessage` (2900/2918).
- `_checkMediaSchedule` (2599): HH:mm + hari cocok → `_startMedia` (2821) — relay ON, akhir playback ditentukan callback `MediaOverlay.onFinished`.
- `_checkMurottalSchedule` (2624) → `_processSingleMurottalSchedule` (2644): logika tarhim/murottal (§3.5); `_startMurottal` (2770) set `_mediaEndTimer` untuk stop-before-adzan; `_stopMurottal` (2836).
- `_startAdzanAudio` (2755): **parameter path & prayerName diabaikan** — hanya menghentikan media; audio adzan mp3 TIDAK diputar dari fungsi ini (bug, §11).
- `_checkPowerTvSchedule` (2470): jendela on/off per hari (mendukung lintas tengah malam) → `_setNativeScreenPower` (2513) via MethodChannel.
- `_triggerRelay` (2799): baca prefs IoT → `http.get('http://ip/path').timeout(2 dtk)` fire-and-forget.
- `_checkForActivePerformerEvent` (2522): cari jadwal petugas yang rentang `date..endDate` memuat hari ini; deep-compare via `jsonEncode`.

**Web server & handler (ringkas — detail rute di §7/§11)**
- `_startWebServer` (414): bind `0.0.0.0:8088`, `await for` request, dispatch method+path, tanpa auth; kegagalan bind hanya di-log (app tetap jalan).
- `_handleGetRequest` (567): render `generateAdminHtml(±60 argumen state)`.
- `_handleGetSettings` (662): JSON semua setting (untuk klien eksternal; tidak dipakai panel sendiri).
- `_handleUpdateSettings` (739–1119): rantai `if` per key form → tulis prefs (identitas, notif, Jumat, hijri, API prayer, jadwal manual `prayer_<Nama>`, hadis, `style_*`, IoT, power, aset, imsakiyah, tema, murottal 12 field × 5 waktu) → `_loadSettings()`.
- Handler CRUD multipart/form: `_handleUploadBg` (494), `_handleAddSlide` (1121), `_handleAddMedia` (1187), `_handleAddMediaLibrary` (1269), `_handleImportFolder` (1352 — scan folder lokal, whitelist ekstensi), `_handleAddPowerSchedule` (1442), `_handleAddHadith` (1514), `_handleAddEvent` (1587), `_handleAddPerformerProfile` (1645, foto), `_handleAddPerformerSchedule` (1728, multi-value), `_handleUploadAsset` (1809), pasangan `delete_*` GET, `_handleTestIot` (1843), `_handleRestartApp` (1849, `exit(0)`), `_handleRebootDevice` (1858, `su -c reboot`).
- `_parseMultipart` (527): `MimeMultipartTransformer`; nama file disanitasi anti path-traversal (baik), **tapi seluruh body dimuat ke memori sebelum ditulis → risiko OOM video besar**.

**UI & helper**
- `build` (3056): Stack kanvas 1280×720 — background (AnimatedSwitcher 800 ms) → gradien gelap → konten `_buildCurrentScreen()` → logo (ScaleTransition) → watermark "KORNET INTER MEDIA | 2026" → `MediaOverlay` (hanya saat `_notifState==none`) → `NotifOverlay` + child countdown MM:SS. `Focus.onKeyEvent`: 5 tombol remote → `_handleSecretMenuGesture` (3014: 3 tekan <5 dtk → push SettingsScreen → kembali → `_loadSettings`).
- `_buildDashboard` (3579): header glassmorphism (nama/alamat/kota + jam/tanggal/Hijriah, teks stroked) + 5 `PrayerTimeCard` (yang berikutnya berdenyut+glow via `_getNextPrayerIndex` 3442) + `ScrollingText` running text (marquee 50 px/s).
- `_buildCurrentScreen` (3279), `_buildScreenTransition` (3370), `_getScreenBackground` (3391), `_buildLogoWidget` (3408), `_buildStrokedText` (3462), `_buildAppHeader` (3485), `_formatDuration` (3653).

**Class lain di main.dart**
- `PrayerTime` (3672): `{name, time}`.
- `PrayerTimeService` (3679): fasad tipis ke `ApiRepository` (fetchApiPrayerTimes / fetchHijriDate / fetchRandomHadith).
- `ScrollingText` (3706): marquee horizontal loop.
- `PrayerTimeCard` (3794): kartu waktu sholat; **prop `cardAsset` tidak pernah dipakai** (aset card.png tak dirender).
- `ScrollingHadith` (3947): crawl vertikal — **tidak pernah di-instaniasi** (dead code; hadithscreen punya implementasi sendiri).


## 5. LAYAR-LAYAR TAYANGAN TV

Semua layar konten adalah `StatefulWidget` yang **menerima data via prop dari main.dart** (slides/performs/events/prayerTimes/textStyles/timeString/warna tema) — tidak membaca prefs sendiri, kecuali `IdleScreen` (hadis) yang justru fetch API mandiri. Pola visual seragam: header glassmorphism (`BackdropFilter blur 10` + teks stroked), footer jadwal 5 waktu, latar dari tema.

| File | Class | Mekanik utama |
|---|---|---|
| `infoscreen.dart` | `InfoScreen` | `PageView` carousel kartu slide (viewportFraction 0.7), auto-advance **10 dtk** + `animateToPage` 600 ms, kartu tetangga mengecil (skala −0.2), border emas kartu aktif; header "INFORMASI MASJID" + jam; footer jadwal. |
| `performerscreen.dart` | `PerformerScreen` | Carousel kartu petugas 8 dtk (foto kiri 40% / nama+peran kanan 60%), judul acara + rentang tanggal Indonesia (`DateFormat id_ID`), **tombol DatePicker** untuk cek petugas tanggal lain (satu-satunya layar interaktif; state lokal terpisah + `didUpdateWidget`), fallback "Tidak ada jadwal". |
| `hadithscreen.dart` | `IdleScreen` + `_AutoScrollHadith` | Fetch hadis random via `ApiRepository` **tiap 5 menit di dalam layar ini** (props `text/source` dari main diabaikan — dua sumber kebenaran); fallback hadis manual prefs → fallback hardcode HR. Bukhari; kartu kaca tengah dengan crawl vertikal linear 30 px/s, jeda 3 dtk, loop; status loading/error internal. |
| `imsakiyahscreen.dart` | `ImsakiyahScreen` | Fetch **tabel imsakiyah bulanan EQuran.id** per provinsi/kota; header tabel 9 kolom; baris kartu warna selang-seling (palet 5 warna), **baris hari ini disorot amber** (pencocokan substring tanggal `dd/MM/yyyy`/`yyyy-MM-dd` — rapuh); auto-scroll `jumpTo(+0.7 px per 30 ms)` dengan jeda saat disentuh (`Listener`); TIDAK menerima warna tema/jam dari main (hardcode amber/teal/black). |
| `eventscreen.dart` | `EventScreen` | Grid 3 kolom kartu agenda (chip tanggal emas + judul), filter "mendatang" via perbandingan string ISO, auto-scroll `jumpTo(+1 px/50 ms)` loop instan; satu-satunya file memakai API warna baru `withValues`. |
| `notifoverlay.dart` | `NotifOverlay` (Stateless) | Overlay fullscreen: latar `bgnotif` (file/asset) + dimmer 70% + judul amber 42 + nama sholat putih 72 bersayangan + pesan italic + slot `child` (countdown MM:SS 90 pt dari main). Semua ukuran hardcode. |
| `mediaoverlay.dart` | `MediaOverlay` | Pemutar per tipe: **video** (`video_player`, heuristik selesai `position>=duration && !isPlaying`, loop via seek+play), **audio** (`just_audio` `onPlayerComplete`, loop seek/resume, sumber file/http/asset), **gambar** (timer 15 dtk × playCount — bukan rotasi), **youtube** = placeholder belum jadi. `onFinished` → callback ke main (lanjut surah murottal / stop / relay off). Field tampilan ayat Quran (`_currentAyatText` dll.) **dead code**; `Image.file` tidak mendukung URL http; jalur error memakai `Future.delayed(3 dtk)` tanpa guard `mounted`. |

**Catatan lintas layar:** `_buildStrokedText/_buildHeader/_buildFooter` diduplikasi di 4–5 file dengan variasi kecil (footer EventScreen tanpa `textStyles` & ukuran beda; footer Imsakiyah tanpa gap); tidak ada `didUpdateWidget` di Info/Event/Imsakiyah → perubahan prop saat layar aktif tidak me-reset indeks/refetch; tiga pola auto-scroll berbeda dan kecepatannya tidak bisa diatur dari Settings.


## 6. HALAMAN PENGATURAN (lib/settings/)

`settings.dart` → `SettingsScreen`: `NavigationRail` 16 menu + `IndexedStack` 15 view (semua view **di-init sekaligus** → polling IoT/API berjalan berbarengan meski tab tak terlihat — boros), indeks 15 = "Keluar" (hardcode). Tidak ada callback ke main; semua tulis prefs, dan main melakukan `_loadSettings()` penuh saat kembali.

| Halaman | Isi & key prefs utama | Catatan penting |
|---|---|---|
| `settings_identity.dart` (281) | `mosque_name`, `mosque_address` (default hardcode "MASJID AL MUNTAHA"/"Perum Bumi Cipta Laras"); info IP `addr:8088`; **Backup** (dump semua prefs → JSON via FilePicker), **Restore** (`prefs.clear()` + tulis ulang per tipe + minta restart), **Reset** (`prefs.clear()`). | Restore tidak atomik — gagal di tengah = pengaturan hilang; backup/restore **diduplikasi identik** di settings_iot. |
| `settings_prayer.dart` (535) | Switch `use_api_prayer_times`, `api_provider` (MyQuran/AlAdhan/EQuran), stepper `hijri_adjustment`, tombol cek API (`_checkApi` → tulis `custom_prayer_times` + `last_prayer_update`), 5 TextField waktu manual, navigasi D-pad + `PopScope`. | Simpan manual **memaksa mode manual**; pencocokan jadwal per indeks array; TextField waktu tanpa validasi `HH:mm`. |
| `settings_city.dart` (368) | Sub-halaman "Pilih Kota" (di-push dari prayer): daftar kota MyQuran / provinsi→kota EQuran, pencarian, `_selectCity` → tulis `kota_id/kota_name` + `use_api=true` + refresh cache jadwal → pop `true`. | Hapus kota di sini **tidak** mematikan `use_api` (beda dari prayer) → status merah; mode EQuran menyimpan **nama provinsi** di `kota_id`. |
| `settings_theme.dart` (523) | 8 preset tema (Emerald Gold dst.) + warna primer/aksen; background per layar + "terapkan ke semua" (`bg_dashboard/info/event`, `bg_apply_all`); logo (`logo_path/show_logo/logo_animation_enabled`); rotasi 30–180 dtk; efek slideshow (`slideshow_effect`). | `TextEditingController` dibuat inline tiap build (L356/413); upload via copy file ke dokumen aplikasi. |
| `settings_text.dart` (201) | Styling 17 elemen teks: `<elemen>_size/_color/_font` + preview live; 6 font & 19 swatch hardcode. | `Color.value` deprecated; ganti elemen = perubahan belum disimpan hilang diam. |
| `settings_slide.dart` (144) | CRUD slide via key `slides` (JSON). | Controller inline per build; tambah/hapus tidak auto-save; model `SlideItem` tidak dipakai di sini. |
| `settings_runningtext.dart` (66) | `running_text`. | Tidak ada `dispose()` controller. |
| `settings_notification.dart` (211) | Durasi/teks adzan-iqomah-sholat (`notif_*`), mode Jumat (`friday_*`). | **10 controller tanpa dispose**; `int.tryParse ?? default` menyembunyikan salah ketik. |
| `settings_media.dart` (795) | Tab 1 playlist (`media_library` JSON; upload, **impor folder** via `getDirectoryPath` + whitelist ekstensi + dedup) ; Tab 2 jadwal tayang (`media_schedules`; dropdown dari playlist, jam, loop, hari). Switch `media_slideshow_enabled`. | 3 import tak terpakai; parsing `time/days` tanpa try (crash data korup); validasi days tidak ada. |
| `settings_murottal.dart` (411) | `ExpansionTile` per 5 waktu: enabled, tarhim (+menit), adzan_enabled, menit sebelum, stop sebelum, sumber file/api, qari (5 hardcode), surah (fetch `equran.id/api/v2/surat`), acak, loop → `murottal_schedules`. | Back-fill default per waktu; field `adzan_path` mati; `s['nomor'] as int` cast keras. |
| `settings_hadith.dart` (203) | `hadith_show/interval/speed` + daftar `custom_hadiths` (dialog tambah, tanpa edit). | Validasi gagal senyap; tidak auto-save. |
| `settings_event.dart` (194) | CRUD agenda `events` via DatePicker → `yyyy-MM-dd`. | Asumsi format tanggal kuat (`DateTime.parse` tanpa try). |
| `settings_performer.dart` (539) | 2 tab: profil petugas (`performer_profiles`: id/nama/peran/foto) & jadwal (`performer_schedules`: nama acara, rentang tanggal, checkbox petugas). | **Jadwal tidak bisa diedit dari UI** (fungsi edit ada tapi tak dirujuk); controller dialog bocor. |
| `settings_powertv.dart` (325) | `power_tv_enabled` + `power_schedules` (jam ON/OFF + FilterChip hari, validasi days). | Eksekusi sebenarnya di `_checkPowerTvSchedule` main.dart. |
| `settings_iot.dart` (367) | `iot_ip/path_on/path_off`; kartu status polling 4 dtk (`GET http://ip/status`), tombol Test ON/OFF. | `_checkConnection` dipanggil **per keystroke** IP; backup/restore duplikat tak terpakai. |
| `settings_imsakiyah.dart` (163) | `show_imsakiyah_screen` + provinsi/kota EQuran. | ~~**Bug**: `_fetchCities` menghapus `_selectedCity` hasil load~~ **DIPERBAIKI (H)**: `_fetchCities(clearSelection)`, load awal pertahankan kota. |


## 7. WEB ADMIN (PORT 8088)

### 7.1 Cara kerja

Bukan SPA/framework: setiap `GET /` **membangkitkan ulang seluruh halaman HTML** dari string Dart. Alur: `main._handleGetRequest` → `generateAdminHtml(...)` (`web_admin_html.dart:23`, **50 parameter named required**) yang menghitung baris tabel (slides, media, murottal 5×accordion, teks 15 elemen, hadis, agenda, petugas, power) → membungkusnya dalam `Map params` (66 entri) → memanggil 17 `build*Section(params)` dari `lib/web_admin/` → digabung `adminStyleCss` + `adminScriptJs` + template. Util `escapeJs`/`escapeHtml` hanya **closure lokal** di file utama — file section tidak punya akses → escaping tidak konsisten. **Tidak ada login, session, token CSRF, validasi Origin**: siapa pun di jaringan (atau via tunnel publik) bisa memanggil semua endpoint.

### 7.2 Aset statis panel

- `web_admin_style.dart` (445): raw-string CSS — variabel `:root` (primary #009688, accent #FFC107), grid menu, kartu glass, tabel, toggle switch, preset tema, media query. Catatan: blok CSS `.sidebar` mati; `--primary-dark` dipakai tapi tak didefinisikan; kelas `.accordion-*`, `.toast`, `.donation-*` dipakai tapi tak ada CSS-nya.
- `web_admin_script.dart` (429): JS vanilla — `showToast`, `showSection`/`showMainMenu` (navigasi tab via hash), `toggleAccordion`, `selectTheme` (auto-submit), `toggleMurottalSource`, 8 fungsi `edit*` (isi form untuk mode edit via onclick), `onLibrarySelect`, `applyCity`, loader kota/provinsi MyQuran & EQuran (fetch langsung dari browser ke API eksternal), plus **interceptor semua `<form>`**: `preventDefault` → `fetch()` → jika JSON `status:'success'` → toast → `location='/#section'` + `reload()`. Baris 209–281 adalah **duplikat dead** dari fungsi loader yang ditimpa definisi berikutnya (±73 baris mati). Konfirmasi `confirm()` untuk semua link `/delete_*`.

### 7.3 Peta section → endpoint

| Section (file) | Endpoint | Payload |
|---|---|---|
| Identitas | `POST /update_settings` | `mosque_name, mosque_address` |
| Jadwal sholat | `POST /update_settings` | `use_api, api_provider, kota_id, kota_name, hijri_adjustment, prayer_<Nama>` |
| Slide | `POST /add_slide` / `GET /delete_slide?i` | `index, title, content` |
| Running text | `POST /update_settings` | `running_text` |
| Notifikasi (2 form) | `POST /update_settings` | `adzan_duration, iqomah_delay/duration, text_*, notif_*, friday_*` |
| Media (3 form) | `POST /add_media`, `/add_media_library`, `/import_folder`; `GET /delete_media(Library)` | multipart file/path, `type, time, is_loop, play_count, day_1..7` |
| Murottal | `POST /update_settings` | 12 field × 5 waktu (`murottal_<Sholat>_*`) |
| Hadis | `POST /update_settings` + `POST /add_hadith` / `GET /delete_hadith` | `hadith_show/interval/speed`, `index, text, source` |
| Agenda | `POST /add_event` / `GET /delete_event` | `index, title, date` |
| Petugas | `POST /add_performer_profile` (foto multipart), `/add_performer_schedule`, `GET /delete_*` | `name, role, photo`; `name, date, endDate, performer_ids[]` |
| IoT | `POST /update_settings`; JS inline → **langsung ke ESP32** (JSONP `/status` + fetch `/on|/off`) | `iot_ip/path_on/path_off` |
| Teks/Font | `POST /update_settings` | `style_<elemen>_size/_color/_font` × 15 |
| Tema (3 form) | `POST /update_settings` (tema, logo/slideshow), `POST /upload_bg` | `theme_primary/accent`, `logo_*`, `rotation_duration_seconds`, `slideshow_effect`, `bg_file, apply_all` |
| Power TV | `POST /update_settings` + `POST /add_power_schedule` / `GET /delete_power_schedule` | `power_tv_enabled`; `on_time, off_time, days[]` |
| Imsakiyah | `POST /update_settings` (+ fetch provinsi/kota EQuran dari browser) | `show_imsakiyah_screen, imsakiyah_province/city` |
| Remote | `POST /update_settings` `tunnel_enabled, vps_host/user/pass/port` — **server tidak pernah membaca key ini** → sukses palsu (fitur SSH belum disambungkan) | |
| Donasi | tanpa endpoint — konten statis (QRIS/Rekening hardcode ke URL ibb.co) | |

Endpoint lain di router yang tidak dipakai UI: `GET /get_settings` (JSON), `POST /upload_asset`, `GET /delete_custom_asset`, `GET /test_iot`, `GET /restart_app`, `GET /reboot_device`.

### 7.4 File yatim (tidak pernah di-import/dirender)

`web_admin_section_dashboard.dart`, `web_admin_section_prayer_times.dart`, `web_admin_section_content.dart`, `web_admin_section_appearance.dart`, `web_admin\slide_item.dart` (duplikat persis `models\slide_item.dart`). Beberapa di antaranya bahkan rusak (import relatif sai `../../models/...`, memanggil JS `togglePrayerSource()` yang tidak ada, form tanpa action). Kandidat hapus aman.

> **✅ Sudah dihapus** (Tahap E, 13 Nov 2026): kelima file yatim ini + kelas `ScrollingHadith` di `main.dart` telah dibersihkan; `flutter analyze` tetap 0 issue.


## 8. API REPOSITORY & SSH TUNNEL

### 8.1 `api_repository.dart` — class `ApiRepository` (7 baris kelas, tanpa cache)

Semua method seragam: timeout 10 dtk (imsakiyah bulanan 15 dtk), decode UTF-8 manual, **kegagalan apa pun → `null`** (tidak pernah melempar), toleransi format ekstrem.

| Method | Baris | Endpoint | Output |
|---|---|---|---|
| `fetchPrayerTimes({kotaId, kotaName, provider})` | 14–196 | MyQuran v3: 3 URI kandidat berurutan (`/jadwal/{id}/today?tz=…`, `/jadwal/{id}/{y}/{m}/{d}`, `?kota=`) | Map 5 waktu; fallback pemindaian rekursif key `subuh/dzuhur/…` untuk format tak terduga |
| `_fetchAlAdhan` | 198–243 | `api.aladhan.com/v1/timingsByCity?city=&country=Indonesia&method=20` | Map 5 waktu (Fajr→Subuh dst.) |
| `_fetchEQuran` | 288–342 | `POST equran.id/api/v2/shalat {provinsi,kabkota}` | Map hari ini |
| `fetchProvincesShalatEQuran` / `fetchCitiesShalatEQuran` | 246–286 | `GET /shalat/provinsi`, `POST /shalat/kabkota` | `List<String>` |
| `fetchMonthlyImsakiyahEQuran` | 346–397 | sama dengan `_fetchEQuran` | `List<Map>` sebulan (`tanggal, imsak…isya`) |
| `fetchHijriDate({adjustment=-2})` | 401–472 | `myquran v2/cal/hijr?adj=` | `{day,month,year,monthName}` + sanity 1400–1500 H |
| `fetchRandomHadith` | 476–494 | `myquran v3/hadis/enc/random` | `{text, source}` (versi Indonesia) |
| `fetchCities` | 498–524 | `myquran v3/sholat/kabkota/semua` | `List<{id, lokasi}>` |

CDN audio murottal (`https://cdn.equran.id/audio-full/<qari>/<surah>.mp3`) dibangun **di main.dart**, bukan di repo ini.

### 8.2 `ssh_tunnel_manager.dart` — class `SshTunnelManager` (133 baris)

Reverse tunnel via `dartssh2`: `connect()` (35–86) → `SSHSocket.connect(host, 22)` → auth **private key diprioritaskan, fallback password** → `forwardRemote(port: remotePort)` (butuh `GatewayPorts=yes` di VPS) → URL publik `http://vps:remotePort` dilaporkan via `onStatusChanged` → loop `await for` menerima koneksi masuk dan `forwardRemote` → tiap koneksi di-`_pipeConnection` (89–118) dua arah (`Stream.pipe`, konkuren) ke `127.0.0.1:8088` (web server lokal TV). `_scheduleReconnect` (120): retry tetap 30 dtk, tanpa backoff. `disconnect()` (126).

**Status fitur: modul ini tidak pernah di-import oleh file mana pun** — form Remote di Web Admin & state `_tunnel*` di main adalah dead code. Import `package:async` juga tak terpakai. Implementasinya layak dipertahankan tinggal dirangkai (perlu simpan `vps_*` di prefs + instansiasi + tampilkan `publicUrl`).


## 9. MODEL DATA, ANDROID, ASET, FOLDER LAIN

### 9.1 Model

- **`SlideItem`** (`models/slide_item.dart`): `{title, content}` + `fromJson/toJson`. **Duplikat identik** di `web_admin/slide_item.dart` (tak pernah di-import).
- **`MurottalSchedule`** (`models/murottal_schedule.dart`): `prayer, enabled, minutesBefore(10), path, sourceType('file'|'api'), qari, surahNumber, currentSurah (runtime), isRandom, loopCount(1), stopBeforeAdzan(2), tarhimEnabled, tarhimMinutesBefore(20), adzanEnabled`; JSON snake_case; `createDefault`. Catatan: halaman settings_murottal dan handler web admin memakai **raw Map**, bukan model ini — skema terdefinisi dua kali.
- **`PrayerTime`** (main.dart:3672): `{name, time}`.
- Bentuk Map ad-hoc lain (tanpa kelas): media schedule `{path,type,time,is_loop,play_count,days}`, library `{id,name,path,type}`, event `{title,date}`, hadis `{text,source}`, profil petugas `{id,name,role,photoPath}`, jadwal petugas `{name,date,endDate,performerIds}`, power `{on,off,days:'CSV'}`.

### 9.2 Aset & folder lain

- `assets/themes/default/`: `bg.jpg, bgnotif.png, card.png, header.png, jam.png, runningtext.png, sidecard.png, slide.png, avatar.png` — konvensi nama file tetap per lapisan layar; folder tema lain tinggal ditambah namanya.
- `assets/audio/`: `tarhim.mp3` (9,3 MB), `adzan.mp3` (2,3 MB).
- ⚠️ **`assets/elements/bgnotif.png` direferensikan main.dart:3240 tapi folder `assets/elements/` tidak ada** — overlay selalu jatuh ke `errorBuilder` fallback `themes/default/bgnotif.png`.
- `tool/`: **kosong** (sisa). `_ref/`: `WiFiManager.cpp/.h` — referensi library Arduino/ESP32 untuk firmware IoT, tidak ikut build.
- `analyze_output.txt`: `flutter analyze` = **0 error, 11 warning, 74 info** — 60 `deprecated_member_use` (mayoritas `withOpacity` & `Color.value`), 9 `use_build_context_synchronously` (di settings), unused import/field (ssh_tunnel, mediaoverlay ayat, settings_media, backup IoT), `default:` unreachable di switch main.dart.


## 10. KAMUS KEY SHARED PREFERENCES (±50 key)

| Domain | Keys |
|---|---|
| Identitas | `mosque_name`, `mosque_address`, `running_text`, `displayId` |
| Jadwal sholat | `use_api_prayer_times`, `api_provider`, `kota_id`, `kota_name`, `custom_prayer_times` (JSON; **juga ditimpa cache API**), `last_prayer_update` (ISO; dibaca settings, tak dipakai logika) |
| Hijriah | `hijri_adjustment`, `hijri_anchor_date`, `hijri_anchor_day`, `hijri_anchor_month`, `hijri_anchor_year`, `hijri_anchor_month_name` (tak pernah dibaca) |
| Notifikasi | `notif_adzan_duration`(180), `notif_iqomah_delay`(10), `notif_iqomah_duration`(60), `notif_text_adzan`, `notif_text_iqomah_timer`, `notif_text_iqomah`, `notif_sholat_duration`(600), `notif_text_sholat`, `friday_mode_enabled`, `friday_khutbah_duration`(30), `friday_khutbah_text` |
| Aset/tema | `header_asset`, `jam_asset`, `card_asset`, `slide_asset`, `sidecard_asset`, `bg_asset`, `bg_dashboard`, `bg_info`, `bg_event`, `running_text_asset` (loop `assetKeys` main.dart:957), `bg_apply_all`, `custom_assets` (JSON list path), `theme_primary_color`, `theme_accent_color`, `logo_path`, `show_logo`, `logo_animation_enabled` |
| Konten | `slides`, `events`, `custom_hadiths`, `performer_profiles`, `performer_schedules` (semua JSON) |
| Media/murottal | `media_schedules`, `media_library`, `media_slideshow_enabled`, `murottal_schedules`, `rotation_duration_seconds`(90), `slideshow_effect`('fade') |
| Hadis | `hadith_show`, `hadith_interval`(5), `hadith_speed`(30 — disimpan, tak dipakai UI) |
| Imsakiyah | `show_imsakiyah_screen`, `imsakiyah_province`, `imsakiyah_city` |
| Power TV | `power_tv_enabled`, `power_schedules` (JSON `{on,off,days:'CSV'}`) |
| IoT | `iot_ip`, `iot_path_on`('/on'), `iot_path_off`('/off') |
| Remote (dead) | `tunnel_enabled`, `vps_host`, `vps_user`, `vps_port` — dibaca main.dart:2196–2200 tapi tidak pernah dipakai; `vps_pass` dikirim form tapi tidak pernah disimpan |
| Style teks | per elemen (15–17): `<elemen>_size` (double), `<elemen>_color` (int ARGB), `<elemen>_font` (String) |


## 11. TEMUAN: BUG, KEAMANAN, CODE SMELL

### 11.1 Keamanan — KRITIS

1. **Web admin tanpa autentikasi apa pun** (main.dart:414–492): siapa pun satu jaringan (atau internet saat tunnel aktif) dapat menulis semua pengaturan, upload file, membaca folder perangkat via `POST /import_folder` (path absolut bebas, 1352), memicu relay, `GET /restart_app` (`exit(0)`), bahkan `GET /reboot_device` (`su -c reboot`, 1858).
2. **Semua operasi destruktif memakai GET** (`/delete_*` ×9, restart, reboot) → CSRF trivial (`<img src="http://tv:8088/delete_slide?i=0">`) dan bisa ikut kena prefetch scanner.
3. **Stored XSS di panel admin**: data user disisipkan mentah ke HTML di ±14 tempat (`web_admin_html.dart` 118, 146–147, 176–177, 186, 440, 459, 479–480, 500, 528, 541, 550, 580) + ±16 tempat di atribut `value="…"` (section identitas/running/notif/jadwal/imsakiyah/iot/remote/teks) + JS-injection pada `onclick` (149, 179, 531, 582). Payload tersimpan di prefs dan dirender ulang — bisa mencuri kendali browser admin; sebagian nilai (kota API) bahkan XSS pihak ketiga.
4. **Menu Settings TV tanpa PIN** — 3× tap header / 3× tombol remote (auto-repeat keyboard bisa memicu tak sengaja, 3071–3081).
5. `vps_pass` dikirim plaintext via HTTP (handler belum menyimpannya — saat fitur diaktifkan jadi kebocoran kredensial); `usesCleartextTraffic=true`; polling IoT dari browser memakai input user → SSRF/probing jaringan lokal (`section_iot.dart:79,94`).
6. Upload multipart dimuat penuh ke memori (`toList()` 533) → DoS/OOM via file besar. (Sanitasi nama file anti path-traversal sudah benar, 546.)

### 11.2 Bug fungsional — TINGGI

> **Status 13 Nov 2026:** item 1, 2, 3, 5, 10 **sudah diperbaiki** (tahap G1–G3, audio/media/jadwal).
> Item 6, 7 (Web Admin) ditunda ke P1. Item 4, 8, 9 belum.

1. ✅ **Audio adzan tidak pernah diputar** — DIPERBAIKI (G2): `_startAdzanAudio` kini memutar `assets/audio/adzan.mp3` via `audioplayers`; player dihentikan saat transisi & `dispose()`.
2. ✅ **Crash loop potensial** — DIPERBAIKI (G1): `_updateTime` membungkus tiap cek jadwal dalam `try/catch`; `int.parse`/`split` diganti helper `_minutesFromHm` (aman untuk `''`, `'--:--'`, "7:5", dsb).
3. ✅ **Slot pemicu terlewat** — DIPERBAIKI (G2): pemicu tak lagi `second==0`; pakai `Set _firedToday` (reset 00:00) sehingga kejadian tetap jalan di detik mana pun pada menitnya, sekali per hari.
4. ✅ **Jadwal manual tertimpa cache API** — DIPERBAIKI (H): key dipisah `custom_prayer_times` (manual) vs `api_prayer_cache` (hasil API); fallback offline `_applyCachedPrayerTimes` baca cache API dulu, baru manual.
5. ✅ **Lanjutan surah murottal API acak salah** — DIPERBAIKI (G1): item awal menyertakan `'surah_number'` sehingga `currentSurah` benar & surah berikutnya lanjut dengan tepat.
6. ⏳ **Double-response di 5+ handler** (`add_media` dll; `_redirect()` setelah close) *(bagian Web Admin → P1)*.
7. ⏳ **Web admin** (toggle apply-all, toast upload, `/#null`, remote palsu, dropdown) *(→ P1)*.
8. ✅/⏳ **Settings**: bug hilang-kota **imsakiyah — DIPERBAIKI (H)** (`_fetchCities` + `clearSelection`). *Belum:* hapus-kota settings_city tak mematikan `use_api`, restore backup tak atomik.
9. ⏳ **Pesan countdown Jumat terbalik** (nama sudah 'Jumat'). *(belum — dampaknya kecil krn Jumat pakai jalur khutbah, bukan countdown)*
10. ✅ **Layar `MediaOverlay`** — DIPERBAIKI sebagian (G3): gambar online kini `Image.network`; callback error diberi guard `mounted` (mencegah race relay adzan). Heuristik akhir video (B8) dibiarkan (risiko rendah).

### 11.3 Code smell / kebersihan — SEDANG–RENDAH

- **God-class**: satu State ±3.400 baris; 8 domain "model" lewat `Map<String,dynamic>`; serialisasi skema murottal terdefinisi 3× (model, settings, handler admin).
- **Dead code**: `ssh_tunnel_manager.dart` tak terpasang; 4 section web admin yatim + `web_admin/slide_item.dart`; `ScrollingHadith`; `PrayerTimeCard.cardAsset`; prop `IdleScreen.text/source`; field ayat `MediaOverlay`; `_hadithSpeed`, `_lastPrayerUpdate`, `hijri_anchor_month_name`, state tunnel; 73 baris JS duplikat; blok kode dikomentari (settings_media 204–231); `tool/` kosong.
- **Duplikasi helper**: stroked text/header/footer di 5 layar; backup/restore 2×; `_focusedContainer` 2×; resolusi path asset/file 4×.
- Deprecated API tercampur (`withOpacity` vs `withValues`, `Color.value`, `onPopInvoked`, `initialValue` vs `value` di dropdown) → indikasi migrasi Flutter parsial; `dispose()` controller bolong di ≥6 halaman settings; `use_build_context_synchronously` 9 titik.
- Hardcode menonjol: port 8088, kanvas 1280×720, watermark "KORNET INTER MEDIA | 2026", nama masjid default "AL MUNTAHA", MethodChannel & applicationId `com.example`, `assets/elements/bgnotif.png` (folder tak ada), qari default, angka default 180/10/60/600/30/90/−2, `ms % 114` sebagai "RNG" (berbias), estimasi bulan Hijriah 30/29 (bisa meleset dari kalender riil), `setState` penuh tiap detik me-rebuild seluruh subtree blur.
- Build Android: signing release memakai debug key; ABI arm64 saja.


## 12. REKOMENDASI PERBAIKAN (urutan prioritas)

**P1 — Amankan Web Admin (sebelum dipasang di masjid lain)**
1. Tambahkan autentikasi (minimal Basic/Digest + PIN) dan token CSRF; tolak mutasi via GET — pindahkan semua `/delete_*`, `/restart_app`, `/reboot_device` ke POST.
2. Jadikan `escapeHtml`/`escapeJs` fungsi top-level yang di-import semua file section; wajibkan di SETIAP interpolasi data user (atau ganti `onclick="fn('$x')"` menjadi `data-*` attributes + event delegation).
3. Streaming multipart ke file (jangan `toList()` di memori); hapus/sembunyikan `reboot_device` kecuali benar-benar diperlukan.

**P2 — Perbaiki logika inti**
4. Putar `adzan.mp3` sungguhan di `_startAdzanAudio` (via audioplayers/just_audio) atau hapus kemampuannya dari kode.
5. Bungkus semua `int.parse` waktu dengan `tryParse` + fallback; ubah pemicu jadwal dari "detik==0" menjadi state "sudah dijalankan hari ini per kejadian" agar tidak terlewat.
6. Pisahkan key `custom_prayer_times` (manual) dari `api_prayer_cache` (hasil API); perbaiki kelanjutan surah acak dengan mengisi `surah_number` di item awal.
7. Hapus `_redirect()` setelah response close di 5 handler + bereskan `import_folder`; samakan semua handler JSON dengan interceptor JS (dan tambah hidden `section` di 13 form) + baca `location.hash` saat load agar tidak terlempar ke menu.
8. Perbaiki toggle apply-all (ke `/update_settings`), bug hilang-kota di settings_imsakiyah, konsistensi hapus-kota, restore backup atomik (tulis ke map dulu, clear belakangan), dan pesan countdown Jumat.

**P3 — Rapikan kode**
> Status per 13 Nov 2026: item 10 (sebagian), 11 (sebagian besar) sudah dikerjakan — lihat §0 & `CHANGELOG.md`.
9. *(belum)* Pecah `_KioskScreenState` menjadi service terpisah (PrayerScheduler, NotifStateMachine, MediaManager, SettingsRepository bertipe) — hilangkan Map ad-hoc, pakai model + satu skema JSON. **Baru dimulai**: `HijriCalculator` diekstraksi ke `lib/services/` (Tahap F) sebagai pola.
10. *(sebagian)* Hapus 4 section yatim + `web_admin/slide_item.dart` + `ScrollingHadith` + dead fields **sudah selesai** (Tahap A/E). **Belum**: rangkai/hapus `SshTunnelManager` & section remote; satukan helper stroked/header/footer & util path asset/file.
11. *(sebagian besar)* Bereskan analyzer (deprecation → `withValues`/`toARGB32`) **selesai** (Tahap B); dispose semua controller **selesai** (Tahap D, kecuali 2 display-field `settings_theme`); guard `mounted` pasca-await **selesai** (Tahap C). **Belum**: ganti `ms % 114` dengan `Random()`; pertimbangkan paket kalender Hijriah resmi.
12. *(belum)* Produksi: ganti `com.example.simasjid` + MethodChannel, signing key release sungguhan, PIN untuk menu Settings, perbaiki path `assets/elements/bgnotif.png`.

---

*Dokumen ini disusun dari pembacaan penuh seluruh 54 file Dart `lib/` (per-function dengan nomor baris), AndroidManifest/build.gradle, pubspec, aset, dan `analyze_output.txt`. Detail per-function yang lebih granular tersedia pada laporan analisis per klaster bila diperlukan.*

