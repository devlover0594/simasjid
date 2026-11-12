import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EventSettingsView extends StatefulWidget {
  const EventSettingsView({super.key});

  @override
  State<EventSettingsView> createState() => _EventSettingsViewState();
}

class _EventSettingsViewState extends State<EventSettingsView> {
  List<Map<String, String>> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('events');
    if (jsonStr != null) {
      try {
        final List decoded = jsonDecode(jsonStr);
        _events = decoded
            .map(
              (e) => {
                'title': e['title'].toString(),
                'date': e['date'].toString(),
              },
            )
            .toList();
        setState(() {});
      } catch (_) {}
    }
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('events', jsonEncode(_events));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Agenda Disimpan')));
  }

  void _addOrEditEvent({int? index}) async {
    final isEditing = index != null;
    final titleCtrl = TextEditingController(
      text: isEditing ? _events[index]['title'] : '',
    );
    DateTime selectedDate = isEditing
        ? DateTime.parse(_events[index]['date']!)
        : DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Agenda' : 'Tambah Agenda'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Kegiatan'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: Text(
                    "Tanggal: ${selectedDate.toLocal().toString().split(' ')[0]}",
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                    );
                    if (picked != null) {
                      setStateDialog(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newItem = {
                    'title': titleCtrl.text,
                    'date': selectedDate.toIso8601String().split('T')[0],
                  };
                  setState(() {
                    if (isEditing) {
                      _events[index] = newItem;
                    } else {
                      _events.add(newItem);
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
    titleCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agenda & Event',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.green,
                  size: 32,
                ),
                onPressed: () => _addOrEditEvent(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _events.isEmpty
                ? const Center(child: Text('Belum ada agenda.'))
                : ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              event['date']!.split('-')[2],
                            ), // Tanggal
                          ),
                          title: Text(event['title']!),
                          subtitle: Text(event['date']!),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _addOrEditEvent(index: index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() => _events.removeAt(index));
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
        ],
      ),
    );
  }
}

