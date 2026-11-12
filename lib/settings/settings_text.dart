import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextSettingsView extends StatefulWidget {
  const TextSettingsView({super.key});

  @override
  State<TextSettingsView> createState() => _TextSettingsViewState();
}

class _TextSettingsViewState extends State<TextSettingsView> {
  String _selectedKey = 'mosque_name';
  double _fontSize = 20;
  Color _fontColor = Colors.white;
  String _fontFamily = 'Roboto';

  final Map<String, String> _elements = {
    'mosque_name': 'Nama Masjid',
    'mosque_address': 'Alamat',
    'clock': 'Jam Digital',
    'date': 'Tanggal',
    'running_text': 'Running Text',
    'slide_title': 'Judul Slide',
    'slide_content': 'Isi Slide',
    'prayer_name': 'Nama Sholat',
    'prayer_time': 'Jam Sholat',
    'hadith_text': 'Teks Hadis',
    'hadith_source': 'Sumber Hadis',
    'performer_event_name': 'Nama Acara (Petugas)',
    'performer_event_date': 'Tanggal Acara (Petugas)',
    'performer_name': 'Nama Petugas',
    'performer_role': 'Peran Petugas',
    'footer_prayer_name': 'Nama Sholat (Footer)',
    'footer_prayer_time': 'Jam Sholat (Footer)',
  };

  final List<String> _fonts = [
    'Roboto',
    'Cairo',
    'Amiri',
    'Oswald',
    'Lato',
    'Open Sans',
  ];

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.indigo,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.brown,
    Colors.grey,
    const Color.fromARGB(255, 130, 241, 2), // Default Mosque Name
    const Color.fromARGB(255, 7, 255, 48), // Default Clock
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  void _loadCurrentValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('${_selectedKey}_size') ?? 20.0;
      int colorVal =
          prefs.getInt('${_selectedKey}_color') ?? Colors.white.value;
      _fontColor = Color(colorVal);
      _fontFamily = prefs.getString('${_selectedKey}_font') ?? 'Roboto';
    });
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_selectedKey}_size', _fontSize);
    await prefs.setInt('${_selectedKey}_color', _fontColor.value);
    await prefs.setString('${_selectedKey}_font', _fontFamily);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pengaturan ${_elements[_selectedKey]} disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Pengaturan Teks & Font',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedKey,
            decoration: const InputDecoration(labelText: 'Pilih Elemen'),
            items: _elements.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value));
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedKey = v);
                _loadCurrentValues();
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Ukuran Font: '),
              Expanded(
                child: Slider(
                  min: 10,
                  max: 150,
                  divisions: 140,
                  label: _fontSize.round().toString(),
                  value: _fontSize,
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
              Text(_fontSize.round().toString()),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _fonts.contains(_fontFamily)
                ? _fontFamily
                : _fonts.first,
            decoration: const InputDecoration(labelText: 'Jenis Font'),
            items: _fonts.map((f) {
              return DropdownMenuItem(
                value: f,
                child: Text(f, style: TextStyle(fontFamily: f)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _fontFamily = v!),
          ),
          const SizedBox(height: 20),
          const Text('Warna Teks:'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colors.map((c) {
              return InkWell(
                onTap: () => setState(() => _fontColor = c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _fontColor == c ? Colors.white : Colors.grey,
                      width: _fontColor == c ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Simpan Perubahan'),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black,
              child: Text(
                'Contoh Tampilan Teks',
                style: TextStyle(
                  fontSize: _fontSize,
                  color: _fontColor,
                  fontFamily: _fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

