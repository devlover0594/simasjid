import React, { useEffect, useState } from 'react';
import { QARIS, SHORT_DAYS, SURAHS_FALLBACK } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { fetchSurahsEQuran } from '../../services/apiRepository';
import type { MediaType, MurottalSchedule } from '../../types/simasjid';
import {
  detectMediaTypeFromFileName,
  readImageAsDataUrl,
} from '../settings/fileHelper';

interface AdminToastProps {
  onToast: (msg: string) => void;
}

/* -------------------------------------------------------------------------- */
/* 6. Media                                                                   */
/* -------------------------------------------------------------------------- */
export const AdminMediaSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [libName, setLibName] = useState('');
  const [libPath, setLibPath] = useState('');
  const [libType, setLibType] = useState<MediaType>('image');
  const [libEditIdx, setLibEditIdx] = useState<number | null>(null);

  const [schedPath, setSchedPath] = useState('');
  const [schedType, setSchedType] = useState<MediaType>('image');
  const [schedTime, setSchedTime] = useState('12:00');
  const [schedLoop, setSchedLoop] = useState(false);
  const [schedCount, setSchedCount] = useState(1);
  const [schedDays, setSchedDays] = useState<number[]>([1, 2, 3, 4, 5, 6, 7]);
  const [schedEditIdx, setSchedEditIdx] = useState<number | null>(null);

  const handleBatchUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? []);
    if (files.length === 0) return;
    const items = [];
    for (const f of files) {
      const type = detectMediaTypeFromFileName(f.name);
      const path =
        type === 'image'
          ? await readImageAsDataUrl(f)
          : URL.createObjectURL(f);
      items.push({
        id: `${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        name: f.name,
        path,
        type,
      });
    }
    updateSettings({ media_library: [...settings.media_library, ...items] });
    onToast(`${items.length} file media ditambahkan!`);
    e.target.value = '';
  };

  return (
    <div className="max-w-[960px] mx-auto space-y-5">
      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
            <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
            Media Library (Playlist)
          </h2>
          <label className="px-3.5 py-2 rounded-lg bg-teal-50 border border-teal-200 text-teal-800 text-xs font-semibold cursor-pointer">
            + Impor File Media
            <input
              type="file"
              multiple
              accept="image/*,video/*,audio/*"
              onChange={handleBatchUpload}
              className="hidden"
            />
          </label>
        </div>

        <label className="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-slate-200 cursor-pointer">
          <span className="text-sm font-semibold text-slate-700">
            Putar Media Library dalam Rotasi Layar TV (Slideshow)
          </span>
          <input
            type="checkbox"
            checked={settings.media_slideshow_enabled}
            onChange={(e) =>
              updateSettings({ media_slideshow_enabled: e.target.checked })
            }
            className="w-5 h-5 accent-teal-600"
          />
        </label>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <input
            type="text"
            placeholder="Nama Media"
            value={libName}
            onChange={(e) => setLibName(e.target.value)}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-sm"
          />
          <select
            value={libType}
            onChange={(e) => setLibType(e.target.value as MediaType)}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-sm"
          >
            <option value="image">Image</option>
            <option value="video">Video</option>
            <option value="audio">Audio</option>
            <option value="youtube">YouTube</option>
          </select>
          <input
            type="text"
            placeholder="URL / Path Media"
            value={libPath}
            onChange={(e) => setLibPath(e.target.value)}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-sm"
          />
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => {
              if (!libName.trim() || !libPath.trim()) {
                onToast('Nama dan path media wajib diisi!');
                return;
              }
              const next = [...settings.media_library];
              const item = {
                id:
                  libEditIdx !== null
                    ? next[libEditIdx].id
                    : String(Date.now()),
                name: libName.trim(),
                path: libPath.trim(),
                type: libType,
              };
              if (libEditIdx !== null) next[libEditIdx] = item;
              else next.push(item);
              updateSettings({ media_library: next });
              setLibName('');
              setLibPath('');
              setLibEditIdx(null);
              onToast('Media library disimpan!');
            }}
            className="flex-1 py-2.5 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
          >
            {libEditIdx !== null ? 'Update Media Library' : 'Tambah ke Library'}
          </button>
          {libEditIdx !== null && (
            <button
              type="button"
              onClick={() => {
                setLibName('');
                setLibPath('');
                setLibEditIdx(null);
              }}
              className="px-4 py-2.5 rounded-[10px] bg-slate-100 text-slate-700 text-sm font-semibold"
            >
              Batal
            </button>
          )}
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-sm border-collapse">
            <thead>
              <tr className="border-b-2 border-slate-200 text-left text-xs uppercase text-slate-500">
                <th className="py-2 px-3">#</th>
                <th className="py-2 px-3">Nama & Tipe</th>
                <th className="py-2 px-3">Sumber</th>
                <th className="py-2 px-3 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody>
              {settings.media_library.map((m, i) => (
                <tr key={m.id} className="border-b border-slate-100">
                  <td className="py-2.5 px-3">{i + 1}</td>
                  <td className="py-2.5 px-3">
                    <div className="font-bold text-slate-800">{m.name}</div>
                    <span className="text-[11px] uppercase px-2 py-0.5 rounded-full bg-teal-50 text-teal-700 font-semibold">
                      {m.type}
                    </span>
                  </td>
                  <td className="py-2.5 px-3 text-xs text-slate-500 max-w-[260px] truncate">
                    {m.path.startsWith('data:') ? '[File Lokal]' : m.path}
                  </td>
                  <td className="py-2.5 px-3 text-right whitespace-nowrap">
                    <button
                      type="button"
                      onClick={() => {
                        setLibName(m.name);
                        setLibPath(m.path);
                        setLibType(m.type);
                        setLibEditIdx(i);
                      }}
                      className="px-2.5 py-1 rounded bg-slate-100 text-xs font-semibold mr-2"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        updateSettings({
                          media_library: settings.media_library.filter(
                            (_, idx) => idx !== i,
                          ),
                        });
                        onToast('Media dihapus!');
                      }}
                      className="px-2.5 py-1 rounded bg-red-50 text-red-600 text-xs font-semibold"
                    >
                      Hapus
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Scheduled Media */}
      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h3 className="font-bold text-slate-900">Jadwal Putar Media Otomatis</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <select
            value={schedPath}
            onChange={(e) => {
              setSchedPath(e.target.value);
              const found = settings.media_library.find(
                (m) => m.path === e.target.value,
              );
              if (found) setSchedType(found.type);
            }}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-sm"
          >
            <option value="">-- Pilih dari Library --</option>
            {settings.media_library.map((m) => (
              <option key={m.id} value={m.path}>
                {m.name}
              </option>
            ))}
          </select>
          <input
            type="text"
            placeholder="URL / Path Media"
            value={schedPath}
            onChange={(e) => setSchedPath(e.target.value)}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-sm"
          />
          <input
            type="time"
            value={schedTime}
            onChange={(e) => setSchedTime(e.target.value)}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-sm"
          />
        </div>

        <div className="flex flex-wrap items-center gap-4 text-sm">
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={schedLoop}
              onChange={(e) => setSchedLoop(e.target.checked)}
              className="accent-teal-600"
            />
            Loop Putar
          </label>
          <div className="flex items-center gap-2">
            <span>Putar:</span>
            <input
              type="number"
              min={1}
              value={schedCount}
              onChange={(e) => setSchedCount(Number(e.target.value) || 1)}
              className="w-16 px-2 py-1 bg-slate-50 border border-slate-200 rounded-lg"
            />
            <span>kali</span>
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
                  className={`px-2.5 py-1 rounded-full text-xs font-medium border ${
                    active
                      ? 'bg-teal-600 text-white border-teal-600'
                      : 'bg-slate-50 text-slate-600 border-slate-200'
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
              onToast('Path media tidak boleh kosong!');
              return;
            }
            const next = [...settings.media_schedules];
            const item = {
              path: schedPath.trim(),
              type: schedType,
              time: schedTime,
              is_loop: schedLoop,
              play_count: schedCount,
              days: schedDays,
            };
            if (schedEditIdx !== null) next[schedEditIdx] = item;
            else next.push(item);
            updateSettings({ media_schedules: next });
            setSchedPath('');
            setSchedEditIdx(null);
            onToast('Jadwal media disimpan!');
          }}
          className="w-full py-2.5 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
        >
          {schedEditIdx !== null ? 'Update Jadwal Media' : 'Tambah Jadwal Media'}
        </button>

        {settings.media_schedules.length > 0 && (
          <table className="w-full text-sm border-collapse">
            <thead>
              <tr className="border-b-2 border-slate-200 text-left text-xs uppercase text-slate-500">
                <th className="py-2 px-3">#</th>
                <th className="py-2 px-3">Media</th>
                <th className="py-2 px-3">Jadwal</th>
                <th className="py-2 px-3 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody>
              {settings.media_schedules.map((ms, i) => (
                <tr key={`${ms.path}-${i}`} className="border-b border-slate-100">
                  <td className="py-2.5 px-3">{i + 1}</td>
                  <td className="py-2.5 px-3">
                    <span className="text-[11px] uppercase px-2 py-0.5 rounded-full bg-teal-50 text-teal-700 font-semibold">
                      {ms.type}
                    </span>
                    <div className="text-xs text-slate-600 truncate max-w-[240px]">
                      {ms.path}
                    </div>
                  </td>
                  <td className="py-2.5 px-3">
                    <span className="font-semibold tabular-nums">{ms.time}</span>{' '}
                    ({ms.play_count}x)
                  </td>
                  <td className="py-2.5 px-3 text-right whitespace-nowrap">
                    <button
                      type="button"
                      onClick={() => {
                        setSchedPath(ms.path);
                        setSchedType(ms.type);
                        setSchedTime(ms.time);
                        setSchedLoop(ms.is_loop);
                        setSchedCount(ms.play_count);
                        setSchedDays(ms.days);
                        setSchedEditIdx(i);
                      }}
                      className="px-2.5 py-1 rounded bg-slate-100 text-xs font-semibold mr-2"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() =>
                        updateSettings({
                          media_schedules: settings.media_schedules.filter(
                            (_, idx) => idx !== i,
                          ),
                        })
                      }
                      className="px-2.5 py-1 rounded bg-red-50 text-red-600 text-xs font-semibold"
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
/* 7. Murottal                                                                */
/* -------------------------------------------------------------------------- */
export const AdminMurottalSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [schedules, setSchedules] = useState<MurottalSchedule[]>(
    settings.murottal_schedules,
  );
  const [openIndex, setOpenIndex] = useState<number | null>(0);
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
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Murottal, Tarhim & Adzan Otomatis
      </h2>

      <div className="space-y-3">
        {schedules.map((s, idx) => {
          const isOpen = openIndex === idx;
          return (
            <div
              key={s.prayer}
              className="border border-slate-200 rounded-[10px] overflow-hidden"
            >
              <button
                type="button"
                onClick={() => setOpenIndex(isOpen ? null : idx)}
                className="w-full px-4 py-3 bg-slate-50 hover:bg-teal-50 flex items-center justify-between font-bold text-slate-900"
              >
                <span>{s.prayer}</span>
                <span className="text-teal-600 text-lg">{isOpen ? '−' : '+'}</span>
              </button>

              {isOpen && (
                <div className="p-4 border-t border-slate-200 space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Aktifkan Tarhim
                      </label>
                      <select
                        value={String(s.tarhim_enabled)}
                        onChange={(e) =>
                          updateItem(idx, {
                            tarhim_enabled: e.target.value === 'true',
                          })
                        }
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                      >
                        <option value="true">Ya</option>
                        <option value="false">Tidak</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Mulai Tarhim (Menit Sebelum Adzan)
                      </label>
                      <input
                        type="number"
                        value={s.tarhim_minutes_before}
                        onChange={(e) =>
                          updateItem(idx, {
                            tarhim_minutes_before: Number(e.target.value) || 20,
                          })
                        }
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Putar Audio Adzan
                      </label>
                      <select
                        value={String(s.adzan_enabled)}
                        onChange={(e) =>
                          updateItem(idx, {
                            adzan_enabled: e.target.value === 'true',
                          })
                        }
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                      >
                        <option value="true">Ya</option>
                        <option value="false">Tidak</option>
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Aktifkan Murottal
                      </label>
                      <select
                        value={String(s.enabled)}
                        onChange={(e) =>
                          updateItem(idx, { enabled: e.target.value === 'true' })
                        }
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                      >
                        <option value="true">Ya</option>
                        <option value="false">Tidak</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Mulai (Menit Sebelum)
                      </label>
                      <input
                        type="number"
                        value={s.minutes_before}
                        onChange={(e) =>
                          updateItem(idx, {
                            minutes_before: Number(e.target.value) || 10,
                          })
                        }
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Berhenti (Menit Sebelum)
                      </label>
                      <input
                        type="number"
                        value={s.stop_before_adzan}
                        onChange={(e) =>
                          updateItem(idx, {
                            stop_before_adzan: Number(e.target.value) || 2,
                          })
                        }
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-500 mb-1">
                      Sumber Murottal
                    </label>
                    <select
                      value={s.source_type}
                      onChange={(e) =>
                        updateItem(idx, {
                          source_type: e.target.value as 'file' | 'api',
                        })
                      }
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                    >
                      <option value="file">File dari Playlist</option>
                      <option value="api">Streaming Surah (API)</option>
                    </select>
                  </div>

                  {s.source_type === 'api' ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      <div>
                        <label className="block text-xs font-semibold text-slate-500 mb-1">
                          Pilih Qori
                        </label>
                        <select
                          value={s.qari || QARIS[0]}
                          onChange={(e) => updateItem(idx, { qari: e.target.value })}
                          className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                        >
                          {QARIS.map((q) => (
                            <option key={q} value={q}>
                              {q}
                            </option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <label className="block text-xs font-semibold text-slate-500 mb-1">
                          Pilih Surah
                        </label>
                        <select
                          value={s.surah_number || 1}
                          onChange={(e) =>
                            updateItem(idx, {
                              surah_number: Number(e.target.value),
                            })
                          }
                          className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                        >
                          {surahs.map((su) => (
                            <option key={su.nomor} value={su.nomor}>
                              {su.nomor}. {su.namaLatin}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                  ) : (
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Pilih File Playlist
                      </label>
                      <select
                        value={s.path || ''}
                        onChange={(e) => updateItem(idx, { path: e.target.value })}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
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
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Acak?
                      </label>
                      <select
                        value={String(s.is_random)}
                        onChange={(e) =>
                          updateItem(idx, { is_random: e.target.value === 'true' })
                        }
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                      >
                        <option value="false">Tidak</option>
                        <option value="true">Ya</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-500 mb-1">
                        Loop
                      </label>
                      <input
                        type="number"
                        min={1}
                        value={s.loop_count}
                        onChange={(e) =>
                          updateItem(idx, {
                            loop_count: Number(e.target.value) || 1,
                          })
                        }
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm"
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
          onToast('Semua jadwal murottal disimpan!');
        }}
        className="w-full py-3 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
      >
        Simpan Jadwal Murottal
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 8. Hadis                                                                   */
/* -------------------------------------------------------------------------- */
export const AdminHadisSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [text, setText] = useState('');
  const [source, setSource] = useState('');
  const [editIdx, setEditIdx] = useState<number | null>(null);

  return (
    <div className="max-w-[960px] mx-auto space-y-5">
      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
          <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
          Pengaturan Hadis
        </h2>

        <label className="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-slate-200 cursor-pointer">
          <span className="text-sm font-semibold text-slate-700">
            Tampilkan Layar Hadis
          </span>
          <input
            type="checkbox"
            checked={settings.hadith_show}
            onChange={(e) => updateSettings({ hadith_show: e.target.checked })}
            className="w-5 h-5 accent-teal-600"
          />
        </label>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1">
              Interval Ganti Hadis (Menit)
            </label>
            <input
              type="number"
              min={1}
              value={settings.hadith_interval}
              onChange={(e) =>
                updateSettings({ hadith_interval: Number(e.target.value) || 5 })
              }
              className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1">
              Kecepatan Scroll (px/s)
            </label>
            <input
              type="number"
              min={10}
              value={settings.hadith_speed}
              onChange={(e) =>
                updateSettings({ hadith_speed: Number(e.target.value) || 30 })
              }
              className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
            />
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h3 className="font-bold text-slate-900">Hadis Manual (Offline)</h3>
        <textarea
          rows={3}
          placeholder="Isi Teks Hadis"
          value={text}
          onChange={(e) => setText(e.target.value)}
          className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
        />
        <input
          type="text"
          placeholder="Sumber (HR. Bukhari, dll)"
          value={source}
          onChange={(e) => setSource(e.target.value)}
          className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
        />
        <button
          type="button"
          onClick={() => {
            if (!text.trim() || !source.trim()) {
              onToast('Teks dan sumber hadis wajib diisi!');
              return;
            }
            const next = [...settings.custom_hadiths];
            const item = { text: text.trim(), source: source.trim() };
            if (editIdx !== null) next[editIdx] = item;
            else next.push(item);
            updateSettings({ custom_hadiths: next });
            setText('');
            setSource('');
            setEditIdx(null);
            onToast('Hadis manual disimpan!');
          }}
          className="w-full py-2.5 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
        >
          {editIdx !== null ? 'Update Hadis' : 'Tambah Hadis'}
        </button>

        {settings.custom_hadiths.length > 0 && (
          <table className="w-full text-sm border-collapse">
            <tbody>
              {settings.custom_hadiths.map((h, i) => (
                <tr key={`${h.source}-${i}`} className="border-b border-slate-100">
                  <td className="py-2.5 px-2">{i + 1}</td>
                  <td className="py-2.5 px-2">
                    <div>{h.text}</div>
                    <div className="text-xs font-bold text-teal-700">{h.source}</div>
                  </td>
                  <td className="py-2.5 px-2 text-right whitespace-nowrap">
                    <button
                      type="button"
                      onClick={() => {
                        setText(h.text);
                        setSource(h.source);
                        setEditIdx(i);
                      }}
                      className="px-2.5 py-1 rounded bg-slate-100 text-xs font-semibold mr-2"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() =>
                        updateSettings({
                          custom_hadiths: settings.custom_hadiths.filter(
                            (_, idx) => idx !== i,
                          ),
                        })
                      }
                      className="px-2.5 py-1 rounded bg-red-50 text-red-600 text-xs font-semibold"
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
/* 9. Agenda                                                                  */
/* -------------------------------------------------------------------------- */
export const AdminAgendaSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [title, setTitle] = useState('');
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [editIdx, setEditIdx] = useState<number | null>(null);

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Agenda Kegiatan
      </h2>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <input
          type="text"
          placeholder="Nama Kegiatan"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="sm:col-span-2 px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
        />
        <input
          type="date"
          value={date}
          onChange={(e) => setDate(e.target.value)}
          className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
        />
      </div>

      <button
        type="button"
        onClick={() => {
          if (!title.trim() || !date) {
            onToast('Judul dan tanggal wajib diisi!');
            return;
          }
          const next = [...settings.events];
          const item = { title: title.trim(), date };
          if (editIdx !== null) next[editIdx] = item;
          else next.push(item);
          updateSettings({ events: next });
          setTitle('');
          setEditIdx(null);
          onToast('Agenda kegiatan disimpan!');
        }}
        className="w-full py-2.5 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
      >
        {editIdx !== null ? 'Update Agenda' : 'Tambah Agenda'}
      </button>

      {settings.events.length > 0 && (
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b-2 border-slate-200 text-left text-xs uppercase text-slate-500">
              <th className="py-2 px-3">#</th>
              <th className="py-2 px-3">Judul</th>
              <th className="py-2 px-3">Tanggal</th>
              <th className="py-2 px-3 text-right">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {settings.events.map((ev, i) => (
              <tr key={`${ev.title}-${i}`} className="border-b border-slate-100">
                <td className="py-2.5 px-3">{i + 1}</td>
                <td className="py-2.5 px-3 font-medium text-slate-800">{ev.title}</td>
                <td className="py-2.5 px-3">{ev.date}</td>
                <td className="py-2.5 px-3 text-right whitespace-nowrap">
                  <button
                    type="button"
                    onClick={() => {
                      setTitle(ev.title);
                      setDate(ev.date);
                      setEditIdx(i);
                    }}
                    className="px-2.5 py-1 rounded bg-slate-100 text-xs font-semibold mr-2"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    onClick={() =>
                      updateSettings({
                        events: settings.events.filter((_, idx) => idx !== i),
                      })
                    }
                    className="px-2.5 py-1 rounded bg-red-50 text-red-600 text-xs font-semibold"
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
  );
};

/* -------------------------------------------------------------------------- */
/* 10. Petugas                                                                */
/* -------------------------------------------------------------------------- */
export const AdminPetugasSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [pName, setPName] = useState('');
  const [pRole, setPRole] = useState('');
  const [pPhoto, setPPhoto] = useState('');
  const [pEditIdx, setPEditIdx] = useState<number | null>(null);

  const [sName, setSName] = useState('');
  const [sDate, setSDate] = useState(new Date().toISOString().slice(0, 10));
  const [sEndDate, setSEndDate] = useState('');
  const [sIds, setSIds] = useState<string[]>([]);
  const [sEditIdx, setSEditIdx] = useState<number | null>(null);

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (!f) return;
    const url = await readImageAsDataUrl(f, 600);
    setPPhoto(url);
    e.target.value = '';
  };

  return (
    <div className="max-w-[960px] mx-auto space-y-5">
      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
          <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
          Profil Petugas
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <input
            type="text"
            placeholder="Nama Petugas"
            value={pName}
            onChange={(e) => setPName(e.target.value)}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
          <input
            type="text"
            placeholder="Peran (Imam / Khotib / Bilal)"
            value={pRole}
            onChange={(e) => setPRole(e.target.value)}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div className="flex gap-2 items-center">
          <input
            type="text"
            placeholder="URL Foto (opsional)"
            value={pPhoto.startsWith('data:') ? '[Foto Lokal]' : pPhoto}
            onChange={(e) => setPPhoto(e.target.value)}
            className="flex-1 px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-sm"
          />
          <label className="px-3.5 py-2 rounded-lg bg-slate-100 border border-slate-200 text-xs font-semibold cursor-pointer">
            Upload Foto
            <input
              type="file"
              accept="image/*"
              onChange={handlePhotoUpload}
              className="hidden"
            />
          </label>
        </div>

        <button
          type="button"
          onClick={() => {
            if (!pName.trim() || !pRole.trim()) {
              onToast('Nama dan peran petugas wajib diisi!');
              return;
            }
            const next = [...settings.performer_profiles];
            const item = {
              id:
                pEditIdx !== null
                  ? next[pEditIdx].id
                  : String(Date.now()),
              name: pName.trim(),
              role: pRole.trim(),
              photoPath: pPhoto.trim(),
            };
            if (pEditIdx !== null) next[pEditIdx] = item;
            else next.push(item);
            updateSettings({ performer_profiles: next });
            setPName('');
            setPRole('');
            setPPhoto('');
            setPEditIdx(null);
            onToast('Profil petugas disimpan!');
          }}
          className="w-full py-2.5 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
        >
          {pEditIdx !== null ? 'Update Petugas' : 'Tambah Petugas'}
        </button>

        {settings.performer_profiles.length > 0 && (
          <table className="w-full text-sm border-collapse">
            <tbody>
              {settings.performer_profiles.map((p, i) => (
                <tr key={p.id} className="border-b border-slate-100">
                  <td className="py-2.5 px-2">{i + 1}</td>
                  <td className="py-2.5 px-2">
                    <div className="font-bold text-slate-900">{p.name}</div>
                    <div className="text-xs text-slate-500">{p.role}</div>
                  </td>
                  <td className="py-2.5 px-2 text-right whitespace-nowrap">
                    <button
                      type="button"
                      onClick={() => {
                        setPName(p.name);
                        setPRole(p.role);
                        setPPhoto(p.photoPath);
                        setPEditIdx(i);
                      }}
                      className="px-2.5 py-1 rounded bg-slate-100 text-xs font-semibold mr-2"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() =>
                        updateSettings({
                          performer_profiles: settings.performer_profiles.filter(
                            (_, idx) => idx !== i,
                          ),
                        })
                      }
                      className="px-2.5 py-1 rounded bg-red-50 text-red-600 text-xs font-semibold"
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

      {/* Jadwal Petugas */}
      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h3 className="font-bold text-slate-900">Jadwal Petugas</h3>
        <input
          type="text"
          placeholder="Nama Acara (mis: Sholat Jumat)"
          value={sName}
          onChange={(e) => setSName(e.target.value)}
          className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
        />
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1">
              Tanggal Mulai
            </label>
            <input
              type="date"
              value={sDate}
              onChange={(e) => setSDate(e.target.value)}
              className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1">
              Tanggal Selesai
            </label>
            <input
              type="date"
              value={sEndDate}
              onChange={(e) => setSEndDate(e.target.value)}
              className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
            />
          </div>
        </div>

        <div className="flex flex-wrap gap-2">
          {settings.performer_profiles.map((p) => {
            const active = sIds.includes(p.id);
            return (
              <label
                key={p.id}
                className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer ${
                  active
                    ? 'bg-teal-50 border-teal-600 text-teal-800'
                    : 'bg-slate-50 border-slate-200 text-slate-700'
                }`}
              >
                <input
                  type="checkbox"
                  checked={active}
                  onChange={() =>
                    setSIds((prev) =>
                      active ? prev.filter((id) => id !== p.id) : [...prev, p.id],
                    )
                  }
                  className="accent-teal-600"
                />
                {p.name} ({p.role})
              </label>
            );
          })}
        </div>

        <button
          type="button"
          onClick={() => {
            if (!sName.trim() || !sDate) {
              onToast('Nama acara dan tanggal wajib diisi!');
              return;
            }
            const next = [...settings.performer_schedules];
            const item = {
              name: sName.trim(),
              date: sDate,
              endDate: sEndDate || sDate,
              performerIds: sIds,
            };
            if (sEditIdx !== null) next[sEditIdx] = item;
            else next.push(item);
            updateSettings({ performer_schedules: next });
            setSName('');
            setSIds([]);
            setSEditIdx(null);
            onToast('Jadwal petugas disimpan!');
          }}
          className="w-full py-2.5 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
        >
          {sEditIdx !== null ? 'Update Jadwal Petugas' : 'Tambah Jadwal Petugas'}
        </button>

        {settings.performer_schedules.length > 0 && (
          <table className="w-full text-sm border-collapse">
            <tbody>
              {settings.performer_schedules.map((sch, i) => {
                const names = settings.performer_profiles
                  .filter((p) => sch.performerIds.includes(p.id))
                  .map((p) => p.name)
                  .join(', ');
                return (
                  <tr key={`${sch.name}-${i}`} className="border-b border-slate-100">
                    <td className="py-2.5 px-2">
                      <div className="font-bold text-slate-900">{sch.name}</div>
                      <div className="text-xs text-slate-500">
                        {sch.date} s/d {sch.endDate || sch.date}
                      </div>
                    </td>
                    <td className="py-2.5 px-2 text-slate-700">{names || '-'}</td>
                    <td className="py-2.5 px-2 text-right whitespace-nowrap">
                      <button
                        type="button"
                        onClick={() => {
                          setSName(sch.name);
                          setSDate(sch.date);
                          setSEndDate(sch.endDate || sch.date);
                          setSIds(sch.performerIds);
                          setSEditIdx(i);
                        }}
                        className="px-2.5 py-1 rounded bg-slate-100 text-xs font-semibold mr-2"
                      >
                        Edit
                      </button>
                      <button
                        type="button"
                        onClick={() =>
                          updateSettings({
                            performer_schedules:
                              settings.performer_schedules.filter(
                                (_, idx) => idx !== i,
                              ),
                          })
                        }
                        className="px-2.5 py-1 rounded bg-red-50 text-red-600 text-xs font-semibold"
                      >
                        Hapus
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
