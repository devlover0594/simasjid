import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_repository.dart';

// ---------------- City Setting ----------------

class CitySettingScreen extends StatefulWidget {
  const CitySettingScreen({super.key});

  @override
  State<CitySettingScreen> createState() => _CitySettingScreenState();
}

class _CitySettingScreenState extends State<CitySettingScreen> {
  // ============ FocusNodes for D-pad / remote navigation ============
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _provinceDropdownFocus = FocusNode();
  final FocusNode _refreshButtonFocus = FocusNode();
  final FocusNode _deleteButtonFocus = FocusNode();

  // Track dialog state for PopScope back-button handling
  bool _isDialogOpen = false;

  final ApiRepository _api = ApiRepository();
  List<Map<String, String>> _cities = [];
  List<Map<String, String>> _filtered = [];
  bool _loading = false;
  String? _selectedId;
  String? _selectedName;
  String _apiProvider = 'MyQuran';

  // For EQuran
  List<String> _provinces = [];
  String? _selectedProvince;
  bool _loadingProvinces = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _provinceDropdownFocus.dispose();
    _refreshButtonFocus.dispose();
    _deleteButtonFocus.dispose();
    super.dispose();
  }

  void _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedId = prefs.getString('kota_id');
    _selectedName = prefs.getString('kota_name');
    _apiProvider = prefs.getString('api_provider') ?? 'MyQuran';
    if (mounted) setState(() {});

    if (_apiProvider == 'EQuran') {
      _fetchProvinces();
    } else {
      _fetchCities();
    }
  }

  Future<void> _fetchProvinces() async {
    setState(() => _loadingProvinces = true);
    final res = await _api.fetchProvincesShalatEQuran();
    setState(() {
      _provinces = res ?? [];
      _loadingProvinces = false;
    });
    // Jika sedang editing dan sudah ada id (provinsi), maka load kota
    if (_selectedId != null && _provinces.contains(_selectedId)) {
      _selectedProvince = _selectedId;
      _fetchCities();
    }
  }

  Future<void> _fetchCities() async {
    _loading = true;
    if (mounted) setState(() {});

    if (_apiProvider == 'EQuran') {
      if (_selectedProvince == null) {
        _loading = false;
        if (mounted) setState(() {});
        return;
      }
      final res = await _api.fetchCitiesShalatEQuran(_selectedProvince!);
      _loading = false;
      if (res != null) {
        _cities = res
            .map((c) => {'id': _selectedProvince!, 'lokasi': c})
            .toList();
        _applyFilter();
      }
    } else {
      final res = await _api.fetchCities();
      _loading = false;
      if (res != null) {
        _cities = res;
        _applyFilter();
      }
    }
    if (mounted) setState(() {});
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_cities);
    } else {
      _filtered = _cities
          .where((c) => c['lokasi']!.toLowerCase().contains(q))
          .toList();
    }
    if (mounted) setState(() {});
  }

  void _selectCity(Map<String, String> city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kota_id', city['id']!);
    await prefs.setString('kota_name', city['lokasi']!);
    // When user selects a city, prefer API schedules
    await prefs.setBool('use_api_prayer_times', true);
    // Ambil jadwal sholat untuk kota baru secara otomatis agar data segar
    await _refreshPrayerTimes();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kota disimpan dan jadwal diperbarui')));
    Navigator.pop(context, true);
  }

  /// Mengambil jadwal sholat terbaru dari API untuk kota yang tersimpan dan
  /// menyimpankannya ke cache (custom_prayer_times) serta mencatat waktu
  /// pembaruan agar layar utama dan settings dapat menampilkan data yang segar.
  Future<void> _refreshPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final kotaId = prefs.getString('kota_id');
    final kotaName = prefs.getString('kota_name');
    final provider = prefs.getString('api_provider') ?? 'MyQuran';
    if (kotaId == null || kotaId.isEmpty) return;
    try {
      final res = await _api.fetchPrayerTimes(
        kotaId: kotaId,
        kotaName: kotaName,
        provider: provider,
      );
      if (res != null && res.isNotEmpty) {
        final times = <String, String>{};
        for (var p in ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya']) {
          times[p] = res[p] ?? res[p.toLowerCase()] ?? '--:--';
        }
        await prefs.setString(
          'custom_prayer_times',
          jsonEncode(
            times.entries.map((e) => {'name': e.key, 'time': e.value}).toList(),
          ),
        );
        await prefs.setString(
          'last_prayer_update',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (_) {
      // Gagal diam-dummy; jadwal akan dicoba lagi saat aplikasi dibuka
    }
  }

  // ============ PopScope back-button handler ============
  Future<bool> _onWillPop() async {
    if (_isDialogOpen) {
      setState(() => _isDialogOpen = false);
      return false;
    }
    return true;
  }

  // Helper: visual indicator saat widget dapat fokus (remote friendly)
  Widget _focusedContainer({
    required bool hasFocus,
    required Widget child,
    Color focusColor = Colors.tealAccent,
  }) {
    return Focus(
      canRequestFocus: true,
      child: Container(
        decoration: BoxDecoration(
          color: hasFocus ? focusColor.withValues(alpha: 0.15) : Colors.transparent,
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
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pilih Kota'),
          backgroundColor: Colors.black87,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              children: [
                if (_selectedName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70),
                      const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Terkini: ${_selectedName ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  _focusedContainer(
                    hasFocus: _deleteButtonFocus.hasFocus,
                    child: TextButton(
                      focusNode: _deleteButtonFocus,
                      onPressed: () async {
                        setState(() => _isDialogOpen = true);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('kota_id');
                        await prefs.remove('kota_name');
                        setState(() => _isDialogOpen = false);
                        if (mounted) {
                          setState(() {
                            _selectedId = null;
                            _selectedName = null;
                          });
                        }
                      },
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
            if (_apiProvider == 'EQuran') ...[
              _focusedContainer(
                hasFocus: _provinceDropdownFocus.hasFocus,
                child: Focus(
                  focusNode: _provinceDropdownFocus,
                  child: DropdownButtonFormField<String>(
                    initialValue: _provinces.contains(_selectedProvince)
                        ? _selectedProvince
                        : null,
                    decoration: const InputDecoration(labelText: 'Pilih Provinsi'),
                    items: _provinces
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: _loadingProvinces
                        ? null
                        : (v) {
                            setState(() {
                              _selectedProvince = v;
                              _cities = [];
                              _filtered = [];
                            });
                            _fetchCities();
                          },
                    hint: _loadingProvinces
                        ? const Text('Memuat Provinsi...')
                        : const Text('Pilih Provinsi'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              focusNode: _searchFocus,
              controller: _searchCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: _apiProvider == 'EQuran'
                    ? 'Cari kota di provinsi ini...'
                    : 'Cari kota...',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_filtered.isEmpty &&
                        _searchCtrl.text.isEmpty &&
                        _apiProvider == 'EQuran' &&
                        _selectedProvince == null)
                  ? const Center(
                      child: Text('Silakan pilih provinsi terlebih dahulu.'),
                    )
                  : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Tidak ada hasil'),
                          const SizedBox(height: 8),
                          _focusedContainer(
                            hasFocus: _refreshButtonFocus.hasFocus,
                            child: ElevatedButton(
                              focusNode: _refreshButtonFocus,
                              onPressed: _fetchCities,
                              child: const Text('Muat ulang'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchCities,
                      child: ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final c = _filtered[index];
                          return ListTile(
                            title: Text(c['lokasi'] ?? ''),
                            subtitle: _apiProvider == 'EQuran'
                                ? null
                                : Text(c['id'] ?? ''),
                            trailing:
                                (_selectedId == c['id'] &&
                                    _selectedName == c['lokasi'])
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () => _selectCity(c),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  ),
  );
  }
}
