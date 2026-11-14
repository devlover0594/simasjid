import 'package:flutter/material.dart';

import 'widgets/tv_focus.dart';
import 'settings/settings_identity.dart';
import 'settings/settings_prayer.dart';
import 'settings/settings_slide.dart';
import 'settings/settings_runningtext.dart';
import 'settings/settings_theme.dart';
import 'settings/settings_notification.dart';
import 'settings/settings_media.dart';
import 'settings/settings_murottal.dart';
import 'settings/settings_hadith.dart';
import 'settings/settings_text.dart';
import 'settings/settings_performer.dart';
import 'settings/settings_event.dart';
import 'settings/settings_iot.dart';
import 'settings/settings_imsakiyah.dart';
import 'settings/settings_powertv.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  /// Dibagikan ke seluruh [TvTextField] anak; dipakai PopScope di bawah agar
  /// tombol back menutup keyboard lebih dulu, bukan langsung keluar Settings.
  final TvKeyboardController _kb = TvKeyboardController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_kb.isEditing) {
          // Keyboard sedang terbuka: tutup dulu, jangan keluar menu.
          _kb.closeEditing();
          return;
        }
        // Tidak ada keyboard terbuka: benar-benar keluar Settings.
        Navigator.pop(context);
      },
      child: TvKeyboardScope(
        controller: _kb,
        child: Scaffold(
          body: Row(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ), // Fix: Use minHeight
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (int index) {
                            if (index == 15) {
                              // Update index keluar karena ada menu baru
                              _kb.closeEditing();
                              Navigator.pop(context, true);
                              return;
                            }
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          labelType: NavigationRailLabelType.all,
                          backgroundColor: Colors.black87,
                          selectedIconTheme: const IconThemeData(
                            color: Colors.tealAccent,
                          ),
                          unselectedIconTheme: const IconThemeData(
                            color: Colors.white70,
                          ),
                          selectedLabelTextStyle: const TextStyle(
                            color: Colors.tealAccent,
                          ),
                          unselectedLabelTextStyle: const TextStyle(
                            color: Colors.white70,
                          ),
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.mosque),
                              label: Text('Identitas'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.access_time),
                              label: Text('Jadwal'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.slideshow),
                              label: Text('Slide'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.text_fields),
                              label: Text('Run Text'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.color_lens),
                              label: Text('Tema'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.notifications_active),
                              label: Text('Notifikasi'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.play_circle_fill),
                              label: Text('Media'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.music_note),
                              label: Text('Murottal'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.book_online),
                              label: Text('Hadis'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.text_format),
                              label: Text('Teks'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.people_alt),
                              label: Text('Petugas'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.event),
                              label: Text('Agenda'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.settings_remote),
                              label: Text('Smart IoT'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.calendar_month),
                              label: Text('Imsakiyah'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.power_settings_new),
                              label: Text('Power TV'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.arrow_back),
                              label: Text('Keluar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    const IdentitySettingsView(),
                    const PrayerSettingsView(),
                    const SlideSettingsView(),
                    const RunningTextSettingsView(),
                    const ThemeSettingsView(),
                    const NotificationSettingsView(),
                    const MediaSettingsView(),
                    const MurottalSettingsView(),
                    const HadithSettingsView(),
                    const TextSettingsView(),
                    const PerformerSettingsView(),
                    const EventSettingsView(), // Ini adalah menu Agenda
                    const IotSettingsView(), // Ini adalah menu IoT
                    const ImsakiyahSettingsView(),
                    const PowerTvSettingsView(),
                    const SizedBox(), // Placeholder for Back
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
