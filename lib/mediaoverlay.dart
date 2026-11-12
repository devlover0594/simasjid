import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class MediaOverlay extends StatefulWidget {
  final String path;
  final String type; // 'image' atau 'video' atau 'audio'
  final int playCount;
  final VoidCallback? onFinished;

  const MediaOverlay({
    super.key,
    required this.path,
    required this.type,
    this.playCount = 1,
    this.onFinished,
  });

  @override
  State<MediaOverlay> createState() => _MediaOverlayState();
}

class _MediaOverlayState extends State<MediaOverlay> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _hasError = false;
  int _currentLoop = 0;
  Timer? _imageTimer;
  String? _currentSurahName;
  int? _currentAyahNumber;
  String? _currentAyatText;
  String? _currentTranslation;
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _initVideo();
    } else if (widget.type == 'image') {
      _startImageTimer();
    } else if (widget.type == 'audio') {
      _initAudio();
    }
  }

  Future<void> _initAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      // Listen to audio completion FIRST before playing
      _audioPlayer!.onPlayerComplete.listen((event) {
        _currentLoop++;
        if (_currentLoop < widget.playCount) {
          _audioPlayer!.seek(Duration.zero);
          _audioPlayer!.resume();
        } else {
          if (widget.onFinished != null) widget.onFinished!();
        }
      });
      
      // Then play the audio
      if (widget.path.startsWith('http')) {
        await _audioPlayer!.play(UrlSource(widget.path));
      } else if (widget.path.startsWith('assets/')) {
        // Aset lokal harus menggunakan AssetSource
        await _audioPlayer!.play(AssetSource(widget.path.replaceFirst('assets/', '')));
      } else {
        // File dari penyimpanan perangkat
        await _audioPlayer!.play(DeviceFileSource(widget.path));
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      if (mounted) setState(() => _hasError = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (widget.onFinished != null) widget.onFinished!();
      });
    }
  }

  void _startImageTimer() {
    // Asumsi 1 putaran gambar = 15 detik
    final duration = Duration(seconds: 15 * widget.playCount);
    _imageTimer = Timer(duration, () {
      if (widget.onFinished != null) widget.onFinished!();
    });
  }

  Future<void> _initVideo() async {
    try {
      if (widget.path.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.path),
        );
      } else {
        final file = File(widget.path);
        if (!await file.exists()) {
          throw const FileSystemException('File tidak ditemukan');
        }
        _videoController = VideoPlayerController.file(file);
      }
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
        _videoController!.play();
        // Kita handle looping secara manual untuk menghitung jumlah putar
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Error loading video: $e');
      if (mounted) setState(() => _hasError = true);
      // Jika error, langsung selesaikan agar tidak stuck
      Future.delayed(const Duration(seconds: 3), () {
        if (widget.onFinished != null) widget.onFinished!();
      });
    }
  }

  void _videoListener() {
    if (_videoController == null) return;
    final value = _videoController!.value;
    if (value.position >= value.duration && !value.isPlaying) {
      _currentLoop++;
      if (_currentLoop < widget.playCount) {
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      } else {
        if (widget.onFinished != null) widget.onFinished!();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _imageTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'youtube') {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'YouTube: ${widget.path}',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      );
    }
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 10),
              Text('Gagal memuat media', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
    if (widget.type == 'audio') {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.audiotrack,
                size: 100,
                color: Colors.tealAccent,
              ),
              const SizedBox(height: 20),
              Text(
                'Now Playing',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.path.split('/').last,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              // Add Quran verse display here if available
              if (_currentAyatText != null) ...[
                const SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (_currentSurahName != null)
                            Text(
                              _currentSurahName!,
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            _currentAyatText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              height: 1.8,
                            ),
                          ),
                          if (_currentTranslation != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              _currentTranslation!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Container(
      color: Colors.black,
      child: Center(
        child: widget.type == 'video'
            ? (_videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const CircularProgressIndicator())
            : Image.file(
                File(widget.path),
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 100,
                ),
              ),
      ),
    );
  }
}
