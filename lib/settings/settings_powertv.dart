import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ---------------- Power TV Setting ----------------

class PowerTvSettingsView extends StatefulWidget {
  const PowerTvSettingsView({super.key});

  @override
  State<PowerTvSettingsView> createState() => _PowerTvSettingsViewState();
}

class _PowerTvSettingsViewState extends State<PowerTvSettingsView> {
  bool _enabled = false;
  List<Map<String, String>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('power_schedules');
    setState(() {
      _enabled = prefs.getBool('power_tv_enabled') ?? false;
      if (jsonStr != null) {
        try {
          final List decoded = jsonDecode(jsonStr);
          _schedules = decoded
              .map(
                (e) => {
                  'on': (e['on'] ?? '04:00').toString(),
                  'off': (e['off'] ?? '21:00').toString(),
                  'days': (e['days'] ?? '1,2,3,4,5,6,7').toString(),
                },
              )
              .toList();
        } catch (_) {
          _schedules = [];
        }
      }
    });
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('power_tv_enabled', _enabled);
    await prefs.setString('power_schedules', jsonEncode(_schedules));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan Power TV Disimpan')),
    );
  }

  Future<void> _addOrEditSchedule({int? index}) async {
    String onTime = index != null ? _schedules[index]['on']! : "04:00";
    String offTime = index != null ? _schedules[index]['off']! : "21:00";
    String days = index != null ? _schedules[index]['days']! : "1,2,3,4,5,6,7";

    final daysList = ['1', '2', '3', '4', '5', '6', '7'];
    final daysNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String tempOn = onTime;
        String tempOff = offTime;
        List<String> tempDays = days
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(index == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Jam Bangun (ON)'),
                      subtitle: Text(
                        tempOn,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.orange,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: int.parse(tempOn.split(':')[0]),
                            minute: int.parse(tempOn.split(':')[1]),
                          ),
                        );
                        if (time != null) {
                          setDialogState(() {
                            tempOn =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Jam Tidur (OFF)'),
                      subtitle: Text(
                        tempOff,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: int.parse(tempOff.split(':')[0]),
                            minute: int.parse(tempOff.split(':')[1]),
                          ),
                        );
                        if (time != null) {
                          setDialogState(() {
                            tempOff =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hari Aktif:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (i) {
                        final d = daysList[i];
                        final isSelected = tempDays.contains(d);
                        return FilterChip(
                          label: Text(daysNames[i]),
                          selected: isSelected,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                tempDays.add(d);
                              } else {
                                tempDays.remove(d);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: tempDays.isEmpty
                      ? null
                      : () => Navigator.pop(context, {
                          'on': tempOn,
                          'off': tempOff,
                          'days': tempDays.join(','),
                        }),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (res != null) {
      setState(() {
        if (index != null) {
          _schedules[index] = res;
        } else {
          _schedules.add(res);
        }
      });
      _save();
    }
  }

  String _getDaysLabel(String days) {
    if (days == "1,2,3,4,5,6,7") return "Setiap Hari";
    final list = days.split(',');
    if (list.length == 5 && !list.contains('6') && !list.contains('7')) {
      return "Senin - Jumat";
    }

    final daysNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return list.map((e) => daysNames[int.parse(e) - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Power TV Terjadwal (Sleep Mode)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _addOrEditSchedule(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Aktifkan Penjadwalan'),
            subtitle: const Text(
              'TV akan masuk/bangun dari sleep mode sesuai jadwal',
            ),
            value: _enabled,
            onChanged: (val) {
              setState(() => _enabled = val);
              _save();
            },
          ),
          const Divider(),
          Expanded(
            child: _schedules.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada jadwal. Klik Tambah untuk memulai.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final s = _schedules[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(
                            Icons.timer,
                            color: Colors.tealAccent,
                          ),
                          title: Text('ON: ${s['on']}  |  OFF: ${s['off']}'),
                          subtitle: Text(
                            'Hari: ${_getDaysLabel(s['days'] ?? '')}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _addOrEditSchedule(index: index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() => _schedules.removeAt(index));
                                  _save();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          const Card(
            color: Colors.black26,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.tealAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anda bisa menambahkan beberapa rentang waktu. Di luar rentang waktu tersebut, TV akan diizinkan masuk ke mode Sleep.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

