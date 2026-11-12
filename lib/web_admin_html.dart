import 'web_admin/web_admin_style.dart';
import 'models/murottal_schedule.dart';
import 'models/slide_item.dart';
import 'web_admin/web_admin_script.dart';
import 'web_admin/web_admin_section_identitas.dart';
import 'web_admin/web_admin_section_jadwal.dart';
import 'web_admin/web_admin_section_running.dart';
import 'web_admin/web_admin_section_notif.dart';
import 'web_admin/web_admin_section_teks.dart';
import 'web_admin/web_admin_section_tema.dart';
import 'web_admin/web_admin_section_slide.dart';
import 'web_admin/web_admin_section_media.dart';
import 'web_admin/web_admin_section_murottal.dart';
import 'web_admin/web_admin_section_hadis.dart';
import 'web_admin/web_admin_section_agenda.dart';
import 'web_admin/web_admin_section_petugas.dart';
import 'web_admin/web_admin_section_iot.dart';
import 'web_admin/web_admin_section_powertv.dart';
import 'web_admin/web_admin_section_imsakiyah.dart';
import 'web_admin/web_admin_section_remote.dart';
import 'web_admin/web_admin_section_donasi.dart';

String generateAdminHtml({
  required String mosqueName,
  required String mosqueAddress,
  required String runningText,
  required int notifAdzanDuration,
  required int notifIqomahDelay,
  required int notifIqomahDuration,
  required String notifTextIqomahTimer, // Added
  required int notifSholatDuration, // Added
  required String notifTextSholat, // Added
  required String notifTextAdzan,
  required String notifTextIqomah,
  required List<SlideItem> slidesData,
  required List<Map<String, dynamic>> mediaSchedules,
  required List<Map<String, dynamic>> mediaLibrary,
  required Map<String, Map<String, dynamic>> textStyles,
  // New params for synchronization
  required bool useApi,
  required bool mediaSlidesEnabled, // Added
  required String apiProvider,
  required String kotaId,
  required String kotaName,
  required int hijriAdjustment,
  required List<Map<String, String>> prayerTimes,
  required bool showHadith,
  required int hadithInterval,
  required int hadithSpeed,
  required List<Map<String, String>> manualHadiths,
  required List<Map<String, String>> events,
  // New params for Assets & IoT
  required List<MurottalSchedule> murottalSchedules,
  required List<Map<String, dynamic>> performerProfiles,
  required List<Map<String, dynamic>> scheduledPerformerEvents,
  required Map<String, String> currentAssets,
  required List<String> availableAssets,
  required String iotIp,
  required String iotPathOn,
  required String iotPathOff,
  required bool showImsakiyahScreen,
  required String imsakiyahProvince,
  required String imsakiyahCity,
  required bool powerTvEnabled,
  required List<Map<String, String>> powerSchedules,
  required int themePrimaryColor,
  required int themeAccentColor,
  required bool bgApplyAll,
  required String logoPath,
  required bool showLogo,
  required bool logoAnimationEnabled,
  required int rotationDurationSeconds,
  required String slideshowEffect,
  required bool fridayModeEnabled,
  required int fridayKhutbahDuration,
  required String fridayKhutbahText,
  required String displayId,
  // Remote Access
  required bool tunnelEnabled,
  required String vpsHost,
  required String vpsUser,
  required int vpsPort,
  required String? publicUrl,
}) {
  // Generate Slides Rows
  String escapeJs(String? s) {
    return s
            ?.replaceAll('\\', '\\\\')
            .replaceAll("'", "\\'")
            .replaceAll('"', '&quot;')
            .replaceAll('\n', '\\n')
            .replaceAll('\r', '\\r') ??
        '';
  }

  String escapeHtml(String? s) {
    return s
            ?.replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;') ??
        '';
  }

  final logoPathSafe = escapeHtml(logoPath);
  final displayIdSafe = escapeHtml(displayId);

  String slidesHtml = '';
  for (int i = 0; i < slidesData.length; i++) {
    final s = slidesData[i];
    final titleSafe = escapeJs(s.title);
    final contentSafe = escapeJs(s.content);
    slidesHtml +=
        '''
        <tr>
          <td>${i + 1}</td>
          <td><b>${s.title}</b><br>${s.content}</td>
          <td style="text-align:center">
            <button onclick="editSlide($i, '$titleSafe', '$contentSafe')" class="btn-edit">[Edit]</button>
            <a href="/delete_slide?i=$i&section=slide" class="btn-delete">[Hapus]</a>
          </td>
        </tr>
      ''';
  }

  // Generate Media Rows
  String mediaHtml = '';
  for (int i = 0; i < mediaSchedules.length; i++) {
    final m = mediaSchedules[i];
    final loopInfo = (m['is_loop'] == true)
        ? "Loop: ${m['play_count']}x"
        : "Sekali Putar";

    final pathSafe = m['path'].toString().replaceAll("'", "\\'");
    final type = m['type'];
    final time = m['time'];
    final isLoop = m['is_loop'].toString();
    final playCount = m['play_count'];
    final days = (m['days'] as List).join(',');

    mediaHtml +=
        '''
        <tr>
          <td>${i + 1}</td>
          <td><span style="badge">${m['type']}</span><br><small>${m['path']}</small></td>
          <td>${m['time']} ($loopInfo)<br><small>Hari: ${m['days']}</small></td>
          <td style="text-align:center">
            <button onclick="editMedia($i, '$pathSafe', '$type', '$time', $isLoop, $playCount, '$days')" class="btn-edit">[Edit]</button>
            <a href="/delete_media?i=$i&section=media" class="btn-delete">[Hapus]</a>
          </td>
        </tr>
      ''';
  }

  // Generate Media Library Rows & Options
  String mediaLibHtml = '';
  String mediaLibOptions = '<option value="">-- Manual --</option>';

  for (int i = 0; i < mediaLibrary.length; i++) {
    final m = mediaLibrary[i];
    final nameSafe = escapeJs(m['name']?.toString());
    final pathSafe = escapeJs(m['path']?.toString());
    final type = m['type'] ?? 'image';
    final id = m['id'] ?? '';

    mediaLibHtml +=
        '''
      <tr>
        <td style="width: 60px; text-align: center;">
          ${i + 1}
          ${type == 'image' ? '<img src="${pathSafe}" style="width: 40px; height: 40px; object-fit: cover; border-radius: 4px; margin-top: 5px;" onerror="this.onerror=null;this.src=\'/assets/broken_image.png\';">' : ''}
          ${type == 'video' ? '<video src="${pathSafe}" style="width: 40px; height: 40px; object-fit: cover; border-radius: 4px; margin-top: 5px;" preload="metadata" onloadeddata="this.currentTime=1;" onerror="this.onerror=null;this.src=\'/assets/broken_video.png\';"></video>' : ''}
          ${type == 'audio' ? '<i class="icon-audio" style="font-size: 30px; margin-top: 5px; color: #607d8b;">🎵</i>' : ''}
        </td>
        <td><b>$nameSafe</b><br><span style="badge">$type</span></td>
        <td><small>$pathSafe</small></td>
        <td style="text-align:center">
           <button onclick="editMediaLib($i, '$nameSafe', '$pathSafe', '$type', '$id')" class="btn-edit">[Edit]</button>
           <a href="/delete_media_library?i=$i&section=media" class="btn-delete">[Hapus]</a>
        </td>
      </tr>
    ''';

    mediaLibOptions +=
        '<option value="$id" data-path="$pathSafe" data-type="$type">$nameSafe</option>';
  }

  // Generate Murottal Schedule Rows
  String murottalSchedulesHtml = '';
  final qaris = [
    'Abdullah-Al-Juhany',
    'Abdulrahman Al-Sudais',
    'Saad Al-Ghamdi',
    'Mishary Al-Afasy',
    'Yasser Al-Dosari',
  ];
  final surahs = [
    {"n": 1, "name": "Al-Fatihah"},
    {"n": 2, "name": "Al-Baqarah"},
    {"n": 3, "name": "Ali 'Imran"},
    {"n": 4, "name": "An-Nisa'"},
    {"n": 5, "name": "Al-Ma'idah"},
    {"n": 6, "name": "Al-An'am"},
    {"n": 7, "name": "Al-A'raf"},
    {"n": 8, "name": "Al-Anfal"},
    {"n": 9, "name": "At-Taubah"},
    {"n": 10, "name": "Yunus"},
    {"n": 11, "name": "Hud"},
    {"n": 12, "name": "Yusuf"},
    {"n": 13, "name": "Ar-Ra'd"},
    {"n": 14, "name": "Ibrahim"},
    {"n": 15, "name": "Al-Hijr"},
    {"n": 16, "name": "An-Nahl"},
    {"n": 17, "name": "Al-Isra'"},
    {"n": 18, "name": "Al-Kahf"},
    {"n": 19, "name": "Maryam"},
    {"n": 20, "name": "Taha"},
    {"n": 21, "name": "Al-Anbiya'"},
    {"n": 22, "name": "Al-Hajj"},
    {"n": 23, "name": "Al-Mu'minun"},
    {"n": 24, "name": "An-Nur"},
    {"n": 25, "name": "Al-Furqan"},
    {"n": 26, "name": "Asy-Syu'ara'"},
    {"n": 27, "name": "An-Naml"},
    {"n": 28, "name": "Al-Qasas"},
    {"n": 29, "name": "Al-'Ankabut"},
    {"n": 30, "name": "Ar-Rum"},
    {"n": 31, "name": "Luqman"},
    {"n": 32, "name": "As-Sajdah"},
    {"n": 33, "name": "Al-Ahzab"},
    {"n": 34, "name": "Saba'"},
    {"n": 35, "name": "Fatir"},
    {"n": 36, "name": "Yasin"},
    {"n": 37, "name": "As-Saffat"},
    {"n": 38, "name": "Sad"},
    {"n": 39, "name": "Az-Zumar"},
    {"n": 40, "name": "Ghafir"},
    {"n": 41, "name": "Fussilat"},
    {"n": 42, "name": "Asy-Syura"},
    {"n": 43, "name": "Az-Zukhruf"},
    {"n": 44, "name": "Ad-Dukhan"},
    {"n": 45, "name": "Al-Jasiyah"},
    {"n": 46, "name": "Al-Ahqaf"},
    {"n": 47, "name": "Muhammad"},
    {"n": 48, "name": "Al-Fath"},
    {"n": 49, "name": "Al-Hujurat"},
    {"n": 50, "name": "Qaf"},
    {"n": 51, "name": "Az-Zariyat"},
    {"n": 52, "name": "At-Tur"},
    {"n": 53, "name": "An-Najm"},
    {"n": 54, "name": "Al-Qamar"},
    {"n": 55, "name": "Ar-Rahman"},
    {"n": 56, "name": "Al-Waqi'ah"},
    {"n": 57, "name": "Al-Hadid"},
    {"n": 58, "name": "Al-Mujadilah"},
    {"n": 59, "name": "Al-Hasyr"},
    {"n": 60, "name": "Al-Mumtahanah"},
    {"n": 61, "name": "As-Saff"},
    {"n": 62, "name": "Al-Jumu'ah"},
    {"n": 63, "name": "Al-Munafiqun"},
    {"n": 64, "name": "At-Tagabun"},
    {"n": 65, "name": "At-Talaq"},
    {"n": 66, "name": "At-Tahrim"},
    {"n": 67, "name": "Al-Mulk"},
    {"n": 68, "name": "Al-Qalam"},
    {"n": 69, "name": "Al-Haqqah"},
    {"n": 70, "name": "Al-Ma'arij"},
    {"n": 71, "name": "Nuh"},
    {"n": 72, "name": "Al-Jinn"},
    {"n": 73, "name": "Al-Muzzammil"},
    {"n": 74, "name": "Al-Muddassir"},
    {"n": 75, "name": "Al-Qiyamah"},
    {"n": 76, "name": "Al-Insan"},
    {"n": 77, "name": "Al-Mursalat"},
    {"n": 78, "name": "An-Naba'"},
    {"n": 79, "name": "An-Nazi'at"},
    {"n": 80, "name": "'Abasa"},
    {"n": 81, "name": "At-Takwir"},
    {"n": 82, "name": "Al-Infitar"},
    {"n": 83, "name": "Al-Mutaffifin"},
    {"n": 84, "name": "Al-Insyiqaq"},
    {"n": 85, "name": "Al-Buruj"},
    {"n": 86, "name": "At-Tariq"},
    {"n": 87, "name": "Al-A'la"},
    {"n": 88, "name": "Al-Ghasyiyah"},
    {"n": 89, "name": "Al-Fajr"},
    {"n": 90, "name": "Al-Balad"},
    {"n": 91, "name": "Asy-Syams"},
    {"n": 92, "name": "Al-Lail"},
    {"n": 93, "name": "Ad-Duha"},
    {"n": 94, "name": "Asy-Syarh"},
    {"n": 95, "name": "At-Tin"},
    {"n": 96, "name": "Al-'Alaq"},
    {"n": 97, "name": "Al-Qadr"},
    {"n": 98, "name": "Al-Bayyinah"},
    {"n": 99, "name": "Az-Zalzalah"},
    {"n": 100, "name": "Al-'Adiyat"},
    {"n": 101, "name": "Al-Qari'ah"},
    {"n": 102, "name": "At-Takasur"},
    {"n": 103, "name": "Al-'Asr"},
    {"n": 104, "name": "Al-Humazah"},
    {"n": 105, "name": "Al-Fil"},
    {"n": 106, "name": "Quraisy"},
    {"n": 107, "name": "Al-Ma'un"},
    {"n": 108, "name": "Al-Kausar"},
    {"n": 109, "name": "Al-Kafirun"},
    {"n": 110, "name": "An-Nasr"},
    {"n": 111, "name": "Al-Masad"},
    {"n": 112, "name": "Al-Ikhlas"},
    {"n": 113, "name": "Al-Falaq"},
    {"n": 114, "name": "An-Nas"},
  ];

  final prayerNamesForMurottal = [
    'Subuh',
    'Dzuhur',
    'Ashar',
    'Maghrib',
    'Isya',
  ];
  for (final prayerName in prayerNamesForMurottal) {
    final schedule = murottalSchedules.firstWhere(
      (s) => s.prayer == prayerName,
      orElse: () => MurottalSchedule.createDefault(prayerName),
    );

    final enabled = schedule.enabled;
    final minutesBefore = schedule.minutesBefore;
    final stopBefore = schedule.stopBeforeAdzan;
    final isRandom = schedule.isRandom;
    final loopCount = schedule.loopCount;
    final path = schedule.path ?? '';
    final sourceType = schedule.sourceType;
    final qari = schedule.qari ?? 'Abdullah-Al-Juhany';
    final surahNumber = schedule.surahNumber ?? 1;
    final tarhimEnabled = schedule.tarhimEnabled;
    final tarhimMinutesBefore = schedule.tarhimMinutesBefore;
    final adzanEnabled =
        schedule.adzanEnabled; // This is for the automatic adzan audio

    // Determine initial display style for the content
    final initialDisplay = enabled || tarhimEnabled || adzanEnabled
        ? 'block'
        : 'none';
    final headerClass = enabled || tarhimEnabled || adzanEnabled
        ? 'accordion-header active'
        : 'accordion-header';

    String currentMediaLibOptions = mediaLibOptions.replaceAll(
      'value="${path.replaceAll('"', '&quot;')}"', // Escape path for HTML attribute
      'value="$path" selected',
    );

    murottalSchedulesHtml +=
        '''
      <div class="card" style="margin-bottom:15px; background: #f0fdfa;">
        <h3>Waktu: <b>$prayerName</b></h3>
      <div class="accordion-item">
        <div class="$headerClass" onclick="toggleAccordion(this)">
          <h3>Waktu: <b>$prayerName</b></h3>
          <span class="accordion-icon"></span>
        </div>
        <div class="accordion-content" style="display: $initialDisplay;">
          <input type="hidden" name="murottal_${prayerName}_prayer" value="$prayerName">
          <h4 style="margin-top:10px; margin-bottom:10px;">Pengaturan Tarhim & Adzan Otomatis</h4>
          <p style="font-size:0.85em; color:#666; margin-bottom:15px;">Aktifkan untuk memutar file <code>tarhim.mp3</code> dan <code>adzan.mp3</code> dari folder aset perangkat secara otomatis.</p>
          <div class="row" style="align-items:center; margin-bottom: 10px; background: #e0f2f1; padding: 8px; border-radius: 6px;">
              <div class="col"><label>Aktifkan Tarhim</label><select name="murottal_${prayerName}_tarhim_enabled"><option value="true" ${tarhimEnabled ? 'selected' : ''}>Ya</option><option value="false" ${!tarhimEnabled ? 'selected' : ''}>Tidak</option></select></div>
              <div class="col"><label>Mulai Tarhim (Menit Sebelum Adzan)</label><input type="number" name="murottal_${prayerName}_tarhim_minutes_before" value="$tarhimMinutesBefore"></div>
              <div class="col"><label>Putar Audio Adzan</label><select name="murottal_${prayerName}_adzan_enabled"><option value="true" ${adzanEnabled ? 'selected' : ''}>Ya</option><option value="false" ${!adzanEnabled ? 'selected' : ''}>Tidak</option></select></div>
          </div>
          <h4 style="margin-top:20px; margin-bottom:10px;">Pengaturan Murottal</h4>
        </div>
        <div class="row" style="align-items:center;">
          <div class="col"><label>Aktifkan Murottal</label><select name="murottal_${prayerName}_enabled"><option value="true" ${enabled ? 'selected' : ''}>Ya</option><option value="false" ${!enabled ? 'selected' : ''}>Tidak</option></select></div>
          <div class="col"><label>Mulai (Menit Sebelum Adzan)</label><input type="number" name="murottal_${prayerName}_minutes_before" value="$minutesBefore"></div>
          <div class="col"><label>Berhenti (Menit Sebelum Adzan)</label><input type="number" name="murottal_${prayerName}_stop_before_adzan" value="$stopBefore"></div>
        </div>
        <div class="row" style="align-items:center; margin-top:10px;">
          <div class="col" style="flex:2">
            <label>Sumber Murottal</label>
            <select name="murottal_${prayerName}_source_type" onchange="toggleMurottalSource(this, '$prayerName')">
              <option value="file" ${sourceType == 'file' ? 'selected' : ''}>File dari Playlist</option>
              <option value="api" ${sourceType == 'api' ? 'selected' : ''}>Streaming Surah (API)</option>
            </select>
          </div>
        </div>
        <div id="murottal_source_file_$prayerName" class="murottal-source-div" style="display:${sourceType == 'file' ? 'block' : 'none'}; margin-top:10px;">
          <label>Pilih File</label><select name="murottal_${prayerName}_path"><option value="">-- Tidak Ada --</option>$currentMediaLibOptions</select>
        </div>
        <div id="murottal_source_api_$prayerName" class="murottal-source-div row" style="display:${sourceType == 'api' ? 'flex' : 'none'}; margin-top:10px; align-items:flex-end;">
          <div class="col" style="flex:2"><label>Pilih Qori</label><select name="murottal_${prayerName}_qari">${qaris.map((q) => '<option value="$q" ${q == qari ? 'selected' : ''}>$q</option>').join('')}</select></div>
          <div class="col"><label>Pilih Surah</label><select name="murottal_${prayerName}_surah_number">${surahs.map((s) => '<option value="${s['n']}" ${s['n'] == surahNumber ? 'selected' : ''}>${s['n']}. ${s['name']}</option>').join('')}</select></div>
        </div>
        <div class="row" style="align-items:center; margin-top:10px;">
          <div class="col"><label>Acak?</label><select name="murottal_${prayerName}_is_random"><option value="false" ${!isRandom ? 'selected' : ''}>Tidak</option><option value="true" ${isRandom ? 'selected' : ''}>Ya</option></select></div>
          <div class="col"><label>Loop</label><input type="number" name="murottal_${prayerName}_loop_count" value="$loopCount"></div>
        </div>
        </div>
      </div>''';
  }

  // Generate Text Settings Rows
  String textSettingsHtml = '';
  final elementNames = {
    'mosque_name': 'Nama Masjid',
    'mosque_address': 'Alamat',
    'clock': 'Jam Digital',
    'date': 'Tanggal',
    'running_text': 'Running Text',
    'slide_title': 'Judul Slide',
    'slide_content': 'Isi Slide',
    'prayer_name': 'Nama Sholat',
    'prayer_time': 'Jam Sholat',
    'performer_event_name': 'Nama Acara (Petugas)',
    'performer_event_date': 'Tanggal Acara (Petugas)',
    'performer_name': 'Nama Petugas',
    'performer_role': 'Peran Petugas',
    'footer_prayer_name': 'Nama Sholat (Footer)',
    'footer_prayer_time': 'Jam Sholat (Footer)',
  };

  final fonts = ['Roboto', 'Cairo', 'Amiri', 'Oswald', 'Lato', 'Open Sans'];

  textStyles.forEach((key, style) {
    String fontOptions = '';
    for (var f in fonts) {
      final selected = (style['font'] == f) ? 'selected' : '';
      fontOptions += '<option value="$f" $selected>$f</option>';
    }

    final colorVal = style['color'] as int;
    final hexColor =
        '#${(colorVal & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    textSettingsHtml +=
        '''
        <tr>
          <td><b>${elementNames[key] ?? key}</b></td>
          <td><input type="number" name="style_${key}_size" value="${style['size']}" step="1" style="width:70px"> px</td>
          <td><input type="color" name="style_${key}_color" value="$hexColor" style="height:30px; width:50px; padding:0; border:none;"></td>
          <td><select name="style_${key}_font">$fontOptions</select></td>
        </tr>
      ''';
  });

  // Generate Manual Hadith Rows
  String hadithHtml = '';
  for (int i = 0; i < manualHadiths.length; i++) {
    final h = manualHadiths[i];
    final textSafe = escapeJs(h['text']);
    final sourceSafe = escapeJs(h['source']);

    hadithHtml +=
        '''
      <tr>
        <td>${i + 1}</td>
        <td>${h['text']}<br><small><b>${h['source']}</b></small></td>
        <td style="text-align:center">
          <button onclick="editHadith($i, '$textSafe', '$sourceSafe')" class="btn-edit">[Edit]</button>
          <a href="/delete_hadith?i=$i&section=hadis" class="btn-delete">[Hapus]</a>
        </td>
      </tr>
    ''';
  }

  // Generate Event Rows
  String eventHtml = '';
  for (int i = 0; i < events.length; i++) {
    final e = events[i];
    final titleSafe = escapeJs(e['title']);
    final date = e['date'];

    eventHtml +=
        '''
      <tr>
        <td>${i + 1}</td>
        <td>${e['title']}</td>
        <td>${e['date']}</td>
        <td style="text-align:center">
          <button onclick="editEvent($i, '$titleSafe', '$date')" class="btn-edit">[Edit]</button>
          <a href="/delete_event?i=$i&section=agenda" class="btn-delete">[Hapus]</a>
        </td>
      </tr>
    ''';
  }

  // Generate Performer Profile Rows
  String performerProfileHtml = '';
  for (int i = 0; i < performerProfiles.length; i++) {
    final p = performerProfiles[i];
    final nameSafe = escapeJs(p['name']);
    final roleSafe = escapeJs(p['role']);

    performerProfileHtml +=
        '''
    <tr>
      <td>${i + 1}</td>
      <td><b>${p['name']}</b><br><small>${p['role']}</small></td>
      <td style="text-align:center">
        <button onclick="editProfile($i, '$nameSafe', '$roleSafe')" class="btn-edit">[Edit]</button>
        <a href="/delete_performer_profile?i=$i&section=petugas" class="btn-delete">[Hapus]</a>
      </td>
    </tr>
  ''';
  }

  // Generate Performer Schedule Rows
  String performerScheduleHtml = '';
  for (int i = 0; i < scheduledPerformerEvents.length; i++) {
    final s = scheduledPerformerEvents[i];
    List<String> performerIds = List<String>.from(s['performerIds'] ?? []);
    String names = performerProfiles
        .where((p) => performerIds.contains(p['id']))
        .map((p) => p['name'] as String? ?? '')
        .join(', ');
    if (names.isEmpty) names = '-';

    final nameSafe = escapeJs(s['name']);
    final date = s['date'];
    final endDate = s['endDate'] ?? date; // Handle endDate
    final ids = performerIds.join(',');

    performerScheduleHtml +=
        '''
    <tr>
      <td><b>${s['name']}</b><br><small>${s['date']} s/d $endDate</small></td>
      <td>$names</td>
      <td style="text-align:center">
        <button onclick="editSchedule($i, '$nameSafe', '$date', '$endDate', '$ids')" class="btn-edit">[Edit]</button>
        <a href="/delete_performer_schedule?i=$i&section=petugas" class="btn-delete">[Hapus]</a>
      </td>
    </tr>''';
  }

  // Generate Performer Checkboxes for the form
  String performerCheckboxes = '';
  for (var p in performerProfiles) {
    performerCheckboxes +=
        '<label><input type="checkbox" name="performer_ids" value="${p['id']}"> ${p['name']} (${p['role']})</label>';
  }

  // Generate Prayer Times Inputs
  String prayerInputs = '';
  for (var p in prayerTimes) {
    prayerInputs +=
        '''
      <div class="row" style="margin-bottom:5px; align-items:center;">
        <div class="col" style="flex:1"><b>${p['name']}</b></div>
        <div class="col" style="flex:2"><input type="time" name="prayer_${p['name']}" value="${p['time']}"></div>
      </div>
    ''';
  }

  // Aset Gambar generation removed per user request

  // Generate Power TV Schedule Rows
  String powerSchedulesHtml = '';
  String getDayNames(String days) {
    if (days == "1,2,3,4,5,6,7") return "Setiap Hari";
    final list = days.split(',').where((e) => e.isNotEmpty).toList();
    final names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    try {
      return list.map((e) => names[int.parse(e) - 1]).join(', ');
    } catch (_) {
      return days;
    }
  }

  for (int i = 0; i < powerSchedules.length; i++) {
    final s = powerSchedules[i];
    final onTime = s['on'] ?? '';
    final offTime = s['off'] ?? '';
    final days = s['days'] ?? '1,2,3,4,5,6,7';
    powerSchedulesHtml +=
        '''
      <tr>
        <td>${i + 1}</td>
        <td><b>ON:</b> $onTime | <b>OFF:</b> $offTime<br><small>Hari: ${getDayNames(days)}</small></td>
        <td style="text-align:center">
          <button onclick="editPowerSchedule($i, '$onTime', '$offTime', '$days')" class="btn-edit">[Edit]</button>
          <a href="/delete_power_schedule?i=$i&section=powertv" class="btn-delete">[Hapus]</a>
        </td>
      </tr>
    ''';
  }

  // Generate Theme Presets
  final List<Map<String, dynamic>> themePresets = [
    {
      'name': 'Emerald Gold (Default)',
      'primary': 0xFF064E3B,
      'accent': 0xFFFFC107,
      'desc': 'Nuansa hijau gelap dipadukan dengan aksen emas elegan.',
    },
    {
      'name': 'Sapphire Cyan',
      'primary': 0xFF0B4C8C,
      'accent': 0xFF00E5FF,
      'desc': 'Nuansa biru laut dalam dengan aksen cyan modern.',
    },
    {
      'name': 'Amethyst Pink',
      'primary': 0xFF4A148C,
      'accent': 0xFFE040FB,
      'desc': 'Nuansa ungu karismatik dengan kilauan pink.',
    },
    {
      'name': 'Ruby Rose',
      'primary': 0xFF880E4F,
      'accent': 0xFFFF8A80,
      'desc': 'Nuansa merah marun menawan berpadu rose.',
    },
    {
      'name': 'Onyx Emerald',
      'primary': 0xFF121212,
      'accent': 0xFF00E676,
      'desc': 'Nuansa hitam pekat dengan sorotan hijau zamrud.',
    },
    {
      'name': 'Crimson Night',
      'primary': 0xFF6A040F,
      'accent': 0xFFE0E0E0,
      'desc': 'Merah tua yang dalam dengan aksen abu-abu terang.',
    },
    {
      'name': 'Oceanic Teal',
      'primary': 0xFF004D40,
      'accent': 0xFF80CBC4,
      'desc': 'Hijau laut gelap yang menenangkan dengan aksen teal muda.',
    },
    {
      'name': 'Royal Indigo',
      'primary': 0xFF1A237E,
      'accent': 0xFFF57F17,
      'desc': 'Biru indigo yang megah dipadukan dengan oranye cerah.',
    },
  ];

  String themePresetsHtml = '';
  for (var preset in themePresets) {
    final isSelected =
        (themePrimaryColor == preset['primary'] &&
        themeAccentColor == preset['accent']);
    final primaryHex =
        '#${(preset['primary'] & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final accentHex =
        '#${(preset['accent'] & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    themePresetsHtml +=
        '''
      <div class="theme-card ${isSelected ? 'active' : ''}" onclick="selectTheme(${preset['primary']}, ${preset['accent']}, this)">
        <div class="theme-preview" style="background: linear-gradient(135deg, $primaryHex, $accentHex);"></div>
        <div class="theme-info">
          <b>${preset['name']}</b><br>
          <small>${preset['desc']}</small>
        </div>
        ${isSelected ? '<span class="check">✓</span>' : ''}
      </div>
    ''';
  }

  final params = <String, dynamic>{
    'mosqueName': mosqueName,
    'mosqueAddress': mosqueAddress,
    'runningText': runningText,
    'notifAdzanDuration': notifAdzanDuration,
    'notifIqomahDelay': notifIqomahDelay,
    'notifIqomahDuration': notifIqomahDuration,
    'notifTextIqomahTimer': notifTextIqomahTimer, // Added
    'notifSholatDuration': notifSholatDuration, // Added
    'notifTextSholat': notifTextSholat, // Added
    'notifTextAdzan': notifTextAdzan,
    'notifTextIqomah': notifTextIqomah,
    'slidesData': slidesData,
    'mediaSchedules': mediaSchedules,
    'mediaLibrary': mediaLibrary,
    'textStyles': textStyles,
    'useApi': useApi,
    'mediaSlidesEnabled': mediaSlidesEnabled, // Added
    'apiProvider': apiProvider,
    'kotaId': kotaId,
    'kotaName': kotaName,
    'hijriAdjustment': hijriAdjustment,
    'prayerTimes': prayerTimes,
    'showHadith': showHadith,
    'hadithInterval': hadithInterval,
    'hadithSpeed': hadithSpeed,
    'manualHadiths': manualHadiths,
    'events': events,
    'murottalSchedules': murottalSchedules,
    'performerProfiles': performerProfiles,
    'scheduledPerformerEvents': scheduledPerformerEvents,
    'currentAssets': currentAssets,
    'availableAssets': availableAssets,
    'iotIp': iotIp,
    'iotPathOn': iotPathOn,
    'iotPathOff': iotPathOff,
    'showImsakiyahScreen': showImsakiyahScreen,
    'imsakiyahProvince': imsakiyahProvince,
    'imsakiyahCity': imsakiyahCity,
    'powerTvEnabled': powerTvEnabled,
    'powerSchedules': powerSchedules,
    'themePrimaryColor': themePrimaryColor,
    'themeAccentColor': themeAccentColor,
    'bgApplyAll': bgApplyAll,
    'logoPath': logoPath,
    'showLogo': showLogo,
    'logoAnimationEnabled': logoAnimationEnabled,
    'rotationDurationSeconds': rotationDurationSeconds,
    'slideshowEffect': slideshowEffect,
    'fridayModeEnabled': fridayModeEnabled,
    'fridayKhutbahDuration': fridayKhutbahDuration,
    'fridayKhutbahText': fridayKhutbahText,
    'tunnelEnabled': tunnelEnabled,
    'vpsHost': vpsHost,
    'vpsUser': vpsUser,
    'vpsPort': vpsPort,
    'publicUrl': publicUrl,
    'logoPathSafe': logoPathSafe,
    'slidesHtml': slidesHtml,
    'mediaHtml': mediaHtml,
    'mediaLibHtml': mediaLibHtml,
    'mediaLibOptions': mediaLibOptions,
    'murottalSchedulesHtml': murottalSchedulesHtml,
    'textSettingsHtml': textSettingsHtml,
    'hadithHtml': hadithHtml,
    'eventHtml': eventHtml,
    'performerProfileHtml': performerProfileHtml,
    'performerScheduleHtml': performerScheduleHtml,
    'performerCheckboxes': performerCheckboxes,
    'prayerInputs': prayerInputs,
    'powerSchedulesHtml': powerSchedulesHtml,
    'themePresetsHtml': themePresetsHtml,
    'prayerNamesForMurottal': prayerNamesForMurottal,
  };

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Admin Panel SIMasjid</title>
$adminStyleCss
$adminScriptJs
</head>
<body>
  <div class="main-container">
    <div class="content">
      <div style="display: flex; align-items: center; margin-bottom: 20px;">
        <button id="back-button" onclick="showMainMenu()" style="display: none; width: auto; padding: 10px 15px; margin-right: 15px; background: #64748b;">&#8592; Kembali</button>
        <h1 id="page-title" style="margin: 0; color: var(--text-primary);">Dashboard</h1>
      </div>

      <div id="main-menu">
        <div class="grid-menu">
          <div class="menu-item" onclick="showSection('identitas', this)"><div class="icon">🏠</div><div class="title">Identitas & Umum</div></div>
          <div class="menu-item" onclick="showSection('jadwal', this)"><div class="icon">🕌</div><div class="title">Jadwal Sholat</div></div>
          <div class="menu-item" onclick="showSection('slide', this)"><div class="icon">📄</div><div class="title">Slide Info</div></div>
          <div class="menu-item" onclick="showSection('running', this)"><div class="icon">⚡</div><div class="title">Running Text</div></div>
          <div class="menu-item" onclick="showSection('notif', this)"><div class="icon">🔔</div><div class="title">Notifikasi</div></div>
          <div class="menu-item" onclick="showSection('media', this)"><div class="icon">🎬</div><div class="title">Media</div></div>
          <div class="menu-item" onclick="showSection('murottal', this)"><div class="icon">🎵</div><div class="title">Murottal</div></div>
          <div class="menu-item" onclick="showSection('hadis', this)"><div class="icon">📚</div><div class="title">Hadis</div></div>
          <div class="menu-item" onclick="showSection('agenda', this)"><div class="icon">📅</div><div class="title">Agenda</div></div>
          <div class="menu-item" onclick="showSection('petugas', this)"><div class="icon">👤</div><div class="title">Petugas</div></div>
          <div class="menu-item" onclick="showSection('iot', this)"><div class="icon">💡</div><div class="title">Smart IoT</div></div>
          <div class="menu-item" onclick="showSection('teks', this)"><div class="icon">✍️</div><div class="title">Teks & Font</div></div>
          <div class="menu-item" onclick="showSection('tema', this)"><div class="icon">🎨</div><div class="title">Tema & Background</div></div>
          <div class="menu-item" onclick="showSection('powertv', this)"><div class="icon">🔌</div><div class="title">Power TV</div></div>
          <div class="menu-item" onclick="showSection('imsakiyah', this)"><div class="icon">🌙</div><div class="title">Imsakiyah</div></div>
          <div class="menu-item" onclick="showSection('remote', this)"><div class="icon">🌐</div><div class="title">Akses Remote</div></div>
          <div class="menu-item" onclick="showSection('donasi', this)"><div class="icon">💖</div><div class="title">Donasi & Dukungan</div></div>
        </div>
      </div>

${buildIdentitasSection(params)}
${buildJadwalSection(params)}
${buildSlideSection(params)}
${buildRunningSection(params)}
${buildNotifSection(params)}
${buildMediaSection(params)}
${buildMurottalSection(params)}
${buildHadisSection(params)}
${buildAgendaSection(params)}
${buildPetugasSection(params)}
${buildIotSection(params)}
${buildTeksSection(params)}
${buildTemaSection(params)}
${buildPowertvSection(params)}
${buildImsakiyahSection(params)}
${buildRemoteSection(params)}
${buildDonasiSection(params)}
  </div>
</body>
</html>
    ''';
}
