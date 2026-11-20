import React, { useEffect, useState } from 'react';
import {
  ChevronDown,
  ChevronUp,
  FolderPlus,
  Plus,
  Save,
  Trash2,
} from 'lucide-react';
import {
  argbToCssRgba,
  COLOR_SWATCHES,
  FONT_FAMILIES,
  QARIS,
  SHORT_DAYS,
  SURAHS_FALLBACK,
  TEXT_STYLE_ELEMENTS,
} from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { fetchSurahsEQuran } from '../../services/apiRepository';
import type {
  MediaType,
  MurottalSchedule,
} from '../../types/simasjid';
import {
  detectMediaTypeFromFileName,
  readImageAsDataUrl,
} from './fileHelper';

interface ToastProps {
  onToast: (msg: string) => void;
}

/* -------------------------------------------------------------------------- */
/* 5. Notification Settings View                                              */
/* -------------------------------------------------------------------------- */
export const NotificationSettingsView: React.FC<ToastProps> = ({ onToast }) => {
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

  const handleSave = () => {
    updateSettings(form);
    onToast('Pengaturan notifikasi disimpan');
  };

  return (
    <div className="space-y-4 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Notifikasi & Sholat Jumat</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm text-white/75 mb-1">
            Durasi Tampilan Adzan (Detik)
          </label>
          <input
            type="number"
            value={form.notif_adzan_duration}
            onChange={(e) =>
              setForm({
                ...form,
                notif_adzan_duration: Number(e.target.value) || 180,
              })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>
        <div>
          <label className="block text-sm text-white/75 mb-1">
            Judul Notifikasi Adzan
          </label>
          <input
            type="text"
            value={form.notif_text_adzan}
            onChange={(e) =>
              setForm({ ...form, notif_text_adzan: e.target.value })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>

        <div>
          <label className="block text-sm text-white/75 mb-1">
            Jeda Waktu Menuju Iqomah (Menit)
          </label>
          <input
            type="number"
            value={form.notif_iqomah_delay}
            onChange={(e) =>
              setForm({
                ...form,
                notif_iqomah_delay: Number(e.target.value) || 0,
              })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>
        <div>
          <label className="block text-sm text-white/75 mb-1">
            Pesan Saat Hitung Mundur Iqomah
          </label>
          <input
            type="text"
            value={form.notif_text_iqomah_timer}
            onChange={(e) =>
              setForm({ ...form, notif_text_iqomah_timer: e.target.value })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>

        <div>
          <label className="block text-sm text-white/75 mb-1">
            Durasi Layar Iqomah (Detik)
          </label>
          <input
            type="number"
            value={form.notif_iqomah_duration}
            onChange={(e) =>
              setForm({
                ...form,
                notif_iqomah_duration: Number(e.target.value) || 60,
              })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>
        <div>
          <label className="block text-sm text-white/75 mb-1">
            Pesan Perintah Iqomah
          </label>
          <input
            type="text"
            value={form.notif_text_iqomah}
            onChange={(e) =>
              setForm({ ...form, notif_text_iqomah: e.target.value })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>

        <div>
          <label className="block text-sm text-white/75 mb-1">
            Durasi Layar Sholat (Detik)
          </label>
          <input
            type="number"
            value={form.notif_sholat_duration}
            onChange={(e) =>
              setForm({
                ...form,
                notif_sholat_duration: Number(e.target.value) || 600,
              })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>
        <div>
          <label className="block text-sm text-white/75 mb-1">
            Pesan Layar Saat Sholat Berlangsung
          </label>
          <input
            type="text"
            value={form.notif_text_sholat}
            onChange={(e) =>
              setForm({ ...form, notif_text_sholat: e.target.value })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>
      </div>

      <div className="pt-3 border-t border-white/15 space-y-3">
        <label className="flex items-center justify-between p-3 rounded-xl bg-white/5 cursor-pointer">
          <div>
            <div className="font-semibold">Aktifkan Mode Sholat Jumat</div>
            <div className="text-xs text-white/60">
              Ubah Dzuhur hari Jumat menjadi tampilan Khutbah Jumat
            </div>
          </div>
          <input
            type="checkbox"
            checked={form.friday_mode_enabled}
            onChange={(e) =>
              setForm({ ...form, friday_mode_enabled: e.target.checked })
            }
            className="w-5 h-5 accent-teal-400"
          />
        </label>

        {form.friday_mode_enabled && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-white/75 mb-1">
                Durasi Khutbah Jumat (Menit)
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
                className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
              />
            </div>
            <div>
              <label className="block text-sm text-white/75 mb-1">
                Teks Himbauan Khutbah
              </label>
              <input
                type="text"
                value={form.friday_khutbah_text}
                onChange={(e) =>
                  setForm({ ...form, friday_khutbah_text: e.target.value })
                }
                className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
              />
            </div>
          </div>
        )}
      </div>

      <button
        type="button"
        onClick={handleSave}
        className="w-full py-2.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold"
      >
        Simpan
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 6. Media Settings View                                                     */
/* -------------------------------------------------------------------------- */
export const MediaSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [libName, setLibName] = useState('');
  const [libType, setLibType] = useState<MediaType>('image');
  const [libPath, setLibPath] = useState('');

  const [schedPath, setSchedPath] = useState('');
  const [schedType, setSchedType] = useState<MediaType>('image');
  const [schedTime, setSchedTime] = useState('12:00');
  const [schedLoop, setSchedLoop] = useState(false);
  const [schedCount, setSchedCount] = useState(1);
  const [schedDays, setSchedDays] = useState<number[]>([1, 2, 3, 4, 5, 6, 7]);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? []);
    if (files.length === 0) return;
    const added = [];
    for (const file of files) {
      const mType = detectMediaTypeFromFileName(file.name);
      const path =
        mType === 'image'
          ? await readImageAsDataUrl(file)
          : URL.createObjectURL(file);
      added.push({
        id: `${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        name: file.name,
        path,
        type: mType,
      });
    }
    updateSettings({
      media_library: [...settings.media_library, ...added],
    });
    onToast(`${added.length} media ditambahkan ke playlist`);
    e.target.value = '';
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Manajemen Media & Jadwal</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <label className="flex items-center justify-between p-3.5 rounded-xl bg-white/5 border border-white/15 cursor-pointer">
        <div>
          <div className="font-semibold">Slideshow Media Library</div>
          <div className="text-xs text-white/60">
            Putar media di Media Library secara otomatis saat rotasi layar
          </div>
        </div>
        <input
          type="checkbox"
          checked={settings.media_slideshow_enabled}
          onChange={(e) =>
            updateSettings({ media_slideshow_enabled: e.target.checked })
          }
          className="w-5 h-5 accent-teal-400"
        />
      </label>

      {/* Media Library */}
      <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="font-bold text-lg text-teal-300">Media Library (Playlist)</h3>
          <label className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white text-xs font-semibold cursor-pointer">
            <FolderPlus className="w-4 h-4" /> Pilih / Impor File Media
            <input
              type="file"
              multiple
              accept="image/*,video/*,audio/*"
              onChange={handleFileUpload}
              className="hidden"
            />
          </label>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <input
            type="text"
            placeholder="Nama Media"
            value={libName}
            onChange={(e) => setLibName(e.target.value)}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
          <select
            value={libType}
            onChange={(e) => setLibType(e.target.value as MediaType)}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          >
            <option value="image">Gambar</option>
            <option value="video">Video</option>
            <option value="audio">Audio</option>
            <option value="youtube">YouTube URL</option>
          </select>
          <input
            type="text"
            placeholder="URL / Path Media"
            value={libPath}
            onChange={(e) => setLibPath(e.target.value)}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
        </div>
        <button
          type="button"
          onClick={() => {
            if (!libName.trim() || !libPath.trim()) {
              onToast('Nama dan URL media harus diisi');
              return;
            }
            updateSettings({
              media_library: [
                ...settings.media_library,
                {
                  id: String(Date.now()),
                  name: libName.trim(),
                  type: libType,
                  path: libPath.trim(),
                },
              ],
            });
            setLibName('');
            setLibPath('');
            onToast('Media ditambahkan ke library');
          }}
          className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 text-sm font-medium"
        >
          <Plus className="w-4 h-4" /> Tambah ke Library
        </button>

        {settings.media_library.length > 0 && (
          <div className="space-y-2 pt-2">
            {settings.media_library.map((item, idx) => (
              <div
                key={item.id}
                className="flex items-center justify-between bg-black/30 px-3 py-2 rounded-lg text-sm"
              >
                <div className="min-w-0">
                  <span className="font-semibold text-white">{item.name}</span>
                  <span className="ml-2 text-xs px-2 py-0.5 rounded bg-teal-500/20 text-teal-300 uppercase">
                    {item.type}
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => {
                    updateSettings({
                      media_library: settings.media_library.filter(
                        (_, i) => i !== idx,
                      ),
                    });
                    onToast('Media library dihapus');
                  }}
                  className="p-1 text-red-400 hover:text-red-300"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Media Schedules */}
      <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
        <h3 className="font-bold text-lg text-amber-300">Jadwal Putar Media</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <select
            value={schedPath}
            onChange={(e) => {
              const val = e.target.value;
              setSchedPath(val);
              const found = settings.media_library.find((m) => m.path === val);
              if (found) setSchedType(found.type);
            }}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          >
            <option value="">-- Pilih dari Library atau isi URL --</option>
            {settings.media_library.map((m) => (
              <option key={m.id} value={m.path}>
                {m.name} ({m.type})
              </option>
            ))}
          </select>
          <input
            type="text"
            placeholder="Atau URL/Path Manual"
            value={schedPath}
            onChange={(e) => setSchedPath(e.target.value)}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
          <input
            type="time"
            value={schedTime}
            onChange={(e) => setSchedTime(e.target.value)}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
        </div>
        <div className="flex flex-wrap items-center gap-4 text-sm">
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={schedLoop}
              onChange={(e) => setSchedLoop(e.target.checked)}
              className="accent-teal-400"
            />
            Loop Putar
          </label>
          <div className="flex items-center gap-2">
            <span>Jumlah Putar:</span>
            <input
              type="number"
              min={1}
              value={schedCount}
              onChange={(e) => setSchedCount(Number(e.target.value) || 1)}
              className="w-16 px-2 py-1 rounded bg-slate-800 border border-white/20 text-white"
            />
          </div>
          <div className="flex flex-wrap gap-1.5">
            {SHORT_DAYS.map((d) => {
              const active = schedDays.includes(d.id);
              return (
                <button
                  key={d.id}
                  type="button"
                  onClick={() =>
                    setSchedDays((prev) =>
                      active ? prev.filter((x) => x !== d.id) : [...prev, d.id],
                    )
                  }
                  className={`px-2.5 py-1 rounded text-xs ${
                    active ? 'bg-teal-600 text-white' : 'bg-slate-800 text-white/60'
                  }`}
                >
                  {d.label}
                </button>
              );
            })}
          </div>
        </div>
        <button
          type="button"
          onClick={() => {
            if (!schedPath.trim()) {
              onToast('Path media jadwal wajib diisi');
              return;
            }
            updateSettings({
              media_schedules: [
                ...settings.media_schedules,
                {
                  path: schedPath.trim(),
                  type: schedType,
                  time: schedTime,
                  is_loop: schedLoop,
                  play_count: schedCount,
                  days: schedDays,
                },
              ],
            });
            onToast('Jadwal media ditambahkan');
          }}
          className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-sm font-semibold"
        >
          Tambah Jadwal Media
        </button>

        {settings.media_schedules.length > 0 && (
          <div className="space-y-2 pt-2">
            {settings.media_schedules.map((ms, idx) => (
              <div
                key={`${ms.path}-${idx}`}
                className="flex items-center justify-between bg-black/30 px-3 py-2 rounded-lg text-sm"
              >
                <div>
                  <span className="font-bold text-amber-300 tabular-nums">
                    {ms.time}
                  </span>{' '}
                  <span className="text-white/90">{ms.path}</span>
                  <div className="text-xs text-white/55">
                    {ms.type} • {ms.play_count}x • Hari: {ms.days.join(',')}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    updateSettings({
                      media_schedules: settings.media_schedules.filter(
                        (_, i) => i !== idx,
                      ),
                    })
                  }
                  className="p-1 text-red-400 hover:text-red-300"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 7. Murottal Settings View                                                  */
/* -------------------------------------------------------------------------- */
export const MurottalSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [schedules, setSchedules] = useState<MurottalSchedule[]>(
    settings.murottal_schedules,
  );
  const [expandedIdx, setExpandedIdx] = useState<number | null>(0);
  const [surahs, setSurahs] = useState(SURAHS_FALLBACK);

  useEffect(() => {
    setSchedules(settings.murottal_schedules);
  }, [settings.murottal_schedules]);

  useEffect(() => {
    void fetchSurahsEQuran().then((res) => {
      if (res && res.length > 0) setSurahs(res);
    });
  }, []);

  const updateItem = (idx: number, patch: Partial<MurottalSchedule>) => {
    setSchedules((prev) =>
      prev.map((item, i) => (i === idx ? { ...item, ...patch } : item)),
    );
  };

  return (
    <div className="space-y-4 max-w-4xl">
      <div>
        <h2 className="text-2xl font-bold text-white">
          Jadwal Murottal Sebelum Adzan
        </h2>
        <p className="text-sm text-white/70 mt-1">
          Atur pemutaran audio/video murottal, tarhim, dan adzan otomatis sebelum
          waktu sholat.
        </p>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <div className="space-y-3">
        {schedules.map((sched, idx) => {
          const isOpen = expandedIdx === idx;
          return (
            <div
              key={sched.prayer}
              className="rounded-xl bg-white/5 border border-white/15 overflow-hidden"
            >
              <button
                type="button"
                onClick={() => setExpandedIdx(isOpen ? null : idx)}
                className="w-full px-4 py-3 flex items-center justify-between text-left hover:bg-white/5"
              >
                <div>
                  <div className="font-bold text-lg text-white">
                    Pengaturan untuk: {sched.prayer}
                  </div>
                  <div className="text-xs text-white/65">
                    {sched.enabled ? 'Murottal aktif' : 'Murottal nonaktif'}
                    {sched.tarhim_enabled ? ' • Tarhim aktif' : ''}
                    {sched.adzan_enabled ? ' • Adzan aktif' : ''}
                  </div>
                </div>
                {isOpen ? (
                  <ChevronUp className="w-5 h-5 text-white/70" />
                ) : (
                  <ChevronDown className="w-5 h-5 text-white/70" />
                )}
              </button>

              {isOpen && (
                <div className="p-4 pt-2 border-t border-white/10 space-y-3">
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <label className="flex items-center justify-between p-2.5 rounded-lg bg-black/25">
                      <span className="text-sm">Aktifkan Murottal</span>
                      <input
                        type="checkbox"
                        checked={sched.enabled}
                        onChange={(e) =>
                          updateItem(idx, { enabled: e.target.checked })
                        }
                        className="accent-teal-400 w-4 h-4"
                      />
                    </label>
                    <label className="flex items-center justify-between p-2.5 rounded-lg bg-black/25">
                      <span className="text-sm">Aktifkan Tarhim</span>
                      <input
                        type="checkbox"
                        checked={sched.tarhim_enabled}
                        onChange={(e) =>
                          updateItem(idx, { tarhim_enabled: e.target.checked })
                        }
                        className="accent-teal-400 w-4 h-4"
                      />
                    </label>
                    <label className="flex items-center justify-between p-2.5 rounded-lg bg-black/25">
                      <span className="text-sm">Putar Adzan</span>
                      <input
                        type="checkbox"
                        checked={sched.adzan_enabled}
                        onChange={(e) =>
                          updateItem(idx, { adzan_enabled: e.target.checked })
                        }
                        className="accent-teal-400 w-4 h-4"
                      />
                    </label>
                  </div>

                  {sched.tarhim_enabled && (
                    <div>
                      <label className="block text-xs text-white/70 mb-1">
                        Mulai Tarhim (Menit Sebelum Adzan)
                      </label>
                      <input
                        type="number"
                        value={sched.tarhim_minutes_before}
                        onChange={(e) =>
                          updateItem(idx, {
                            tarhim_minutes_before: Number(e.target.value) || 20,
                          })
                        }
                        className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
                      />
                    </div>
                  )}

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs text-white/70 mb-1">
                        Mulai (Menit Sebelum)
                      </label>
                      <input
                        type="number"
                        value={sched.minutes_before}
                        onChange={(e) =>
                          updateItem(idx, {
                            minutes_before: Number(e.target.value) || 10,
                          })
                        }
                        className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-white/70 mb-1">
                        Stop (Menit Sebelum)
                      </label>
                      <input
                        type="number"
                        value={sched.stop_before_adzan}
                        onChange={(e) =>
                          updateItem(idx, {
                            stop_before_adzan: Number(e.target.value) || 2,
                          })
                        }
                        className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs text-white/70 mb-1">
                      Sumber Murottal
                    </label>
                    <select
                      value={sched.source_type}
                      onChange={(e) =>
                        updateItem(idx, {
                          source_type: e.target.value as 'file' | 'api',
                        })
                      }
                      className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
                    >
                      <option value="file">File dari Playlist</option>
                      <option value="api">Streaming Surah (API)</option>
                    </select>
                  </div>

                  {sched.source_type === 'api' ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      <div>
                        <label className="block text-xs text-white/70 mb-1">
                          Pilih Qori
                        </label>
                        <select
                          value={sched.qari || QARIS[0]}
                          onChange={(e) =>
                            updateItem(idx, { qari: e.target.value })
                          }
                          className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
                        >
                          {QARIS.map((q) => (
                            <option key={q} value={q}>
                              {q}
                            </option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <label className="block text-xs text-white/70 mb-1">
                          Pilih Surah
                        </label>
                        <select
                          value={sched.surah_number || 1}
                          onChange={(e) =>
                            updateItem(idx, {
                              surah_number: Number(e.target.value),
                            })
                          }
                          className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
                        >
                          {surahs.map((s) => (
                            <option key={s.nomor} value={s.nomor}>
                              {s.nomor}. {s.namaLatin}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                  ) : (
                    <div>
                      <label className="block text-xs text-white/70 mb-1">
                        Pilih File dari Playlist
                      </label>
                      <select
                        value={sched.path || ''}
                        onChange={(e) =>
                          updateItem(idx, { path: e.target.value })
                        }
                        className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
                      >
                        <option value="">-- Tidak Ada --</option>
                        {settings.media_library
                          .filter((m) => m.type === 'audio' || m.type === 'video')
                          .map((m) => (
                            <option key={m.id} value={m.path}>
                              {m.name}
                            </option>
                          ))}
                      </select>
                    </div>
                  )}

                  <div className="grid grid-cols-2 gap-3">
                    <label className="flex items-center justify-between p-2.5 rounded-lg bg-black/25">
                      <span className="text-sm">Acak?</span>
                      <input
                        type="checkbox"
                        checked={sched.is_random}
                        onChange={(e) =>
                          updateItem(idx, { is_random: e.target.checked })
                        }
                        className="accent-teal-400 w-4 h-4"
                      />
                    </label>
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-white/75">Loop:</span>
                      <input
                        type="number"
                        min={1}
                        value={sched.loop_count}
                        onChange={(e) =>
                          updateItem(idx, {
                            loop_count: Number(e.target.value) || 1,
                          })
                        }
                        className="flex-1 px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
                      />
                    </div>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      <button
        type="button"
        onClick={() => {
          updateSettings({ murottal_schedules: schedules });
          onToast('Jadwal Murottal Disimpan');
        }}
        className="px-6 py-2.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold flex items-center gap-2"
      >
        <Save className="w-4 h-4" /> Simpan
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 8. Hadith Settings View                                                    */
/* -------------------------------------------------------------------------- */
export const HadithSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [text, setText] = useState('');
  const [source, setSource] = useState('');

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Pengaturan Mutiara Hadis</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <label className="flex items-center justify-between p-3.5 rounded-xl bg-white/5 border border-white/15 cursor-pointer">
        <span>Tampilkan Layar Hadis</span>
        <input
          type="checkbox"
          checked={settings.hadith_show}
          onChange={(e) => updateSettings({ hadith_show: e.target.checked })}
          className="w-5 h-5 accent-teal-400"
        />
      </label>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm text-white/75 mb-1">
            Interval Ganti Hadis (Menit)
          </label>
          <input
            type="number"
            min={1}
            value={settings.hadith_interval}
            onChange={(e) =>
              updateSettings({ hadith_interval: Number(e.target.value) || 5 })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>
        <div>
          <label className="block text-sm text-white/75 mb-1">
            Kecepatan Scroll (px/detik)
          </label>
          <input
            type="number"
            min={10}
            max={120}
            value={settings.hadith_speed}
            onChange={(e) =>
              updateSettings({ hadith_speed: Number(e.target.value) || 30 })
            }
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>
      </div>

      <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
        <h3 className="font-bold text-amber-300">Hadis Manual (Cadangan Offline)</h3>
        <textarea
          rows={3}
          placeholder="Isi Teks Hadis"
          value={text}
          onChange={(e) => setText(e.target.value)}
          className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
        />
        <input
          type="text"
          placeholder="Sumber (contoh: HR. Bukhari)"
          value={source}
          onChange={(e) => setSource(e.target.value)}
          className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
        />
        <button
          type="button"
          onClick={() => {
            if (!text.trim() || !source.trim()) {
              onToast('Isi dan sumber hadis wajib diisi');
              return;
            }
            updateSettings({
              custom_hadiths: [
                ...settings.custom_hadiths,
                { text: text.trim(), source: source.trim() },
              ],
            });
            setText('');
            setSource('');
            onToast('Hadis manual ditambahkan');
          }}
          className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-sm font-semibold"
        >
          Tambah Hadis
        </button>

        {settings.custom_hadiths.map((h, idx) => (
          <div
            key={`${h.source}-${idx}`}
            className="flex items-start justify-between bg-black/30 p-3 rounded-lg gap-3 text-sm"
          >
            <div>
              <p className="text-white/90">"{h.text}"</p>
              <p className="text-amber-300 font-semibold mt-1">{h.source}</p>
            </div>
            <button
              type="button"
              onClick={() =>
                updateSettings({
                  custom_hadiths: settings.custom_hadiths.filter(
                    (_, i) => i !== idx,
                  ),
                })
              }
              className="p-1 text-red-400"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 9. Text Settings View                                                      */
/* -------------------------------------------------------------------------- */
export const TextSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [selectedKey, setSelectedKey] = useState('mosque_name');
  const currentStyle = settings.text_styles[selectedKey] ?? {
    size: 20,
    color: 0xffffffff,
    font: 'Roboto',
  };
  const [size, setSize] = useState(currentStyle.size);
  const [color, setColor] = useState(currentStyle.color);
  const [font, setFont] = useState(currentStyle.font);

  useEffect(() => {
    const st = settings.text_styles[selectedKey];
    if (st) {
      setSize(st.size);
      setColor(st.color);
      setFont(st.font);
    }
  }, [selectedKey, settings.text_styles]);

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Pengaturan Teks & Font</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <div>
        <label className="block text-sm text-white/75 mb-1">Pilih Elemen</label>
        <select
          value={selectedKey}
          onChange={(e) => setSelectedKey(e.target.value)}
          className="w-full px-3 py-2.5 rounded-lg bg-slate-800 border border-white/20 text-white"
        >
          {Object.entries(TEXT_STYLE_ELEMENTS).map(([k, label]) => (
            <option key={k} value={k}>
              {label}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="block text-sm text-white/75 mb-1">
          Ukuran Font: <span className="font-bold text-teal-300">{size} px</span>
        </label>
        <input
          type="range"
          min={10}
          max={150}
          value={size}
          onChange={(e) => setSize(Number(e.target.value))}
          className="w-full accent-teal-400"
        />
      </div>

      <div>
        <label className="block text-sm text-white/75 mb-1">Jenis Font</label>
        <select
          value={FONT_FAMILIES.includes(font) ? font : 'Roboto'}
          onChange={(e) => setFont(e.target.value)}
          className="w-full px-3 py-2.5 rounded-lg bg-slate-800 border border-white/20 text-white"
        >
          {FONT_FAMILIES.map((f) => (
            <option key={f} value={f}>
              {f}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="block text-sm text-white/75 mb-2">Warna Teks</label>
        <div className="flex flex-wrap gap-2.5">
          {COLOR_SWATCHES.map((sw) => (
            <button
              key={sw}
              type="button"
              onClick={() => setColor(sw)}
              className="w-10 h-10 rounded-full transition-transform"
              style={{
                backgroundColor: argbToCssRgba(sw),
                border:
                  color === sw ? '3px solid #ffffff' : '1px solid #64748b',
                transform: color === sw ? 'scale(1.1)' : 'scale(1)',
              }}
            />
          ))}
        </div>
      </div>

      <button
        type="button"
        onClick={() => {
          updateSettings({
            text_styles: {
              ...settings.text_styles,
              [selectedKey]: {
                ...(settings.text_styles[selectedKey] ?? {}),
                size,
                color,
                font,
              },
            },
          });
          onToast(`Pengaturan ${TEXT_STYLE_ELEMENTS[selectedKey]} disimpan`);
        }}
        className="w-full py-2.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold"
      >
        Simpan Perubahan
      </button>

      <div className="p-4 bg-black rounded-xl border border-white/15 flex items-center justify-center min-h-[100px] overflow-hidden">
        <span
          style={{
            fontSize: `${Math.min(72, size)}px`,
            color: argbToCssRgba(color),
            fontFamily: `'${font}', sans-serif`,
          }}
        >
          Contoh Tampilan Teks
        </span>
      </div>
    </div>
  );
};
