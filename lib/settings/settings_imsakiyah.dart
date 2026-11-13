import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_repository.dart';

class ImsakiyahSettingsView extends StatefulWidget {
  const ImsakiyahSettingsView({super.key});

  @override
  State<ImsakiyahSettingsView> createState() => _ImsakiyahSettingsViewState();
}

class _ImsakiyahSettingsViewState extends State<ImsakiyahSettingsView> {
  bool _showImsakiyahScreen = false;
  String? _selectedProvince;
  String? _selectedCity;
  List<String> _provinces = [];
  List<String> _cities = [];
  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;

  final ApiRepository _apiRepository = ApiRepository();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showImsakiyahScreen = prefs.getBool('show_imsakiyah_screen') ?? false;
    _selectedProvince = prefs.getString('imsakiyah_province');
    _selectedCity = prefs.getString('imsakiyah_city');

    await _fetchProvinces();
    if (_selectedProvince != null) {
      // Saat memuat awal, JANGAN hapus kota terpilih yang tersimpan dari prefs.
      await _fetchCities(_selectedProvince!, clearSelection: false);
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_imsakiyah_screen', _showImsakiyahScreen);
    await prefs.setString('imsakiyah_province', _selectedProvince ?? '');
    await prefs.setString('imsakiyah_city', _selectedCity ?? '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan Imsakiyah Disimpan')),
    );
  }

  Future<void> _fetchProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
    });
    final fetchedProvinces = await _apiRepository.fetchProvincesShalatEQuran();
    if (mounted) {
      setState(() {
        _provinces = fetchedProvinces ?? [];
        _isLoadingProvinces = false;
      });
    }
  }

  Future<void> _fetchCities(
    String province, {
    bool clearSelection = true,
  }) async {
    setState(() {
      _isLoadingCities = true;
      _cities = []; // Clear previous cities
      // Hanya reset kota saat provinsi benar-benar berganti (bukan saat load
      // awal), agar kota tersimpan tidak hilang & tidak tertulis ''.
      if (clearSelection) {
        _selectedCity = null;
      }
    });
    final fetchedCities = await _apiRepository.fetchCitiesShalatEQuran(
      province,
    );
    if (mounted) {
      setState(() {
        _cities = fetchedCities ?? [];
        _isLoadingCities = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Pengaturan Jadwal Imsakiyah',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Tampilkan Layar Imsakiyah'),
            subtitle: const Text(
              'Jika aktif, layar jadwal imsakiyah akan muncul dalam rotasi layar.',
            ),
            value: _showImsakiyahScreen,
            onChanged: (v) {
              setState(() => _showImsakiyahScreen = v);
              _saveSettings();
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Pilih Lokasi Imsakiyah (EQuran.id API):',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _provinces.contains(_selectedProvince)
                ? _selectedProvince
                : null,
            decoration: const InputDecoration(labelText: 'Provinsi'),
            items: _provinces.map((p) {
              return DropdownMenuItem(value: p, child: Text(p));
            }).toList(),
            onChanged: _isLoadingProvinces
                ? null
                : (v) async {
                    if (v != null) {
                      setState(() {
                        _selectedProvince = v;
                        _selectedCity =
                            null; // Reset city when province changes
                      });
                      await _fetchCities(v);
                      _saveSettings();
                    }
                  },
            hint: _isLoadingProvinces
                ? const Text('Memuat Provinsi...')
                : const Text('Pilih Provinsi'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _cities.contains(_selectedCity) ? _selectedCity : null,
            decoration: const InputDecoration(labelText: 'Kabupaten/Kota'),
            items: _cities.map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: _isLoadingCities || _selectedProvince == null
                ? null
                : (v) {
                    setState(() => _selectedCity = v);
                    _saveSettings();
                  },
            hint: _isLoadingCities
                ? const Text('Memuat Kota...')
                : const Text('Pilih Kabupaten/Kota'),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Simpan Pengaturan Imsakiyah'),
          ),
        ],
      ),
    );
  }
}

