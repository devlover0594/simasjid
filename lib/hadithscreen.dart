import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui'; // Diperlukan untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_repository.dart';

class IdleScreen extends StatefulWidget {
  final String? text;
  final String? source;
  final List<Map<String, String>> prayerTimes;
  final Map<String, TextStyle> textStyles;
  final String timeString;
  final Color primaryColor;
  final Color accentColor;

  const IdleScreen({
    super.key,
    this.text,
    this.source,
    this.prayerTimes = const [],
    this.textStyles = const {},
    this.timeString = '',
    this.primaryColor = const Color(0xFF064E3B),
    this.accentColor = Colors.amber,
  });

  @override
  State<IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends State<IdleScreen> {
  final ApiRepository _apiRepository = ApiRepository();
  Map<String, String>? _hadithData;
  Timer? _hadithTimer;
  bool _isLoading = true;
  String? _errorMessage;

  late String _bgAsset = 'bg.jpg';
  late TextStyle _textStyle = const TextStyle(
    fontSize: 28,
    color: Colors.white,
    height: 1.5,
    shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
  );
  late TextStyle _sourceStyle;

  @override
  void initState() {
    super.initState();
    _sourceStyle = TextStyle(
      fontSize: 22,
      fontStyle: FontStyle.italic,
      color: widget.accentColor,
      fontWeight: FontWeight.bold,
    );
    _loadSettings();
    _loadNewHadith();
    // Muat ulang hadis setiap 5 menit
    _hadithTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadNewHadith();
    });
  }

  @override
  void dispose() {
    _hadithTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bgAsset = prefs.getString('bg_asset') ?? 'bg.jpg';

      // Load Text Styles
      _textStyle = _loadTextStyle(prefs, 'hadith_text', _textStyle);
      _sourceStyle = _loadTextStyle(prefs, 'hadith_source', _sourceStyle);
    });
  }

  TextStyle _loadTextStyle(
    SharedPreferences prefs,
    String key,
    TextStyle defaultStyle,
  ) {
    double size = prefs.getDouble('${key}_size') ?? defaultStyle.fontSize!;
    int colorVal =
        prefs.getInt('${key}_color') ??
        defaultStyle.color?.toARGB32() ??
        Colors.white.toARGB32();
    String font = prefs.getString('${key}_font') ?? 'Roboto';

    return defaultStyle.copyWith(
      fontSize: size,
      color: Color(colorVal),
      fontFamily: font,
      shadows: [const Shadow(blurRadius: 2, color: Colors.black54)],
    );
  }

  Future<void> _loadNewHadith() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Coba ambil dari API
      Map<String, String>? hadith = await _apiRepository.fetchRandomHadith();

      // 2. Jika API gagal, ambil dari Manual (SharedPreferences)
      if (hadith == null) {
        final prefs = await SharedPreferences.getInstance();
        final manualJson = prefs.getString('custom_hadiths');
        if (manualJson != null) {
          List decoded = jsonDecode(manualJson);
          if (decoded.isNotEmpty) {
            final random = Random();
            final item = decoded[random.nextInt(decoded.length)];
            hadith = {
              'text': item['text'].toString(),
              'source': item['source'].toString(),
            };
          }
        }
      }

      // 3. Jika masih kosong, gunakan default agar layar tidak blank
      hadith ??= {
        'text':
            'Sebaik-baik kalian adalah orang yang mempelajari Al-Qur\'an dan mengajarkannya.',
        'source': 'HR. Bukhari',
      };

      if (mounted) {
        setState(() {
          _hadithData = hadith;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  ImageProvider _getBgImage(String path) {
    if (path.startsWith('/') || path.contains(Platform.pathSeparator)) {
      return FileImage(File(path));
    }
    return AssetImage('assets/themes/default/$path');
  }

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(color: widget.accentColor.withValues(alpha: 0.5), width: 1.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStrokedText(
                'MUTIARA HADIS',
                TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.accentColor),
              ),
              _buildStrokedText(
                widget.timeString,
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _getBgImage(_bgAsset),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.black54],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              // Area Konten Utama (Glassmorphism + Auto Scroll)
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(40.0),
                    // Efek Glassmorphism
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: widget.accentColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _buildContent(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrokedText(
    String text,
    TextStyle style, {
    double strokeWidth = 2,
  }) {
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..color = Colors.black,
          ),
        ),
        Text(text, style: style),
      ],
    );
  }

  Widget _buildFooter() {
    if (widget.prayerTimes.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: widget.primaryColor.withValues(alpha: 0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.prayerTimes.map((pt) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStrokedText(
                pt['name'] ?? '',
                widget.textStyles['footer_prayer_name'] ??
                    TextStyle(
                      color: widget.accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              _buildStrokedText(
                pt['time'] ?? '',
                widget.textStyles['footer_prayer_time'] ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _hadithData == null) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.redAccent, fontSize: 20),
      );
    }

    if (_hadithData != null) {
      return _AutoScrollHadith(
        text: _hadithData!['text']!,
        source: _hadithData!['source']!,
        textStyle: _textStyle,
        sourceStyle: _sourceStyle,
      );
    }

    // Fallback
    return const Text(
      'Memuat hadis...',
      style: TextStyle(color: Colors.white70, fontSize: 20),
    );
  }
}

class _AutoScrollHadith extends StatefulWidget {
  final String text;
  final String source;
  final TextStyle textStyle;
  final TextStyle sourceStyle;

  const _AutoScrollHadith({
    required this.text,
    required this.source,
    required this.textStyle,
    required this.sourceStyle,
  });

  @override
  State<_AutoScrollHadith> createState() => _AutoScrollHadithState();
}

class _AutoScrollHadithState extends State<_AutoScrollHadith> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      double maxScroll = _scrollController.position.maxScrollExtent;
      // Hanya scroll jika konten lebih panjang dari layar
      if (maxScroll > 0) {
        // Kecepatan scroll: semakin panjang teks, semakin lama durasinya
        double durationSeconds = maxScroll / 30; // 30 pixels per second
        if (durationSeconds < 5) durationSeconds = 5;

        _scrollTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          _scrollController
              .animateTo(
                maxScroll,
                duration: Duration(seconds: durationSeconds.toInt()),
                curve: Curves.linear,
              )
              .then((_) {
                // Setelah sampai bawah, tunggu sebentar lalu kembali ke atas
                if (mounted) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      _scrollController.jumpTo(0);
                      _startScrolling(); // Ulangi
                    }
                  });
                }
              });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      physics:
          const NeverScrollableScrollPhysics(), // User tidak bisa scroll manual (mode kiosk)
      children: [
        // Spacer atas agar teks mulai dari tengah jika pendek
        const SizedBox(height: 20),
        Text(
          '"${widget.text}"',
          textAlign: TextAlign.center,
          style: widget.textStyle,
        ),
        const SizedBox(height: 30),
        Text(
          '(${widget.source})',
          textAlign: TextAlign.center,
          style: widget.sourceStyle,
        ),
        const SizedBox(
          height: 50,
        ), // Spacer bawah agar teks tidak terpotong mendadak
      ],
    );
  }
}
