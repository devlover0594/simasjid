import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SlideSettingsView extends StatefulWidget {
  const SlideSettingsView({super.key});

  @override
  State<SlideSettingsView> createState() => _SlideSettingsViewState();
}

class _SlideSettingsViewState extends State<SlideSettingsView> {
  List<Map<String, String>> _slides = [
    {
      'title': 'Selamat Datang',
      'content': 'Mohon luruskan dan rapatkan shaf sholat.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('slides');
    if (jsonStr != null) {
      try {
        final List decoded = jsonDecode(jsonStr);
        final tmp = <Map<String, String>>[];
        for (final e in decoded) {
          tmp.add({
            'title': (e['title'] ?? '').toString(),
            'content': (e['content'] ?? '').toString(),
          });
        }
        _slides = tmp;
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slides', jsonEncode(_slides));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Slides disimpan')));
  }

  void _addSlide() {
    setState(() {
      _slides.add({'title': '', 'content': ''});
    });
  }

  void _removeSlide(int index) {
    setState(() {
      _slides.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Slide Informasi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addSlide,
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.green,
                  size: 32,
                ),
                tooltip: 'Tambah Slide',
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          ..._slides.asMap().entries.map((entry) {
            final idx = entry.key;
            final slide = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Slide ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeSlide(idx),
                          tooltip: 'Hapus Slide',
                        ),
                      ],
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Judul'),
                      initialValue: slide['title'],
                      onChanged: (v) => slide['title'] = v,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Konten'),
                      initialValue: slide['content'],
                      onChanged: (v) => slide['content'] = v,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            );
          }),
          ElevatedButton(onPressed: _save, child: const Text('Simpan')),
        ],
      ),
    );
  }
}

