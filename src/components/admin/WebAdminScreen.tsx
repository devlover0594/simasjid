import React, { useEffect, useState } from 'react';
import { Monitor } from 'lucide-react';
import { useKiosk } from '../../context/KioskContext';
import {
  AdminIdentitasSection,
  AdminJadwalSection,
  AdminNotifSection,
  AdminRunningSection,
  AdminSlideSection,
  AdminTeksSection,
  AdminTemaSection,
} from './AdminCoreSections';
import {
  AdminAgendaSection,
  AdminHadisSection,
  AdminMediaSection,
  AdminMurottalSection,
  AdminPetugasSection,
} from './AdminMediaSections';
import {
  AdminDonasiSection,
  AdminImsakiyahSection,
  AdminIotSection,
  AdminPowertvSection,
  AdminRemoteSection,
} from './AdminSystemSections';

type SectionId =
  | 'identitas'
  | 'jadwal'
  | 'slide'
  | 'running'
  | 'notif'
  | 'media'
  | 'murottal'
  | 'hadis'
  | 'agenda'
  | 'petugas'
  | 'iot'
  | 'teks'
  | 'tema'
  | 'powertv'
  | 'imsakiyah'
  | 'remote'
  | 'donasi';

const MENU_TILES: { id: SectionId; icon: string; title: string }[] = [
  { id: 'identitas', icon: '🏠', title: 'Identitas & Umum' },
  { id: 'jadwal', icon: '🕌', title: 'Jadwal Sholat' },
  { id: 'slide', icon: '📄', title: 'Slide Info' },
  { id: 'running', icon: '⚡', title: 'Running Text' },
  { id: 'notif', icon: '🔔', title: 'Notifikasi' },
  { id: 'media', icon: '🎬', title: 'Media' },
  { id: 'murottal', icon: '🎵', title: 'Murottal' },
  { id: 'hadis', icon: '📚', title: 'Hadis' },
  { id: 'agenda', icon: '📅', title: 'Agenda' },
  { id: 'petugas', icon: '👤', title: 'Petugas' },
  { id: 'iot', icon: '💡', title: 'Smart IoT' },
  { id: 'teks', icon: '✍️', title: 'Teks & Font' },
  { id: 'tema', icon: '🎨', title: 'Tema & Background' },
  { id: 'powertv', icon: '🔌', title: 'Power TV' },
  { id: 'imsakiyah', icon: '🌙', title: 'Imsakiyah' },
  { id: 'remote', icon: '🌐', title: 'Akses Remote' },
  { id: 'donasi', icon: '💖', title: 'Donasi & Dukungan' },
];

export const WebAdminScreen: React.FC = () => {
  const { openKiosk } = useKiosk();
  const [activeSection, setActiveSection] = useState<SectionId | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (!toast) return;
    const t = window.setTimeout(() => setToast(null), 2800);
    return () => window.clearTimeout(t);
  }, [toast]);

  const currentTile = MENU_TILES.find((t) => t.id === activeSection);

  const renderSection = () => {
    switch (activeSection) {
      case 'identitas':
        return <AdminIdentitasSection onToast={setToast} />;
      case 'jadwal':
        return <AdminJadwalSection onToast={setToast} />;
      case 'slide':
        return <AdminSlideSection onToast={setToast} />;
      case 'running':
        return <AdminRunningSection onToast={setToast} />;
      case 'notif':
        return <AdminNotifSection onToast={setToast} />;
      case 'media':
        return <AdminMediaSection onToast={setToast} />;
      case 'murottal':
        return <AdminMurottalSection onToast={setToast} />;
      case 'hadis':
        return <AdminHadisSection onToast={setToast} />;
      case 'agenda':
        return <AdminAgendaSection onToast={setToast} />;
      case 'petugas':
        return <AdminPetugasSection onToast={setToast} />;
      case 'iot':
        return <AdminIotSection onToast={setToast} />;
      case 'teks':
        return <AdminTeksSection onToast={setToast} />;
      case 'tema':
        return <AdminTemaSection onToast={setToast} />;
      case 'powertv':
        return <AdminPowertvSection onToast={setToast} />;
      case 'imsakiyah':
        return <AdminImsakiyahSection onToast={setToast} />;
      case 'remote':
        return <AdminRemoteSection onToast={setToast} />;
      case 'donasi':
        return <AdminDonasiSection />;
      default:
        return null;
    }
  };

  return (
    <div className="admin-root pb-16">
      {/* Sticky Topbar */}
      <header className="sticky top-0 z-40 flex items-center justify-between gap-3 px-6 py-4 bg-white/90 backdrop-blur-md border-b border-slate-200">
        <div className="flex items-center gap-3">
          {activeSection && (
            <button
              type="button"
              onClick={() => setActiveSection(null)}
              className="px-3.5 py-2 rounded-[10px] bg-slate-50 hover:bg-slate-200 border border-slate-200 text-slate-800 text-sm font-semibold"
            >
              ← Kembali
            </button>
          )}
          <h1 className="text-xl font-bold text-slate-900 tracking-tight">
            {currentTile ? currentTile.title : 'Admin Panel SIMasjid'}
          </h1>
        </div>

        <button
          type="button"
          onClick={openKiosk}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white text-sm font-semibold transition-colors"
        >
          <Monitor className="w-4 h-4" /> Kembali ke Display TV
        </button>
      </header>

      {/* Content */}
      <div className="p-6">
        {!activeSection ? (
          <div className="max-w-[960px] mx-auto grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
            {MENU_TILES.map((tile) => (
              <button
                key={tile.id}
                type="button"
                onClick={() => setActiveSection(tile.id)}
                className="bg-white rounded-[14px] p-5 border border-slate-200 shadow-sm hover:-translate-y-0.5 hover:shadow-md hover:border-teal-600 transition-all flex flex-col items-center gap-2.5 text-center"
              >
                <div className="w-14 h-14 rounded-full bg-teal-50 flex items-center justify-center text-3xl">
                  {tile.icon}
                </div>
                <div className="font-semibold text-slate-900 text-[15px]">
                  {tile.title}
                </div>
              </button>
            ))}
          </div>
        ) : (
          renderSection()
        )}
      </div>

      {toast && (
        <div className="fixed bottom-5 right-5 z-50 bg-slate-900 text-white px-5 py-3 rounded-xl shadow-xl text-sm font-medium">
          {toast}
        </div>
      )}
    </div>
  );
};
