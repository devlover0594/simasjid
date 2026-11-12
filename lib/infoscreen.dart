import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'models/slide_item.dart';

class InfoScreen extends StatefulWidget {
  final List<SlideItem> slides;
  final List<Map<String, String>> prayerTimes;
  final Map<String, TextStyle> textStyles;
  final String timeString;
  final Color primaryColor;
  final Color accentColor;

  const InfoScreen({
    super.key,
    required this.slides,
    this.prayerTimes = const [],
    this.textStyles = const {},
    this.timeString = '',
    this.primaryColor = const Color(0xFF064E3B),
    this.accentColor = Colors.amber,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);

    // Auto scroll logic (bergantian tampil)
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_currentPage < widget.slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
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
              bottom: BorderSide(
                color: widget.accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStrokedText(
                'INFORMASI MASJID',
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
    Widget content;
    if (widget.slides.isEmpty) {
      content = const Center(
        child: Text(
          "Tidak ada informasi saat ini.",
          style: TextStyle(color: Colors.white70, fontSize: 24),
        ),
      );
    } else {
      content = Center(
        child: SizedBox(
          height: 500, // Tinggi area card
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.slides.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final slide = widget.slides[index];
              // Animasi scale untuk item yang aktif vs tidak aktif
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                  } else {
                    value = (index == _currentPage) ? 1.0 : 0.8;
                  }
                  return Transform.scale(
                    scale: Curves.easeOut.transform(value),
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 20,
                  ),
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
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.5),
                          border: Border.all(
                            color: _currentPage == index
                                ? widget.accentColor
                                : widget.accentColor.withValues(alpha: 0.3),
                            width: _currentPage == index ? 2 : 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slide.title,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: widget.accentColor,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  child: Text(
                                    slide.content,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
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
          ),
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
}
