# Changelog

Semua perubahan penting pada proyek **SIMasjid** dicatat di file ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.1.0/),
dan proyek ini memakai [Semantic Versioning](https://semver.org/lang/id/).

Jenis perubahan: `Ditambahkan` (added) · `Diubah` (changed) · `Diperbaiki` (fixed) ·
`Dihapus` (removed) · `Keamanan` (security) · `Deprecated` (fitur yang akan dihapus).

---

## [Unreleased]

### Ditambahkan
- `CHANGELOG.md` ini sebagai catatan perubahan berkelanjutan.
- Repo Git diinisialisasi; commit baseline `chore: baseline kondisi awal sebelum perapihan kode`
  sebagai titik balik (rollback point) sebelum perbaikan apa pun.

### Diubah
- **Tahap A — Perapihan (dead code & style):** `flutter analyze` turun dari **89 → 73 issue**
  (0 error, 0 warning; seluruh sisa adalah `info` deprecation/build-context).
- `settings_media.dart`: dua `if (mounted)` tanpa blok diberi kurung kurawal (lint
  `curly_braces_in_flow_control_structures`).
- `web_admin_html.dart`: `${pathSafe}` → `$pathSafe` (lint `unnecessary_brace_in_string_interps`).
- **Tahap B — Deprecation:** `flutter analyze` turun dari **73 → 11 issue** (0 error, 0 warning,
  0 deprecation). Semua pemanggilan API usang dimigrasikan ke API Flutter terbaru:
  - `withOpacity(x)` → `withValues(alpha: x)` (via `dart fix`, 58 titik di 10 file).
  - `Color.value` → `Color.toARGB32()` (mis. `Colors.amber.value`, `Colors.white.value`, `_fontColor.value`).
  - `PopScope.onPopInvoked: (didPop)` → `onPopInvokedWithResult: (didPop, result)` pada
    `settings_city.dart` & `settings_prayer.dart`.
- **Tahap C — Guard `BuildContext` pasca-async:** `flutter analyze` turun dari **11 → 0 issue**
  (bersih total). Semua pemakaian `BuildContext` setelah `await` kini dijaga dengan `context.mounted`
  (sebelumnya memakai `mounted` milik State yang dianggap lint "unrelated"):
  - `settings_city.dart` (1), `settings_identity.dart` (1), `settings_performer.dart` (1, pakai `ctx.mounted`),
    `settings_media.dart` (4, pakai `dialogContext.mounted`/`context.mounted`), `settings_prayer.dart` (4).
- **Tahap D — Kebocoran `TextEditingController`:** `flutter analyze` tetap **0 issue**.
  - Ditambah `dispose()` yang menghapus field controller: `settings_runningtext.dart` (1),
    `settings_identity.dart` (2), `settings_notification.dart` (10), `settings_hadith.dart` (2).
  - Controller lokal dialog kini di-`dispose()` setelah dialog selesai: `settings_event.dart` (`titleCtrl`),
    `settings_hadith.dart` (`textCtrl`/`sourceCtrl`; `_addManualHadith` dibuat `async` + `await showDialog`).
  - `settings_slide.dart`: `TextField(controller: TextEditingController(text:…))` inline →
    `TextFormField(initialValue:…)` sehingga controller internal dikelola widget (bebas bocor).
- **Tahap F — Mulai restrukturisasi god-class:** `flutter analyze` tetap **0 issue**.
  - Diperkenalkan folder `lib/services/` sebagai pola pemecahan `_KioskScreenState`.
  - Diedstraksi kalkulasi tanggal Hijriah inkremental (±40 baris aritmetika inline di `_updateTime`)
    menjadi `lib/services/hijri_calculator.dart` (class `HijriDate` + `HijriCalculator.advance`).
    `main.dart` kini memanggil service; guard null anchor diperluas mencakup month/year (setara,
    karena ketiganya selalu disimpan bersamaan).
  - **Diverifikasi kesetaraan perilaku**: 4.005 kombinasi (anchor × diff 0–800 hari) diuji terhadap
    algoritma lama → 0 selisih.

### Diperbaiki
- **Tahap G1 — Crash-proofing & kepatuhan jadwal (P2, audio/media):** `flutter analyze` tetap **0 issue**.
  - **B1 (KRITIS):** `_updateTime` (dipanggil `Timer.periodic` 1 detik) kini membungkus tiap pengecekan
    jadwal (`_checkPrayerTime`/`_checkMediaSchedule`/`_checkMurottalSchedule`/`_checkForActivePerformerEvent`/
    `_checkPowerTvSchedule`) dalam `try/catch`. Sebelumnya satu data waktu korup melempar exception yang
    **mematikan seluruh timer otomasi** (jam + semua jadwal berhenti sampai restart).
  - Ditambah helper `_minutesFromHm()` (parse "HH:mm"/"H:m" → menit, `null` bila tak valid). Dipakai di
    `_processSingleMurottalSchedule` dan `_checkPowerTvSchedule` untuk mengganti `int.parse`/`split` mentah
    yang bisa `FormatException`/`RangeError` (mis. `PrayerTime('','')` dari `orElse`, atau entri manual "7:5").
  - **B4:** item murottal API awal kini menyertakan `'surah_number'` (surah pertama, termasuk hasil acak),
    sehingga `onFinished` melanjutkan ke surah berikutnya dengan benar — bukan selalu kembali ke Al-Baqarah.
- **Tahap G2 — Kepatuhan jadwal & audio adzan (P2):** `flutter analyze` tetap **0 issue**.
  - **B3 (TINGGI):** pemicu adzan/media/murottal/tarhim **tidak lagi bergantung pada tepat `second==0`**.
    Ditambah `Set<String> _firedToday` (di-reset tiap 00:00): tiap kejadian dicek **setiap detik** dan
    dipicu sekali per hari via kunci (`adzan:<nama>`, `media:<index>`, `tarhim:<nama>`, `murottal:<nama>`).
    Kini jadwal tetap jalan meski satu tick terlambat/terlewat, dan tidak memicu dobel. Guard prioritas
    (notif/media aktif) dipertahankan, tapi kejadian bisa menyusul di detik lain pada menit yang sama.
  - **B5:** pencocokan waktu memakai **menit-terparse** (`_minutesFromHm`) alih-alih perbandingan string
    `"HH:mm"`, sehingga entri manual tak ternormalisasi (mis. "7:5") tetap cocok dengan jam "07:05".
  - **B2 (TINGGI):** **audio adzan kini benar-benar diputar.** `_startAdzanAudio` (sebelumnya mengabaikan
    `path`/`prayerName`) memanggil `_playAdzanAudio()` yang memutar `assets/audio/adzan.mp3` via
    `audioplayers` (`AssetSource`). Player adzan (`_adzanPlayer`) dihentikan & dilepas saat fase adzan
    selesai, saat sholat dimulai, dan di `dispose()`.
- **Tahap G3 — Bug `MediaOverlay` (P2):** `flutter analyze` tetap **0 issue**.
  - **B7:** callback error audio/video (`Future.delayed(3s) → onFinished`) kini diberi guard `if (!mounted)
    return;`. Sebelumnya, media yang gagal lalu ditimpa adzan bisa memanggil `onFinished` setelah widget
    dibuang → `_triggerRelay(false)` yang **mematikan relay adzan** (race).
  - **B6:** tampilan gambar kini mendukung URL online — `path` diawali `http` memakai `Image.network`,
    selainnya `Image.file` (sebelumnya gambar playlist online selalu gagal tampil).
  - **B8 (dibiarkan, risiko rendah):** heuristik akhir video `position>=duration && !isPlaying` tetap
    dipakai; mengubah deteksi selesai video tanpa pengujian perangkat nyata berisiko regresi.

### Deprecated
_(belum ada)_

### Catatan tersisa (sengaja tidak diubah agar tidak menimbulkan regresi)
- `settings_theme.dart`: dua `TextField(readOnly)` menampilkan path (`_bgPath`/`_logoPath`) via controller
  inline tiap build. Ini bocor ringan, tetapi `initialValue` akan memutus reaktivitas tampilan path, jadi
  dibiarkan; perbaikan ideal = refactor ke widget baris bertipe `StatefulWidget` yang memiliki controller.

### Dihapus
- **Tahap E — File/kelas yatim (dead code):** `flutter analyze` tetap **0 issue** (type-check lintas
  proyek memastikan tak ada referensi rusak).
  - 5 file `lib/web_admin/` yang tidak pernah di-import/dipanggil: `web_admin_section_appearance.dart`,
    `web_admin_section_content.dart`, `web_admin_section_dashboard.dart`, `web_admin_section_prayer_times.dart`,
    `slide_item.dart` (duplikat `models/slide_item.dart`).
  - Kelas `ScrollingHadith` + `_ScrollingHadithState` di `main.dart` (tidak pernah di-instaniasi;
    `hadithscreen.dart` punya implementasi crawl sendiri).
- `main.dart`: field tak terbaca `_lastPrayerUpdate` (+ penulisannya), `default:` unreachable pada
  dua `switch` `_getNotificationTitle/_getNotificationMessage`, dan variabel stack `st` pada `catch`.
- `mediaoverlay.dart`: field mati `_currentAyahNumber`.
- `web_admin_html.dart`: variabel lokal tak terpakai `displayIdSafe`.
- `settings_media.dart`: import tak terpakai (`intl`, `api_repository`, `http`).
- `web_admin_section_murottal.dart`: import tak terpakai (`models/murottal_schedule.dart`).
- `settings_iot.dart`: method duplikat mati `_backupSettings`/`_restoreSettings` (versi aktif ada di
  `settings_identity.dart`) + import yang menjadi tak terpakai (`dart:io`, `intl`, `file_picker`).

---

## Referensi
- Dokumen patokan development: `Rangkuman-Analisis-SIMasjid.md` (analisa lengkap 54 file Dart).
