import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HadithSettingsView extends StatefulWidget {
  const HadithSettingsView({super.key});

  @override
  State<HadithSettingsView> createState() => _HadithSettingsViewState();
}

class _HadithSettingsViewState extends State<HadithSettingsView> {
  bool _showHadith = true;
  final _intervalCtrl = TextEditingController();
  final _speedCtrl = TextEditingController();
  List<Map<String, String>> _manualHadiths = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _showHadith = prefs.getBool('hadith_show') ?? true;
    _intervalCtrl.text = (prefs.getInt('hadith_interval') ?? 5)
        .toString(); // minutes
    _speedCtrl.text = (prefs.getInt('hadith_speed') ?? 30)
        .toString(); // seconds to scroll

    final manualJson = prefs.getString('custom_hadiths');
    if (manualJson != null) {
      try {
        List decoded = jsonDecode(manualJson);
        _manualHadiths = decoded
            .map(
              (e) => {
                'text': e['text'].toString(),
                'source': e['source'].toString(),
              },
            )
            .toList();
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hadith_show', _showHadith);
    await prefs.setInt(
      'hadith_interval',
      int.tryParse(_intervalCtrl.text) ?? 5,
    );
    await prefs.setInt('hadith_speed', int.tryParse(_speedCtrl.text) ?? 30);
    await prefs.setString('custom_hadiths', jsonEncode(_manualHadiths));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengaturan Hadis Disimpan')));
  }

  void _addManualHadith() {
    final textCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tambah Hadis Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(labelText: 'Isi Hadis'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: sourceCtrl,
              decoration: const InputDecoration(labelText: 'Sumber (Perawi)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textCtrl.text.isNotEmpty && sourceCtrl.text.isNotEmpty) {
                setState(() {
                  _manualHadiths.add({
                    'text': textCtrl.text,
                    'source': sourceCtrl.text,
                  });
                });
                Navigator.pop(c);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _removeManualHadith(int index) {
    setState(() {
      _manualHadiths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Pengaturan Tampilan Hadis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Tampilkan Hadis Acak'),
            subtitle: const Text('Menampilkan hadis acak secara periodik.'),
            value: _showHadith,
            onChanged: (v) {
              setState(() => _showHadith = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _intervalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Interval Hadis Baru (menit)',
              helperText: 'Berapa menit sekali hadis akan diganti.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _speedCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Durasi Scroll (detik)',
              helperText:
                  'Semakin besar, semakin lambat. Waktu untuk scroll dari bawah ke atas.',
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Hadis Manual (Offline)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: _addManualHadith,
                tooltip: 'Tambah Hadis Manual',
              ),
            ],
          ),
          if (_manualHadiths.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Belum ada hadis manual. Tambahkan untuk cadangan saat offline.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ..._manualHadiths.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Card(
              child: ListTile(
                title: Text(
                  item['text']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item['source']!),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeManualHadith(idx),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Simpan')),
        ],
      ),
    );
  }
}

