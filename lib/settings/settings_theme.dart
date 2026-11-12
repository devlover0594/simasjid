import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ThemeSettingsView extends StatefulWidget {
  const ThemeSettingsView({super.key});

  @override
  State<ThemeSettingsView> createState() => _ThemeSettingsViewState();
}

class _ThemeSettingsViewState extends State<ThemeSettingsView> {
  int _primaryColor = 0xFF064E3B; // Dark Emerald
  int _accentColor = 0xFFFFC107; // Amber
  String _bgPath = 'bg.jpg';
  bool _applyToAll = false;
  String _logoPath = '';
  bool _showLogo = false;
  bool _logoAnimationEnabled = false;
  int _rotationDurationSeconds = 90;
  String _slideshowEffect = 'fade';

  final Map<String, String> _slideshowEffectOptions = {
    'fade': 'Fade',
    'slide': 'Slide',
    'zoom': 'Zoom',
  };

  final List<Map<String, dynamic>> _themePresets = [
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _primaryColor = prefs.getInt('theme_primary_color') ?? 0xFF064E3B;
      _accentColor = prefs.getInt('theme_accent_color') ?? 0xFFFFC107;
      _bgPath = prefs.getString('bg_dashboard') ?? 'bg.jpg';
      _applyToAll = prefs.getBool('bg_apply_all') ?? false;
      _logoPath = prefs.getString('logo_path') ?? '';
      _showLogo = prefs.getBool('show_logo') ?? false;
      _logoAnimationEnabled = prefs.getBool('logo_animation_enabled') ?? false;
      _rotationDurationSeconds =
          prefs.getInt('rotation_duration_seconds') ?? 90;
      _slideshowEffect = prefs.getString('slideshow_effect') ?? 'fade';
    });
  }

  void _save(int primary, int accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_primary_color', primary);
    await prefs.setInt('theme_accent_color', accent);
    setState(() {
      _primaryColor = primary;
      _accentColor = accent;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tema & Warna berhasil disimpan!')),
    );
  }

  void _saveBackground() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bg_dashboard', _bgPath);
    await prefs.setBool('bg_apply_all', _applyToAll);
    if (_applyToAll) {
      await prefs.setString('bg_asset', _bgPath);
      await prefs.setString('bg_info', _bgPath);
      await prefs.setString('bg_event', _bgPath);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Background berhasil disimpan!')),
    );
  }

  Future<void> _saveLogoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logo_path', path);
    setState(() {
      _logoPath = path;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo masjid berhasil disimpan!')),
    );
  }

  Future<void> _saveShowLogo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_logo', value);
    setState(() {
      _showLogo = value;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Logo masjid akan ditampilkan.'
              : 'Logo masjid disembunyikan.',
        ),
      ),
    );
  }

  Future<void> _saveLogoAnimation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logo_animation_enabled', value);
    setState(() {
      _logoAnimationEnabled = value;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Animasi logo masjid diaktifkan.'
              : 'Animasi logo masjid dinonaktifkan.',
        ),
      ),
    );
  }

  Future<void> _saveRotationDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rotation_duration_seconds', seconds);
    setState(() {
      _rotationDurationSeconds = seconds;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Durasi slideshow berhasil disimpan!')),
    );
  }

  Future<void> _saveSlideshowEffect(String effect) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slideshow_effect', effect);
    setState(() {
      _slideshowEffect = effect;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Efek slideshow disimpan: ${_slideshowEffectOptions[effect]}',
        ),
      ),
    );
  }

  Future<void> _pickBackground() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        final directory = await getApplicationDocumentsDirectory();
        final fileName = path.split(Platform.pathSeparator).last;
        final newPath = '${directory.path}${Platform.pathSeparator}$fileName';
        await File(path).copy(newPath);

        setState(() {
          _bgPath = newPath;
        });

        _saveBackground();
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Tema & Nuansa Warna',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Pilih paduan warna untuk efek glassmorphism pada aplikasi. '
              'Warna ini akan mengubah tampilan utama, background frame, serta '
              'aksen-aksen penting di layar TV masjid Anda.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),
          ..._themePresets.map((preset) {
            bool isSelected =
                _primaryColor == preset['primary'] &&
                _accentColor == preset['accent'];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isSelected ? Colors.white12 : Colors.black45,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isSelected
                      ? Color(preset['accent'])
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => _save(preset['primary'], preset['accent']),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(preset['primary']),
                              Color(preset['accent']),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white24, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Color(preset['accent']).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset['name'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Color(preset['accent'])
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preset['desc'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Color(preset['accent']),
                          size: 32,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 30),
          const Text(
            'Background Utama',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Upload gambar background untuk layar dashboard. Anda juga dapat menerapkannya ke semua layar.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: _bgPath),
                  decoration: const InputDecoration(
                    labelText: 'Path Background',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload'),
                onPressed: _pickBackground,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Terapkan ke Semua Layar'),
            subtitle: const Text(
              'Gunakan background ini untuk layar Jadwal, Info, Hadis, dan Petugas',
            ),
            value: _applyToAll,
            onChanged: (val) {
              setState(() => _applyToAll = val);
              _saveBackground();
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Logo Masjid',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Tambahkan logo masjid yang akan ditampilkan di layar utama.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          SwitchListTile(
            title: const Text('Tampilkan Logo Masjid'),
            subtitle: const Text('Aktifkan logo pada layar utama.'),
            value: _showLogo,
            onChanged: _saveShowLogo,
          ),
          SwitchListTile(
            title: const Text('Animasi Logo'),
            subtitle: const Text('Beri efek animasi ketika logo tampil.'),
            value: _logoAnimationEnabled,
            onChanged: _saveLogoAnimation,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: _logoPath),
                  decoration: const InputDecoration(
                    labelText: 'Path Logo Masjid',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Logo'),
                onPressed: () async {
                  try {
                    FilePickerResult? result = await FilePicker.pickFiles(
                      type: FileType.image,
                    );
                    if (result != null && result.files.single.path != null) {
                      final path = result.files.single.path!;
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final fileName = path.split(Platform.pathSeparator).last;
                      final newPath =
                          '${directory.path}${Platform.pathSeparator}$fileName';
                      await File(path).copy(newPath);
                      _saveLogoPath(newPath);
                    }
                  } catch (e) {
                    debugPrint('Error picking logo file: $e');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Durasi Pergantian Layar',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Atur durasi rotasi layar utama sebelum berpindah ke layar berikutnya.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _rotationDurationSeconds.toDouble(),
                  min: 30,
                  max: 180,
                  divisions: 15,
                  label: '$_rotationDurationSeconds detik',
                  onChanged: (value) {
                    setState(() {
                      _rotationDurationSeconds = value.toInt();
                    });
                  },
                  onChangeEnd: (value) {
                    _saveRotationDuration(value.toInt());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_rotationDurationSeconds detik',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Efek Slideshow',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Pilih efek transisi saat layar utama berpindah.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _slideshowEffectOptions.entries.map((entry) {
              final selected = entry.key == _slideshowEffect;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) {
                  _saveSlideshowEffect(entry.key);
                },
                selectedColor: Colors.tealAccent.withValues(alpha: 0.2),
                backgroundColor: Colors.white10,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

