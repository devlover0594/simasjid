import React, { useEffect, useState } from 'react';
import { Download, Search, Upload, X } from 'lucide-react';
import {
  argbToHex,
  DEFAULT_TEXT_STYLES,
  FONT_FAMILIES,
  hexToArgbInt,
  TEXT_STYLE_ELEMENTS,
  THEME_PRESETS,
} from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { fetchCities } from '../../services/apiRepository';
import { exportBackupJson } from '../../services/storageService';
import type { ApiProvider, CityItem, SlideshowEffect } from '../../types/simasjid';
import { readImageAsDataUrl } from '../settings/fileHelper';

interface AdminToastProps {
  onToast: (msg: string) => void;
}

/* -------------------------------------------------------------------------- */
/* 1. Identitas & Umum                                                        */
/* -------------------------------------------------------------------------- */
export const AdminIdentitasSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings, restoreBackup, resetSettings } = useKiosk();
  const [name, setName] = useState(settings.mosque_name);
  const [address, setAddress] = useState(settings.mosque_address);
  const [confirmReset, setConfirmReset] = useState(false);

  useEffect(() => {
    setName(settings.mosque_name);
    setAddress(settings.mosque_address);
  }, [settings.mosque_name, settings.mosque_address]);

  const handleBackup = () => {
    const json = exportBackupJson(settings);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `simasjid_backup_${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    onToast('Backup JSON berhasil diunduh!');
  };

  const handleRestore = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const txt = await file.text();
      restoreBackup(txt);
      onToast('Restore pengaturan berhasil!');
    } catch {
      onToast('Gagal membaca file backup JSON.');
    }
    e.target.value = '';
  };

  return (
    <div className="max-w-[960px] mx-auto space-y-5">
      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm">
        <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5 mb-1">
          <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
          General Identity
        </h2>
        <p className="text-sm text-slate-500 mb-4">
          ID Display: <code className="bg-slate-100 px-2 py-0.5 rounded font-mono text-teal-700">{settings.displayId}</code>
        </p>

        <div className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1.5">
              Nama Masjid
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px] text-slate-900 focus:outline-none focus:border-teal-600"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1.5">
              Alamat
            </label>
            <input
              type="text"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px] text-slate-900 focus:outline-none focus:border-teal-600"
            />
          </div>
          <button
            type="button"
            onClick={() => {
              updateSettings({
                mosque_name: name.trim() || 'MASJID AL MUNTAHA',
                mosque_address: address.trim(),
              });
              onToast('Identitas masjid berhasil disimpan!');
            }}
            className="w-full py-3 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm transition-colors"
          >
            Simpan Identitas
          </button>
        </div>
      </div>

      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h3 className="font-bold text-slate-900">Backup, Restore & Reset</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <button
            type="button"
            onClick={handleBackup}
            className="py-2.5 px-4 rounded-[10px] bg-slate-100 hover:bg-slate-200 border border-slate-200 text-slate-800 font-semibold text-sm flex items-center justify-center gap-2"
          >
            <Download className="w-4 h-4" /> Backup JSON
          </button>
          <label className="py-2.5 px-4 rounded-[10px] bg-teal-50 hover:bg-teal-100 border border-teal-200 text-teal-800 font-semibold text-sm flex items-center justify-center gap-2 cursor-pointer">
            <Upload className="w-4 h-4" /> Restore JSON
            <input
              type="file"
              accept=".json,application/json"
              onChange={handleRestore}
              className="hidden"
            />
          </label>
          <button
            type="button"
            onClick={() => setConfirmReset(true)}
            className="py-2.5 px-4 rounded-[10px] bg-red-50 hover:bg-red-100 border border-red-200 text-red-600 font-semibold text-sm"
          >
            Reset Default
          </button>
        </div>
      </div>

      {confirmReset && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
            <h4 className="font-bold text-lg text-slate-900">
              Reset Semua Pengaturan?
            </h4>
            <p className="text-sm text-slate-600">
              Semua data pengaturan, slide, agenda, dan jadwal akan dikembalikan
              ke pengaturan awal.
            </p>
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setConfirmReset(false)}
                className="px-4 py-2 rounded-lg bg-slate-100 text-slate-700 text-sm font-medium"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={() => {
                  resetSettings();
                  setConfirmReset(false);
                  onToast('Semua pengaturan telah direset!');
                }}
                className="px-4 py-2 rounded-lg bg-red-600 text-white text-sm font-semibold"
              >
                Reset Sekarang
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 2. Jadwal Sholat                                                           */
/* -------------------------------------------------------------------------- */
export const AdminJadwalSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, prayerTimes, updateSettings, refreshPrayerTimes } =
    useKiosk();
  const [useApi, setUseApi] = useState(settings.use_api_prayer_times);
  const [provider, setProvider] = useState<ApiProvider>(settings.api_provider);
  const [hijriAdj, setHijriAdj] = useState(settings.hijri_adjustment);
  const [times, setTimes] = useState(prayerTimes.map((p) => ({ ...p })));
  const [cityPickerOpen, setCityPickerOpen] = useState(false);
  const [cities, setCities] = useState<CityItem[]>([]);
  const [search, setSearch] = useState('');

  useEffect(() => {
    setTimes(prayerTimes.map((p) => ({ ...p })));
  }, [prayerTimes]);

  const openCityModal = async () => {
    setCityPickerOpen(true);
    if (cities.length === 0) {
      const list = await fetchCities();
      setCities(list ?? []);
    }
  };

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Pengaturan Jadwal Sholat
      </h2>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1.5">
            Sumber Jadwal
          </label>
          <select
            value={useApi ? 'true' : 'false'}
            onChange={(e) => setUseApi(e.target.value === 'true')}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          >
            <option value="true">Otomatis via API</option>
            <option value="false">Input Manual</option>
          </select>
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1.5">
            Provider API
          </label>
          <select
            value={provider}
            onChange={(e) => setProvider(e.target.value as ApiProvider)}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          >
            <option value="MyQuran">MyQuran</option>
            <option value="AlAdhan">AlAdhan</option>
            <option value="EQuran">EQuran.id</option>
          </select>
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1.5">
            Penyesuaian Hijriyah (Hari)
          </label>
          <input
            type="number"
            value={hijriAdj}
            onChange={(e) => setHijriAdj(Number(e.target.value))}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
      </div>

      <div className="p-3.5 rounded-[10px] bg-slate-50 border border-slate-200 flex items-center justify-between gap-3">
        <div className="text-sm">
          <span className="text-slate-500">Kota Terpilih:</span>{' '}
          <strong className="text-slate-900">
            {settings.kota_name || 'Belum dipilih'}
          </strong>
        </div>
        <button
          type="button"
          onClick={openCityModal}
          className="px-3.5 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-xs font-semibold"
        >
          Cari / Pilih Kota
        </button>
      </div>

      <div className="space-y-2.5 pt-2">
        <h3 className="font-semibold text-slate-800 text-sm">
          Waktu Sholat (Manual / Override)
        </h3>
        {times.map((p, idx) => (
          <div key={p.name} className="flex items-center gap-4">
            <div className="w-28 font-semibold text-slate-700 text-sm">{p.name}</div>
            <input
              type="time"
              value={p.time === '--:--' ? '' : p.time}
              onChange={(e) => {
                const next = [...times];
                next[idx] = { ...next[idx], time: e.target.value };
                setTimes(next);
              }}
              className="flex-1 px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px] tabular-nums"
            />
          </div>
        ))}
      </div>

      <div className="flex gap-3 pt-2">
        <button
          type="button"
          onClick={() => {
            updateSettings({
              use_api_prayer_times: useApi,
              api_provider: provider,
              hijri_adjustment: hijriAdj,
              custom_prayer_times: times,
            });
            if (useApi) void refreshPrayerTimes();
            onToast('Pengaturan jadwal sholat disimpan!');
          }}
          className="flex-1 py-3 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
        >
          Simpan Jadwal Sholat
        </button>
      </div>

      {cityPickerOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full max-h-[80vh] flex flex-col overflow-hidden shadow-2xl">
            <div className="p-4 border-b border-slate-200 flex items-center justify-between">
              <h4 className="font-bold text-slate-900">Pilih Kota (MyQuran)</h4>
              <button
                type="button"
                onClick={() => setCityPickerOpen(false)}
                className="text-slate-500 hover:text-slate-900"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-3 border-b border-slate-100 relative">
              <Search className="w-4 h-4 text-slate-400 absolute left-6 top-5.5" />
              <input
                type="text"
                placeholder="Ketik nama kota..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-3 py-2 rounded-lg bg-slate-50 border border-slate-200 text-sm"
              />
            </div>
            <div className="flex-1 overflow-y-auto p-2 space-y-1">
              {cities
                .filter((c) =>
                  c.lokasi.toLowerCase().includes(search.toLowerCase()),
                )
                .map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => {
                      updateSettings({
                        kota_id: c.id,
                        kota_name: c.lokasi,
                        use_api_prayer_times: true,
                      });
                      setUseApi(true);
                      setCityPickerOpen(false);
                      onToast(`Kota diubah ke ${c.lokasi}`);
                    }}
                    className="w-full text-left px-3 py-2 rounded-lg hover:bg-teal-50 text-sm flex justify-between"
                  >
                    <span className="text-slate-800">{c.lokasi}</span>
                    <span className="text-xs text-slate-400 font-mono">{c.id}</span>
                  </button>
                ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 3. Slide Info                                                              */
/* -------------------------------------------------------------------------- */
export const AdminSlideSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [editIdx, setEditIdx] = useState<number | null>(null);

  const handleSubmit = () => {
    if (!title.trim()) {
      onToast('Judul slide tidak boleh kosong!');
      return;
    }
    const next = [...settings.slides];
    const item = { title: title.trim(), content: content.trim() };
    if (editIdx !== null) next[editIdx] = item;
    else next.push(item);

    updateSettings({ slides: next });
    setTitle('');
    setContent('');
    setEditIdx(null);
    onToast(editIdx !== null ? 'Slide diperbarui!' : 'Slide ditambahkan!');
  };

  return (
    <div className="max-w-[960px] mx-auto space-y-5">
      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
          <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
          Tambah / Edit Slide Info
        </h2>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Judul Slide
          </label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Isi Pengumuman
          </label>
          <textarea
            rows={3}
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={handleSubmit}
            className="flex-1 py-3 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
          >
            {editIdx !== null ? 'Update Slide' : 'Tambah Slide'}
          </button>
          {editIdx !== null && (
            <button
              type="button"
              onClick={() => {
                setTitle('');
                setContent('');
                setEditIdx(null);
              }}
              className="px-4 py-3 rounded-[10px] bg-slate-100 text-slate-700 font-semibold text-sm"
            >
              Batal
            </button>
          )}
        </div>
      </div>

      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm overflow-x-auto">
        <h3 className="font-bold text-slate-900 mb-3">Daftar Slide Aktif</h3>
        {settings.slides.length === 0 ? (
          <div className="text-center py-6 border border-dashed border-slate-300 rounded-lg text-slate-500 text-sm">
            Belum ada slide info.
          </div>
        ) : (
          <table className="w-full text-sm border-collapse">
            <thead>
              <tr className="border-b-2 border-slate-200 text-left text-xs uppercase text-slate-500">
                <th className="py-2.5 px-3">#</th>
                <th className="py-2.5 px-3">Judul & Isi</th>
                <th className="py-2.5 px-3 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody>
              {settings.slides.map((s, i) => (
                <tr key={`${s.title}-${i}`} className="border-b border-slate-100">
                  <td className="py-3 px-3">{i + 1}</td>
                  <td className="py-3 px-3">
                    <div className="font-bold text-slate-900">{s.title}</div>
                    <div className="text-slate-600">{s.content}</div>
                  </td>
                  <td className="py-3 px-3 text-right whitespace-nowrap">
                    <button
                      type="button"
                      onClick={() => {
                        setTitle(s.title);
                        setContent(s.content);
                        setEditIdx(i);
                      }}
                      className="px-2.5 py-1 rounded bg-slate-100 hover:bg-teal-50 border border-slate-200 text-xs font-semibold mr-2"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        updateSettings({
                          slides: settings.slides.filter((_, idx) => idx !== i),
                        });
                        onToast('Slide dihapus!');
                      }}
                      className="px-2.5 py-1 rounded bg-red-50 hover:bg-red-500 hover:text-white text-red-600 text-xs font-semibold"
                    >
                      Hapus
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 4. Running Text                                                            */
/* -------------------------------------------------------------------------- */
export const AdminRunningSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [text, setText] = useState(settings.running_text);

  useEffect(() => {
    setText(settings.running_text);
  }, [settings.running_text]);

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Running Text
      </h2>
      <textarea
        rows={4}
        value={text}
        onChange={(e) => setText(e.target.value)}
        className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
      />
      <button
        type="button"
        onClick={() => {
          updateSettings({ running_text: text.trim() });
          onToast('Running text disimpan!');
        }}
        className="w-full py-3 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
      >
        Simpan Running Text
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 5. Notifikasi                                                              */
/* -------------------------------------------------------------------------- */
export const AdminNotifSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [form, setForm] = useState({
    notif_adzan_duration: settings.notif_adzan_duration,
    notif_text_adzan: settings.notif_text_adzan,
    notif_iqomah_delay: settings.notif_iqomah_delay,
    notif_text_iqomah_timer: settings.notif_text_iqomah_timer,
    notif_iqomah_duration: settings.notif_iqomah_duration,
    notif_text_iqomah: settings.notif_text_iqomah,
    notif_sholat_duration: settings.notif_sholat_duration,
    notif_text_sholat: settings.notif_text_sholat,
    friday_mode_enabled: settings.friday_mode_enabled,
    friday_khutbah_duration: settings.friday_khutbah_duration,
    friday_khutbah_text: settings.friday_khutbah_text,
  });

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Pengaturan Notifikasi Adzan, Iqomah & Jumat
      </h2>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Durasi Tampilan Adzan (Detik)
          </label>
          <input
            type="number"
            value={form.notif_adzan_duration}
            onChange={(e) =>
              setForm({ ...form, notif_adzan_duration: Number(e.target.value) || 180 })
            }
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Judul Notifikasi Adzan
          </label>
          <input
            type="text"
            value={form.notif_text_adzan}
            onChange={(e) => setForm({ ...form, notif_text_adzan: e.target.value })}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Jeda Menuju Iqomah (Menit)
          </label>
          <input
            type="number"
            value={form.notif_iqomah_delay}
            onChange={(e) =>
              setForm({ ...form, notif_iqomah_delay: Number(e.target.value) || 0 })
            }
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Pesan Timer Iqomah
          </label>
          <input
            type="text"
            value={form.notif_text_iqomah_timer}
            onChange={(e) =>
              setForm({ ...form, notif_text_iqomah_timer: e.target.value })
            }
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Durasi Layar Iqomah (Detik)
          </label>
          <input
            type="number"
            value={form.notif_iqomah_duration}
            onChange={(e) =>
              setForm({ ...form, notif_iqomah_duration: Number(e.target.value) || 60 })
            }
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Pesan Perintah Iqomah
          </label>
          <input
            type="text"
            value={form.notif_text_iqomah}
            onChange={(e) => setForm({ ...form, notif_text_iqomah: e.target.value })}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Durasi Layar Sholat (Detik)
          </label>
          <input
            type="number"
            value={form.notif_sholat_duration}
            onChange={(e) =>
              setForm({ ...form, notif_sholat_duration: Number(e.target.value) || 600 })
            }
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Pesan Layar Sholat
          </label>
          <input
            type="text"
            value={form.notif_text_sholat}
            onChange={(e) => setForm({ ...form, notif_text_sholat: e.target.value })}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
      </div>

      <div className="pt-3 border-t border-slate-200 space-y-3">
        <label className="flex items-center justify-between cursor-pointer">
          <div>
            <div className="font-semibold text-sm text-slate-800">
              Mode Sholat Jumat
            </div>
            <div className="text-xs text-slate-500">
              Ganti Dzuhur hari Jumat menjadi tampilan Khutbah Jumat
            </div>
          </div>
          <input
            type="checkbox"
            checked={form.friday_mode_enabled}
            onChange={(e) =>
              setForm({ ...form, friday_mode_enabled: e.target.checked })
            }
            className="w-5 h-5 accent-teal-600"
          />
        </label>

        {form.friday_mode_enabled && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-500 mb-1">
                Durasi Khutbah (Menit)
              </label>
              <input
                type="number"
                value={form.friday_khutbah_duration}
                onChange={(e) =>
                  setForm({
                    ...form,
                    friday_khutbah_duration: Number(e.target.value) || 30,
                  })
                }
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-500 mb-1">
                Teks Himbauan Khutbah
              </label>
              <input
                type="text"
                value={form.friday_khutbah_text}
                onChange={(e) =>
                  setForm({ ...form, friday_khutbah_text: e.target.value })
                }
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
              />
            </div>
          </div>
        )}
      </div>

      <button
        type="button"
        onClick={() => {
          updateSettings(form);
          onToast('Pengaturan notifikasi disimpan!');
        }}
        className="w-full py-3 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
      >
        Simpan Notifikasi
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 12. Teks & Font                                                            */
/* -------------------------------------------------------------------------- */
export const AdminTeksSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [styles, setStyles] = useState(
    () => structuredClone({ ...DEFAULT_TEXT_STYLES, ...settings.text_styles }),
  );

  useEffect(() => {
    setStyles(structuredClone({ ...DEFAULT_TEXT_STYLES, ...settings.text_styles }));
  }, [settings.text_styles]);

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Pengaturan Teks & Font
      </h2>
      <div className="overflow-x-auto">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b-2 border-slate-200 text-left text-xs uppercase text-slate-500">
              <th className="py-2.5 px-3">Elemen</th>
              <th className="py-2.5 px-3">Ukuran (px)</th>
              <th className="py-2.5 px-3">Warna</th>
              <th className="py-2.5 px-3">Font</th>
            </tr>
          </thead>
          <tbody>
            {Object.entries(TEXT_STYLE_ELEMENTS).map(([key, label]) => {
              const st = styles[key] ?? DEFAULT_TEXT_STYLES[key];
              return (
                <tr key={key} className="border-b border-slate-100">
                  <td className="py-2.5 px-3 font-semibold text-slate-800">{label}</td>
                  <td className="py-2.5 px-3">
                    <input
                      type="number"
                      min={10}
                      max={150}
                      value={st.size}
                      onChange={(e) =>
                        setStyles((prev) => ({
                          ...prev,
                          [key]: { ...st, size: Number(e.target.value) || 20 },
                        }))
                      }
                      className="w-20 px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg"
                    />
                  </td>
                  <td className="py-2.5 px-3">
                    <input
                      type="color"
                      value={argbToHex(st.color)}
                      onChange={(e) =>
                        setStyles((prev) => ({
                          ...prev,
                          [key]: { ...st, color: hexToArgbInt(e.target.value) },
                        }))
                      }
                      className="w-12 h-8 p-0.5 rounded border border-slate-200 cursor-pointer"
                    />
                  </td>
                  <td className="py-2.5 px-3">
                    <select
                      value={FONT_FAMILIES.includes(st.font) ? st.font : 'Roboto'}
                      onChange={(e) =>
                        setStyles((prev) => ({
                          ...prev,
                          [key]: { ...st, font: e.target.value },
                        }))
                      }
                      className="px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg"
                    >
                      {FONT_FAMILIES.map((f) => (
                        <option key={f} value={f}>
                          {f}
                        </option>
                      ))}
                    </select>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <button
        type="button"
        onClick={() => {
          updateSettings({ text_styles: styles });
          onToast('Semua gaya teks berhasil disimpan!');
        }}
        className="w-full py-3 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
      >
        Simpan Semua Teks & Font
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 13. Tema & Background                                                      */
/* -------------------------------------------------------------------------- */
export const AdminTemaSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [logoPath, setLogoPath] = useState(settings.logo_path);
  const [showLogo, setShowLogo] = useState(settings.show_logo);
  const [logoAnim, setLogoAnim] = useState(settings.logo_animation_enabled);
  const [rotDur, setRotDur] = useState(settings.rotation_duration_seconds);
  const [effect, setEffect] = useState<SlideshowEffect>(settings.slideshow_effect);

  const handleBgUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const dataUrl = await readImageAsDataUrl(file);
    const patch: Partial<typeof settings> = { bg_dashboard: dataUrl };
    if (settings.bg_apply_all) {
      patch.bg_asset = dataUrl;
      patch.bg_info = dataUrl;
      patch.bg_event = dataUrl;
    }
    updateSettings(patch);
    onToast('Background baru berhasil diterapkan!');
    e.target.value = '';
  };

  const handleLogoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const dataUrl = await readImageAsDataUrl(file, 600);
    setLogoPath(dataUrl);
    updateSettings({ logo_path: dataUrl });
    onToast('Logo berhasil diunggah!');
    e.target.value = '';
  };

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-6">
      <div>
        <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
          <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
          Tema & Nuansa Warna
        </h2>
        <p className="text-sm text-slate-500 mt-1">
          Pilih paduan warna untuk efek glassmorphism dan aksen di layar TV Anda.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-4">
          {THEME_PRESETS.map((preset) => {
            const isSelected =
              settings.theme_primary_color === preset.primary &&
              settings.theme_accent_color === preset.accent;
            const pHex = argbToHex(preset.primary);
            const aHex = argbToHex(preset.accent);
            return (
              <button
                key={preset.name}
                type="button"
                onClick={() => {
                  updateSettings({
                    theme_primary_color: preset.primary,
                    theme_accent_color: preset.accent,
                  });
                  onToast(`Tema ${preset.name} diterapkan!`);
                }}
                className={`text-left p-4 rounded-xl border-2 flex items-center gap-3.5 relative transition-all ${
                  isSelected
                    ? 'border-teal-600 bg-teal-50'
                    : 'border-slate-200 bg-white hover:border-teal-400'
                }`}
              >
                <div
                  className="w-12 h-12 rounded-xl shrink-0 shadow-sm"
                  style={{
                    background: `linear-gradient(135deg, ${pHex}, ${aHex})`,
                  }}
                />
                <div>
                  <div className="font-bold text-sm text-slate-900">
                    {preset.name}
                  </div>
                  <div className="text-xs text-slate-500 mt-0.5">{preset.desc}</div>
                </div>
                {isSelected && (
                  <span className="absolute right-3 top-2.5 text-teal-600 font-bold">
                    ✓
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      <div className="p-5 rounded-xl bg-slate-50 border-2 border-dashed border-slate-200 space-y-4">
        <h3 className="font-bold text-slate-800">Background Utama</h3>
        <div className="flex flex-wrap items-center gap-3">
          <label className="px-4 py-2.5 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-sm font-semibold cursor-pointer inline-flex items-center gap-2">
            <Upload className="w-4 h-4" /> Upload Background
            <input
              type="file"
              accept="image/*"
              onChange={handleBgUpload}
              className="hidden"
            />
          </label>
          <label className="flex items-center gap-2.5 text-sm text-slate-700 cursor-pointer ml-auto">
            <input
              type="checkbox"
              checked={settings.bg_apply_all}
              onChange={(e) => {
                const apply = e.target.checked;
                const patch: Partial<typeof settings> = { bg_apply_all: apply };
                if (apply) {
                  patch.bg_asset = settings.bg_dashboard;
                  patch.bg_info = settings.bg_dashboard;
                  patch.bg_event = settings.bg_dashboard;
                }
                updateSettings(patch);
              }}
              className="w-4 h-4 accent-teal-600"
            />
            Terapkan ke Semua Layar
          </label>
        </div>
      </div>

      <div className="p-5 rounded-xl bg-slate-50 border border-slate-200 space-y-4">
        <h3 className="font-bold text-slate-800">Logo Masjid & Slideshow</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <label className="flex items-center gap-2.5 text-sm font-medium text-slate-700 cursor-pointer">
            <input
              type="checkbox"
              checked={showLogo}
              onChange={(e) => setShowLogo(e.target.checked)}
              className="w-4 h-4 accent-teal-600"
            />
            Tampilkan Logo Masjid
          </label>
          <label className="flex items-center gap-2.5 text-sm font-medium text-slate-700 cursor-pointer">
            <input
              type="checkbox"
              checked={logoAnim}
              onChange={(e) => setLogoAnim(e.target.checked)}
              className="w-4 h-4 accent-teal-600"
            />
            Animasi Logo
          </label>
        </div>

        <div className="flex gap-2.5 items-center">
          <input
            type="text"
            value={logoPath.startsWith('data:') ? '[Logo Lokal]' : logoPath}
            onChange={(e) => setLogoPath(e.target.value)}
            placeholder="URL Logo atau Upload"
            className="flex-1 px-3.5 py-2 bg-white border border-slate-200 rounded-[10px] text-sm"
          />
          <label className="px-3.5 py-2 rounded-lg bg-slate-200 hover:bg-slate-300 text-slate-800 text-xs font-semibold cursor-pointer">
            Upload Logo
            <input
              type="file"
              accept="image/*"
              onChange={handleLogoUpload}
              className="hidden"
            />
          </label>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1">
              Durasi Rotasi Layar (detik)
            </label>
            <input
              type="number"
              min={30}
              max={180}
              value={rotDur}
              onChange={(e) => setRotDur(Number(e.target.value) || 90)}
              className="w-full px-3.5 py-2 bg-white border border-slate-200 rounded-[10px]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1">
              Efek Slideshow
            </label>
            <select
              value={effect}
              onChange={(e) => setEffect(e.target.value as SlideshowEffect)}
              className="w-full px-3.5 py-2 bg-white border border-slate-200 rounded-[10px]"
            >
              <option value="fade">Fade</option>
              <option value="slide">Slide</option>
              <option value="zoom">Zoom</option>
            </select>
          </div>
        </div>

        <button
          type="button"
          onClick={() => {
            updateSettings({
              logo_path: logoPath,
              show_logo: showLogo,
              logo_animation_enabled: logoAnim,
              rotation_duration_seconds: Math.min(180, Math.max(30, rotDur)),
              slideshow_effect: effect,
            });
            onToast('Logo & Slideshow disimpan!');
          }}
          className="w-full py-3 rounded-[10px] bg-teal-700 hover:bg-teal-800 text-white font-semibold text-sm"
        >
          Simpan Logo & Slideshow
        </button>
      </div>
    </div>
  );
};
