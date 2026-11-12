import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RunningTextSettingsView extends StatefulWidget {
  const RunningTextSettingsView({super.key});

  @override
  State<RunningTextSettingsView> createState() =>
      _RunningTextSettingsViewState();
}

class _RunningTextSettingsViewState extends State<RunningTextSettingsView> {
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _textCtrl.text =
        prefs.getString('running_text') ??
        "Selamat Datang di Masjid Al-Muntaha. Mohon nonaktifkan ponsel saat memasuki area sholat dan rapatkan shaf untuk kenyamanan bersama.";
    if (mounted) setState(() {});
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('running_text', _textCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Disimpan')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Running Text',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),
          TextField(
            controller: _textCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Isi Teks Berjalan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Simpan')),
        ],
      ),
    );
  }
}

