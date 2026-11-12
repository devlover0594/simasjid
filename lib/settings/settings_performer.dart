import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

// ---------------- Performer Settings ----------------

class PerformerSettingsView extends StatefulWidget {
  const PerformerSettingsView({super.key});

  @override
  State<PerformerSettingsView> createState() => _PerformerSettingsViewState();
}

class _PerformerSettingsViewState extends State<PerformerSettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Pengaturan Petugas Acara',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Profil Petugas'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Jadwal Petugas'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_PerformerProfilesTab(), _PerformerSchedulesTab()],
          ),
        ),
      ],
    );
  }
}

class _PerformerProfilesTab extends StatefulWidget {
  const _PerformerProfilesTab();

  @override
  State<_PerformerProfilesTab> createState() => _PerformerProfilesTabState();
}

class _PerformerProfilesTabState extends State<_PerformerProfilesTab> {
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('performer_profiles');
    if (jsonStr != null) {
      try {
        _profiles = List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
        setState(() {});
      } catch (_) {}
    }
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('performer_profiles', jsonEncode(_profiles));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil Disimpan')));
  }

  Future<void> _addOrEditProfile({int? index}) async {
    final isEditing = index != null;
    final profile = isEditing ? _profiles[index] : null;

    final nameCtrl = TextEditingController(text: profile?['name'] ?? '');
    final roleCtrl = TextEditingController(text: profile?['role'] ?? '');
    String? photoPath = profile?['photoPath'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Profil' : 'Tambah Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Peran',
                  hintText: 'Khotib, Imam, Penceramah, dll.',
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      photoPath?.split(Platform.pathSeparator).last ??
                          'Belum ada foto',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Upload & Pilih Foto',
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.image,
                      );
                      if (result != null && result.files.single.path != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final fileName = result.files.single.name;
                        final newPath =
                            '${appDir.path}${Platform.pathSeparator}$fileName';
                        await File(result.files.single.path!).copy(newPath);

                        // This is a workaround because we can't call setState of the parent here.
                        // The path is updated, and when saved, it will be correct.
                        photoPath = newPath;

                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Foto dipilih: $fileName')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newProfile = {
                'id':
                    profile?['id'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                'name': nameCtrl.text,
                'role': roleCtrl.text,
                'photoPath': photoPath,
              };
              setState(() {
                if (isEditing) {
                  _profiles[index] = newProfile;
                } else {
                  _profiles.add(newProfile);
                }
              });
              _save();
              Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == true) {
      _load(); // Reload to reflect changes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addOrEditProfile,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _profiles.isEmpty
            ? const Center(child: Text('Belum ada profil petugas.'))
            : ListView.builder(
                itemCount: _profiles.length,
                itemBuilder: (context, index) {
                  final p = _profiles[index];
                  final photoFile = p['photoPath'] != null
                      ? File(p['photoPath'])
                      : null;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            (photoFile != null && photoFile.existsSync())
                            ? FileImage(photoFile)
                            : null,
                        child: (photoFile == null || !photoFile.existsSync())
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(p['name'] ?? 'Tanpa Nama'),
                      subtitle: Text(p['role'] ?? 'Tanpa Peran'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _addOrEditProfile(index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => _profiles.removeAt(index));
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
    );
  }
}

class _PerformerSchedulesTab extends StatefulWidget {
  const _PerformerSchedulesTab();
  @override
  State<_PerformerSchedulesTab> createState() => _PerformerSchedulesTabState();
}

class _PerformerSchedulesTabState extends State<_PerformerSchedulesTab> {
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _allProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // Load schedules
    final schedulesJson = prefs.getString('performer_schedules');
    if (schedulesJson != null) {
      try {
        _schedules = List<Map<String, dynamic>>.from(jsonDecode(schedulesJson));
      } catch (_) {}
    }
    // Load profiles
    final profilesJson = prefs.getString('performer_profiles');
    if (profilesJson != null) {
      try {
        _allProfiles = List<Map<String, dynamic>>.from(
          jsonDecode(profilesJson),
        );
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('performer_schedules', jsonEncode(_schedules));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Jadwal Disimpan')));
  }

  Future<void> _addOrEditSchedule({int? index}) async {
    final isEditing = index != null;
    final schedule = isEditing ? _schedules[index] : null;

    final nameCtrl = TextEditingController(text: schedule?['name'] ?? '');
    DateTime selectedDate = schedule?['date'] != null
        ? (DateTime.tryParse(schedule!['date']) ?? DateTime.now())
        : DateTime.now();
    DateTime selectedEndDate = schedule?['endDate'] != null
        ? (DateTime.tryParse(schedule!['endDate']) ?? selectedDate)
        : selectedDate;

    List<String> selectedPerformerIds = schedule?['performerIds'] != null
        ? List<String>.from(schedule!['performerIds'])
        : [];

    final bool? success = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Jadwal' : 'Tambah Jadwal'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Acara',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        "Mulai: ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          locale: const Locale('id', 'ID'),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                            // Pastikan tanggal selesai tidak sebelum tanggal mulai
                            if (selectedEndDate.isBefore(selectedDate)) {
                              selectedEndDate = selectedDate;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        "Selesai: ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedEndDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate,
                          firstDate:
                              selectedDate, // Min date adalah tanggal mulai
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 2),
                          ),
                          locale: const Locale('id', 'ID'),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedEndDate = picked);
                        }
                      },
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Pilih Petugas:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: _allProfiles.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada profil petugas. Silakan tambah di tab "Profil Petugas".',
                              ),
                            )
                          : ListView.builder(
                              itemCount: _allProfiles.length,
                              itemBuilder: (context, i) {
                                final profile = _allProfiles[i];
                                final photoFile = profile['photoPath'] != null
                                    ? File(profile['photoPath'])
                                    : null;
                                final isSelected = selectedPerformerIds
                                    .contains(profile['id']);
                                return CheckboxListTile(
                                  secondary: CircleAvatar(
                                    backgroundImage:
                                        (photoFile != null &&
                                            photoFile.existsSync())
                                        ? FileImage(photoFile)
                                        : null,
                                    child:
                                        (photoFile == null ||
                                            !photoFile.existsSync())
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(profile['name'] ?? 'Tanpa Nama'),
                                  subtitle: Text(
                                    profile['role'] ?? 'Tanpa Peran',
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedPerformerIds.add(profile['id']);
                                      } else {
                                        selectedPerformerIds.remove(
                                          profile['id'],
                                        );
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newSchedule = {
                      'name': nameCtrl.text,
                      'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                      'endDate': DateFormat(
                        'yyyy-MM-dd',
                      ).format(selectedEndDate),
                      'performerIds': selectedPerformerIds,
                    };
                    setState(() {
                      if (isEditing) {
                        _schedules[index] = newSchedule;
                      } else {
                        _schedules.add(newSchedule);
                      }
                    });
                    _save();
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true) {
      _loadData(); // Reload to reflect changes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addOrEditSchedule,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _schedules.isEmpty
            ? const Center(child: Text('Belum ada jadwal petugas.'))
            : ListView.builder(
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final s = _schedules[index];
                  List<String> performerIds = List<String>.from(
                    s['performerIds'] ?? [],
                  );
                  String performerNames = _allProfiles
                      .where((p) => performerIds.contains(p['id']))
                      .map((p) => p['name'] as String? ?? '')
                      .join(', ');
                  if (performerNames.isEmpty) {
                    performerNames = 'Belum ada petugas ditugaskan';
                  }

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_note, size: 40),
                      title: Text(s['name'] ?? 'Tanpa Nama'),
                      subtitle: Text(
                        '${s['date'] ?? 'Tanpa Tanggal'} s/d ${s['endDate'] ?? s['date']}\nPetugas: $performerNames',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _schedules.removeAt(index));
                          _save();
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

