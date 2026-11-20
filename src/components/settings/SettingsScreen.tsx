import React, { useEffect, useState } from 'react';
import {
  ArrowLeft,
  BellRing,
  BookOpen,
  Calendar,
  CalendarDays,
  CaseSensitive,
  Clock,
  Landmark,
  Music,
  Palette,
  PlayCircle,
  Power,
  Presentation,
  Radio,
  Type,
  Users,
} from 'lucide-react';
import { useKiosk } from '../../context/KioskContext';
import {
  EventSettingsView,
  ImsakiyahSettingsView,
  IotSettingsView,
  PerformerSettingsView,
  PowerTvSettingsView,
} from './SettingsAdvancedViews';
import {
  IdentitySettingsView,
  PrayerSettingsView,
  RunningTextSettingsView,
  SlideSettingsView,
  ThemeSettingsView,
} from './SettingsGeneralViews';
import {
  HadithSettingsView,
  MediaSettingsView,
  MurottalSettingsView,
  NotificationSettingsView,
  TextSettingsView,
} from './SettingsScheduleViews';

const NAV_ITEMS = [
  { id: 0, label: 'Identitas', icon: Landmark },
  { id: 1, label: 'Jadwal', icon: Clock },
  { id: 2, label: 'Slide', icon: Presentation },
  { id: 3, label: 'Run Text', icon: Type },
  { id: 4, label: 'Tema', icon: Palette },
  { id: 5, label: 'Notifikasi', icon: BellRing },
  { id: 6, label: 'Media', icon: PlayCircle },
  { id: 7, label: 'Murottal', icon: Music },
  { id: 8, label: 'Hadis', icon: BookOpen },
  { id: 9, label: 'Teks', icon: CaseSensitive },
  { id: 10, label: 'Petugas', icon: Users },
  { id: 11, label: 'Agenda', icon: Calendar },
  { id: 12, label: 'Smart IoT', icon: Radio },
  { id: 13, label: 'Imsakiyah', icon: CalendarDays },
  { id: 14, label: 'Power TV', icon: Power },
  { id: 15, label: 'Keluar', icon: ArrowLeft },
] as const;

export const SettingsScreen: React.FC = () => {
  const { closeSettings } = useKiosk();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [toast, setToast] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToast(msg);
  };

  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(null), 2800);
    return () => window.clearTimeout(t);
  }, [toast]);

  // Escape closes settings cleanly
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        closeSettings();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [closeSettings]);

  const renderContent = () => {
    switch (selectedIndex) {
      case 0:
        return <IdentitySettingsView onToast={showToast} />;
      case 1:
        return <PrayerSettingsView onToast={showToast} />;
      case 2:
        return <SlideSettingsView onToast={showToast} />;
      case 3:
        return <RunningTextSettingsView onToast={showToast} />;
      case 4:
        return <ThemeSettingsView onToast={showToast} />;
      case 5:
        return <NotificationSettingsView onToast={showToast} />;
      case 6:
        return <MediaSettingsView onToast={showToast} />;
      case 7:
        return <MurottalSettingsView onToast={showToast} />;
      case 8:
        return <HadithSettingsView onToast={showToast} />;
      case 9:
        return <TextSettingsView onToast={showToast} />;
      case 10:
        return <PerformerSettingsView onToast={showToast} />;
      case 11:
        return <EventSettingsView onToast={showToast} />;
      case 12:
        return <IotSettingsView onToast={showToast} />;
      case 13:
        return <ImsakiyahSettingsView onToast={showToast} />;
      case 14:
        return <PowerTvSettingsView onToast={showToast} />;
      default:
        return null;
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950 text-white flex overflow-hidden">
      {/* Left NavigationRail matching Flutter SettingsScreen */}
      <nav className="w-24 sm:w-28 bg-black/90 border-r border-white/15 overflow-y-auto shrink-0 py-2 flex flex-col">
        {NAV_ITEMS.map((item) => {
          const Icon = item.icon;
          const active = selectedIndex === item.id;
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => {
                if (item.id === 15) {
                  closeSettings();
                } else {
                  setSelectedIndex(item.id);
                }
              }}
              className={`w-full py-2.5 px-1.5 flex flex-col items-center justify-center gap-1 transition-colors ${
                active
                  ? 'text-teal-300 bg-teal-500/15 border-r-2 border-teal-300'
                  : 'text-white/70 hover:text-white hover:bg-white/5'
              }`}
            >
              <Icon className="w-5 h-5" />
              <span className="text-[11px] font-medium leading-tight text-center">
                {item.label}
              </span>
            </button>
          );
        })}
      </nav>

      {/* Main Content Area */}
      <main className="flex-1 overflow-y-auto p-6 bg-slate-900">
        {renderContent()}
      </main>

      {toast && (
        <div className="fixed bottom-5 right-6 z-50 bg-teal-600 text-white px-5 py-2.5 rounded-xl shadow-2xl font-medium text-sm">
          {toast}
        </div>
      )}
    </div>
  );
};
