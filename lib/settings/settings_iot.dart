import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ---------------- IoT Settings ----------------

class IotSettingsView extends StatefulWidget {
  const IotSettingsView({super.key});

  @override
  State<IotSettingsView> createState() => _IotSettingsViewState();
}

class _IotSettingsViewState extends State<IotSettingsView> {
  final _ipCtrl = TextEditingController();
  final _pathOnCtrl = TextEditingController();
  final _pathOffCtrl = TextEditingController();

  // Status koneksi ke perangkat IoT (ESP32)
  bool? _connected; // null = belum dicek / IP kosong
  String _relayLabel = '';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startStatusPoll();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _ipCtrl.dispose();
    _pathOnCtrl.dispose();
    _pathOffCtrl.dispose();
    super.dispose();
  }

  void _startStatusPoll() {
    _statusTimer?.cancel();
    // cek setiap 4 detik + sekali langsung
    _statusTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkConnection(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    final ip = _ipCtrl.text.trim();
    if (!mounted) return;
    if (ip.isEmpty) {
      setState(() {
        _connected = null;
        _relayLabel = '';
      });
      return;
    }

    try {
      // Probe ke endpoint /status milik firmware ESP32 SIMasjid
      final resp = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(seconds: 3));

      // Perangkat merespon HTTP apa pun -> "terhubung".
      // Baris JSON hanya di-parse jika status 200 (firmware SIMasjid).
      final ok = resp.statusCode >= 200 && resp.statusCode < 500;
      String relay = '';
      if (ok && resp.statusCode == 200) {
        try {
          final data = jsonDecode(resp.body);
          if (data is Map<String, dynamic>) {
            relay = (data['relay'] as String? ?? '').toString();
          }
        } catch (_) {
          // response 200 namun bukan JSON -> tetap dianggap terhubung
        }
      }
      if (!mounted) return;
      setState(() {
        _connected = ok;
        _relayLabel = relay;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _relayLabel = '';
      });
    }
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _ipCtrl.text = prefs.getString('iot_ip') ?? '';
    _pathOnCtrl.text = prefs.getString('iot_path_on') ?? '/on';
    _pathOffCtrl.text = prefs.getString('iot_path_off') ?? '/off';
    if (mounted) setState(() {});
  }

  Future<void> _backupSettings() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mempersiapkan data backup...')),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> allSettings = {};
      for (String key in keys) {
        allSettings[key] = prefs.get(key);
      }

      final jsonString = jsonEncode(allSettings);
      final fileName =
          'simasjid_backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';

      // Menggunakan file_picker untuk menyimpan file
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Simpan Backup Pengaturan',
        fileName: fileName,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup berhasil disimpan di $outputFile')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal melakukan backup: $e')));
    }
  }

  Future<void> _restoreSettings() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> settings = jsonDecode(jsonString);

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Hapus pengaturan lama

        for (var key in settings.keys) {
          final value = settings[key];
          // SharedPreferences hanya mendukung tipe data dasar
          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          } else if (value is List) {
            // SharedPreferences hanya bisa menyimpan List<String>
            await prefs.setStringList(
              key,
              value.map((e) => e.toString()).toList(),
            );
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Restore berhasil! Silakan restart aplikasi untuk menerapkan perubahan.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal melakukan restore: $e')));
    }
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('iot_ip', _ipCtrl.text.trim());
    await prefs.setString('iot_path_on', _pathOnCtrl.text.trim());
    await prefs.setString('iot_path_off', _pathOffCtrl.text.trim());
    await _checkConnection();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengaturan IoT Disimpan')));
  }

  Future<void> _testConnection(bool turnOn) async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('IP Address belum diisi')));
      return;
    }
    final path = turnOn ? _pathOnCtrl.text.trim() : _pathOffCtrl.text.trim();
    final url = 'http://$ip$path';

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mengirim request ke $url ...')));
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sukses! Perintah terkirim.')),
      );
      await _checkConnection();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Widget _buildStatusCard() {
    final Color indicatorColor;
    String statusText;

    if (_connected == null) {
      indicatorColor = Colors.grey;
      statusText = 'IP Address belum diisi';
    } else if (_connected == true) {
      indicatorColor = Colors.green;
      statusText = 'Terhubung'; // Initial value
      if (_relayLabel.isNotEmpty) {
        statusText = 'Terhubung • Relay ${_relayLabel.toUpperCase()}';
      }
    } else {
      indicatorColor = Colors.red;
      statusText = 'Tidak Terhubung';
    }

    return Card(
      elevation: 0,
      color: indicatorColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: indicatorColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.circle, color: indicatorColor, size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Periksa ulang',
              visualDensity: VisualDensity.compact,
              onPressed: _checkConnection,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Smart IoT (Relay Control)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const Text(
            'Kontrol perangkat luar (ESP32/Arduino) via WiFi saat media diputar.',
          ),
          const SizedBox(height: 20),
          _buildStatusCard(),
          const SizedBox(height: 20),
          TextField(
            controller: _ipCtrl,
            onChanged: (_) => _checkConnection(),
            decoration: const InputDecoration(
              labelText: 'IP Address ESP32',
              hintText: 'Contoh: 192.168.1.200',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathOnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Path ON',
                    hintText: '/on',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _testConnection(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Test ON'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathOffCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Path OFF',
                    hintText: '/off',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _testConnection(false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Test OFF'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Simpan Pengaturan'),
          ),
        ],
      ),
    );
  }
}
