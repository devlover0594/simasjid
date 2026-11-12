import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ---------------- Subpages ----------------

class IdentitySettingsView extends StatefulWidget {
  const IdentitySettingsView({super.key});

  @override
  State<IdentitySettingsView> createState() => _IdentitySettingsViewState();
}

class _IdentitySettingsViewState extends State<IdentitySettingsView> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _ipAddress = "Memuat IP...";

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text = prefs.getString('mosque_name') ?? 'MASJID AL MUNTAHA';
    _addressCtrl.text =
        prefs.getString('mosque_address') ?? 'Perum Bumi Cipta Laras';

    // Get IP Address
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            _ipAddress = "${addr.address}:8088";
          }
        }
      }
    } catch (_) {
      _ipAddress = "Tidak terhubung ke Wi-Fi";
    }

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
    await prefs.setString('mosque_name', _nameCtrl.text.trim());
    await prefs.setString('mosque_address', _addressCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Disimpan')));
  }

  void _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset ke default?'),
        content: const Text(
          'PERINGATAN: Semua pengaturan akan dihapus dan dikembalikan ke awal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset Sekarang'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Hapus semua preferensi

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset selesai. Silakan restart aplikasi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Identitas Masjid',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Masjid'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Alamat'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal),
            ),
            child: SelectableText(
              'SULIT MENGETIK DI TV? GUNAKAN HP SAJA.\nHubungkan HP ke Wi-Fi yang sama, buka Chrome dan ketik:\nhttp://$_ipAddress',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Simpan')),
          const SizedBox(height: 40),
          const Divider(),
          const Text(
            'Manajemen Data',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _backupSettings,
                  icon: const Icon(Icons.download),
                  label: const Text('Backup Pengaturan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _restoreSettings,
                  icon: const Icon(Icons.upload),
                  label: const Text('Restore Pengaturan'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.red),
          const Text(
            'Zona Bahaya',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.restore),
            label: const Text('Reset Semua Pengaturan ke Awal'),
          ),
        ],
      ),
    );
  }
}
