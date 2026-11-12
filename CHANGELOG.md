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
