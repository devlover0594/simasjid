import 'dart:io';
import 'package:flutter/material.dart';

class NotifOverlay extends StatelessWidget {
  final String title;
  final String prayerName;
  final String message;
  final String bgImage;
  final Widget? child;

  const NotifOverlay({
    super.key,
    required this.title,
    required this.prayerName,
    required this.message,
    required this.bgImage,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider bgProvider;
    if (bgImage.startsWith('/') || bgImage.contains(Platform.pathSeparator)) {
      bgProvider = FileImage(File(bgImage));
    } else {
      // Fallback logic for assets
      bgProvider = AssetImage(
        bgImage.contains('/') ? bgImage : 'assets/themes/default/$bgImage',
      );
    }

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image(
            image: bgProvider,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if specific path fails, try theme path or color
              return Image.asset(
                'assets/themes/default/bgnotif.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: Colors.black87),
              );
            },
          ),
        ),
        // Dimmer
        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.7))),
        // Content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                prayerName,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: message.isNotEmpty
                    ? SizedBox(
                        height: 100, // Beri batasan tinggi untuk pesan
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox(height: 100),
              ),
              if (child != null) ...[const SizedBox(height: 50), child!],
            ],
          ),
        ),
      ],
    );
  }
}
