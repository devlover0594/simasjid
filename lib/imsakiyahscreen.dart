import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'api_repository.dart';

class ImsakiyahScreen extends StatefulWidget {
  final String? province;
  final String? city;
  final List<Map<String, String>> prayerTimes;
  final Map<String, TextStyle> textStyles;

  const ImsakiyahScreen({
    super.key,
    required this.province,
    required this.city,
    this.prayerTimes = const [],
    this.textStyles = const {},
  });

  @override
  State<ImsakiyahScreen> createState() => _ImsakiyahScreenState();
}

class _ImsakiyahScreenState extends State<ImsakiyahScreen> {
  final ApiRepository _apiRepository = ApiRepository();
  List<Map<String, String>> _imsakiyahData = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Controller untuk mengontrol posisi scroll
  final ScrollController _scrollController = ScrollController();
  // Timer untuk menjalankan animasi scroll secara berkala
  Timer? _scrollTimer;
  // Flag untuk mendeteksi apakah user sedang menyentuh layar
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _fetchImsakiyah();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Fungsi untuk memulai auto-scroll
  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_scrollController.hasClients && !_isUserInteracting) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset;

        if (currentScroll >= maxScroll) {
          // Jika sudah sampai paling bawah, kembali ke atas setelah jeda singkat
          _scrollTimer?.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _scrollController.animateTo(
                0,
                duration: const Duration(seconds: 1),
                curve: Curves.easeOut,
              );
              _startAutoScroll();
            }
          });
        } else {
          // Geser sejauh 0.7 pixel setiap 50ms (bisa disesuaikan kecepatannya)
          _scrollController.jumpTo(currentScroll + 0.7);
        }
      }
    });
  }

  Future<void> _fetchImsakiyah() async {
    if (widget.province == null || widget.city == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Provinsi atau Kota belum dipilih di pengaturan.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiRepository.fetchMonthlyImsakiyahEQuran(
        widget.province!,
        widget.city!,
      );

      if (mounted) {
        setState(() {
          if (data != null && data.isNotEmpty) {
            _imsakiyahData = data;
            _isLoading = false;
            // Jalankan scroll otomatis setelah data tampil
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _startAutoScroll(),
            );
          } else {
            _errorMessage = 'Gagal mengambil data imsakiyah atau data kosong.';
            _isLoading = false;
          }
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

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            border: const Border(
              bottom: BorderSide(color: Colors.white24, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStrokedText(
                'JADWAL IMSAKIYAH',
                const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 1.5,
                ),
                strokeWidth: 2,
                textAlign: TextAlign.center,
              ),
              if (widget.city != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: _buildStrokedText(
                    '${widget.city ?? ''}, ${widget.province ?? ''}',
                    const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    strokeWidth: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
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
    TextAlign textAlign = TextAlign.start,
  }) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = Colors.black,
          ),
        ),
        Text(text, textAlign: textAlign, style: style),
      ],
    );
  }

  Widget _buildTableHeader() {
    final headers = [
      'Tanggal',
      'Imsak',
      'Subuh',
      'Terbit',
      'Dhuha',
      'Dzuhur',
      'Ashar',
      'Maghrib',
      'Isya',
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.8), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
      ),
      child: Row(
        children: headers.map((h) {
          return Expanded(
            flex: h == 'Tanggal' ? 3 : 1,
            child: Text(
              h,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlassCard(Map<String, String> data, int index) {
    // Warna-warni nuansa islami (Teal, Green, Blue, Purple) dengan transparansi
    final List<Color> cardColors = [
      Colors.teal.withValues(alpha: 0.2),
      Colors.green.withValues(alpha: 0.2),
      Colors.blue.withValues(alpha: 0.2),
      Colors.indigo.withValues(alpha: 0.2),
      Colors.purple.withValues(alpha: 0.2),
    ];

    // Cek apakah tanggal ini adalah hari ini
    bool isToday = false;
    final now = DateTime.now();
    final dateStr = data['tanggal'] ?? '';
    final dayPad = now.day.toString().padLeft(2, '0');
    final monthPad = now.month.toString().padLeft(2, '0');
    final yearStr = now.year.toString();

    if (dateStr.contains('$dayPad/$monthPad/$yearStr') ||
        dateStr.contains('$yearStr-$monthPad-$dayPad')) {
      isToday = true;
    }

    final color = isToday
        ? Colors.amber.withValues(alpha: 0.4)
        : cardColors[index % cardColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isToday ? Colors.amber : Colors.white.withValues(alpha: 0.2),
                width: isToday ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isToday
                      ? Colors.amber.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.1),
                  blurRadius: isToday ? 20 : 10,
                  spreadRadius: isToday ? 2 : 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildStrokedText(
                    data['tanggal'] ?? '',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    strokeWidth: 1.5,
                    textAlign: TextAlign.center,
                  ),
                ),
                ...[
                  'imsak',
                  'subuh',
                  'terbit',
                  'dhuha',
                  'dzuhur',
                  'ashar',
                  'maghrib',
                  'isya',
                ].map((key) {
                  return Expanded(
                    flex: 1,
                    child: _buildStrokedText(
                      data[key] ?? '',
                      TextStyle(
                        color: isToday ? Colors.white : Colors.amberAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      strokeWidth: 1.5,
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ],
            ),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.black54, Colors.black87],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            // Header Tabel
            _buildTableHeader(),
            // List Data
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: _buildStrokedText(
                        _errorMessage!,
                        const TextStyle(
                          color: Colors.red,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        strokeWidth: 2,
                      ),
                    )
                  : Listener(
                      // Mendeteksi sentuhan manual untuk menjeda scroll
                      onPointerDown: (_) => _isUserInteracting = true,
                      onPointerUp: (_) => _isUserInteracting = false,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: _imsakiyahData
                                .asMap()
                                .entries
                                .map(
                                  (entry) =>
                                      _buildGlassCard(entry.value, entry.key),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (widget.prayerTimes.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      color: Colors.black.withValues(alpha: 0.8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: widget.prayerTimes.map((pt) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStrokedText(
                  pt['name'] ?? '',
                  widget.textStyles['footer_prayer_name'] ??
                      const TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                  strokeWidth: 2,
                ),
                _buildStrokedText(
                  pt['time'] ?? '',
                  widget.textStyles['footer_prayer_time'] ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                  strokeWidth: 2,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
