import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PerformerScreen extends StatefulWidget {
  final String eventName;
  final String eventDate;
  final String? eventEndDate;
  final List<Map<String, String>> performers;
  final List<Map<String, String>> prayerTimes;
  final Map<String, TextStyle> textStyles;
  final List<Map<String, dynamic>> allSchedules;
  final List<Map<String, dynamic>> allProfiles;
  final String timeString;
  final Color primaryColor;
  final Color accentColor;

  const PerformerScreen({
    super.key,
    required this.eventName,
    required this.eventDate,
    this.eventEndDate,
    this.performers = const [],
    this.prayerTimes = const [],
    this.textStyles = const {},
    this.allSchedules = const [],
    this.allProfiles = const [],
    this.timeString = '',
    this.primaryColor = const Color(0xFF064E3B),
    this.accentColor = Colors.amber,
  });

  @override
  State<PerformerScreen> createState() => _PerformerScreenState();
}

class _PerformerScreenState extends State<PerformerScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  // State lokal untuk menampung data yang sedang ditampilkan (bisa berubah via DatePicker)
  late String _eventName;
  late String _eventDate;
  late String? _eventEndDate;
  late List<Map<String, String>> _performers;

  @override
  void initState() {
    super.initState();
    _eventName = widget.eventName;
    _eventDate = widget.eventDate;
    _eventEndDate = widget.eventEndDate;
    _performers = widget.performers;

    // viewportFraction diatur agar kartu di sampingnya sedikit terlihat
    _pageController = PageController(viewportFraction: 0.75);

    // Logika auto-scroll
    _timer = Timer.periodic(const Duration(seconds: 8), (Timer timer) {
      if (_performers.isEmpty) return; // Jangan scroll jika kosong

      if (_currentPage < _performers.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void didUpdateWidget(PerformerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika data dari parent berubah (misal rotasi layar), reset tampilan ke default parent
    if (widget.eventName != oldWidget.eventName ||
        widget.eventDate != oldWidget.eventDate) {
      setState(() {
        _eventName = widget.eventName;
        _eventDate = widget.eventDate;
        _eventEndDate = widget.eventEndDate;
        _performers = widget.performers;
        _currentPage = 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime initialDate =
        DateTime.tryParse(_eventDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
      helpText: 'Cek Jadwal Pengisi Acara',
    );

    if (picked != null) {
      final pickedDate = DateTime(picked.year, picked.month, picked.day);

      // Cari jadwal di tanggal tersebut
      final event = widget.allSchedules.firstWhere((e) {
        final startStr = e['date'] as String?;
        if (startStr == null) return false;
        final start = DateTime.parse(startStr);
        DateTime end = start;
        if (e['endDate'] != null) {
          end = DateTime.parse(e['endDate'] as String);
        }
        return (pickedDate.isAtSameMomentAs(start) ||
                pickedDate.isAfter(start)) &&
            (pickedDate.isAtSameMomentAs(end) || pickedDate.isBefore(end));
      }, orElse: () => <String, dynamic>{});

      if (event.isNotEmpty) {
        // Jika ada acara, ambil data petugasnya
        List<String> pIds = List<String>.from(event['performerIds'] ?? []);
        List<Map<String, String>> newPerformers = widget.allProfiles
            .where((p) => pIds.contains(p['id']))
            .map(
              (p) => {
                'name': p['name'] as String? ?? '',
                'role': p['role'] as String? ?? '',
                'photoUrl': p['photoPath'] as String? ?? '',
              },
            )
            .toList();

        setState(() {
          _eventName = event['name'];
          _eventDate = event['date'];
          _eventEndDate = event['endDate'];
          _performers = newPerformers;
          _currentPage = 0;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tidak ada agenda pada ${DateFormat('d MMMM yyyy', 'id_ID').format(picked)}',
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildScreenHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(color: widget.accentColor.withOpacity(0.5), width: 1.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStrokedText(
                'AGENDA & PETUGAS',
                TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.accentColor,
                ),
              ),
              _buildStrokedText(
                widget.timeString,
                const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widget induk sebaiknya menangani untuk tidak menampilkan layar ini jika tidak ada performer.
    // Namun, pengecekan di sini tetap merupakan praktik yang baik.
    if (_performers.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada jadwal pengisi acara saat ini.",
          style: TextStyle(color: Colors.white70, fontSize: 24),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScreenHeader(),
        const SizedBox(height: 10),
        _buildHeader(),
        const SizedBox(height: 10),
        Expanded(child: _buildPerformerSlider()),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Text(
            _eventName,
            style:
                widget.textStyles['performer_event_name']?.copyWith(
                  shadows: [
                    const Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ) ??
                TextStyle(fontSize: 36, color: widget.accentColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDateRange(_eventDate, _eventEndDate),
                style:
                    widget.textStyles['performer_event_date'] ??
                    const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_month, color: widget.accentColor),
                tooltip: 'Cek Tanggal Lain',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateRange(String dateStr, String? endDateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final fmt = DateFormat('d MMM yyyy', 'id_ID');
      final fullFmt = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

      if (endDateStr != null && endDateStr != dateStr) {
        final endDt = DateTime.parse(endDateStr);
        return "${fmt.format(dt)} - ${fullFmt.format(endDt)}";
      }
      return fullFmt.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildPerformerSlider() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _performers.length,
      onPageChanged: (int index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        final performer = _performers[index];
        // Animasi scaling dari InfoScreen
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 1.0;
            if (_pageController.hasClients &&
                _pageController.position.haveDimensions) {
              value = _pageController.page! - index;
              value = (1 - (value.abs() * 0.25)).clamp(0.0, 1.0);
            } else {
              value = (index == 0) ? 1.0 : 0.75;
            }
            return Transform.scale(
              scale: Curves.easeOut.transform(value),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 15,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.5),
                    border: Border.all(
                      color: _currentPage == index
                          ? widget.accentColor
                          : widget.accentColor.withOpacity(0.3),
                      width: _currentPage == index ? 2.5 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  // Ubah layout menjadi Row (Kiri: Foto, Kanan: Teks) untuk mengatasi masalah rasio foto
                  child: Row(
                    children: [
                      // Foto Performer
                      Expanded(
                        flex: 4,
                        child: Container(
                          margin: const EdgeInsets.all(15),
                          child: _buildPerformerImage(performer['photoUrl']),
                        ),
                      ),
                      // Info Performer
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                performer['name'] ?? 'Nama Pengisi Acara',
                                style:
                                    widget.textStyles['performer_name'] ??
                                    const TextStyle(
                                      fontSize: 32,
                                      color: Colors.white,
                                    ),
                                textAlign: TextAlign.left,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                performer['role'] ?? 'Peran',
                                style:
                                    widget.textStyles['performer_role'] ??
                                    TextStyle(
                                      fontSize: 24,
                                      color: widget.accentColor,
                                    ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = Colors.black,
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
      color: widget.primaryColor.withOpacity(0.8),
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

  Widget _buildPerformerImage(String? path) {
    ImageProvider imageProvider;
    if (path != null && path.isNotEmpty) {
      // Cek apakah path adalah URL http atau file lokal
      if (path.startsWith('http')) {
        imageProvider = NetworkImage(path);
      } else {
        imageProvider = FileImage(File(path));
      }
    } else {
      // Fallback ke placeholder jika path tidak ada
      imageProvider = const AssetImage(
        'assets/themes/default/bg.jpg',
      ); // Atau placeholder lain
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image(
        image: imageProvider,
        fit: BoxFit.cover,
        alignment: Alignment
            .topCenter, // Fokus ke bagian atas (wajah) agar tidak terpotong
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(color: widget.accentColor),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Jika gagal load (file tidak ada, url salah, dll)
          return Container(
            color: Colors.grey[800],
            child: const Icon(Icons.person, color: Colors.white54, size: 100),
          );
        },
      ),
    );
  }
}
