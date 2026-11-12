import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  final _adzanDurationCtrl = TextEditingController();
  final _iqomahDelayCtrl = TextEditingController();
  final _iqomahDurationCtrl = TextEditingController();
  final _textAdzanCtrl = TextEditingController();
  final _textIqomahTimer = TextEditingController();
  final _textIqomahCtrl = TextEditingController();
  final _khutbahDurationCtrl = TextEditingController();
  final _khutbahTextCtrl = TextEditingController();
  final _sholatDurationCtrl = TextEditingController();
  final _sholatTextCtrl = TextEditingController();
  bool _fridayModeEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _adzanDurationCtrl.text = (prefs.getInt('notif_adzan_duration') ?? 180)
        .toString(); // detik
    _iqomahDelayCtrl.text = (prefs.getInt('notif_iqomah_delay') ?? 10)
        .toString(); // menit
    _iqomahDurationCtrl.text = (prefs.getInt('notif_iqomah_duration') ?? 60)
        .toString(); // detik
    _textAdzanCtrl.text =
        prefs.getString('notif_text_adzan') ?? 'SAATNYA ADZAN';
    _textIqomahTimer.text =
        prefs.getString('notif_text_iqomah_timer') ??
        'DOA ANTARA ADZAN DAN IQOMAH NISCAYA AKAN TERKABUL';
    _textIqomahCtrl.text =
        prefs.getString('notif_text_iqomah') ?? 'LURUSKAN DAN RAPATKAN SHAF';

    _fridayModeEnabled = prefs.getBool('friday_mode_enabled') ?? true;
    _khutbahDurationCtrl.text = (prefs.getInt('friday_khutbah_duration') ?? 30)
        .toString();
    _khutbahTextCtrl.text =
        prefs.getString('friday_khutbah_text') ??
        "Harap tenang saat khutbah berlangsung, nonaktifkan ponsel Anda.";

    _sholatDurationCtrl.text = (prefs.getInt('notif_sholat_duration') ?? 600)
        .toString();
    _sholatTextCtrl.text =
        prefs.getString('notif_text_sholat') ??
        'SHOLAT TELAH DIMULAI, HARAP TENANG';
    if (mounted) setState(() {});
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'notif_adzan_duration',
      int.tryParse(_adzanDurationCtrl.text) ?? 180,
    );
    await prefs.setInt(
      'notif_iqomah_delay',
      int.tryParse(_iqomahDelayCtrl.text) ?? 10,
    );
    await prefs.setInt(
      'notif_iqomah_duration',
      int.tryParse(_iqomahDurationCtrl.text) ?? 60,
    );
    await prefs.setString('notif_text_adzan', _textAdzanCtrl.text);
    await prefs.setString('notif_text_iqomah_timer', _textIqomahTimer.text);
    await prefs.setString('notif_text_iqomah', _textIqomahCtrl.text);

    await prefs.setBool('friday_mode_enabled', _fridayModeEnabled);
    await prefs.setInt(
      'friday_khutbah_duration',
      int.tryParse(_khutbahDurationCtrl.text) ?? 30,
    );
    await prefs.setString('friday_khutbah_text', _khutbahTextCtrl.text);

    await prefs.setInt(
      'notif_sholat_duration',
      int.tryParse(_sholatDurationCtrl.text) ?? 600,
    );
    await prefs.setString('notif_text_sholat', _sholatTextCtrl.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan Notifikasi Disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Pengaturan Notifikasi Adzan & Iqomah',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),
          TextField(
            controller: _adzanDurationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Durasi Notifikasi Adzan (detik)',
              helperText: 'Berapa lama layar Adzan muncul',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _iqomahDelayCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jeda Menuju Iqomah (menit)',
              helperText: 'Waktu tunggu antara Adzan dan Iqomah',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _iqomahDurationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Durasi Notifikasi Iqomah (detik)',
              helperText: 'Berapa lama layar Iqomah muncul',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textAdzanCtrl,
            decoration: const InputDecoration(
              labelText: 'Teks Judul Adzan',
              hintText: 'Contoh: MEMASUKI WAKTU',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textIqomahTimer,
            decoration: const InputDecoration(
              labelText: 'Teks Timer Iqomah',
              hintText:
                  'Contoh: DOA ANTARA ADZAN DAN IQOMAH NISCAYA AKAN TERKABUL',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textIqomahCtrl,
            decoration: const InputDecoration(
              labelText: 'Pesan Iqomah',
              hintText: 'Contoh: LURUSKAN DAN RAPATKAN SHAF',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pengaturan Mode Sholat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          TextField(
            controller: _sholatDurationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Durasi Mode Sholat (detik)',
              helperText: 'Layar akan kembali normal setelah durasi ini',
            ),
          ),
          TextField(
            controller: _sholatTextCtrl,
            decoration: const InputDecoration(labelText: 'Pesan Saat Sholat'),
          ),
          const Divider(),
          const Text(
            'Mode Khusus Sholat Jumat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Aktifkan Mode Jumat'),
            subtitle: const Text(
              'Tampilkan layar khusus saat waktu Khutbah Jumat',
            ),
            value: _fridayModeEnabled,
            onChanged: (v) => setState(() => _fridayModeEnabled = v),
          ),
          TextField(
            controller: _khutbahDurationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Durasi Khutbah (menit)',
            ),
          ),
          TextField(
            controller: _khutbahTextCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Pesan Khutbah'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
