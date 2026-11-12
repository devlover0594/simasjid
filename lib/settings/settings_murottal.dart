import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ---------------- Murottal Settings ----------------

class MurottalSettingsView extends StatefulWidget {
  const MurottalSettingsView({super.key});

  @override
  State<MurottalSettingsView> createState() => _MurottalSettingsViewState();
}

class _MurottalSettingsViewState extends State<MurottalSettingsView> {
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _mediaLibrary = [];
  final _prayerNames = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
  final List<String> _qaris = [
    'Abdullah-Al-Juhany',
    'Abdulrahman Al-Sudais',
    'Saad Al-Ghamdi',
    'Mishary Al-Afasy',
    'Yasser Al-Dosari',
  ];
  List<Map<String, dynamic>> _surahs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _fetchSurahs() async {
    try {
      final response = await http.get(
        Uri.parse('https://equran.id/api/v2/surat'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          if (mounted) {
            setState(() {
              _surahs = List<Map<String, dynamic>>.from(data['data']);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching surahs: $e');
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final schedJson = prefs.getString('murottal_schedules');
    if (schedJson != null) {
      try {
        _schedules = List<Map<String, dynamic>>.from(jsonDecode(schedJson));
      } catch (_) {}
    }

    final libJson = prefs.getString('media_library');
    if (libJson != null) {
      try {
        _mediaLibrary = List<Map<String, dynamic>>.from(jsonDecode(libJson));
      } catch (_) {}
    }

    // Ensure all prayer times have a schedule entry
    for (final prayerName in _prayerNames) {
      if (!_schedules.any((s) => s['prayer'] == prayerName)) {
        _schedules.add({
          'prayer': prayerName,
          'enabled': false,
          'minutes_before': 10,
          'is_random': false,
          'loop_count': 1,
          'stop_before_adzan': 2,
          'path': '',
          'source_type': 'file', // 'file' or 'api'
          'qari': 'Abdullah-Al-Juhany',
          'surah_number': 1,
          // --- Fitur Pro: Tarhim & Adzan Otomatis ---
          'tarhim_enabled': false,
          'tarhim_minutes_before': 20,
          'adzan_enabled': false,
          'adzan_path': '',
        });
      }
    }

    // Sort schedules according to prayer order
    _schedules.sort(
      (a, b) => _prayerNames
          .indexOf(a['prayer'])
          .compareTo(_prayerNames.indexOf(b['prayer'])),
    );

    if (mounted) setState(() {});
    _fetchSurahs();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('murottal_schedules', jsonEncode(_schedules));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Jadwal Murottal Disimpan')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Murottal Sebelum Adzan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Atur pemutaran audio/video murottal secara otomatis sebelum waktu sholat.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                final prayerName = schedule['prayer'] ?? 'Sholat';
                final enabled = schedule['enabled'] as bool? ?? false;
                final tarhimEnabled =
                    schedule['tarhim_enabled'] as bool? ?? false;
                final adzanEnabled =
                    schedule['adzan_enabled'] as bool? ?? false;
                final sourceType = schedule['source_type'] ?? 'file';
                final qari = schedule['qari'] ?? _qaris.first;
                final surahNumber = schedule['surah_number'] ?? 1;
                final selectedPath = schedule['path']?.toString() ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      'Pengaturan untuk: $prayerName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      enabled ? 'Murottal aktif' : 'Murottal nonaktif',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Aktifkan Murottal'),
                              value: enabled,
                              onChanged: (val) =>
                                  setState(() => schedule['enabled'] = val),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Aktifkan Tarhim'),
                                    value: tarhimEnabled,
                                    onChanged: (val) => setState(
                                      () => schedule['tarhim_enabled'] = val,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Putar Adzan'),
                                    value: adzanEnabled,
                                    onChanged: (val) => setState(
                                      () => schedule['adzan_enabled'] = val,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (tarhimEnabled) ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue:
                                    (schedule['tarhim_minutes_before'] ?? 20)
                                        .toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Mulai Tarhim (Menit Sebelum Adzan)',
                                  prefixIcon: Icon(Icons.schedule),
                                ),
                                onChanged: (v) =>
                                    schedule['tarhim_minutes_before'] =
                                        int.tryParse(v) ?? 20,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Catatan: Fitur Tarhim akan memutar file "assets/audio/tarhim.mp3" secara otomatis.',
                                style: TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        (schedule['minutes_before'] ?? 10)
                                            .toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Mulai (Menit Sebelum)',
                                    ),
                                    onChanged: (v) =>
                                        schedule['minutes_before'] =
                                            int.tryParse(v) ?? 10,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        (schedule['stop_before_adzan'] ?? 2)
                                            .toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Stop (Menit Sebelum)',
                                    ),
                                    onChanged: (v) =>
                                        schedule['stop_before_adzan'] =
                                            int.tryParse(v) ?? 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: sourceType,
                              decoration: const InputDecoration(
                                labelText: 'Sumber Murottal',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'file',
                                  child: Text('File dari Playlist'),
                                ),
                                DropdownMenuItem(
                                  value: 'api',
                                  child: Text('Streaming Surah (API)'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => schedule['source_type'] = v),
                            ),
                            const SizedBox(height: 8),
                            if (sourceType == 'api') ...[
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: qari,
                                      decoration: const InputDecoration(
                                        labelText: 'Pilih Qori',
                                      ),
                                      items: _qaris
                                          .map(
                                            (q) => DropdownMenuItem(
                                              value: q,
                                              child: Text(q),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => schedule['qari'] = v),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      initialValue: surahNumber,
                                      decoration: const InputDecoration(
                                        labelText: 'Pilih Surah',
                                      ),
                                      items: _surahs.isEmpty
                                          ? [
                                              const DropdownMenuItem(
                                                value: 1,
                                                child: Text('Memuat...'),
                                              ),
                                            ]
                                          : _surahs.map((s) {
                                              return DropdownMenuItem<int>(
                                                value: s['nomor'] as int,
                                                child: Text(
                                                  '${s['nomor']}. ${s['namaLatin']}',
                                                ),
                                              );
                                            }).toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(
                                            () => schedule['surah_number'] = v,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              DropdownButtonFormField<String>(
                                initialValue: selectedPath.isEmpty
                                    ? null
                                    : selectedPath,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih File dari Playlist',
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('-- Tidak Ada --'),
                                  ),
                                  ..._mediaLibrary
                                      .where(
                                        (m) =>
                                            m['type'] == 'video' ||
                                            m['type'] == 'audio',
                                      )
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item['path']?.toString() ?? '',
                                          child: Text(
                                            item['name']?.toString() ?? '',
                                          ),
                                        ),
                                      )
                                      ,
                                ],
                                onChanged: (v) =>
                                    setState(() => schedule['path'] = v ?? ''),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Acak?'),
                                    value:
                                        schedule['is_random'] as bool? ?? false,
                                    onChanged: (val) => setState(
                                      () => schedule['is_random'] = val,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: (schedule['loop_count'] ?? 1)
                                        .toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Loop',
                                    ),
                                    onChanged: (v) => schedule['loop_count'] =
                                        int.tryParse(v) ?? 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}
