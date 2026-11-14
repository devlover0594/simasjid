// Dev-only preview generator: renders the Web Admin HTML with mock data so the
// UI can be inspected in a browser without running the Android TV app.
// Not part of the app build. Run:  dart run tool/gen_admin_preview.dart <out.html>
import 'dart:io';
import 'package:simasjid/web_admin_html.dart';
import 'package:simasjid/models/slide_item.dart';
import 'package:simasjid/models/murottal_schedule.dart';

void main(List<String> args) {
  final out = args.isNotEmpty ? args[0] : 'admin-preview.html';

  final html = generateAdminHtml(
    mosqueName: 'MASJID AL MUNTAHA',
    mosqueAddress: 'Perum Bumi Cipta Laras',
    runningText: 'Selamat Datang di Masjid Al-Muntaha. Mohon nonaktifkan ponsel.',
    notifAdzanDuration: 180,
    notifIqomahDelay: 10,
    notifIqomahDuration: 60,
    notifTextIqomahTimer: 'DOA ANTARA ADZAN DAN IQOMAH',
    notifSholatDuration: 600,
    notifTextSholat: 'SHOLAT TELAH DIMULAI, HARAP TENANG',
    notifTextAdzan: 'SAATNYA ADZAN',
    notifTextIqomah: 'LURUSKAN DAN RAPATKAN SHAF',
    slidesData: [
      SlideItem(title: 'Jumat Bersih', content: 'Kegiatan kerja bakti setiap Jumat pagi.'),
      SlideItem(title: 'TPA', content: 'Pendaftaran santri TPA dibuka.'),
    ],
    mediaSchedules: [
      {'type': 'image', 'path': '/sdcard/banner.jpg', 'time': '18:30', 'is_loop': false, 'play_count': 1, 'days': ['1', '2', '3']},
      {'type': 'video', 'path': '/sdcard/kajian.mp4', 'time': '19:00', 'is_loop': true, 'play_count': 3, 'days': ['5']},
    ],
    mediaLibrary: [
      {'name': 'Banner Kajian', 'path': '/sdcard/banner.jpg', 'type': 'image', 'id': 'a1'},
      {'name': 'Kajian Subuh', 'path': '/sdcard/kajian.mp4', 'type': 'video', 'id': 'a2'},
      {'name': 'Murottal Full', 'path': '/sdcard/murottal.mp3', 'type': 'audio', 'id': 'a3'},
    ],
    textStyles: {
      'mosque_name': {'size': 48.0, 'color': 0xFFFFFFFF, 'font': 'Cairo'},
      'clock': {'size': 68.0, 'color': 0xFF07FF30, 'font': 'Roboto'},
      'running_text': {'size': 24.0, 'color': 0xFFFFC107, 'font': 'Oswald'},
    },
    useApi: true,
    mediaSlidesEnabled: true,
    apiProvider: 'MyQuran',
    kotaId: '564',
    kotaName: 'Kab. Semarang',
    hijriAdjustment: -2,
    prayerTimes: [
      {'name': 'Subuh', 'time': '04:30'},
      {'name': 'Dzuhur', 'time': '11:50'},
      {'name': 'Ashar', 'time': '15:10'},
      {'name': 'Maghrib', 'time': '17:55'},
      {'name': 'Isya', 'time': '19:10'},
    ],
    showHadith: true,
    hadithInterval: 5,
    hadithSpeed: 30,
    manualHadiths: [
      {'text': 'Sebaik-baik kalian adalah yang belajar Al-Quran dan mengajarkannya.', 'source': 'HR. Bukhari'},
    ],
    events: [
      {'title': 'Kajian Ahad Pagi', 'date': '2026-11-20'},
      {'title': 'Bakti Sosial', 'date': '2026-12-05'},
    ],
    murottalSchedules: [
      MurottalSchedule(prayer: 'Subuh', enabled: true, sourceType: 'api', qari: 'Mishary Al-Afasy', surahNumber: 18, tarhimEnabled: true),
      MurottalSchedule.createDefault('Dzuhur'),
    ],
    performerProfiles: [
      {'name': 'Ust. Ahmad', 'role': 'Imam', 'id': 'p1'},
      {'name': 'Bilal Hasan', 'role': 'Muadzin', 'id': 'p2'},
    ],
    scheduledPerformerEvents: [
      {'name': 'Khotbah Jumat', 'date': '2026-11-20', 'endDate': '2026-11-20', 'performerIds': ['p1']},
    ],
    currentAssets: {},
    availableAssets: ['bg1.jpg', 'logo.png'],
    iotIp: '192.168.1.200',
    iotPathOn: '/on',
    iotPathOff: '/off',
    showImsakiyahScreen: true,
    imsakiyahProvince: 'Jawa Tengah',
    imsakiyahCity: 'Semarang',
    powerTvEnabled: false,
    powerSchedules: [
      {'on': '05:00', 'off': '22:00', 'days': '1,2,3,4,5,6,7'},
    ],
    themePrimaryColor: 0xFF064E3B,
    themeAccentColor: 0xFFFFC107,
    bgApplyAll: true,
    logoPath: '/sdcard/logo.png',
    showLogo: true,
    logoAnimationEnabled: true,
    rotationDurationSeconds: 10,
    slideshowEffect: 'fade',
    fridayModeEnabled: true,
    fridayKhutbahDuration: 30,
    fridayKhutbahText: 'Harap tenang saat khutbah berlangsung.',
    displayId: 'TV-RUANG-UTAMA',
    tunnelEnabled: false,
    vpsHost: 'example.com',
    vpsUser: 'root',
    vpsPort: 22,
    publicUrl: null,
  );

  File(out).writeAsStringSync(html);
  stdout.writeln('WROTE $out (${html.length} bytes)');
}
