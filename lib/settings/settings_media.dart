import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../api_repository.dart';
import 'package:http/http.dart' as http;

class MediaSettingsView extends StatefulWidget {
  const MediaSettingsView({super.key});

  @override
  State<MediaSettingsView> createState() => _MediaSettingsViewState();
}

class _MediaSettingsViewState extends State<MediaSettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _mediaSlidesEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mediaSlidesEnabled = prefs.getBool('media_slideshow_enabled') ?? false;
    });
  }

  Future<void> _saveMediaSlideshowEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('media_slideshow_enabled', enabled);
    setState(() {
      _mediaSlidesEnabled = enabled;
    });
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
            'Pengaturan Media & Playlist',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SwitchListTile(
          title: const Text('Aktifkan Media Slideshow'),
          subtitle: const Text(
            'Putar item playlist media sebagai bagian dari rotasi layar utama.',
          ),
          value: _mediaSlidesEnabled,
          onChanged: _saveMediaSlideshowEnabled,
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.video_library), text: 'Playlist Media'),
            Tab(icon: Icon(Icons.schedule), text: 'Jadwal Tayang'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_MediaLibraryTab(), _MediaScheduleTab()],
          ),
        ),
      ],
    );
  }
}

class _MediaLibraryTab extends StatefulWidget {
  const _MediaLibraryTab();

  @override
  State<_MediaLibraryTab> createState() => _MediaLibraryTabState();
}

class _MediaLibraryTabState extends State<_MediaLibraryTab> {
  List<Map<String, dynamic>> _library = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('media_library');
    if (jsonStr != null) {
      try {
        _library = List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
        setState(() {});
      } catch (_) {}
    }
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('media_library', jsonEncode(_library));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Playlist Disimpan')));
  }

  Future<void> _importFromFolder() async {
    try {
      // Use the static methods for compatibility with different file_picker versions
      String? selectedDirectory = await FilePicker.getDirectoryPath();

      if (selectedDirectory != null) {
        final dir = Directory(selectedDirectory);
        final List<FileSystemEntity> entities = await dir.list().toList();
        final List<Map<String, dynamic>> newItems = [];
        final supportedExtensions = [
          '.jpg',
          '.jpeg',
          '.png',
          '.mp4',
          '.mkv',
          '.avi',
          '.mp3',
        ];

        for (var entity in entities) {
          if (entity is File) {
            final path = entity.path;
            final extension = path
                .substring(path.lastIndexOf('.'))
                .toLowerCase();
            if (supportedExtensions.contains(extension)) {
              String type;
              if (['.jpg', '.jpeg', '.png'].contains(extension)) {
                type = 'image';
              } else if (['.mp4', '.mkv', '.avi'].contains(extension)) {
                type = 'video';
              } else {
                type = 'audio';
              }

              // Hindari duplikat berdasarkan path
              if (!_library.any((item) => item['path'] == path)) {
                newItems.add({
                  'id':
                      '${DateTime.now().millisecondsSinceEpoch}${path.hashCode}',
                  'name': path.split(Platform.pathSeparator).last,
                  'path': path,
                  'type': type,
                });
              }
            }
          }
        }

        if (newItems.isNotEmpty) {
          setState(() => _library.addAll(newItems));
          _save();
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${newItems.length} media berhasil diimpor.'),
              ),
            );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada media baru yang ditemukan.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error importing from folder: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengimpor: $e')));
    }
  }

  Future<void> _pickFile(
    TextEditingController controller,
    bool upload,
    BuildContext dialogContext,
  ) async {
    // try {
    //   FilePickerResult? result = await FilePicker.pickFiles(
    //     type: FileType.custom,
    //     allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mkv', 'avi'],
    //   );

    //   if (result != null && result.files.single.path != null) {
    //     String path = result.files.single.path!;

    //     if (upload) {
    //       final directory = await getApplicationDocumentsDirectory();
    //       final fileName = path.split(Platform.pathSeparator).last;
    //       final newPath = '${directory.path}${Platform.pathSeparator}$fileName';
    //       await File(path).copy(newPath);
    //       path = newPath;
    //       if (mounted) {
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           const SnackBar(
    //             content: Text('File berhasil diupload ke penyimpanan internal'),
    //           ),
    //         );
    //       }
    //     }
    //     controller.text = path;
    //   }
    // } catch (e) {
    //   debugPrint('Error picking file: $e');
    // }
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mkv', 'avi', 'mp3'],
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;

        if (upload) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = path.split(Platform.pathSeparator).last;
          final newPath = '${directory.path}${Platform.pathSeparator}$fileName';
          await File(path).copy(newPath);
          path = newPath;
          if (mounted) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text('File berhasil diupload ke penyimpanan internal'),
              ),
            );
          }
        }
        controller.text = path;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka file: $e')));
      }
    }
  }

  void _addOrEditItem({Map<String, dynamic>? item, int? index}) async {
    final isEditing = item != null && index != null; // Fix: More robust check
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final pathCtrl = TextEditingController(text: item?['path'] ?? '');
    String type = item?['type'] ?? 'image';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Edit Media Playlist' : 'Tambah Media ke Playlist',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama Media',
                      hintText: 'Contoh: Kajian Subuh',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const [
                      DropdownMenuItem(value: 'image', child: Text('Gambar')),
                      DropdownMenuItem(value: 'video', child: Text('Video')),
                      DropdownMenuItem(
                        value: 'audio',
                        child: Text('Audio (MP3)'),
                      ),
                      DropdownMenuItem(
                        value: 'youtube',
                        child: Text('YouTube'),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => type = v!),
                    decoration: const InputDecoration(labelText: 'Tipe Media'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pathCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: type == 'youtube'
                                ? 'Link YouTube'
                                : 'Path File (Absolute)',
                            hintText: type == 'youtube'
                                ? 'https://www.youtube.com/watch?v=...'
                                : '/storage/emulated/0/Download/video.mp4',
                          ),
                        ),
                      ),
                      if (type != 'youtube') ...[
                        IconButton(
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Browse File',
                          onPressed: () => _pickFile(pathCtrl, false, context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.upload_file),
                          tooltip: 'Upload ke Internal',
                          onPressed: () => _pickFile(pathCtrl, true, context),
                        ),
                      ],
                    ],
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
                onPressed: () {
                  final newItem = {
                    'id':
                        item?['id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameCtrl.text.isEmpty
                        ? 'Media Baru'
                        : nameCtrl.text,
                    'path': pathCtrl.text,
                    'type': type,
                  };
                  setState(() {
                    if (isEditing) {
                      _library[index] = newItem;
                    } else {
                      _library.add(newItem);
                    }
                  });
                  _save();
                  Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _importFromFolder,
            label: const Text('Impor Folder'),
            icon: const Icon(Icons.create_new_folder_outlined),
            heroTag: 'import-folder',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _addOrEditItem(),
            heroTag: 'add-item',
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _library.isEmpty
            ? const Center(child: Text('Playlist kosong. Tambahkan media.'))
            : ListView.builder(
                itemCount: _library.length,
                itemBuilder: (context, index) {
                  final item = _library[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        item['type'] == 'video'
                            ? Icons.videocam
                            : item['type'] == 'audio'
                            ? Icons.audiotrack
                            : Icons.image,
                      ),
                      title: Text(item['name'] ?? 'Tanpa Nama'),
                      subtitle: Text(item['path'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _addOrEditItem(item: item, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _confirmDeleteItem(context, index);
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

  void _confirmDeleteItem(BuildContext context, int index) async {
    final itemToDelete = _library[index];
    final path = itemToDelete['path'] as String?;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Media?'),
        content: Text(
          'Anda akan menghapus "${itemToDelete['name']}" dari playlist. Apakah Anda juga ingin menghapus file fisiknya dari penyimpanan jika memungkinkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Hapus file fisik jika berada di direktori aplikasi
    if (path != null && path.isNotEmpty) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        if (path.startsWith(appDir.path)) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File fisik berhasil dihapus.')),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus file: $e')),
          );
        }
      }
    }

    // Hapus dari library dan simpan
    setState(() => _library.removeAt(index));
    _save();
  }
}

class _MediaScheduleTab extends StatefulWidget {
  const _MediaScheduleTab();

  @override
  State<_MediaScheduleTab> createState() => _MediaScheduleTabState();
}

class _MediaScheduleTabState extends State<_MediaScheduleTab> {
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _library = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final schedJson = prefs.getString('media_schedules');
    if (schedJson != null) {
      try {
        _schedules = List<Map<String, dynamic>>.from(jsonDecode(schedJson));
      } catch (_) {}
    }
    final libJson = prefs.getString('media_library');
    if (libJson != null) {
      try {
        _library = List<Map<String, dynamic>>.from(jsonDecode(libJson));
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('media_schedules', jsonEncode(_schedules));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Jadwal Media Disimpan')));
  }

  void _addOrEditSchedule({Map<String, dynamic>? item, int? index}) async {
    final isEditing = item != null;
    final pathCtrl = TextEditingController(text: item?['path'] ?? '');
    final playCountCtrl = TextEditingController(
      text: (item?['play_count'] ?? 1).toString(),
    );
    bool isLoop = item?['is_loop'] ?? false;
    String type = item?['type'] ?? 'image';
    TimeOfDay time = item != null
        ? TimeOfDay(
            hour: int.parse(item['time'].split(':')[0]),
            minute: int.parse(item['time'].split(':')[1]),
          )
        : const TimeOfDay(hour: 12, minute: 0);
    List<int> days = item != null
        ? List<int>.from(item['days'])
        : [1, 2, 3, 4, 5, 6, 7];

    // Helper to find library item by path
    String? selectedLibraryId;
    // Try to match existing path to library
    try {
      final match = _library.firstWhere(
        (element) => element['path'] == pathCtrl.text,
      );
      selectedLibraryId = match['id'];
    } catch (_) {}

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Jadwal' : 'Tambah Jadwal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_library.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selectedLibraryId,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilih dari Playlist',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('-- Manual / Custom --'),
                        ),
                        ..._library.map(
                          (l) => DropdownMenuItem(
                            value: l['id'] as String,
                            child: Text(l['name'] ?? 'Tanpa Nama'),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          selectedLibraryId = v;
                          if (v != null) {
                            final libItem = _library.firstWhere(
                              (e) => e['id'] == v,
                            );
                            pathCtrl.text = libItem['path'];
                            type = libItem['type'];
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pathCtrl,
                    autofocus: _library.isEmpty,
                    textInputAction: TextInputAction.next,
                    readOnly:
                        selectedLibraryId !=
                        null, // Read only if selected from library
                    decoration: const InputDecoration(
                      labelText: 'Path / URL Media',
                      helperText: 'Otomatis terisi jika memilih dari playlist',
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Type is auto-set or manual
                  if (selectedLibraryId == null)
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      items: const [
                        DropdownMenuItem(value: 'image', child: Text('Gambar')),
                        DropdownMenuItem(value: 'video', child: Text('Video')),
                        DropdownMenuItem(
                          value: 'youtube',
                          child: Text('YouTube'),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => type = v!),
                      decoration: const InputDecoration(
                        labelText: 'Tipe Media',
                      ),
                    ),

                  const SizedBox(height: 10),
                  ListTile(
                    title: Text('Jam Mulai: ${time.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: time,
                        initialEntryMode: TimePickerEntryMode.input,
                      );
                      if (t != null) setDialogState(() => time = t);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Looping?'),
                    value: isLoop,
                    onChanged: (v) => setDialogState(() => isLoop = v),
                  ),
                  if (isLoop)
                    TextField(
                      controller: playCountCtrl,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Putar',
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text('Hari Aktif:'),
                  Wrap(
                    spacing: 5,
                    children: List.generate(7, (i) {
                      final dayIdx = i + 1;
                      final dayName = [
                        'Sen',
                        'Sel',
                        'Rab',
                        'Kam',
                        'Jum',
                        'Sab',
                        'Ahd',
                      ][i];
                      return FilterChip(
                        label: Text(dayName),
                        selected: days.contains(dayIdx),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              days.add(dayIdx);
                            } else {
                              days.remove(dayIdx);
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
                onPressed: () {
                  final newItem = {
                    'path': pathCtrl.text,
                    'type': type,
                    'time':
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    'is_loop': isLoop,
                    'play_count': isLoop
                        ? (int.tryParse(playCountCtrl.text) ?? 1)
                        : 1,
                    'days': days,
                  };
                  setState(() {
                    if (isEditing) {
                      _schedules[index!] = newItem;
                    } else {
                      _schedules.add(newItem);
                    }
                  });
                  _save();
                  Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditSchedule(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _schedules.isEmpty
            ? const Center(child: Text('Belum ada jadwal tayang.'))
            : ListView.builder(
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final item = _schedules[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        item['type'] == 'video'
                            ? Icons.videocam
                            : item['type'] == 'audio'
                            ? Icons.audiotrack
                            : Icons.image,
                      ),
                      title: Text(item['path'].split('/').last),
                      subtitle: Text(
                        'Jam: ${item['time']} | ${(item['is_loop'] == true) ? "Loop: ${item['play_count']}x" : "Sekali"} | Hari: ${item['days'].length}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _addOrEditSchedule(item: item, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }
}
