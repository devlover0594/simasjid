import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http; // Tambahkan package http
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';
import 'dart:convert';
import 'api_repository.dart';
import 'notifoverlay.dart';
import 'mediaoverlay.dart';
import 'web_admin_html.dart';
import 'hadithscreen.dart';
import 'infoscreen.dart';
import 'eventscreen.dart';
import 'imsakiyahscreen.dart'; // Import the new screen
import 'models/murottal_schedule.dart';
import 'models/slide_item.dart';
import 'performerscreen.dart';

Future<void> main() async {
  // Pastikan binding sudah siap sebelum memanggil fungsi async
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi data lokal untuk format tanggal (misal: 'EEEE, d MMMM yyyy' dalam Bahasa Indonesia)
  await initializeDateFormatting('id_ID', null);
  runApp(const MainApp());
}

// Helper untuk membedakan Asset bawaan vs File Custom
ImageProvider resolveAppImage(String path) {
  if (path.startsWith('/') || path.contains(Platform.pathSeparator)) {
    if (!File(path).existsSync()) {
      return const AssetImage('assets/themes/default/bg.jpg');
    }
    return FileImage(File(path));
  }
  return AssetImage('assets/themes/default/$path');
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Memaksa orientasi landscape untuk tampilan TV/Kiosk
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIMasjid',
      theme: ThemeData.dark().copyWith(
        focusColor: Colors.tealAccent.withOpacity(0.4),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian, untuk kalender, dll.
        Locale('en', 'US'), // English, sebagai fallback
      ],
      locale: const Locale('id', 'ID'),
      home: const KioskScreen(),
    );
  }
}

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

enum NotifState { none, adzan, countdown, khutbah, iqomah, sholat }

class _KioskScreenState extends State<KioskScreen>
    with SingleTickerProviderStateMixin {
  String _timeString = "";
  String _dateString = "";
  String _hijriDateString = "";
  late Timer _timer;

  // Unique display identifier for kiosk pairing
  String? _displayId;

  // Variabel Identitas Masjid
  String _mosqueName = "MASJID AL MUNTAHA";
  String _mosqueAddress = "Perum Bumi Cipta Laras";

  // Asset overrides (dapat diubah lewat Settings) - Default values
  String _headerAsset = 'header.png';
  String _jamAsset = 'jam.png';
  String _cardAsset = 'card.png';
  String _slideAsset = 'slide.png';
  String _sideCardAsset = 'sidecard.png';
  String _bgAsset = 'bg.jpg';
  String _bgDashboard = 'bg.jpg';
  String _bgInfo = 'bg.jpg';
  String _bgEvent = 'bg.jpg';
  String _logoPath = '';
  bool _showLogo = false;
  bool _logoAnimationEnabled = false;
  String _runningTextAsset = 'runningtext.png';
  String _runningText =
      "Selamat Datang di Masjid Al Muntaha. Mohon luruskan dan rapatkan shaf.";
  bool _bgApplyAll = false;
  String _slideshowEffect = 'fade';

  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;

  // Data Slide (Default)
  List<SlideItem> _slidesData = [
    SlideItem(
      title: 'Selamat Datang',
      content: 'Mohon luruskan dan rapatkan shaf sholat.',
    ),
    SlideItem(
      title: 'Kajian Rutin',
      content: 'Setiap Ahad Ba\'da Subuh bersama Ustadz Fulan.',
    ),
    SlideItem(
      title: 'Infaq Pembangunan',
      content: 'Salurkan infaq terbaik anda untuk pembangunan menara.',
    ),
  ];

  // Variabel untuk gesture settings
  int _tapCount = 0;
  Timer? _tapResetTimer;

  // Data jadwal sholat
  List<PrayerTime> _prayerTimes = [
    PrayerTime('Subuh', '--:--'),
    PrayerTime('Dzuhur', '--:--'),
    PrayerTime('Ashar', '--:--'),
    PrayerTime('Maghrib', '--:--'),
    PrayerTime('Isya', '--:--'),
  ];
  late final PrayerTimeService _prayerTimeService;
  String? _kotaId;
  String? _kotaName;
  bool _useApi = true;
  DateTime? _lastPrayerUpdate; // Waktu pembaruan jadwal sholat terakhir
  DateTime? _anchorGregorian;
  int? _anchorHijriDay;
  int? _anchorHijriMonth;
  int? _anchorHijriYear;
  int _hijriAdjustment = -2; // Default adjustment

  // Notifikasi State
  NotifState _notifState = NotifState.none;
  String _currentPrayerName = "";
  int _countdownSeconds = 0;
  Timer? _notifTimer;

  // Notifikasi Settings
  int _notifAdzanDuration = 180; // seconds
  int _notifIqomahDelay = 10; // minutes
  int _notifIqomahDuration = 60; // seconds
  String _notifTextAdzan = "MEMASUKI WAKTU";
  String _notifTextIqomah = "LURUSKAN DAN RAPATKAN SHAF";
  String _notifTextIqomahTimer =
      "DOA ANTARA ADZAN DAN IQOMAH NISCAYA AKAN TERKABUL";
  int _notifSholatDuration = 600; // seconds, default 10 menit
  String _notifTextSholat = "SHOLAT TELAH DIMULAI, HARAP TENANG";

  // Sholat Jumat Settings
  bool _fridayModeEnabled = true;
  int _fridayKhutbahDuration = 30; // minutes
  String _fridayKhutbahText =
      "Harap tenang saat khutbah berlangsung, nonaktifkan ponsel Anda.";

  // Media Schedule State
  List<Map<String, dynamic>> _mediaSchedules = [];
  List<Map<String, dynamic>> _mediaLibrary = [];
  bool _isMediaActive = false;
  bool _isMurottalActive = false; // Flag for Murottal
  bool _mediaSlidesEnabled = false;
  int _currentMediaSlideIndex = 0;
  int _rotationDurationSeconds = 90;
  Map<String, dynamic>? _currentMediaItem;
  Timer? _mediaEndTimer;
  MurottalSchedule? _currentMurottalSchedule; // To store current murottal job

  // Murottal Schedule State
  List<MurottalSchedule> _murottalSchedules = [];

  // Hadith State
  bool _showHadith = true;
  int _hadithInterval = 5; // minutes
  int _hadithSpeed = 30; // seconds
  Map<String, String>? _hadithData;
  Timer? _hadithTimer;
  List<Map<String, String>> _manualHadiths = [];

  // Event State
  List<Map<String, String>> _eventsData = [];

  // IoT Settings State
  String _iotIp = "";
  String _iotPathOn = "/on";
  String _iotPathOff = "/off";

  // Custom Assets State
  List<String> _customAssets = [];
  Color _themePrimaryColor = const Color(0xFF064E3B);
  Color _themeAccentColor = Colors.amber;

  // Performer State
  List<Map<String, dynamic>> _performerProfiles = [];
  List<Map<String, dynamic>> _scheduledPerformerEvents = [];
  Map<String, dynamic>? _activePerformerEvent;

  // Imsakiyah State
  bool _showImsakiyahScreen = false;
  String? _imsakiyahProvince;
  String? _imsakiyahCity;
  // Available Assets List (Sama seperti di settings.dart)
  final List<String> _availableAssets = [
    'bg.jpg',
    'bgnotif.png',
    'card.png',
    'header.png',
    'jam.png',
    'notif1.png',
    'runningtext.png',
    'slide.png',
    'sidecard.png',
  ];

  HttpServer? _webServer;
  final FocusNode _keyboardFocusNode = FocusNode();

  // Text Styles
  Map<String, TextStyle> _textStyles = {};

  // Power TV State
  static const _powerChannel = MethodChannel('com.example.simasjid/power');
  bool _powerTvEnabled = false;
  List<Map<String, String>> _powerSchedules = [];
  bool _isScreenPowerOn = true;

  // Remote Access State
  bool _tunnelEnabled = false;
  String _vpsHost = '';
  String _vpsUser = '';
  int _vpsPort = 22;

  // Screen Rotation State
  int _screenIndex = 0; // 0: Dashboard, 1: Hadith, 2: Info
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _prayerTimeService = PrayerTimeService(api: ApiRepository());
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _logoScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _initializeDisplay(); // Panggil fungsi inisialisasi display
    _updateTime();
    _loadSettings(); // Load setting saat aplikasi mulai (will call _loadPrayerTimes after settings)
    _startWebServer(); // Mulai Web Server untuk kontrol via HP
    _requestStoragePermission(); // Meminta izin penyimpanan saat startup
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  Future<void> _initializeDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('displayId');

    if (storedId == null || storedId.isEmpty) {
      // Jika ID belum ada, buat baru
      storedId = 'SIMASJID-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      await prefs.setString('displayId', storedId);
    }

    setState(() {
      _displayId = storedId;
    });
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      PermissionStatus status;

      // Untuk Android 11 (SDK 30) ke atas, kita butuh MANAGE_EXTERNAL_STORAGE
      if (deviceInfo.version.sdkInt >= 30) {
        status = await Permission.manageExternalStorage.request();
      } else {
        // Untuk versi lebih lama, cukup Permission.storage
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        debugPrint("Izin penyimpanan diberikan.");
      } else if (status.isDenied) {
        debugPrint("Izin penyimpanan ditolak.");
        // Anda bisa menampilkan dialog di sini untuk memberitahu user
        // bahwa fitur impor folder tidak akan berfungsi.
      } else if (status.isPermanentlyDenied) {
        debugPrint("Izin penyimpanan ditolak permanen, buka pengaturan.");
        openAppSettings(); // Buka pengaturan aplikasi agar user bisa mengaktifkan manual
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopWebServer();
    _tapResetTimer?.cancel();
    _notifTimer?.cancel();
    _mediaEndTimer?.cancel();
    _hadithTimer?.cancel();
    _rotationTimer?.cancel();
    _logoController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _startScreenRotation() {
    _rotationTimer?.cancel();
    // Ganti layar setiap durasi yang dikonfigurasi oleh user
    _rotationTimer = Timer.periodic(Duration(seconds: _rotationDurationSeconds), (
      timer,
    ) {
      // Jangan rotasi jika ada notifikasi (Adzan/Iqomah) atau Media sedang main
      if (_notifState != NotifState.none || _isMediaActive) return;

      // Buat daftar layar yang aktif untuk rotasi
      List<int> activeScreens = [0]; // 0: Dashboard (selalu aktif)
      if (_showHadith) activeScreens.add(1); // 1: Hadith
      activeScreens.add(
        2,
      ); // 2: Info (selalu aktif, tampilkan "tidak ada info" jika kosong)
      activeScreens.add(
        3,
      ); // 3: Event (selalu aktif, tampilkan "tidak ada agenda" jika kosong)
      if (_activePerformerEvent != null) {
        activeScreens.add(4); // 4: Performer (hanya aktif jika ada jadwal)
      }
      if (_showImsakiyahScreen) activeScreens.add(5); // 5: Imsakiyah
      if (_mediaSlidesEnabled && _mediaLibrary.isNotEmpty) {
        activeScreens.add(6); // 6: Media Slideshow
      }

      // Cari index dari layar saat ini di dalam daftar layar aktif
      int currentActiveIndex = activeScreens.indexOf(_screenIndex);
      // Jika layar saat ini tidak lagi aktif (misal: jadwal performer sudah lewat), reset ke dashboard
      if (currentActiveIndex == -1) {
        currentActiveIndex = 0;
      }

      // Tentukan index berikutnya dalam daftar layar aktif
      int nextActiveIndex = (currentActiveIndex + 1) % activeScreens.length;

      setState(() {
        // Atur _screenIndex ke layar aktif berikutnya
        _screenIndex = activeScreens[nextActiveIndex];
      });

      if (_screenIndex == 6 && !_isMediaActive) {
        _playNextMediaSlide();
      }

      _checkForActivePerformerEvent();
    });
  }

  void _playNextMediaSlide() {
    if (_mediaLibrary.isEmpty) return;

    final mediaItem =
        _mediaLibrary[_currentMediaSlideIndex % _mediaLibrary.length];
    _currentMediaSlideIndex =
        (_currentMediaSlideIndex + 1) % _mediaLibrary.length;

    final path = mediaItem['path'] as String?;
    final type = mediaItem['type'] as String? ?? 'image';
    if (path == null || path.isEmpty) return;

    _startMedia({
      'path': path,
      'type': type,
      'play_count': 1,
      'is_slideshow': true,
    });
  }

  // --- Web Server Logic ---
  Future<void> _startWebServer() async {
    try {
      _stopWebServer();
      // Listen pada port 8088 (8080 sering bentrok dengan sistem Android TV)
      _webServer = await HttpServer.bind(InternetAddress.anyIPv4, 8088);
      debugPrint('Web Server running on port 8088');

      await for (HttpRequest request in _webServer!) {
        try {
          final method = request.method;
          final path = request.uri.path;

          if (method == 'GET' && (path == '/' || path == '/index.html')) {
            _handleGetRequest(request);
          } else if (method == 'GET' && path == '/get_settings') {
            await _handleGetSettings(request);
          } else if (method == 'POST' && path == '/update_settings') {
            await _handleUpdateSettings(request);
          } else if (method == 'POST' && path == '/add_slide') {
            await _handleAddSlide(request);
          } else if (method == 'GET' && path == '/delete_slide') {
            await _handleDeleteSlide(request);
          } else if (method == 'POST' && path == '/add_media') {
            await _handleAddMedia(request);
          } else if (method == 'GET' && path == '/delete_media') {
            await _handleDeleteMedia(request);
          } else if (method == 'POST' && path == '/add_media_library') {
            await _handleAddMediaLibrary(request);
          } else if (method == 'POST' && path == '/upload_bg') {
            await _handleUploadBg(request);
          } else if (method == 'GET' && path == '/delete_custom_asset') {
            await _handleDeleteCustomAsset(request);
          } else if (method == 'GET' && path == '/delete_media_library') {
            await _handleDeleteMediaLibrary(request);
          } else if (method == 'POST' && path == '/import_folder') {
            await _handleImportFolder(request);
          } else if (method == 'POST' && path == '/add_hadith') {
            await _handleAddHadith(request);
          } else if (method == 'GET' && path == '/delete_hadith') {
            await _handleDeleteHadith(request);
          } else if (method == 'POST' && path == '/add_event') {
            await _handleAddEvent(request);
          } else if (method == 'GET' && path == '/delete_event') {
            await _handleDeleteEvent(request);
          } else if (method == 'POST' && path == '/add_performer_profile') {
            await _handleAddPerformerProfile(request);
          } else if (method == 'GET' && path == '/delete_performer_profile') {
            await _handleDeletePerformerProfile(request);
          } else if (method == 'POST' && path == '/add_performer_schedule') {
            await _handleAddPerformerSchedule(request);
          } else if (method == 'GET' && path == '/delete_performer_schedule') {
            await _handleDeletePerformerSchedule(request);
          } else if (method == 'POST' && path == '/add_power_schedule') {
            await _handleAddPowerSchedule(request);
          } else if (method == 'GET' && path == '/delete_power_schedule') {
            await _handleDeletePowerSchedule(request);
          } else if (method == 'POST' && path == '/upload_asset') {
            await _handleUploadAsset(request);
          } else if (method == 'GET' && path == '/test_iot') {
            await _handleTestIot(request);
          } else if (method == 'GET' && path == '/restart_app') {
            _handleRestartApp(request);
          } else if (method == 'GET' && path == '/reboot_device') {
            _handleRebootDevice(request);
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..write('Not Found')
              ..close();
          }
        } catch (e) {
          debugPrint('Web Server Error: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to start Web Server: $e');
    }
  }

  Future<void> _handleUploadBg(HttpRequest request) async {
    final params = await _parseMultipart(request);
    final filePath = params['bg_file'] as String?;

    if (filePath != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bg_dashboard', filePath);

      // Jika 'apply_all' dicentang, terapkan ke semua background
      if (params['apply_all'] == 'true') {
        await prefs.setString('bg_info', filePath);
        await prefs.setString('bg_event', filePath);
        await prefs.setBool('bg_apply_all', true);
      }

      await _loadSettings(); // Muat ulang pengaturan
      _redirect(request, params['section'] as String?);
    } else {
      _redirect(request, params['section'] as String?);
    }
  }

  Future<void> _handleDeleteCustomAsset(HttpRequest request) async {
    final path = request.uri.queryParameters['path'];
    if (path != null) {
      _customAssets.remove(path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('custom_assets', _customAssets);
      await _loadSettings();
    }
    _redirect(request, request.uri.queryParameters['section']);
  }

  Future<Map<String, dynamic>> _parseMultipart(HttpRequest request) async {
    final result = <String, dynamic>{};
    final boundary = request.headers.contentType?.parameters['boundary'];
    if (boundary == null) return result;

    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer.bind(request).toList();

    for (final part in parts) {
      final disposition = HeaderValue.parse(
        part.headers['content-disposition']!,
      );
      final name = disposition.parameters['name']!;
      final filename = disposition.parameters['filename'];

      if (filename != null) {
        // It's a file
        final appDir = await getApplicationDocumentsDirectory();
        // Sanitize filename to prevent path traversal issues.
        final safeFilename = filename.split(RegExp(r'[/\\]')).last;
        if (safeFilename.isEmpty) continue;

        final filePath = '${appDir.path}${Platform.pathSeparator}$safeFilename';
        final file = File(filePath);

        await part.pipe(file.openWrite());
        result[name] = filePath; // Store the saved path
      } else {
        // It's a text field
        final content = await utf8.decodeStream(part);
        result[name] = content;
      }
    }
    return result;
  }

  void _stopWebServer() {
    _webServer?.close(force: true);
  }

  void _handleGetRequest(HttpRequest request) {
    final textStylesMap = <String, Map<String, dynamic>>{};
    _textStyles.forEach((key, style) {
      textStylesMap[key] = {
        'size': style.fontSize ?? 20.0,
        'color': style.color?.value ?? 0xFFFFFFFF,
        'font': style.fontFamily ?? 'Roboto',
      };
    });

    final prayerTimesList = _prayerTimes
        .map((p) => {'name': p.name, 'time': p.time})
        .toList();

    final currentAssets = {
      'header_asset': _headerAsset,
      'jam_asset': _jamAsset,
      'card_asset': _cardAsset,
      'slide_asset': _slideAsset,
      'sidecard_asset': _sideCardAsset,
      'bg_asset': _bgAsset,
      'bg_dashboard': _bgDashboard,
      'bg_info': _bgInfo,
      'bg_event': _bgEvent,
      'running_text_asset': _runningTextAsset,
    };

    final allAssets = [..._availableAssets, ..._customAssets];

    final html = generateAdminHtml(
      mosqueName: _mosqueName,
      mosqueAddress: _mosqueAddress,
      runningText: _runningText,
      notifAdzanDuration: _notifAdzanDuration,
      notifIqomahDelay: _notifIqomahDelay,
      notifIqomahDuration: _notifIqomahDuration,
      notifTextIqomahTimer: _notifTextIqomahTimer, // Added
      notifSholatDuration: _notifSholatDuration, // Added
      notifTextSholat: _notifTextSholat, // Added
      notifTextAdzan: _notifTextAdzan,
      notifTextIqomah: _notifTextIqomah,
      slidesData: _slidesData,
      mediaSchedules: _mediaSchedules,
      mediaLibrary: _mediaLibrary,
      textStyles: textStylesMap,
      useApi: _useApi,
      mediaSlidesEnabled: _mediaSlidesEnabled, // Added
      apiProvider: _prayerTimeService.provider,
      kotaId: _kotaId ?? '',
      kotaName: _kotaName ?? '',
      hijriAdjustment: _hijriAdjustment,
      prayerTimes: prayerTimesList,
      showHadith: _showHadith,
      hadithInterval: _hadithInterval,
      hadithSpeed: _hadithSpeed,
      manualHadiths: _manualHadiths,
      events: _eventsData,
      murottalSchedules: _murottalSchedules,
      performerProfiles: _performerProfiles,
      scheduledPerformerEvents: _scheduledPerformerEvents,
      currentAssets: currentAssets,
      availableAssets: allAssets,
      iotIp: _iotIp,
      iotPathOn: _iotPathOn,
      iotPathOff: _iotPathOff,
      showImsakiyahScreen: _showImsakiyahScreen,
      imsakiyahProvince: _imsakiyahProvince ?? '',
      imsakiyahCity: _imsakiyahCity ?? '',
      powerTvEnabled: _powerTvEnabled,
      powerSchedules: _powerSchedules,
      themePrimaryColor: _themePrimaryColor.value,
      themeAccentColor: _themeAccentColor.value,
      bgApplyAll: _bgApplyAll,
      logoPath: _logoPath,
      showLogo: _showLogo,
      logoAnimationEnabled: _logoAnimationEnabled,
      rotationDurationSeconds: _rotationDurationSeconds,
      slideshowEffect: _slideshowEffect,
      fridayModeEnabled: _fridayModeEnabled,
      fridayKhutbahDuration: _fridayKhutbahDuration,
      fridayKhutbahText: _fridayKhutbahText,
      displayId: _displayId ?? 'N/A',
      tunnelEnabled: _tunnelEnabled,
      vpsHost: _vpsHost,
      vpsUser: _vpsUser,
      vpsPort: _vpsPort,
      publicUrl: null, // publicUrl akan di-handle oleh SshTunnelManager
    );

    request.response
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }

  Future<void> _handleGetSettings(HttpRequest request) async {
    final prayerTimesList = _prayerTimes
        .map((p) => {'name': p.name, 'time': p.time})
        .toList();

    final murottalSchedulesList = _murottalSchedules.map((s) {
      // Konversi setiap jadwal murottal menjadi Map yang aman untuk JSON
      // Ini akan mengatasi error jika ada tipe data yang tidak bisa di-encode
      return s.toJson();
    }).toList();
    final styleData = <String, String>{};
    _textStyles.forEach((key, style) {
      styleData['style_${key}_size'] = (style.fontSize ?? 20.0).toString();
      styleData['style_${key}_font'] = style.fontFamily ?? 'Roboto';
      final colorValue = style.color?.value ?? 0xFFFFFFFF;
      styleData['style_${key}_color'] =
          '#${(colorValue & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    });

    final responseData = <String, dynamic>{
      'mosque_name': _mosqueName,
      'mosque_address': _mosqueAddress,
      'running_text': _runningText,
      'adzan_duration': _notifAdzanDuration.toString(),
      'iqomah_delay': _notifIqomahDelay.toString(),
      'iqomah_duration': _notifIqomahDuration.toString(),
      'notif_text_iqomah_timer': _notifTextIqomahTimer, // Added
      'notif_sholat_duration': _notifSholatDuration.toString(), // Added
      'notif_text_sholat': _notifTextSholat, // Added
      'text_adzan': _notifTextAdzan,
      'text_iqomah': _notifTextIqomah,
      'friday_mode_enabled': _fridayModeEnabled.toString(),
      'friday_khutbah_duration': _fridayKhutbahDuration.toString(),
      'friday_khutbah_text': _fridayKhutbahText,
      'hijri_adjustment': _hijriAdjustment.toString(),
      'use_api': _useApi.toString(),
      'media_slideshow_enabled': _mediaSlidesEnabled.toString(), // Added
      'api_provider': _prayerTimeService.provider,
      'kota_id': _kotaId ?? '',
      'kota_name': _kotaName ?? '',
      'manual_prayer_times': prayerTimesList,
      'hadith_show': _showHadith.toString(),
      'hadith_interval': _hadithInterval.toString(),
      'hadith_speed': _hadithSpeed.toString(),
      'iot_ip': _iotIp,
      'iot_path_on': _iotPathOn,
      'iot_path_off': _iotPathOff,
      'power_tv_enabled': _powerTvEnabled.toString(),
      'show_imsakiyah_screen': _showImsakiyahScreen.toString(),
      'imsakiyah_province': _imsakiyahProvince ?? '',
      'imsakiyah_city': _imsakiyahCity ?? '',
      'apply_all': _bgApplyAll.toString(),
      'logo_path': _logoPath,
      'show_logo': _showLogo.toString(),
      'logo_animation_enabled': _logoAnimationEnabled.toString(),
      'rotation_duration_seconds': _rotationDurationSeconds.toString(),
      'slideshow_effect': _slideshowEffect,
      'running_text_asset': _runningTextAsset,
      'header_asset': _headerAsset,
      'jam_asset': _jamAsset,
      'card_asset': _cardAsset,
      'slide_asset': _slideAsset,
      'sidecard_asset': _sideCardAsset,
      'bg_asset': _bgAsset,
      'bg_dashboard': _bgDashboard,
      'bg_info': _bgInfo,
      'bg_event': _bgEvent,
      'murottal_schedules': murottalSchedulesList,
      ...styleData,
    };

    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(responseData))
      ..close();
  }

  Future<void> _handleUpdateSettings(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    Map<String, String> params = {};
    try {
      params = Uri.splitQueryString(content);
      debugPrint('Received update_settings params: $params');
      final prefs = await SharedPreferences.getInstance();

      if (params['mosque_name'] != null) {
        await prefs.setString(
          'mosque_name',
          Uri.decodeComponent(params['mosque_name']!).replaceAll('+', ' '),
        );
      }
      if (params['mosque_address'] != null) {
        await prefs.setString(
          'mosque_address',
          Uri.decodeComponent(params['mosque_address']!).replaceAll('+', ' '),
        );
      }
      if (params['running_text'] != null) {
        await prefs.setString(
          'running_text',
          Uri.decodeComponent(params['running_text']!).replaceAll('+', ' '),
        );
      }

      if (params['adzan_duration'] != null) {
        await prefs.setInt(
          'notif_adzan_duration',
          int.tryParse(params['adzan_duration']!) ?? 180,
        );
      }
      if (params['iqomah_delay'] != null) {
        await prefs.setInt(
          'notif_iqomah_delay',
          int.tryParse(params['iqomah_delay']!) ?? 10,
        );
      }
      if (params['iqomah_duration'] != null) {
        await prefs.setInt(
          'notif_iqomah_duration',
          int.tryParse(params['iqomah_duration']!) ?? 60,
        );
      }

      if (params['text_adzan'] != null) {
        await prefs.setString(
          'notif_text_adzan',
          Uri.decodeComponent(params['text_adzan']!).replaceAll('+', ' '),
        );
      }
      if (params['text_iqomah'] != null) {
        await prefs.setString(
          'notif_text_iqomah',
          Uri.decodeComponent(params['text_iqomah']!).replaceAll('+', ' '),
        );
      }

      if (params['friday_mode_enabled'] != null) {
        await prefs.setBool(
          'friday_mode_enabled',
          params['friday_mode_enabled'] == 'true',
        );
      }
      if (params['friday_khutbah_duration'] != null) {
        await prefs.setInt(
          'friday_khutbah_duration',
          int.tryParse(params['friday_khutbah_duration']!) ?? 30,
        );
      }
      if (params['friday_khutbah_text'] != null) {
        await prefs.setString(
          'friday_khutbah_text',
          Uri.decodeComponent(
            params['friday_khutbah_text']!,
          ).replaceAll('+', ' '),
        );
      }

      // Handle new notification settings
      if (params['notif_text_iqomah_timer'] != null) {
        await prefs.setString(
          'notif_text_iqomah_timer',
          Uri.decodeComponent(
            params['notif_text_iqomah_timer']!,
          ).replaceAll('+', ' '),
        );
      }
      if (params['notif_sholat_duration'] != null) {
        await prefs.setInt(
          'notif_sholat_duration',
          int.tryParse(params['notif_sholat_duration']!) ?? 600,
        );
      }
      if (params['notif_text_sholat'] != null) {
        await prefs.setString(
          'notif_text_sholat',
          Uri.decodeComponent(
            params['notif_text_sholat']!,
          ).replaceAll('+', ' '),
        );
      }
      // Handle Hijri Adjustment
      if (params['hijri_adjustment'] != null) {
        await prefs.setInt(
          'hijri_adjustment',
          int.tryParse(params['hijri_adjustment']!) ?? -2,
        );
      }

      // Handle Prayer Settings
      if (params['use_api'] != null) {
        await prefs.setBool(
          'use_api_prayer_times',
          params['use_api'] == 'true',
        );
      }
      if (params['kota_id'] != null) {
        await prefs.setString('kota_id', params['kota_id']!);
      }
      if (params['api_provider'] != null) {
        await prefs.setString('api_provider', params['api_provider']!);
      }
      if (params['kota_name'] != null) {
        await prefs.setString(
          'kota_name',
          Uri.decodeComponent(params['kota_name']!).replaceAll('+', ' '),
        );
      }

      // Handle Manual Prayer Times Update
      bool manualUpdated = false;
      final newPrayerTimes = _prayerTimes
          .map((p) => {'name': p.name, 'time': p.time})
          .toList();
      for (var p in newPrayerTimes) {
        final key = 'prayer_${p['name']}';
        if (params.containsKey(key)) {
          p['time'] = Uri.decodeComponent(params[key]!).replaceAll('%3A', ':');
          manualUpdated = true;
        }
      }
      if (manualUpdated) {
        await prefs.setString(
          'custom_prayer_times',
          jsonEncode(newPrayerTimes),
        );
      }

      // Handle Hadith Settings
      if (params['hadith_show'] != null) {
        await prefs.setBool('hadith_show', params['hadith_show'] == 'true');
      }
      if (params['hadith_interval'] != null) {
        await prefs.setInt(
          'hadith_interval',
          int.tryParse(params['hadith_interval']!) ?? 5,
        );
      }
      if (params['hadith_speed'] != null) {
        await prefs.setInt(
          'hadith_speed',
          int.tryParse(params['hadith_speed']!) ?? 30,
        );
      }

      // Handle Style Updates
      for (final key in params.keys) {
        if (key.startsWith('style_')) {
          final value = params[key]!;
          if (key.endsWith('_size')) {
            final element = key.substring(6, key.length - 5);
            await prefs.setDouble(
              '${element}_size',
              double.tryParse(value) ?? 20.0,
            );
          } else if (key.endsWith('_font')) {
            final element = key.substring(6, key.length - 5);
            await prefs.setString('${element}_font', value);
          } else if (key.endsWith('_color')) {
            final element = key.substring(6, key.length - 6);
            if (value.startsWith('#') && value.length == 7) {
              await prefs.setInt(
                '${element}_color',
                int.parse('FF${value.substring(1)}', radix: 16),
              );
            }
          }
        }
      }

      // Handle IoT Settings
      if (params['iot_ip'] != null) {
        await prefs.setString('iot_ip', Uri.decodeComponent(params['iot_ip']!));
      }
      if (params['iot_path_on'] != null) {
        await prefs.setString(
          'iot_path_on',
          Uri.decodeComponent(params['iot_path_on']!),
        );
      }
      if (params['iot_path_off'] != null) {
        await prefs.setString(
          'iot_path_off',
          Uri.decodeComponent(params['iot_path_off']!),
        );
      }

      // Handle Power TV Settings
      if (params['power_tv_enabled'] != null) {
        await prefs.setBool(
          'power_tv_enabled',
          params['power_tv_enabled'] == 'true',
        );
      }

      // Handle Asset Settings
      final assetKeys = [
        'header_asset',
        'jam_asset',
        'card_asset',
        'slide_asset',
        'sidecard_asset',
        'bg_asset',
        'bg_dashboard',
        'bg_info',
        'bg_event',
        'running_text_asset',
      ];
      for (var key in assetKeys) {
        if (params[key] != null) {
          await prefs.setString(key, params[key]!);
        }
      }

      // Handle Imsakiyah & Background Apply All
      if (params['media_slideshow_enabled'] != null) {
        await prefs.setBool(
          'media_slideshow_enabled',
          params['media_slideshow_enabled'] == 'true',
        );
      }
      if (params['show_imsakiyah_screen'] != null) {
        await prefs.setBool(
          'show_imsakiyah_screen',
          params['show_imsakiyah_screen'] == 'true',
        );
      }
      if (params['imsakiyah_province'] != null) {
        await prefs.setString(
          'imsakiyah_province',
          Uri.decodeComponent(
            params['imsakiyah_province']!,
          ).replaceAll('+', ' '),
        );
      }
      if (params['imsakiyah_city'] != null) {
        await prefs.setString(
          'imsakiyah_city',
          Uri.decodeComponent(params['imsakiyah_city']!).replaceAll('+', ' '),
        );
      }
      if (params['action'] == 'update_apply_all' &&
          params['apply_all'] != null) {
        await prefs.setBool('bg_apply_all', params['apply_all'] == 'true');
      } else if (params['action'] == 'update_apply_all') {
        // If action is update_apply_all but checkbox is missing, it means it's unchecked
        await prefs.setBool('bg_apply_all', false);
      }

      if (params['action'] == 'update_theme_settings') {
        if (params['logo_path'] != null) {
          await prefs.setString('logo_path', params['logo_path']!);
        }
        await prefs.setBool('show_logo', params['show_logo'] == 'true');
        await prefs.setBool(
          'logo_animation_enabled',
          params['logo_animation_enabled'] == 'true',
        );
        if (params['rotation_duration_seconds'] != null) {
          await prefs.setInt(
            'rotation_duration_seconds',
            int.tryParse(params['rotation_duration_seconds']!) ?? 90,
          );
        }
        if (params['slideshow_effect'] != null) {
          await prefs.setString(
            'slideshow_effect',
            params['slideshow_effect']!,
          );
        }
      }

      // Handle Theme Color Update
      if (params['theme_primary'] != null) {
        await prefs.setInt(
          'theme_primary_color',
          int.tryParse(params['theme_primary']!) ?? 0xFF064E3B,
        );
      }
      if (params['theme_accent'] != null) {
        await prefs.setInt(
          'theme_accent_color',
          int.tryParse(params['theme_accent']!) ?? Colors.amber.value,
        );
      }

      // Handle Murottal Settings
      final prayerNamesForMurottal = [
        'Subuh',
        'Dzuhur',
        'Ashar',
        'Maghrib',
        'Isya',
      ];
      bool murottalUpdated = false;
      List<Map<String, dynamic>> newMurottalSchedules = [];

      for (final prayerName in prayerNamesForMurottal) {
        final prefix = 'murottal_${prayerName}_';
        if (params.containsKey('${prefix}prayer')) {
          murottalUpdated = true;
          newMurottalSchedules.add({
            'prayer': params['${prefix}prayer'],
            'enabled': params['${prefix}enabled'] == 'true',
            'minutes_before':
                int.tryParse(params['${prefix}minutes_before'] ?? '10') ?? 10,
            'is_random': params['${prefix}is_random'] == 'true',
            'loop_count':
                int.tryParse(params['${prefix}loop_count'] ?? '1') ?? 1,
            'stop_before_adzan':
                int.tryParse(params['${prefix}stop_before_adzan'] ?? '2') ?? 2,
            'path': params['${prefix}path'],
            'source_type': params['${prefix}source_type'],
            'qari': params['${prefix}qari'],
            'surah_number':
                int.tryParse(params['${prefix}surah_number'] ?? '1') ?? 1,
            // Save Tarhim and Adzan settings
            'tarhim_enabled': params['${prefix}tarhim_enabled'] == 'true',
            'tarhim_minutes_before':
                int.tryParse(
                  params['${prefix}tarhim_minutes_before'] ?? '20',
                ) ??
                20,
            'adzan_enabled': params['${prefix}adzan_enabled'] == 'true',
          });
        }
      }

      if (murottalUpdated) {
        await prefs.setString(
          'murottal_schedules',
          jsonEncode(newMurottalSchedules),
        );
      }

      await _loadSettings();
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'success',
            'message': 'Pengaturan berhasil disimpan!',
          }),
        )
        ..close();
    } catch (e, st) {
      debugPrint('Error in _handleUpdateSettings: $e\n$st');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'Terjadi kesalahan server: $e',
          }),
        )
        ..close();
      return; // Exit to prevent calling _redirect in finally
    }
  }

  Future<void> _handleAddSlide(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    final params = Uri.splitQueryString(content);
    debugPrint('Received add_slide params: $params');

    final title = Uri.decodeComponent(
      params['title'] ?? '',
    ).replaceAll('+', ' ');
    final contentText = Uri.decodeComponent(
      params['content'] ?? '',
    ).replaceAll('+', ' ');
    final index = int.tryParse(params['index'] ?? '-1') ?? -1;

    if (title.isNotEmpty) {
      final newItem = SlideItem(title: title, content: contentText);
      if (index >= 0 && index < _slidesData.length) {
        _slidesData[index] = newItem;
      } else {
        _slidesData.add(newItem);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'slides',
        jsonEncode(_slidesData.map((s) => s.toJson()).toList()),
      );
      await _loadSettings(); // Reload settings to update UI
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'success',
            'message': 'Slide berhasil ditambahkan/diperbarui.',
          }),
        )
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'Judul slide tidak boleh kosong.',
          }),
        )
        ..close();
    }
  }

  Future<void> _handleDeleteSlide(HttpRequest request) async {
    final indexStr = request.uri.queryParameters['i'];
    if (indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _slidesData.length) {
        _slidesData.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'slides',
          jsonEncode(_slidesData.map((s) => s.toJson()).toList()),
        );
        await _loadSettings();
      }
    }
    _redirect(request, request.uri.queryParameters['section']);
  }

  Future<void> _handleAddMedia(HttpRequest request) async {
    final params = await _parseMultipart(request);

    debugPrint('Received add_media params: $params');
    // If a file is uploaded, it overrides the text path.
    String path =
        params['media_file'] as String? ?? params['path'] as String? ?? '';

    final type = params['type'] as String? ?? 'image';
    final time = params['time'] as String? ?? '12:00';
    final isLoop = params['is_loop'] == 'true';
    final playCount = int.tryParse(params['play_count'] as String? ?? '1') ?? 1;
    final index = int.tryParse(params['index'] as String? ?? '-1') ?? -1;

    List<int> days = [];
    for (int i = 1; i <= 7; i++) {
      if (params.containsKey('day_$i')) {
        days.add(i);
      }
    }

    // Jika edit dan tidak ada file baru, gunakan path lama
    if (path.isEmpty && index >= 0 && index < _mediaSchedules.length) {
      path = _mediaSchedules[index]['path'];
    }

    if (path.isNotEmpty) {
      final newItem = {
        'path': path,
        'type': type,
        'time': time,
        'is_loop': isLoop,
        'play_count': playCount,
        'days': days,
      };

      if (index >= 0 && index < _mediaSchedules.length) {
        _mediaSchedules[index] = newItem;
      } else {
        _mediaSchedules.add(newItem);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('media_schedules', jsonEncode(_mediaSchedules));
      await _loadSettings(); // Reload settings to update UI
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'success',
            'message': 'Jadwal media berhasil ditambahkan/diperbarui.',
          }),
        )
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'Path media tidak boleh kosong.',
          }),
        )
        ..close();
    }
    _redirect(request, params['section'] as String?);
  }

  Future<void> _handleDeleteMedia(HttpRequest request) async {
    final indexStr = request.uri.queryParameters['i'];
    if (indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _mediaSchedules.length) {
        _mediaSchedules.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('media_schedules', jsonEncode(_mediaSchedules));
        await _loadSettings();
      }
    }
    _redirect(request, request.uri.queryParameters['section']);
  }

  Future<void> _handleAddMediaLibrary(HttpRequest request) async {
    final params = await _parseMultipart(request);

    debugPrint('Received add_media_library params: $params');
    String path =
        params['media_file'] as String? ?? params['path'] as String? ?? '';
    final name = params['name'] as String? ?? 'Media Baru';
    final type = params['type'] as String? ?? 'image';
    final index = int.tryParse(params['index'] as String? ?? '-1') ?? -1;
    final id =
        params['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // Jika edit dan tidak ada file baru, gunakan path lama
    if (path.isEmpty && index >= 0 && index < _mediaLibrary.length) {
      path = _mediaLibrary[index]['path'];
    }

    if (path.isNotEmpty) {
      final newItem = {'id': id, 'name': name, 'path': path, 'type': type};

      if (index >= 0 && index < _mediaLibrary.length) {
        _mediaLibrary[index] = newItem;
      } else {
        _mediaLibrary.add(newItem);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('media_library', jsonEncode(_mediaLibrary));
      await _loadSettings(); // Reload settings to update UI
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'success',
            'message': 'Media library berhasil ditambahkan/diperbarui.',
          }),
        )
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'Path media tidak boleh kosong.',
          }),
        )
        ..close();
    }
    _redirect(request, params['section'] as String?);
  }

  Future<void> _handleDeleteMediaLibrary(HttpRequest request) async {
    final indexStr = request.uri.queryParameters['i'];
    if (indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _mediaLibrary.length) {
        // Hapus file fisik jika berada di direktori aplikasi
        final itemToDelete = _mediaLibrary[index];
        final path = itemToDelete['path'] as String?;
        if (path != null && path.isNotEmpty) {
          try {
            final appDir = await getApplicationDocumentsDirectory();
            if (path.startsWith(appDir.path)) {
              final file = File(path);
              if (await file.exists()) await file.delete();
            }
          } catch (e) {
            debugPrint("Gagal menghapus file dari web admin: $e");
          }
        }
      }
      if (index != null && index >= 0 && index < _mediaLibrary.length) {
        _mediaLibrary.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('media_library', jsonEncode(_mediaLibrary));
        await _loadSettings();
      }
    }
    _redirect(request, request.uri.queryParameters['section']);
  }

  Future<void> _handleImportFolder(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    final params = Uri.splitQueryString(content);
    final folderPath = params['folder_path'];

    if (folderPath != null && folderPath.isNotEmpty) {
      try {
        final dir = Directory(folderPath);
        if (await dir.exists()) {
          final List<FileSystemEntity> entities = await dir.list().toList();
          final List<Map<String, dynamic>> newItems = [];
          final supportedExtensions = [
            '.jpg',
            '.jpeg',
            '.png',
            '.mp4',
            '.mkv',
            '.avi',
            '.mp3',
          ];

          for (var entity in entities) {
            if (entity is File) {
              final path = entity.path;
              final extension = path
                  .substring(path.lastIndexOf('.'))
                  .toLowerCase();
              if (supportedExtensions.contains(extension)) {
                String type;
                if (['.jpg', '.jpeg', '.png'].contains(extension)) {
                  type = 'image';
                } else if (['.mp4', '.mkv', '.avi'].contains(extension)) {
                  type = 'video';
                } else {
                  type = 'audio';
                }

                // Hindari duplikat
                if (!_mediaLibrary.any((item) => item['path'] == path)) {
                  newItems.add({
                    'id':
                        '${DateTime.now().millisecondsSinceEpoch}${path.hashCode}',
                    'name': path.split(Platform.pathSeparator).last,
                    'path': path,
                    'type': type,
                  });
                }
              }
            }
          }
          _mediaLibrary.addAll(newItems);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('media_library', jsonEncode(_mediaLibrary));
          await _loadSettings(); // Reload settings to update UI
          request.response
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'status': 'success',
                'message': 'Folder berhasil diimpor ke media library.',
              }),
            )
            ..close();
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write(
              jsonEncode({
                'status': 'error',
                'message': 'Folder tidak ditemukan.',
              }),
            )
            ..close();
        }
      } catch (e) {
        debugPrint("Error importing folder from web: $e");
      }
    }
    _redirect(request, params['section']);
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write(
        jsonEncode({
          'status': 'error',
          'message': 'Path folder tidak boleh kosong.',
        }),
      )
      ..close();
  }

  Future<void> _handleAddPowerSchedule(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    final paramsAll = <String, List<String>>{};
    for (final pair in content.split('&')) {
      final kv = pair.split('=');
      if (kv.isNotEmpty) {
        final key = Uri.decodeQueryComponent(kv[0]);
        final value = kv.length > 1 ? Uri.decodeQueryComponent(kv[1]) : '';
        paramsAll.putIfAbsent(key, () => []).add(value);
      }
    }

    final onTime = paramsAll['on_time']?.first ?? '04:00';
    final offTime = paramsAll['off_time']?.first ?? '21:00';
    final days = paramsAll['days'] ?? ['1', '2', '3', '4', '5', '6', '7'];
    final index = int.tryParse(paramsAll['index']?.first ?? '-1') ?? -1;

    final newItem = {'on': onTime, 'off': offTime, 'days': days.join(',')};
    if (index >= 0 && index < _powerSchedules.length) {
      _powerSchedules[index] = newItem;
    } else {
      _powerSchedules.add(newItem);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('power_schedules', jsonEncode(_powerSchedules));
    await _loadSettings(); // Reload settings to update UI
    request.response
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode({
          'status': 'success',
          'message': 'Jadwal Power TV berhasil ditambahkan/diperbarui.',
        }),
      )
      ..close();
  }

  Future<void> _handleDeletePowerSchedule(HttpRequest request) async {
    final indexStr = request.uri.queryParameters['i'];
    if (indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _powerSchedules.length) {
        _powerSchedules.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('power_schedules', jsonEncode(_powerSchedules));
        await _loadSettings();
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'status': 'success',
              'message': 'Jadwal Power TV berhasil dihapus.',
            }),
          )
          ..close();
        return; // Penting: return setelah mengirim respons
      }
    }
    // Jika indeks null atau tidak valid, kirim respons error
    request.response
      ..statusCode = HttpStatus.badRequest
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode({
          'status': 'error',
          'message': 'Gagal menghapus jadwal Power TV: Indeks tidak valid.',
        }),
      )
      ..close();
  }

  Future<void> _handleAddHadith(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    Map<String, String> params = {};
    try {
      params = Uri.splitQueryString(content);
      debugPrint('Received add_hadith params: $params');
      final text = Uri.decodeComponent(
        params['text'] ?? '',
      ).replaceAll('+', ' ');
      final source = Uri.decodeComponent(
        params['source'] ?? '',
      ).replaceAll('+', ' ');
      final index = int.tryParse(params['index'] ?? '-1') ?? -1;

      if (text.isNotEmpty && source.isNotEmpty) {
        final newItem = {'text': text, 'source': source};
        if (index >= 0 && index < _manualHadiths.length) {
          _manualHadiths[index] = newItem;
        } else {
          _manualHadiths.add(newItem);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_hadiths', jsonEncode(_manualHadiths));
        await _loadSettings(); // Reload settings to update UI
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'status': 'success',
              'message': 'Hadis berhasil ditambahkan/diperbarui.',
            }),
          )
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write(
            jsonEncode({
              'status': 'error',
              'message': 'Teks dan sumber hadis tidak boleh kosong.',
            }),
          )
          ..close();
      }
    } catch (e, st) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'Terjadi kesalahan server: $e',
          }),
        )
        ..close();
      return; // Exit to prevent calling _redirect in finally
    }
  }

  Future<void> _handleDeleteHadith(HttpRequest request) async {
    final indexStr = request.uri.queryParameters['i'];
    if (indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _manualHadiths.length) {
        _manualHadiths.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_hadiths', jsonEncode(_manualHadiths));
        await _loadSettings();
      }
    }
    _redirect(request, request.uri.queryParameters['section']);
  }

  Future<void> _handleAddEvent(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    final params = Uri.splitQueryString(content);
    debugPrint('Received add_event params: $params');
    final title = Uri.decodeComponent(
      params['title'] ?? '',
    ).replaceAll('+', ' ');
    final date = Uri.decodeComponent(params['date'] ?? '');
    final index = int.tryParse(params['index'] ?? '-1') ?? -1;

    if (title.isNotEmpty && date.isNotEmpty) {
      final newItem = {'title': title, 'date': date};
      if (index >= 0 && index < _eventsData.length) {
        _eventsData[index] = newItem;
      } else {
        _eventsData.add(newItem);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('events', jsonEncode(_eventsData));
      await _loadSettings(); // Reload settings to update UI
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'success',
            'message': 'Agenda berhasil ditambahkan/diperbarui.',
          }),
        )
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'Judul dan tanggal agenda tidak boleh kosong.',
          }),
        )
        ..close();
    }
    _redirect(request, params['section']);
  }

  Future<void> _handleDeleteEvent(HttpRequest request) async {
    final indexStr = request.uri.queryParameters['i'];
    if (indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _eventsData.length) {
        _eventsData.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('events', jsonEncode(_eventsData));
        await _loadSettings();
      }
    }
    _redirect(request, request.uri.queryParameters['section']);
  }

  Future<void> _handleAddPerformerProfile(HttpRequest request) async {
    final params = await _parseMultipart(request);
    final name = params['name'] as String? ?? '';
    debugPrint('Received add_performer_profile params: $params');
    final role = params['role'] as String? ?? '';
    final photoPath =
        params['photo'] as String?; // 'photo' is the file input name
    final index = int.tryParse(params['index'] as String? ?? '-1') ?? -1;

    if (name.isNotEmpty && role.isNotEmpty) {
      String? finalPhoto = photoPath;
      String id = DateTime.now().millisecondsSinceEpoch.toString();

      if (index >= 0 && index < _performerProfiles.length) {
        id = _performerProfiles[index]['id'];
        finalPhoto ??= _performerProfiles[index]['photoPath'];
      }

      final newProfile = {
        'id': id,
        'name': name,
        'role': role,
        'photoPath': finalPhoto,
      };

      if (index >= 0 && index < _performerProfiles.length) {
        _performerProfiles[index] = newProfile;
      } else {
        _performerProfiles.add(newProfile);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'performer_profiles',
        jsonEncode(_performerProfiles),
      );
      await _loadSettings(); // Reload settings to update UI
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'success',
            'message': 'Profil petugas berhasil ditambahkan/diperbarui.',
          }),
        )
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'Nama dan peran petugas tidak boleh kosong.',
          }),
        )
        ..close();
    }
    _redirect(request, params['section'] as String?);
  }

  Future<void> _handleDeletePerformerProfile(HttpRequest request) async {
    final indexStr = request.uri.queryParameters['i'];
    if (indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _performerProfiles.length) {
        _performerProfiles.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'performer_profiles',
          jsonEncode(_performerProfiles),
        );
        await _loadSettings();
      }
    }
    _redirect(
      request,
      request.uri.queryParameters['section'],
    ); // Corrected: Use request.uri.queryParameters
    debugPrint(
      'Redirecting after delete_performer_profile to: ${request.uri.queryParameters['section']}',
    ); // Corrected: Use request.uri.queryParameters
  }

  Future<void> _handleAddPerformerSchedule(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    final paramsAll = <String, List<String>>{};
    for (final pair in content.split('&')) {
      final kv = pair.split('=');
      if (kv.isNotEmpty) {
        final key = Uri.decodeQueryComponent(kv[0]);
        final value = kv.length > 1 ? Uri.decodeQueryComponent(kv[1]) : '';
        paramsAll.putIfAbsent(key, () => []).add(value);
      }
    }

    debugPrint('Received add_performer_schedule params: $paramsAll');
    final name = paramsAll['name']?.first ?? '';
    final date = paramsAll['date']?.first ?? '';
    final endDate = paramsAll['endDate']?.first ?? '';
    final performerIds = paramsAll['performer_ids'] ?? [];
    final index = int.tryParse(paramsAll['index']?.first ?? '-1') ?? -1;

    if (name.isNotEmpty && date.isNotEmpty) {
      final newSchedule = {
        'name': name,
        'date': date,
        'endDate': endDate.isNotEmpty ? endDate : date,
        'performerIds': performerIds,
      };

      if (index >= 0 && index < _scheduledPerformerEvents.length) {
        _scheduledPerformerEvents[index] = newSchedule;
      } else {
        _scheduledPerformerEvents.add(newSchedule);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'performer_schedules',
        jsonEncode(_scheduledPerformerEvents),
      );
      await _loadSettings(); // Reload settings to update UI
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'success',
            'message': 'Jadwal petugas berhasil ditambahkan/diperbarui.',
          }),
        )
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'Nama dan tanggal jadwal tidak boleh kosong.',
          }),
        )
        ..close();
    }
    _redirect(request, paramsAll['section']?.first);
  }

  Future<void> _handleDeletePerformerSchedule(HttpRequest request) async {
    final indexStr = request.uri.queryParameters['i'];
    if (indexStr != null) {
      final index = int.tryParse(indexStr);
      if (index != null &&
          index >= 0 &&
          index < _scheduledPerformerEvents.length) {
        _scheduledPerformerEvents.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'performer_schedules',
          jsonEncode(_scheduledPerformerEvents),
        );
        await _loadSettings();
      }
    }
    _redirect(request, request.uri.queryParameters['section']);
  }

  Future<void> _handleUploadAsset(HttpRequest request) async {
    final params = await _parseMultipart(request);
    final filePath = params['asset_file'] as String?;

    if (filePath != null) {
      final prefs = await SharedPreferences.getInstance();
      if (!_customAssets.contains(filePath)) {
        debugPrint('Uploading asset: $filePath');
        _customAssets.add(filePath);
        await prefs.setStringList('custom_assets', _customAssets);
      }
      await _loadSettings(); // Reload settings to update UI
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'success',
            'message': 'Aset berhasil diunggah.',
          }),
        )
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          jsonEncode({
            'status': 'error',
            'message': 'File aset tidak ditemukan.',
          }),
        )
        ..close();
    }
  }

  Future<void> _handleTestIot(HttpRequest request) async {
    final turnOn = request.uri.queryParameters['action'] == 'on';
    await _triggerRelay(turnOn);
    _redirect(request, request.uri.queryParameters['section']);
  }

  void _handleRestartApp(HttpRequest request) {
    // This is a bit of a hack. In a real production app, you'd use a more robust
    // mechanism like a platform channel to ask the OS to restart the app.
    // For now, we'll just exit, and if the app is run as a service, it might be
    // restarted by the system.
    _redirect(request, null); // Redirect first to close the connection
    Future.delayed(const Duration(seconds: 1), () => exit(0));
  }

  void _handleRebootDevice(HttpRequest request) {
    // This requires root access on the device, which is common for kiosks.
    // It might not work on standard consumer Android devices.
    _redirect(request, null);
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        await Process.run('su', ['-c', 'reboot']);
      } catch (e) {
        debugPrint("Failed to reboot device: $e. Root access may be required.");
        // As a fallback, restart the app
        exit(0);
      }
    });
  }

  void _redirect(HttpRequest request, String? sectionId) {
    String redirectUrl = '/';
    if (sectionId != null && sectionId.isNotEmpty) {
      debugPrint('Redirecting to section: $sectionId');
      redirectUrl = '/#$sectionId';
    } else {
      debugPrint('Redirecting to root (no section specified)');
    }
    request.response
      ..redirect(Uri.parse(redirectUrl), status: HttpStatus.movedTemporarily)
      ..close();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Text Styles
    Map<String, TextStyle> defaultStyles = {
      'mosque_name': const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        fontFamily: 'Cairo',
        color: Color.fromARGB(255, 130, 241, 2),
      ),
      'mosque_address': const TextStyle(
        fontSize: 18,
        color: Color.fromRGBO(255, 255, 255, 0.9),
      ),
      'clock': const TextStyle(
        fontSize: 68,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        color: Color.fromARGB(255, 7, 255, 48),
        fontFamily: 'Cairo',
      ),
      'date': const TextStyle(fontSize: 30, color: Colors.white),
      'running_text': const TextStyle(
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      'slide_title': const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.amber,
      ),
      'slide_content': const TextStyle(fontSize: 18, color: Colors.white),
      'prayer_name': const TextStyle(
        fontSize: 20,
        color: Colors.amberAccent,
        fontWeight: FontWeight.w500,
      ),
      'prayer_time': const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      'performer_event_name': const TextStyle(
        color: Colors.amber,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      'performer_event_date': const TextStyle(
        color: Colors.white70,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      'performer_name': const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      'performer_role': const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Colors.amber,
      ),
      'footer_prayer_name': const TextStyle(
        fontSize: 20,
        color: Colors.amber,
        fontWeight: FontWeight.bold,
      ),
      'footer_prayer_time': const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    };

    _textStyles = {};
    defaultStyles.forEach((key, style) {
      double size = prefs.getDouble('${key}_size') ?? style.fontSize!;
      int colorVal = prefs.getInt('${key}_color') ?? style.color!.value;
      String font =
          prefs.getString('${key}_font') ?? style.fontFamily ?? 'Roboto';

      _textStyles[key] = style.copyWith(
        fontSize: size,
        color: Color(colorVal),
        fontFamily: font,
      );
    });

    setState(() {
      _mosqueName = prefs.getString('mosque_name') ?? "MASJID AL MUNTAHA";
      _mosqueAddress =
          prefs.getString('mosque_address') ?? "Perum Bumi Cipta Laras";

      // Assets overrides
      _headerAsset = prefs.getString('header_asset') ?? _headerAsset;
      _jamAsset = prefs.getString('jam_asset') ?? _jamAsset;
      _cardAsset = prefs.getString('card_asset') ?? _cardAsset;
      _slideAsset = prefs.getString('slide_asset') ?? _slideAsset;
      _sideCardAsset = prefs.getString('sidecard_asset') ?? _sideCardAsset;
      _bgAsset = prefs.getString('bg_asset') ?? _bgAsset;
      _bgDashboard = prefs.getString('bg_dashboard') ?? _bgAsset;
      _bgInfo = prefs.getString('bg_info') ?? _bgAsset;
      _bgEvent = prefs.getString('bg_event') ?? _bgAsset;
      _logoPath = prefs.getString('logo_path') ?? '';
      _showLogo = prefs.getBool('show_logo') ?? false;
      _logoAnimationEnabled = prefs.getBool('logo_animation_enabled') ?? false;
      _runningTextAsset =
          prefs.getString('running_text_asset') ?? _runningTextAsset;
      _runningText = prefs.getString('running_text') ?? _runningText;
      _bgApplyAll = prefs.getBool('bg_apply_all') ?? false;

      // Load slides dari SharedPreferences
      final slidesJson = prefs.getString('slides');
      if (slidesJson != null) {
        try {
          final List decoded = jsonDecode(slidesJson);
          _slidesData = decoded.map((e) => SlideItem.fromJson(e)).toList();
        } catch (e) {
          debugPrint('Error loading slides: $e');
        }
      }

      // Set kota id if present
      _kotaId = prefs.getString('kota_id');
      _kotaName = prefs.getString('kota_name');

      _prayerTimeService.provider =
          prefs.getString('api_provider') ?? 'MyQuran';
      // Use API preference
      _useApi = prefs.getBool('use_api_prayer_times') ?? true;

      // Load custom prayer times only if user prefers manual times
      if (!_useApi) {
        final prayerJson = prefs.getString('custom_prayer_times');
        if (prayerJson != null) {
          try {
            final List decoded = jsonDecode(prayerJson);
            _prayerTimes = decoded
                .map(
                  (e) => PrayerTime(e['name'] as String, e['time'] as String),
                )
                .toList();
          } catch (e) {
            // ignore parse errors and keep defaults
          }
        }
      }

      // Load Notification Settings
      _notifAdzanDuration = prefs.getInt('notif_adzan_duration') ?? 180;
      _notifIqomahDelay = prefs.getInt('notif_iqomah_delay') ?? 10;
      _notifIqomahDuration = prefs.getInt('notif_iqomah_duration') ?? 60;
      _notifTextAdzan = prefs.getString('notif_text_adzan') ?? "MEMASUKI WAKTU";
      // Load new notification settings
      _notifTextIqomahTimer =
          prefs.getString('notif_text_iqomah_timer') ??
          "DOA ANTARA ADZAN DAN IQOMAH NISCAYA AKAN TERKABUL";
      _notifTextIqomah =
          prefs.getString('notif_text_iqomah') ?? "LURUSKAN DAN RAPATKAN SHAF";
      _notifSholatDuration = prefs.getInt('notif_sholat_duration') ?? 600;
      _notifTextSholat =
          prefs.getString('notif_text_sholat') ??
          "SHOLAT TELAH DIMULAI, HARAP TENANG";
      _fridayModeEnabled = prefs.getBool('friday_mode_enabled') ?? true;
      _fridayKhutbahDuration = prefs.getInt('friday_khutbah_duration') ?? 30;
      _fridayKhutbahText =
          prefs.getString('friday_khutbah_text') ??
          "Harap tenang saat khutbah berlangsung, nonaktifkan ponsel Anda.";

      // Load Hijri Adjustment
      _hijriAdjustment = prefs.getInt('hijri_adjustment') ?? -2;

      // Load Media Schedules
      final mediaJson = prefs.getString('media_schedules');
      if (mediaJson != null) {
        try {
          _mediaSchedules = List<Map<String, dynamic>>.from(
            jsonDecode(mediaJson),
          );
        } catch (_) {}
      }

      // Load Media Library
      final libJson = prefs.getString('media_library');
      if (libJson != null) {
        try {
          _mediaLibrary = List<Map<String, dynamic>>.from(jsonDecode(libJson));
        } catch (_) {}
      }

      _mediaSlidesEnabled = prefs.getBool('media_slideshow_enabled') ?? false;
      _rotationDurationSeconds =
          prefs.getInt('rotation_duration_seconds') ?? 90;

      _slideshowEffect = prefs.getString('slideshow_effect') ?? 'fade';

      // Load Murottal Schedules
      final murottalJson = prefs.getString('murottal_schedules');
      if (murottalJson != null) {
        try {
          final List decoded = jsonDecode(murottalJson);
          _murottalSchedules = decoded
              .map((e) => MurottalSchedule.fromJson(e))
              .toList();
        } catch (e) {
          debugPrint('Error loading murottal schedules: $e');
        }
      }

      // Load Imsakiyah Settings
      _showImsakiyahScreen = prefs.getBool('show_imsakiyah_screen') ?? false;
      _imsakiyahProvince = prefs.getString('imsakiyah_province');
      _imsakiyahCity = prefs.getString('imsakiyah_city');

      // Load Power TV Settings
      _powerTvEnabled = prefs.getBool('power_tv_enabled') ?? false;
      final powerJson = prefs.getString('power_schedules');
      if (powerJson != null) {
        try {
          final List decoded = jsonDecode(powerJson);
          _powerSchedules = decoded
              .map(
                (e) => {
                  'on': e['on'].toString(),
                  'off': e['off'].toString(),
                  'days': (e['days'] ?? '1,2,3,4,5,6,7').toString(),
                },
              )
              .toList();
        } catch (_) {
          _powerSchedules = [];
        }
      } else {
        _powerSchedules = [];
      }

      // Ensure initial screen state based on schedule
      if (_powerTvEnabled) {
        _checkPowerTvSchedule(DateTime.now());
      } else {
        _setNativeScreenPower(true); // Always on if disabled
      }

      // Load Hadith Settings
      _showHadith = prefs.getBool('hadith_show') ?? true;
      _hadithInterval = prefs.getInt('hadith_interval') ?? 5;
      _hadithSpeed = prefs.getInt('hadith_speed') ?? 30;

      // Load Manual Hadiths
      final manualHadithJson = prefs.getString('custom_hadiths');
      if (manualHadithJson != null) {
        try {
          List decoded = jsonDecode(manualHadithJson);
          _manualHadiths = decoded
              .map(
                (e) => {
                  'text': e['text'].toString(),
                  'source': e['source'].toString(),
                },
              )
              .toList();
        } catch (_) {}
      } else {
        _manualHadiths = [];
      }

      // Load Events
      final eventsJson = prefs.getString('events');
      if (eventsJson != null) {
        try {
          final List decoded = jsonDecode(eventsJson);
          _eventsData = decoded
              .map(
                (e) => {
                  'title': e['title'].toString(),
                  'date': e['date'].toString(),
                },
              )
              .toList();
        } catch (_) {}
      }

      // Load Performer Profiles
      final performerProfilesJson = prefs.getString('performer_profiles');
      if (performerProfilesJson != null) {
        try {
          _performerProfiles = List<Map<String, dynamic>>.from(
            jsonDecode(performerProfilesJson),
          );
        } catch (_) {
          _performerProfiles = [];
        }
      }

      // Load Performer Schedules
      final performerSchedulesJson = prefs.getString('performer_schedules');
      if (performerSchedulesJson != null) {
        try {
          _scheduledPerformerEvents = List<Map<String, dynamic>>.from(
            jsonDecode(performerSchedulesJson),
          );
        } catch (_) {}
      }
      // Load Imsakiyah Settings
      _imsakiyahCity = prefs.getString('imsakiyah_city');
    });

    // Load Remote Access Settings
    _tunnelEnabled = prefs.getBool('tunnel_enabled') ?? false;
    _vpsHost = prefs.getString('vps_host') ?? '';
    _vpsUser = prefs.getString('vps_user') ?? '';
    _vpsPort = prefs.getInt('vps_port') ?? 22;

    // Cleanup expired events and schedules
    await _cleanupExpiredData();

    // Load IoT Settings
    _iotIp = prefs.getString('iot_ip') ?? '';
    _iotPathOn = prefs.getString('iot_path_on') ?? '/on';
    _iotPathOff = prefs.getString('iot_path_off') ?? '/off';

    // Load Custom Assets
    _customAssets = prefs.getStringList('custom_assets') ?? [];

    // Load Theme Colors
    _themePrimaryColor = Color(
      prefs.getInt('theme_primary_color') ?? 0xFF064E3B,
    );
    _themeAccentColor = Color(
      prefs.getInt('theme_accent_color') ?? Colors.amber.value,
    );

    // Load Hijri Anchor (Memori Terakhir)
    final anchorDateStr = prefs.getString('hijri_anchor_date');
    if (anchorDateStr != null) {
      _anchorGregorian = DateTime.tryParse(anchorDateStr);
      _anchorHijriDay = prefs.getInt('hijri_anchor_day');
      _anchorHijriMonth = prefs.getInt('hijri_anchor_month');
      _anchorHijriYear = prefs.getInt('hijri_anchor_year');
    }

    // After loading settings, try fetching from API
    _loadPrayerTimes();
    _loadHijriDate();
    _setupHadithFeature();
    _startScreenRotation();
  }

  Future<void> _loadPrayerTimes() async {
    if (!_useApi) {
      // Manual mode selected, nothing to fetch from API
      return;
    }

    try {
      final data = await _prayerTimeService.fetchApiPrayerTimes(
        kotaId: _kotaId,
        kotaName: _kotaName,
      );
      if (mounted) {
        if (data != null && data.isNotEmpty) {
          setState(() {
            final order = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
            _prayerTimes = order
                .map(
                  (name) => PrayerTime(
                    name,
                    data[name] ?? (data[name.toLowerCase()] ?? '--:--'),
                  ),
                )
                .toList();
          });
          // Simpan hasil API ke SharedPreferences agar tersedia offline
          // dan catat waktu pembaruan untuk deteksi jadwal yang usang.
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'custom_prayer_times',
            jsonEncode(
              _prayerTimes
                  .map((p) => {'name': p.name, 'time': p.time})
                  .toList(),
            ),
          );
          await prefs.setString(
            'last_prayer_update',
            DateTime.now().toIso8601String(),
          );
          _lastPrayerUpdate = DateTime.now();
        } else {
          // API returned no data — fallback to manual if available
          final prefs = await SharedPreferences.getInstance();
          final prayerJson = prefs.getString('custom_prayer_times');
          if (prayerJson != null) {
            try {
              final List decoded = jsonDecode(prayerJson);
              if (mounted) {
                setState(() {
                  _prayerTimes = decoded
                      .map(
                        (e) => PrayerTime(
                          e['name'] as String,
                          e['time'] as String,
                        ),
                      )
                      .toList();
                });
              }
            } catch (_) {
              // fallthrough to defaults
            }
          }
        }
      }
    } catch (e) {
      // On error, try manual times as fallback
      final prefs = await SharedPreferences.getInstance();
      final prayerJson = prefs.getString('custom_prayer_times');
      if (prayerJson != null) {
        try {
          final List decoded = jsonDecode(prayerJson);
          if (mounted) {
            setState(() {
              _prayerTimes = decoded
                  .map(
                    (e) => PrayerTime(e['name'] as String, e['time'] as String),
                  )
                  .toList();
            });
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _loadHijriDate() async {
    if (!_useApi) return;
    try {
      final data = await _prayerTimeService.fetchHijriDate(
        adjustment: _hijriAdjustment,
      );
      if (data != null && mounted) {
        // Simpan data ke SharedPreferences sebagai "Ingatan"
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day); // Hapus jam/menit

        await prefs.setString('hijri_anchor_date', today.toIso8601String());
        await prefs.setInt('hijri_anchor_day', data['day']);
        await prefs.setInt('hijri_anchor_month', data['month']);
        await prefs.setInt('hijri_anchor_year', data['year']);
        await prefs.setString('hijri_anchor_month_name', data['monthName']);

        setState(() {
          _anchorGregorian = today;
          _anchorHijriDay = data['day'];
          _anchorHijriMonth = data['month'];
          _anchorHijriYear = data['year'];
        });
      }
    } catch (_) {
      // Jika error (offline), biarkan menggunakan data anchor yang lama
    }
  }

  Future<void> _setupHadithFeature() async {
    _hadithTimer?.cancel();
    if (_showHadith) {
      // Fetch immediately
      _loadNewHadith();
      // Then set up periodic fetch
      _hadithTimer = Timer.periodic(Duration(minutes: _hadithInterval), (
        timer,
      ) {
        _loadNewHadith();
      });
    } else {
      // If disabled, clear the data
      if (mounted) {
        setState(() {
          _hadithData = null;
        });
      }
    }
  }

  Future<void> _loadNewHadith() async {
    if (!_showHadith) return;
    final hadith = await _prayerTimeService.fetchRandomHadith();
    if (mounted && hadith != null) {
      setState(() => _hadithData = hadith);
    }
  }

  // (Dihapus: _fetchPrayerTimes tidak digunakan)

  void _updateTime() {
    final DateTime now = DateTime.now();
    _checkPrayerTime(now);
    _checkMediaSchedule(now);
    _checkMurottalSchedule(now); // This now handles both file and API

    // Cek jadwal performer sekali per menit
    if (now.second == 0) {
      _checkForActivePerformerEvent();
      _checkPowerTvSchedule(now);

      // Cleanup data yang sudah terlewati setiap hari baru (jam 00:00)
      if (now.hour == 0 && now.minute == 0) {
        _cleanupExpiredData();
        // Perbarui jadwal sholat setiap hari baru agar data tidak usang
        // ketika aplikasi berjalan terus-menerus (kiosk/TV).
        _loadPrayerTimes();
      }
    }

    setState(() {
      _timeString =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      _dateString = "${now.day} ${months[now.month - 1]} ${now.year}";

      // Hijri date (approximation using arithmetic conversion)
      if (_anchorGregorian != null && _anchorHijriDay != null) {
        // Hitung selisih hari dari data terakhir yang disimpan
        final today = DateTime(now.year, now.month, now.day);
        final diff = today.difference(_anchorGregorian!).inDays;

        int hDay = _anchorHijriDay! + diff;
        int hMonth = _anchorHijriMonth!;
        int hYear = _anchorHijriYear!;

        // Normalisasi Tanggal (Estimasi: Ganjil 30 hari, Genap 29 hari)
        while (true) {
          int daysInMonth = (hMonth % 2 != 0) ? 30 : 29;
          if (hDay <= daysInMonth) break;
          hDay -= daysInMonth;
          hMonth++;
          if (hMonth > 12) {
            hMonth = 1;
            hYear++;
          }
        }

        final hijriMonths = [
          'Muharram',
          'Safar',
          'Rabiul Awal',
          'Rabiul Akhir',
          'Jumadil Awal',
          'Jumadil Akhir',
          'Rajab',
          "Sya'ban",
          'Ramadhan',
          'Syawwal',
          'Dzulqaidah',
          'Dzulhijah',
        ];
        String monthName = (hMonth >= 1 && hMonth <= 12)
            ? hijriMonths[hMonth - 1]
            : '';
        _hijriDateString = "$hDay $monthName $hYear H";
      } else {
        _hijriDateString = '';
      }
    });
  }

  void _checkPowerTvSchedule(DateTime now) {
    if (!_powerTvEnabled) {
      if (!_isScreenPowerOn) _setNativeScreenPower(true);
      return;
    }

    if (_powerSchedules.isEmpty) {
      if (!_isScreenPowerOn) _setNativeScreenPower(true);
      return;
    }

    final nowMin = now.hour * 60 + now.minute;
    final dayOfWeek = now.weekday.toString();
    bool shouldBeOn = false;

    for (final schedule in _powerSchedules) {
      final days = (schedule['days'] ?? '1,2,3,4,5,6,7').split(',');
      if (!days.contains(dayOfWeek)) continue;

      final onParts = (schedule['on'] ?? "04:00").split(':');
      final offParts = (schedule['off'] ?? "21:00").split(':');
      final onMin = int.parse(onParts[0]) * 60 + int.parse(onParts[1]);
      final offMin = int.parse(offParts[0]) * 60 + int.parse(offParts[1]);

      if (onMin < offMin) {
        if (nowMin >= onMin && nowMin < offMin) {
          shouldBeOn = true;
          break;
        }
      } else {
        // Over midnight schedule
        if (nowMin >= onMin || nowMin < offMin) {
          shouldBeOn = true;
          break;
        }
      }
    }

    if (shouldBeOn != _isScreenPowerOn) {
      _setNativeScreenPower(shouldBeOn);
    }
  }

  Future<void> _setNativeScreenPower(bool isOn) async {
    try {
      await _powerChannel.invokeMethod('setScreenPower', {'on': isOn});
      setState(() => _isScreenPowerOn = isOn);
    } catch (e) {
      debugPrint("Error setting screen power: $e");
    }
  }

  void _checkForActivePerformerEvent() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Map<String, dynamic>? foundEvent;
    try {
      foundEvent = _scheduledPerformerEvents.firstWhere((event) {
        final startStr = event['date'];
        if (startStr == null) return false;
        final start = DateTime.parse(startStr);
        DateTime end = start;
        if (event['endDate'] != null) {
          end = DateTime.parse(event['endDate']);
        }
        // Cek apakah hari ini ada di antara start dan end (inklusif)
        return (today.isAtSameMomentAs(start) || today.isAfter(start)) &&
            (today.isAtSameMomentAs(end) || today.isBefore(end));
      });
    } catch (e) {
      foundEvent = null;
    }

    // Perbandingan sederhana sebelumnya tidak dapat mendeteksi perubahan pada daftar 'performerIds'.
    // Gunakan jsonEncode untuk perbandingan mendalam (deep comparison) yang andal.
    if (jsonEncode(_activePerformerEvent) != jsonEncode(foundEvent)) {
      setState(() {
        _activePerformerEvent = foundEvent;
      });
    }
  }

  Future<void> _cleanupExpiredData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prefs = await SharedPreferences.getInstance();
    bool changed = false;

    // 1. Cleanup Agenda (Events)
    int originalEventCount = _eventsData.length;
    _eventsData.removeWhere((event) {
      try {
        final eventDate = DateTime.parse(event['date']!);
        return eventDate.isBefore(today);
      } catch (_) {
        return false;
      }
    });
    if (_eventsData.length != originalEventCount) {
      changed = true;
      await prefs.setString('events', jsonEncode(_eventsData));
    }

    // 2. Cleanup Jadwal Petugas (Schedules)
    int originalScheduleCount = _scheduledPerformerEvents.length;
    _scheduledPerformerEvents.removeWhere((schedule) {
      try {
        // Gunakan endDate jika ada, jika tidak gunakan date
        final endStr = schedule['endDate'] ?? schedule['date'];
        final endDate = DateTime.parse(endStr);
        return endDate.isBefore(today);
      } catch (_) {
        return false;
      }
    });
    if (_scheduledPerformerEvents.length != originalScheduleCount) {
      changed = true;
      await prefs.setString(
        'performer_schedules',
        jsonEncode(_scheduledPerformerEvents),
      );
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  void _checkMediaSchedule(DateTime now) {
    // Jangan cek jika notifikasi adzan/iqomah sedang aktif (prioritas lebih tinggi)
    if (_notifState != NotifState.none) return;

    // Jika media sedang aktif, tidak perlu cek jadwal baru (tunggu selesai)
    if (_isMediaActive) return;

    final currentTimeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final currentDay = now.weekday; // 1 = Senin, 7 = Ahad

    // Cek detik 0 agar trigger hanya sekali per menit
    if (now.second != 0) return;

    for (var item in _mediaSchedules) {
      if (item['time'] == currentTimeStr) {
        List<dynamic> days = item['days'];
        if (days.contains(currentDay)) {
          _startMedia(item);
          break;
        }
      }
    }
  }

  void _checkMurottalSchedule(DateTime now) {
    // Don't check if any media/notification is already active
    if (_isMediaActive || _notifState != NotifState.none) return;

    // Check only once per minute
    if (now.second != 0) return;

    // --- Logika Baru: Tarhim -> Murottal (sebelum Adzan) ---
    for (var schedule in _murottalSchedules) {
      // Cek apakah ada jadwal yang cocok untuk diputar (Tarhim atau Murottal).
      // Fungsi ini akan mengembalikan true jika ada media yang dimulai, agar loop berhenti.
      bool didStart = _processSingleMurottalSchedule(now, schedule);
      if (didStart) {
        break; // Hanya proses satu jadwal per menit untuk menghindari tumpang tindih
      }
    }
  }

  /// Memproses satu jadwal sholat untuk Tarhim, Murottal, atau Adzan.
  /// Mengembalikan `true` jika ada media (Murottal/Tarhim) yang mulai diputar sebelum adzan.
  bool _processSingleMurottalSchedule(DateTime now, MurottalSchedule schedule) {
    final prayerName = schedule.prayer;
    final minutesBefore = schedule.minutesBefore;
    // Find the prayer time for today
    final prayer = _prayerTimes.firstWhere(
      (p) => p.name == prayerName,
      orElse: () => PrayerTime('', ''),
    );
    if (prayer.time == '--:--') return false;

    final prayerTimeParts = prayer.time.split(':');
    final prayerHour = int.parse(prayerTimeParts[0]);
    final prayerMinute = int.parse(prayerTimeParts[1]);
    final prayerDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      prayerHour,
      prayerMinute,
    );

    // Calculate start time
    final startTime = prayerDateTime.subtract(Duration(minutes: minutesBefore));

    // --- Cek Tarhim ---
    if (schedule.tarhimEnabled) {
      final tarhimStartTime = prayerDateTime.subtract(
        Duration(minutes: schedule.tarhimMinutesBefore),
      );

      if (now.hour == tarhimStartTime.hour &&
          now.minute == tarhimStartTime.minute) {
        final tarhimItem = {
          'path': 'assets/audio/tarhim.mp3', // Langsung gunakan path dari asset
          'type': 'audio', // Tarhim selalu audio
          'play_count': 1, // Biasanya tidak di-loop, tapi bisa disesuaikan
          'stop_before_adzan': 0, // Tarhim berhenti saat selesai
          'prayer_time': prayerDateTime,
        };
        _startMurottal(tarhimItem); // Gunakan startMurottal untuk memutar audio
        return true; // Tarhim dimulai, hentikan proses
      }
    }

    // --- Cek Murottal ---
    // Murottal hanya akan diputar jika tidak ada Tarhim yang sedang berjalan
    // dan waktunya sudah masuk.
    if (!schedule.enabled) {
      return false; // Jika murottal tidak aktif, selesai untuk jadwal ini
    }

    // Check if it's time to start
    if (now.hour == startTime.hour && now.minute == startTime.minute) {
      final sourceType = schedule.sourceType;
      final isRandom = schedule.isRandom;
      String? mediaPath;
      String mediaType = 'audio'; // Default to audio for API

      if (sourceType == 'api') {
        final qari = schedule.qari ?? 'Abdullah-Al-Juhany';
        int surahNumber = schedule.surahNumber ?? 1;

        if (isRandom) {
          // Random surah from 1 to 114
          surahNumber = (DateTime.now().millisecondsSinceEpoch % 114) + 1;
        }

        final surahNumberPadded = surahNumber.toString().padLeft(3, '0');
        final qariSlug = qari.replaceAll(' ', '-');
        mediaPath =
            'https://cdn.equran.id/audio-full/$qariSlug/$surahNumberPadded.mp3';
        mediaType = 'audio';
      } else {
        // 'file'
        mediaPath = schedule.path;
        if (isRandom) {
          final playableMedia = _mediaLibrary
              .where((m) => m['type'] == 'video' || m['type'] == 'audio')
              .toList();
          if (playableMedia.isNotEmpty) {
            final randomIndex =
                (DateTime.now().millisecondsSinceEpoch % playableMedia.length);
            mediaPath = playableMedia[randomIndex]['path'];
          }
        }

        if (mediaPath != null && mediaPath.isNotEmpty) {
          final mediaItem = _mediaLibrary.firstWhere(
            (m) => m['path'] == mediaPath,
            orElse: () => {'type': 'video'},
          );
          mediaType = mediaItem['type'];
        }
      }

      if (mediaPath != null && mediaPath.isNotEmpty) {
        final murottalItem = {
          'path': mediaPath,
          'type': mediaType,
          'play_count': schedule.loopCount,
          'stop_before_adzan': schedule.stopBeforeAdzan,
          'prayer_time': prayerDateTime, // Pass prayer time for stop logic
        };
        _currentMurottalSchedule = schedule; // Save the schedule for looping
        _startMurottal(murottalItem); // Memulai Murottal
        return true; // Murottal dimulai, hentikan proses
      }
    }
    return false; // Tidak ada media yang dimulai untuk jadwal ini
  }

  void _startAdzanAudio(String path, String prayerName) {
    // Hentikan media yang sedang berjalan (Tarhim/Murottal/media terjadwal)
    // karena Adzan punya prioritas lebih tinggi.
    _mediaEndTimer?.cancel();
    setState(() {
      _isMediaActive = false;
      _isMurottalActive = false;
      _currentMurottalSchedule = null;
      _currentMediaItem = null;
    });
    // Relay/amplifier TIDAK dinyalakan di sini. Relay akan dinyalakan oleh
    // _startAdzanSequence() yang dipanggil tepat setelah fungsi ini, agar
    // relay tidak sempat ON lalu seketika OFF.
  }

  void _startMurottal(Map<String, dynamic> item) {
    setState(() {
      _isMediaActive = true;
      _isMurottalActive = true;
      _currentMurottalSchedule?.currentSurah =
          item['surah_number']; // Track current surah
      _currentMediaItem = item;
    });

    _mediaEndTimer?.cancel();
    // Nyalakan Relay (Amplifier/Speaker) saat Murottal dimulai
    _triggerRelay(true);

    // Timer to stop before Adzan
    final int stopMinutes = item['stop_before_adzan'] ?? 2;
    if (stopMinutes > 0) {
      final DateTime prayerTime = item['prayer_time'];
      final stopTime = prayerTime.subtract(Duration(minutes: stopMinutes));
      final durationUntilStop = stopTime.difference(DateTime.now());

      if (durationUntilStop.isNegative == false) {
        _mediaEndTimer = Timer(durationUntilStop, () {
          _stopMurottal();
        });
      }
    }
  }

  // --- IoT / Relay Control Logic ---
  Future<void> _triggerRelay(bool turnOn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('iot_ip') ?? '';
      if (ip.isEmpty) return;

      final pathOn = prefs.getString('iot_path_on') ?? '/on';
      final pathOff = prefs.getString('iot_path_off') ?? '/off';

      // Construct URL: http://192.168.1.x/on
      final urlString = 'http://$ip${turnOn ? pathOn.trim() : pathOff.trim()}';
      final uri = Uri.parse(urlString);

      debugPrint('IoT Trigger: $urlString');

      // Fire and forget (timeout pendek agar tidak memblokir UI)
      await http.get(uri).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('IoT Error: $e');
    }
  }

  void _startMedia(Map<String, dynamic> item) {
    setState(() {
      _isMediaActive = true;
      _isMurottalActive = false; // This is a regular media, not Murottal
      _currentMediaItem = item;
    });

    // Timer durasi dihapus. Sekarang kita mengandalkan callback onFinished dari MediaOverlay
    // untuk memberitahu kapan media selesai diputar (berdasarkan play_count).
    _mediaEndTimer?.cancel();

    // Nyalakan Relay (Amplifier/Speaker)
    _triggerRelay(true);
  }

  void _stopMurottal() {
    if (_isMurottalActive && mounted) {
      setState(() {
        _isMediaActive = false;
        _isMurottalActive = false;
        _currentMurottalSchedule = null;
        _currentMediaItem = null;
        _mediaEndTimer?.cancel();
        // Matikan relay setelah Murottal selesai
        _triggerRelay(false); // Matikan relay setelah Murottal selesai
      });
    }
  }

  void _checkPrayerTime(DateTime now) {
    // Simple check: if current HH:mm:ss matches a prayer time :00
    // We only trigger if state is none to avoid re-triggering
    if (_notifState != NotifState.none) return;

    final currentTimeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Check if seconds is 0 to trigger exactly at the minute
    if (now.second != 0) return;

    for (var p in _prayerTimes) {
      if (p.time == currentTimeStr) {
        // Cek apakah ada jadwal murottal yang mengaktifkan adzan untuk waktu sholat ini
        final adzanSchedule = _murottalSchedules.any(
          (s) => s.prayer == p.name && s.adzanEnabled,
        );
        if (adzanSchedule) {
          _startAdzanAudio('assets/audio/adzan.mp3', p.name);
        }

        _startAdzanSequence(p.name);
        break;
      }
    }
  }

  void _startKhutbahSequence() {
    setState(() {
      _notifState = NotifState.khutbah;
    });
    _notifTimer?.cancel();
    _notifTimer = Timer(Duration(minutes: _fridayKhutbahDuration), () {
      // After Khutbah, go straight to Sholat
      _startSholatSequence();
    });
  }

  void _startIqomahSequence(String prayerName) {
    setState(() {
      _notifState = NotifState.iqomah;
      _currentPrayerName = prayerName;
    });
    _notifTimer?.cancel();
    _notifTimer = Timer(Duration(seconds: _notifIqomahDuration), () {
      // After Iqomah, start Sholat
      _startSholatSequence();
    });
  }

  String _getNotificationTitle() {
    switch (_notifState) {
      case NotifState.adzan:
        return _notifTextAdzan;
      case NotifState.iqomah:
        return "IQOMAH";
      case NotifState.sholat:
        return "SHOLAT BERJAMAAH";
      case NotifState.khutbah:
        return "KHUTBAH JUMAT";
      case NotifState.countdown:
        return "MENUJU IQOMAH";
      case NotifState.none:
      default:
        return "";
    }
  }

  String _getNotificationMessage() {
    switch (_notifState) {
      case NotifState.khutbah:
        return _fridayKhutbahText;
      case NotifState.iqomah:
        return _notifTextIqomah;
      case NotifState.sholat:
        return _notifTextSholat;
      case NotifState.countdown:
        final now = DateTime.now();
        final isFridayDzuhur =
            _currentPrayerName == 'Dzuhur' && now.weekday == DateTime.friday;
        // Only show iqomah timer text if it's not Friday Dzuhur countdown
        if (!isFridayDzuhur) {
          return _notifTextIqomahTimer;
        }
        return ""; // No specific message for Friday Dzuhur countdown
      case NotifState.adzan:
        return "Mari Segera Menuju Masjid";
      case NotifState.none:
      default:
        return "";
    }
  }

  void _startAdzanSequence(String prayerName) {
    String effectivePrayerName = prayerName;
    final now = DateTime.now();

    // Override prayerName to 'Jumat' if it's Friday and Friday mode is enabled for Dzuhur
    if (prayerName == 'Dzuhur' &&
        now.weekday == DateTime.friday &&
        _fridayModeEnabled) {
      effectivePrayerName = 'Jumat';
    }

    setState(() {
      _notifState = NotifState.adzan;
      _currentPrayerName = effectivePrayerName;

      // Paksa kembali ke Dashboard saat Adzan (opsional, tapi overlay akan menutupinya)
      // _screenIndex = 0;
      // Overlay NotifOverlay akan muncul di atas apapun screen-nya.

      // Jika ada media yang sedang main, matikan paksa karena Adzan prioritas
      if (_isMediaActive) {
        _isMediaActive = false;
        _currentMurottalSchedule = null;
        _isMurottalActive = false;
        _currentMediaItem = null;
        _mediaEndTimer?.cancel();
      }
    });

    // Nyalakan relay/amplifier untuk Adzan. Relay ini dimatikan otomatis
    // (mengirim /off) saat rangkaian Adzan -> Iqomah -> Sholat selesai,
    // lihat _startSholatSequence().
    _triggerRelay(true);

    // Timer for Adzan Display
    _notifTimer?.cancel();
    _notifTimer = Timer(Duration(seconds: _notifAdzanDuration), () {
      // Cek apakah ini sholat Jumat (Hari Jumat dan waktu Dzuhur)
      if (effectivePrayerName == 'Jumat' &&
          now.weekday == DateTime.friday &&
          _fridayModeEnabled) {
        _startKhutbahSequence();
      } else {
        // After Adzan, start Countdown for Iqomah
        if (_notifIqomahDelay > 0) {
          setState(() {
            _notifState = NotifState.countdown;
            _countdownSeconds = _notifIqomahDelay * 60;
          });
          _startCountdown();
        } else {
          // No delay, go straight to Iqomah
          _startIqomahSequence(effectivePrayerName);
        }
      }
    });
  }

  void _startCountdown() {
    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _startIqomahSequence(_currentPrayerName);
      }
    });
  }

  void _handleSecretMenuGesture() async {
    _tapCount++;
    if (_tapCount >= 3) {
      _tapCount = 0;
      _tapResetTimer?.cancel();

      // Tunggu sampai kembali dari menu setting, lalu reload data
      await Navigator.push<bool?>(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      // reload settings and prayer times if something in settings changed
      await _loadSettings();
      // Panggil pengecekan event petugas secara eksplisit setelah memuat pengaturan baru
      _checkForActivePerformerEvent();
      // Selalu coba load prayer times setelah kembali dari setting,
      // karena user mungkin mengubah kota/metode tanpa menekan tombol 'Simpan/Keluar' yang mengembalikan true
      _loadPrayerTimes();
    } else {
      _tapResetTimer?.cancel();
      _tapResetTimer = Timer(
        const Duration(milliseconds: 500),
        () => _tapCount = 0,
      );
    }
  }

  void _startSholatSequence() {
    setState(() {
      _notifState = NotifState.sholat;
    });
    _notifTimer?.cancel();
    _notifTimer = Timer(Duration(seconds: _notifSholatDuration), () {
      setState(() {
        _notifState = NotifState.none;
      });
      // Matikan relay/amplifier (kirim /off) setelah rangkaian
      // Adzan -> Iqomah -> Sholat selesai.
      _triggerRelay(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Resolusi referensi desain (HD 720p).
    // Dengan ini, tampilan akan di-scale secara proporsional di layar 4K/1080p/dll.
    const double designWidth = 1280;
    const double designHeight = 720;

    // Tentukan background berdasarkan screen index
    String currentBg = _getScreenBackground(_screenIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final k = event.logicalKey;
            if (k == LogicalKeyboardKey.select || // D-pad center
                k == LogicalKeyboardKey.enter ||
                k == LogicalKeyboardKey.numpadEnter ||
                k == LogicalKeyboardKey.gameButtonA ||
                k == LogicalKeyboardKey.space) {
              _handleSecretMenuGesture();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: designWidth,
                height: designHeight,
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        child: Image(
                          image: resolveAppImage(currentBg),
                          key: ValueKey(currentBg),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.black87),
                        ),
                      ),
                    ),
                    // Overlay gradient agar teks terbaca
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(0, 0, 0, 0.6),
                              Colors.transparent,
                              Color.fromRGBO(0, 0, 0, 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- KONTEN UTAMA ---
                    // Jika ada jadwal performer aktif, tampilkan PerformerScreen.
                    // Jika tidak, jalankan rotasi layar seperti biasa.
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return _buildScreenTransition(child, animation);
                            },
                        child: _buildCurrentScreen(),
                      ),
                    ),

                    // Identitas Pembuat (Watermark)
                    if (_showLogo && _logoPath.isNotEmpty)
                      Positioned(
                        top: 20,
                        left: 20,
                        child: _logoAnimationEnabled
                            ? ScaleTransition(
                                scale: _logoScaleAnimation,
                                child: _buildLogoWidget(),
                              )
                            : _buildLogoWidget(),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 20,
                      child: Text(
                        "KORNET INTER MEDIA | 2026",
                        style: TextStyle(
                          color: Colors.white.withOpacity(1.0),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(blurRadius: 3, color: Colors.black),
                          ],
                        ),
                      ),
                    ),

                    // Overlay Media (Video/Image)
                    if (_isMediaActive &&
                        _currentMediaItem != null &&
                        _notifState == NotifState.none)
                      MediaOverlay(
                        path: _currentMediaItem!['path'],
                        type: _currentMediaItem!['type'],
                        playCount: _currentMediaItem!['play_count'] ?? 1,
                        onFinished: () {
                          // Check if it's a Murottal from API and can play next
                          if (_isMurottalActive &&
                              _currentMurottalSchedule?.sourceType == 'api') {
                            final schedule = _currentMurottalSchedule!;
                            final prayerTime =
                                _currentMediaItem!['prayer_time'] as DateTime;
                            final stopMinutes =
                                _currentMediaItem!['stop_before_adzan'] as int;
                            final stopTime = prayerTime.subtract(
                              Duration(minutes: stopMinutes),
                            );

                            // Check if there is still time to play another surah
                            if (DateTime.now().isBefore(stopTime)) {
                              int nextSurahNumber =
                                  (schedule.currentSurah ?? 1) + 1;
                              if (nextSurahNumber > 114) {
                                nextSurahNumber = 1; // Loop back to Al-Fatihah
                              }
                              final qari =
                                  schedule.qari ?? 'Abdullah-Al-Juhany';
                              final surahNumberPadded = nextSurahNumber
                                  .toString()
                                  .padLeft(3, '0');
                              final qariSlug = qari.replaceAll(' ', '-');
                              final mediaPath =
                                  'https://cdn.equran.id/audio-full/$qariSlug/$surahNumberPadded.mp3';

                              final nextMurottalItem = {
                                ..._currentMediaItem!, // copy previous settings
                                'path': mediaPath,
                                'type': 'audio',
                                'surah_number': nextSurahNumber,
                              };

                              // Start the next surah without stopping the relay
                              setState(() {
                                _currentMediaItem = nextMurottalItem;
                                _currentMurottalSchedule!.currentSurah =
                                    nextSurahNumber;
                              });
                              return; // Exit to avoid calling _stopMurottal
                            }
                          }

                          // If not a looping Murottal, or time is up, stop everything.
                          if (_isMurottalActive) {
                            _stopMurottal();
                          } else {
                            setState(() {
                              _isMediaActive = false;
                              _currentMediaItem = null;
                              _triggerRelay(false);
                            });
                          }
                        },
                      ),

                    // Overlay Notifikasi
                    if (_notifState != NotifState.none)
                      NotifOverlay(
                        bgImage:
                            'assets/elements/bgnotif.png', // Sesuai permintaan user
                        title: _getNotificationTitle(),
                        prayerName: _currentPrayerName,
                        message: _getNotificationMessage(),
                        child: _notifState == NotifState.countdown
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Text(
                                  _formatDuration(_countdownSeconds),
                                  style: const TextStyle(
                                    fontSize: 90,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                    fontFeatures: [
                                      ui.FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    final prayerTimesList = _prayerTimes
        .map((p) => {'name': p.name, 'time': p.time})
        .toList();

    switch (_screenIndex) {
      case 1:
        return IdleScreen(
          key: const ValueKey('HadithScreen'),
          text: _hadithData?['text'],
          source: _hadithData?['source'],
          prayerTimes: prayerTimesList,
          textStyles: _textStyles,
          timeString: _timeString,
          primaryColor: _themePrimaryColor,
          accentColor: _themeAccentColor,
        );
      case 2:
        return InfoScreen(
          key: const ValueKey('InfoScreen'),
          slides: _slidesData, // Pass the List<SlideItem>
          prayerTimes: prayerTimesList,
          textStyles: _textStyles,
          timeString: _timeString,
          primaryColor: _themePrimaryColor,
          accentColor: _themeAccentColor,
        );
      case 3:
        return EventScreen(
          key: const ValueKey('EventScreen'),
          events: _eventsData,
          prayerTimes: prayerTimesList,
          timeString: _timeString,
          primaryColor: _themePrimaryColor,
          accentColor: _themeAccentColor,
        );
      case 4:
        // Layar ini hanya akan dipanggil jika _activePerformerEvent tidak null (lihat _startScreenRotation)
        if (_activePerformerEvent == null) {
          // Fallback jika state tidak konsisten, kembali ke dashboard
          return _buildDashboard(key: const ValueKey('Dashboard'));
        }
        // Siapkan data untuk PerformerScreen
        List<String> performerIds = List<String>.from(
          _activePerformerEvent!['performerIds'] ?? [],
        );
        List<Map<String, String>> performersData = _performerProfiles
            .where((profile) => performerIds.contains(profile['id']))
            .map((profile) {
              return {
                'name': profile['name'] as String? ?? 'Nama tidak ada',
                'role': profile['role'] as String? ?? 'Peran tidak ada',
                'photoUrl': profile['photoPath'] as String? ?? '',
              };
            })
            .toList();

        return PerformerScreen(
          key: ValueKey(
            'PerformerScreen_${_activePerformerEvent!['name']}_${performerIds.join(',')}',
          ),
          eventName:
              _activePerformerEvent!['name'] as String? ?? 'Acara Khusus',
          eventDate:
              _activePerformerEvent!['date'] as String? ??
              '', // Tanggal sudah diformat di main.dart
          eventEndDate: _activePerformerEvent!['endDate'] as String?,
          performers: performersData,
          prayerTimes: prayerTimesList,
          textStyles: _textStyles,
          allSchedules: _scheduledPerformerEvents,
          allProfiles: _performerProfiles,
          timeString: _timeString,
          primaryColor: _themePrimaryColor,
          accentColor: _themeAccentColor,
        );
      case 5:
        return ImsakiyahScreen(
          key: const ValueKey('ImsakiyahScreen'),
          province: _imsakiyahProvince,
          city: _imsakiyahCity,
          prayerTimes: prayerTimesList,
          textStyles: _textStyles,
        );

      case 0:
      default:
        return _buildDashboard(key: const ValueKey('Dashboard'));
    }
  }

  Widget _buildScreenTransition(Widget child, Animation<double> animation) {
    switch (_slideshowEffect) {
      case 'slide':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case 'zoom':
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      case 'fade':
      default:
        return FadeTransition(opacity: animation, child: child);
    }
  }

  String _getScreenBackground(int screenIndex) {
    switch (screenIndex) {
      case 1:
        return _bgInfo.isNotEmpty ? _bgInfo : _bgAsset;
      case 2:
        return _bgInfo.isNotEmpty ? _bgInfo : _bgAsset;
      case 3:
        return _bgEvent.isNotEmpty ? _bgEvent : _bgAsset;
      case 4:
      case 5:
        return _bgDashboard.isNotEmpty ? _bgDashboard : _bgAsset;
      case 0:
      default:
        return _bgDashboard.isNotEmpty ? _bgDashboard : _bgAsset;
    }
  }

  Widget _buildLogoWidget() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image(
          image: resolveAppImage(_logoPath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white70,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  int _getNextPrayerIndex() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < _prayerTimes.length; i++) {
      final p = _prayerTimes[i];
      if (p.time == '--:--') continue;

      final parts = p.time.split(':');
      if (parts.length != 2) continue;

      final pHour = int.tryParse(parts[0]) ?? 0;
      final pMinute = int.tryParse(parts[1]) ?? 0;
      final pMinutes = pHour * 60 + pMinute;

      if (pMinutes > currentMinutes) return i;
    }
    return 0;
  }

  Widget _buildStrokedText(
    String text,
    TextStyle? style, {
    double strokeWidth = 3,
    Color strokeColor = Colors.black,
  }) {
    if (style == null) return Text(text);
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(text, style: style),
      ],
    );
  }

  Widget _buildAppHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: double.infinity, // Ensure full width
            padding: const EdgeInsets.fromLTRB(30, 25, 30, 25),
            decoration: BoxDecoration(
              color: _themePrimaryColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _themeAccentColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _handleSecretMenuGesture,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStrokedText(
                        _mosqueName,
                        _textStyles['mosque_name']?.copyWith(
                          color: _themeAccentColor,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStrokedText(
                            _mosqueAddress,
                            _textStyles['mosque_address'],
                            strokeWidth: 2,
                          ),
                          if (_kotaName != null)
                            _buildStrokedText(
                              _kotaName!,
                              _textStyles['mosque_address']?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              strokeWidth: 2,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 75,
                      child: _buildStrokedText(
                        _timeString,
                        _textStyles['clock']?.copyWith(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: _themeAccentColor.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildStrokedText(
                      _dateString,
                      _textStyles['date'],
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 6),
                    if (_hijriDateString.isNotEmpty)
                      _buildStrokedText(
                        _hijriDateString,
                        _textStyles['date']?.copyWith(color: _themeAccentColor),
                        strokeWidth: 2,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard({Key? key}) {
    final nextIdx = _getNextPrayerIndex();
    return Column(
      key: key,
      children: [
        _buildAppHeader(),
        // Tengah: Jadwal Sholat (Full Width)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _prayerTimes.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    return Expanded(
                      child: _buildPrayerTimeItem(
                        p.name,
                        p.time,
                        idx == nextIdx,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // Bawah Sekali: Running Text
        Container(
          width: double.infinity,
          height: 100,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _themePrimaryColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _themeAccentColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ScrollingText(
                  text: _runningText,
                  style:
                      _textStyles['running_text']?.copyWith(
                        color: _themeAccentColor,
                      ) ??
                      TextStyle(
                        fontSize: 28,
                        color: _themeAccentColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                  useStroke: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildPrayerTimeItem(String name, String time, bool isNext) {
    return PrayerTimeCard(
      name: name,
      time: time,
      isNext: isNext,
      cardAsset: _cardAsset,
      textStyles: _textStyles,
      primaryColor: _themePrimaryColor,
      accentColor: _themeAccentColor,
    );
  }
}

class PrayerTime {
  final String name;
  final String time;

  PrayerTime(this.name, this.time);
}

class PrayerTimeService {
  final ApiRepository _api;
  late String provider;

  PrayerTimeService({ApiRepository? api}) : _api = api ?? ApiRepository();

  /// Returns raw API data or null on failure.
  Future<Map<String, String>?> fetchApiPrayerTimes({
    String? kotaId,
    String? kotaName,
  }) async {
    return await _api.fetchPrayerTimes(
      kotaId: kotaId,
      kotaName: kotaName,
      provider: provider,
    );
  }

  Future<Map<String, dynamic>?> fetchHijriDate({int adjustment = -2}) async {
    return await _api.fetchHijriDate(adjustment: adjustment);
  }

  Future<Map<String, String>?> fetchRandomHadith() async {
    return await _api.fetchRandomHadith();
  }
}

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool useStroke;

  const ScrollingText({
    super.key,
    required this.text,
    required this.style,
    this.useStroke = false,
  });

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      double maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        double durationSeconds = maxScroll / 50; // Kecepatan scroll
        _scrollController
            .animateTo(
              maxScroll,
              duration: Duration(seconds: durationSeconds.toInt()),
              curve: Curves.linear,
            )
            .then((_) async {
              if (mounted) {
                _scrollController.jumpTo(0);
                _startScrolling();
              }
            });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget textWidget;
    if (widget.useStroke) {
      textWidget = Stack(
        children: [
          Text(
            widget.text,
            style: widget.style.copyWith(
              foreground: ui.Paint()
                ..style = ui.PaintingStyle.stroke
                ..strokeWidth = 3
                ..color = Colors.black,
            ),
          ),
          Text(widget.text, style: widget.style),
        ],
      );
    } else {
      textWidget = Text(widget.text, style: widget.style);
    }

    return ListView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Center(child: textWidget),
        SizedBox(width: MediaQuery.of(context).size.width), // Jarak loop
      ],
    );
  }
}

class PrayerTimeCard extends StatefulWidget {
  final String name;
  final String time;
  final bool isNext;
  final String cardAsset;
  final Map<String, TextStyle> textStyles;
  final Color primaryColor;
  final Color accentColor;

  const PrayerTimeCard({
    super.key,
    required this.name,
    required this.time,
    required this.isNext,
    required this.cardAsset,
    required this.textStyles,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<PrayerTimeCard> createState() => _PrayerTimeCardState();
}

class _PrayerTimeCardState extends State<PrayerTimeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isNext ? _scaleAnimation.value : 1.0;
        final glowOpacity = widget.isNext
            ? (_controller.value * 0.5 + 0.2)
            : 0.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 25,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isNext
                          ? [
                              widget.accentColor.withOpacity(0.4),
                              widget.primaryColor.withOpacity(0.8),
                            ]
                          : [
                              Colors.white.withOpacity(0.1),
                              widget.primaryColor.withOpacity(0.4),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: widget.isNext
                          ? widget.accentColor
                          : widget.accentColor.withOpacity(0.3),
                      width: widget.isNext ? 2.5 : 1.5,
                    ),
                    boxShadow: widget.isNext
                        ? [
                            BoxShadow(
                              color: widget.accentColor.withOpacity(
                                glowOpacity,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          widget.name.toUpperCase(),
                          style: widget.textStyles['prayer_name']?.copyWith(
                            color: widget.isNext
                                ? Colors.white
                                : widget.accentColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              const Shadow(
                                color: Colors.black87,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          widget.time,
                          style: widget.textStyles['prayer_time']?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: widget.isNext ? 50 : 40,
                            shadows: [
                              const Shadow(color: Colors.black, blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ScrollingHadith extends StatefulWidget {
  final String text;
  final String source;
  final Duration scrollDuration;

  const ScrollingHadith({
    super.key,
    required this.text,
    required this.source,
    required this.scrollDuration,
  });

  @override
  State<ScrollingHadith> createState() => _ScrollingHadithState();
}

class _ScrollingHadithState extends State<ScrollingHadith> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;

    // Only scroll if content is larger than the viewport
    if (maxScroll > 0) {
      // Animate from start to end
      _scrollController
          .animateTo(
            maxScroll,
            duration: widget.scrollDuration,
            curve: Curves.linear,
          )
          .then((_) {
            // When done, wait a bit, then jump back and restart
            if (mounted) {
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  _scrollController.jumpTo(0);
                  _startScrolling();
                }
              });
            }
          });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 60), // To start from outside the view
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                  ),
                  children: [
                    TextSpan(text: '${widget.text} '),
                    TextSpan(
                      text: '(${widget.source})',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60), // To scroll completely out of view
          ],
        ),
      ),
    );
  }
}
