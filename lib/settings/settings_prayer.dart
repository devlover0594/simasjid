import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../api_repository.dart';
import 'settings_city.dart';

class PrayerSettingsView extends StatefulWidget {
  const PrayerSettingsView({super.key});

  @override
  State<PrayerSettingsView> createState() => _PrayerSettingsViewState();
}

class _PrayerSettingsViewState extends State<PrayerSettingsView> {
  // ============ FocusNodes for D-pad / remote navigation ============
  final FocusNode _switchApiFocus = FocusNode();
  final FocusNode _dropdownProviderFocus = FocusNode();
  final FocusNode _minusHijriFocus = FocusNode();
  final FocusNode _plusHijriFocus = FocusNode();
  final FocusNode _refreshApiFocus = FocusNode();
  final FocusNode _pickCityFocus = FocusNode();
  final FocusNode _deleteCityFocus = FocusNode();
  final FocusNode _saveButtonFocus = FocusNode();

  // Persistent controllers + focus nodes for prayer time TextFields
  final List<TextEditingController> _timeControllers = [];
  final List<FocusNode> _timeFocusNodes = List.generate(5, (_) => FocusNode());

  // Track overlay state for PopScope back-button handling
  bool _isKeyboardOpen = false;
  bool _isDialogOpen = false;
  int? _activeTextFieldIndex; // which TextField triggered the keyboard

  final List<Map<String, String>> _times = [
    {'name': 'Subuh', 'time': '--:--'},
    {'name': 'Dzuhur', 'time': '--:--'},
    {'name': 'Ashar', 'time': '--:--'},
    {'name': 'Maghrib', 'time': '--:--'},
    {'name': 'Isya', 'time': '--:--'},
  ];
  bool _useApi = true;
  String? _selectedCityName;
  String _apiProvider = 'MyQuran';
  String _apiStatus = 'Belum dicek';
  Color _statusColor = Colors.grey;
  int _hijriAdjustment = -2;
  String _lastUpdate = '-'; // Waktu pembaruan jadwal sholat terakhir

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller untuk setiap waktu sholat
    for (int i = 0; i < _times.length; i++) {
      _timeControllers.add(TextEditingController(text: _times[i]['time']));
    }
    _load();
  }

  @override
  void dispose() {
    _switchApiFocus.dispose();
    _dropdownProviderFocus.dispose();
    _minusHijriFocus.dispose();
    _plusHijriFocus.dispose();
    _refreshApiFocus.dispose();
    _pickCityFocus.dispose();
    _deleteCityFocus.dispose();
    _saveButtonFocus.dispose();
    for (final c in _timeControllers) {
      c.dispose();
    }
    for (final f in _timeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _useApi = prefs.getBool('use_api_prayer_times') ?? true;
    _apiProvider = prefs.getString('api_provider') ?? 'MyQuran';
    _selectedCityName = prefs.getString('kota_name');
    _hijriAdjustment = prefs.getInt('hijri_adjustment') ?? -2;
    final jsonStr = prefs.getString('custom_prayer_times');
    if (jsonStr != null) {
      try {
        final List decoded = jsonDecode(jsonStr);
        for (int i = 0; i < decoded.length && i < _times.length; i++) {
          _times[i]['time'] = decoded[i]['time'] ?? _times[i]['time'];
          if (i < _timeControllers.length) {
            _timeControllers[i].text = _times[i]['time']!;
          }
        }
      } catch (_) {}
    }
    // Tampilkan waktu pembaruan terakhir jika tersedia
    final lastUpdateStr = prefs.getString('last_prayer_update');
    if (lastUpdateStr != null) {
      try {
        _lastUpdate = DateTime.parse(lastUpdateStr).toLocal().toString();
      } catch (_) {
        _lastUpdate = '-';
      }
    }
    if (mounted) setState(() {});
    if (_useApi) _checkApi();
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _times.length && i < _timeControllers.length; i++) {
      _times[i]['time'] = _timeControllers[i].text;
    }
    await prefs.setString('custom_prayer_times', jsonEncode(_times));
    // When user saves manual times, prefer manual mode
    await prefs.setString('api_provider', _apiProvider);
    await prefs.setBool('use_api_prayer_times', false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Jadwal disimpan')));
  }

  Future<void> _checkApi() async {
    if (!_useApi) {
      setState(() {
        _apiStatus = 'Mode Manual Aktif';
        _statusColor = Colors.orange;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final kotaId = prefs.getString('kota_id');
    final kotaName = prefs.getString('kota_name');

    if (_apiProvider == 'MyQuran' && (kotaId == null || kotaId.isEmpty)) {
      setState(() {
        _apiStatus = 'Kota belum dipilih!';
        _statusColor = Colors.red;
      });
      return;
    }

    setState(() {
      _apiStatus = 'Sedang mengecek...';
      _statusColor = Colors.blue;
    });
    final repo = ApiRepository();
    final res = await repo.fetchPrayerTimes(
      kotaId: kotaId,
      kotaName: kotaName,
      provider: _apiProvider,
    );
    if (mounted) {
      setState(() {
        if (res != null && res.isNotEmpty) {
          _apiStatus = 'Berhasil terhubung';
          _statusColor = Colors.green;
          for (var t in _times) {
            final val = res[t['name']];
            if (val != null) {
              t['time'] = val;
            }
          }
          for (int i = 0; i < _timeControllers.length; i++) {
            _timeControllers[i].text = _times[i]['time'] ?? _timeControllers[i].text;
          }
        } else {
          _apiStatus = 'Gagal (Gunakan Data Offline)';
          _statusColor = Colors.orange;
        }
      });
      // Simpan hasil API ke cache terpisah (jangan menimpa jadwal manual user).
      if (res != null && res.isNotEmpty) {
        await prefs.setString('api_prayer_cache', jsonEncode(_times));
        await prefs.setString(
          'last_prayer_update',
          DateTime.now().toIso8601String(),
        );
      }
    }
  }

  // ============ Floating keyboard focus management ============
  void _openKeyboard(int textFieldIndex) {
    setState(() {
      _isKeyboardOpen = true;
      _activeTextFieldIndex = textFieldIndex;
    });
    // Pindah fokus ke tombol keyboard (simulasi tombol keyboard di sini;
    // ganti dengan FocusNode tombol keyboard asli Anda saat integrasi)
    _saveButtonFocus.requestFocus();
  }

  void _closeKeyboard() {
    setState(() {
      _isKeyboardOpen = false;
    });
    // Kembalikan fokus ke TextField asal
    if (_activeTextFieldIndex != null &&
        _activeTextFieldIndex! < _timeFocusNodes.length) {
      _timeFocusNodes[_activeTextFieldIndex!].requestFocus();
    }
    _activeTextFieldIndex = null;
  }

  // ============ PopScope back-button handler ============
  Future<bool> _onWillPop() async {
    // Jika keyboard atau dialog sedang terbuka, tutup dulu
    if (_isKeyboardOpen) {
      _closeKeyboard();
      return false;
    }
    if (_isDialogOpen) {
      setState(() => _isDialogOpen = false);
      return false;
    }
    // Semua overlay sudah tertutup, izinkan pop
    return true;
  }

  // Helper: visual indicator saat widget dapat fokus (remote friendly)
  Widget _focusedContainer({
    required bool hasFocus,
    required Widget child,
    Color focusColor = Colors.tealAccent,
    Color normalColor = Colors.transparent,
  }) {
    return Focus(
      canRequestFocus: true,
      child: Container(
        decoration: BoxDecoration(
          color: hasFocus ? focusColor.withValues(alpha: 0.15) : normalColor,
          border: Border.all(
            color: hasFocus ? focusColor : Colors.white24,
            width: hasFocus ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jadwal Sholat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              // Switch: Gunakan Jadwal API
              _focusedContainer(
                hasFocus: _switchApiFocus.hasFocus,
                child: SwitchListTile(
                  focusNode: _switchApiFocus,
                  title: const Text('Gunakan Jadwal API (MyQuran)'),
                  subtitle: const Text(
                    'Jika aktif, jadwal diambil dari API berdasarkan kota yang dipilih',
                  ),
                  value: _useApi,
                  onChanged: (v) async {
                    setState(() => _useApi = v);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('use_api_prayer_times', v);
                    _checkApi();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v ? 'Gunakan jadwal API' : 'Gunakan jadwal manual',
                        ),
                      ),
                    );
                  },
                ),
              ),
          if (_useApi) ...[
            const SizedBox(height: 8),
            // Dropdown: Server API
            _focusedContainer(
              hasFocus: _dropdownProviderFocus.hasFocus,
              child: Focus(
                focusNode: _dropdownProviderFocus,
                child: DropdownButton<String>(
                  value: _apiProvider,
                  dropdownColor: Colors.grey[850],
                  items: const [
                    DropdownMenuItem(value: 'MyQuran', child: Text('MyQuran')),
                    DropdownMenuItem(value: 'AlAdhan', child: Text('AlAdhan')),
                    DropdownMenuItem(value: 'EQuran', child: Text('EQuran.id')),
                  ],
                  onChanged: (v) async {
                    if (v != null) {
                      setState(() => _apiProvider = v);
                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setString('api_provider', v);
                      _checkApi();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Row: Adj. Hijriyah
            Row(
              children: [
                const Text('Adj. Hijriyah:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                _focusedContainer(
                  hasFocus: _minusHijriFocus.hasFocus,
                  child: IconButton(
                    focusNode: _minusHijriFocus,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      setState(() => _hijriAdjustment--);
                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setInt(
                          'hijri_adjustment', _hijriAdjustment);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_hijriAdjustment Hari',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _focusedContainer(
                  hasFocus: _plusHijriFocus.hasFocus,
                  child: IconButton(
                    focusNode: _plusHijriFocus,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () async {
                      setState(() => _hijriAdjustment++);
                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setInt(
                          'hijri_adjustment', _hijriAdjustment);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row: Status API
            Row(
              children: [
                const Text('Status API: '),
                Text(
                  _apiStatus,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Terakhir: $_lastUpdate',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(width: 8),
                _focusedContainer(
                  hasFocus: _refreshApiFocus.hasFocus,
                  child: IconButton(
                    focusNode: _refreshApiFocus,
                    onPressed: _checkApi,
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          // City picker (integrated)
          Card(
            color: Colors.white12,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCityName ??
                          'Belum dipilih (pilih kota untuk API)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  _focusedContainer(
                    hasFocus: _pickCityFocus.hasFocus,
                    child: TextButton(
                      focusNode: _pickCityFocus,
                      onPressed: () async {
                        setState(() => _isDialogOpen = true);
                        final res = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CitySettingScreen(),
                          ),
                        );
                        setState(() => _isDialogOpen = false);
                        if (res == true) {
                          // reload saved city and mark using API
                          final prefs =
                              await SharedPreferences.getInstance();
                          _selectedCityName =
                              prefs.getString('kota_name');
                          _useApi =
                              prefs.getBool('use_api_prayer_times') ??
                                  true;
                          if (!context.mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Kota disimpan dan jadwal API diaktifkan',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Pilih Kota'),
                    ),
                  ),
                  if (_selectedCityName != null) ...[
                    const SizedBox(width: 8),
                    _focusedContainer(
                      hasFocus: _deleteCityFocus.hasFocus,
                      child: TextButton(
                        focusNode: _deleteCityFocus,
                        onPressed: () async {
                          setState(() => _isDialogOpen = true);
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.remove('kota_id');
                          await prefs.remove('kota_name');
                          await prefs.setBool(
                              'use_api_prayer_times', false);
                          _selectedCityName = null;
                          _useApi = false;
                          setState(() => _isDialogOpen = false);
                          if (!context.mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Kota dihapus; jadwal manual diaktifkan',
                              ),
                            ),
                          );
                        },
                        child: const Text('Hapus'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_times.length, (index) {
            final t = _times[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t['name']!,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      focusNode: _timeFocusNodes[index],
                      controller: _timeControllers[index],
                      onChanged: (v) => t['time'] = v,
                      onTap: () => _openKeyboard(index),
                      onEditingComplete: _closeKeyboard,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          _focusedContainer(
            hasFocus: _saveButtonFocus.hasFocus,
            child: ElevatedButton(
              focusNode: _saveButtonFocus,
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ),
        ],
      ),
      ),
    ),
  );
  }
}

