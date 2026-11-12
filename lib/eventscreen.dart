import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class EventScreen extends StatefulWidget {
  final List<Map<String, String>> events;
  final List<Map<String, String>> prayerTimes;
  final String timeString;
  final Color primaryColor;
  final Color accentColor;

  const EventScreen({
    super.key,
    required this.events,
    this.prayerTimes = const [],
    required this.timeString,
    this.primaryColor = const Color(0xFF064E3B),
    this.accentColor = Colors.amber,
  });

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    // Auto scroll perlahan jika konten melebihi layar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (
          timer,
        ) {
          if (_scrollController.hasClients) {
            double newPos = _scrollController.offset + 1.0;
            if (newPos >= maxScroll) {
              // Jika sampai bawah, kembali ke atas (loop)
              _scrollController.jumpTo(0);
            } else {
              _scrollController.jumpTo(newPos);
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final year = parts[0];
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      const months = [
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
      return '$day ${months[month - 1]} $year';
    } catch (_) {
      return dateStr;
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
            color: widget.primaryColor.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(color: widget.accentColor.withValues(alpha: 0.5), width: 1.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStrokedText(
                'AGENDA KEGIATAN',
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

  @override
  Widget build(BuildContext context) {
    // Urutkan event berdasarkan tanggal
    final sortedEvents = List<Map<String, String>>.from(widget.events);
    sortedEvents.sort((a, b) {
      return (a['date'] ?? '').compareTo(b['date'] ?? '');
    });

    // Filter hanya event yang belum lewat (hari ini atau masa depan)
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final upcomingEvents = sortedEvents.where((e) {
      return (e['date'] ?? '').compareTo(todayStr) >= 0;
    }).toList();

    Widget content;
    if (upcomingEvents.isEmpty) {
      content = const Center(
        child: Text(
          "Tidak ada agenda kegiatan mendatang.",
          style: TextStyle(color: Colors.white70, fontSize: 24),
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 kartu per baris
            childAspectRatio: 1.6,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: upcomingEvents.length,
          itemBuilder: (context, index) {
            final event = upcomingEvents[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.5),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatDate(event['date'] ?? ''),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            event['title'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: content),
        _buildFooter(),
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
              Text(
                pt['name'] ?? '',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pt['time'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
