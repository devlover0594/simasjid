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

### Dihapus
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
