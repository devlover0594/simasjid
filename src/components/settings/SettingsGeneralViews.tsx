import React, { useEffect, useState } from 'react';
import {
  CheckCircle2,
  Download,
  ExternalLink,
  MapPin,
  MinusCircle,
  PlusCircle,
  RefreshCw,
  RotateCcw,
  Save,
  Search,
  Trash2,
  Upload,
  X,
} from 'lucide-react';
import {
  argbToHex,
  THEME_PRESETS,
} from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { fetchCities } from '../../services/apiRepository';
import { exportBackupJson } from '../../services/storageService';
import type { ApiProvider, CityItem, SlideshowEffect } from '../../types/simasjid';
import { readImageAsDataUrl } from './fileHelper';

interface ToastProps {
  onToast: (msg: string) => void;
}

/* -------------------------------------------------------------------------- */
/* 0. Identity Settings View                                                  */
/* -------------------------------------------------------------------------- */
export const IdentitySettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const {
    settings,
    updateSettings,
    restoreBackup,
    resetSettings,
    openAdmin,
  } = useKiosk();
  const [name, setName] = useState(settings.mosque_name);
  const [address, setAddress] = useState(settings.mosque_address);
  const [confirmResetOpen, setConfirmResetOpen] = useState(false);

  useEffect(() => {
    setName(settings.mosque_name);
    setAddress(settings.mosque_address);
  }, [settings.mosque_name, settings.mosque_address]);

  const handleSave = () => {
    updateSettings({
      mosque_name: name.trim() || 'MASJID AL MUNTAHA',
      mosque_address: address.trim(),
    });
    onToast('Identitas masjid disimpan');
  };

  const handleBackup = () => {
    const json = exportBackupJson(settings);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `simasjid_backup_${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    onToast('Backup JSON berhasil diunduh');
  };

  const handleRestore = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const text = await file.text();
      restoreBackup(text);
      onToast('Restore berhasil diterapkan!');
    } catch {
      onToast('File backup tidak valid');
    }
    e.target.value = '';
  };

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Identitas Masjid</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <div className="space-y-4">
        <div>
          <label className="block text-sm text-white/75 mb-1">Nama Masjid</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-3.5 py-2.5 rounded-lg bg-slate-800 border border-white/20 text-white focus:border-teal-400 outline-none"
          />
        </div>
        <div>
          <label className="block text-sm text-white/75 mb-1">Alamat</label>
          <input
            type="text"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            className="w-full px-3.5 py-2.5 rounded-lg bg-slate-800 border border-white/20 text-white focus:border-teal-400 outline-none"
          />
        </div>
      </div>

      <div className="p-4 rounded-xl bg-teal-500/15 border border-teal-400/50 text-center space-y-2">
        <p className="text-amber-300 font-bold text-sm">
          ID Display: <span className="font-mono">{settings.displayId}</span>
        </p>
        <p className="text-white/85 text-sm">
          Ingin mengedit semua pengaturan dari dashboard web yang lebih lengkap?
        </p>
        <button
          type="button"
          onClick={openAdmin}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold text-sm transition-colors"
        >
          <ExternalLink className="w-4 h-4" /> Buka Panel Web Admin
        </button>
      </div>

      <button
        type="button"
        onClick={handleSave}
        className="w-full py-2.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold flex items-center justify-center gap-2"
      >
        <Save className="w-4 h-4" /> Simpan
      </button>

      <div className="pt-4 border-t border-white/15 space-y-3">
        <h3 className="font-bold text-white/90">Manajemen Data</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <button
            type="button"
            onClick={handleBackup}
            className="py-2.5 px-4 rounded-lg bg-slate-700 hover:bg-slate-600 text-white font-medium flex items-center justify-center gap-2"
          >
            <Download className="w-4 h-4" /> Backup Pengaturan
          </button>
          <label className="py-2.5 px-4 rounded-lg bg-teal-700 hover:bg-teal-600 text-white font-medium flex items-center justify-center gap-2 cursor-pointer">
            <Upload className="w-4 h-4" /> Restore Pengaturan
            <input
              type="file"
              accept=".json,application/json"
              onChange={handleRestore}
              className="hidden"
            />
          </label>
        </div>
      </div>

      <div className="pt-4 border-t border-red-500/40 space-y-3">
        <h3 className="font-bold text-red-400">Zona Bahaya</h3>
        <button
          type="button"
          onClick={() => setConfirmResetOpen(true)}
          className="w-full py-2.5 rounded-lg bg-red-600/90 hover:bg-red-600 text-white font-semibold flex items-center justify-center gap-2"
        >
          <RotateCcw className="w-4 h-4" /> Reset Semua Pengaturan ke Awal
        </button>
      </div>

      {confirmResetOpen && (
        <div className="fixed inset-0 z-50 bg-black/75 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-white/20 rounded-xl max-w-md w-full p-6 space-y-4">
            <h4 className="text-lg font-bold text-white">Reset ke default?</h4>
            <p className="text-sm text-white/75">
              PERINGATAN: Semua pengaturan akan dihapus dan dikembalikan ke awal.
            </p>
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setConfirmResetOpen(false)}
                className="px-4 py-2 rounded-lg bg-slate-700 text-white text-sm"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={() => {
                  resetSettings();
                  setConfirmResetOpen(false);
                  onToast('Pengaturan direset ke awal');
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
/* 1. Prayer Settings View + City Modal                                       */
/* -------------------------------------------------------------------------- */
export const PrayerSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, prayerTimes, updateSettings, refreshPrayerTimes } =
    useKiosk();
  const [manualTimes, setManualTimes] = useState(
    prayerTimes.map((p) => ({ ...p })),
  );
  const [apiStatus, setApiStatus] = useState('Belum dicek');
  const [checking, setChecking] = useState(false);
  const [cityModalOpen, setCityModalOpen] = useState(false);
  const [cities, setCities] = useState<CityItem[]>([]);
  const [citySearch, setCitySearch] = useState('');
  const [loadingCities, setLoadingCities] = useState(false);

  useEffect(() => {
    setManualTimes(prayerTimes.map((p) => ({ ...p })));
  }, [prayerTimes]);

  const handleCheckApi = async () => {
    if (!settings.use_api_prayer_times) {
      setApiStatus('Mode Manual Aktif');
      return;
    }
    setChecking(true);
    setApiStatus('Sedang mengecek...');
    const ok = await refreshPrayerTimes();
    setChecking(false);
    setApiStatus(ok ? 'Berhasil terhubung' : 'Gagal (Gunakan Data Offline)');
  };

  const openCityPicker = async () => {
    setCityModalOpen(true);
    if (cities.length === 0) {
      setLoadingCities(true);
      const list = await fetchCities();
      setCities(list ?? []);
      setLoadingCities(false);
    }
  };

  const filteredCities = cities.filter((c) =>
    c.lokasi.toLowerCase().includes(citySearch.toLowerCase()),
  );

  return (
    <div className="space-y-4 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Jadwal Sholat</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <label className="flex items-center justify-between p-3.5 rounded-xl bg-white/5 border border-white/15 cursor-pointer">
        <div>
          <div className="font-semibold text-white">
            Gunakan Jadwal API (MyQuran / AlAdhan / EQuran)
          </div>
          <div className="text-xs text-white/65">
            Jika aktif, jadwal diambil dari API berdasarkan kota yang dipilih
          </div>
        </div>
        <input
          type="checkbox"
          checked={settings.use_api_prayer_times}
          onChange={(e) => {
            updateSettings({ use_api_prayer_times: e.target.checked });
            onToast(
              e.target.checked
                ? 'Jadwal API diaktifkan'
                : 'Jadwal manual diaktifkan',
            );
          }}
          className="w-5 h-5 accent-teal-400"
        />
      </label>

      {settings.use_api_prayer_times && (
        <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div>
              <label className="block text-xs text-white/65 mb-1">
                Server API
              </label>
              <select
                value={settings.api_provider}
                onChange={(e) =>
                  updateSettings({
                    api_provider: e.target.value as ApiProvider,
                  })
                }
                className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
              >
                <option value="MyQuran">MyQuran</option>
                <option value="AlAdhan">AlAdhan</option>
                <option value="EQuran">EQuran.id</option>
              </select>
            </div>

            <div>
              <span className="block text-xs text-white/65 mb-1">
                Adj. Hijriyah
              </span>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() =>
                    updateSettings({
                      hijri_adjustment: settings.hijri_adjustment - 1,
                    })
                  }
                  className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-teal-300"
                >
                  <MinusCircle className="w-5 h-5" />
                </button>
                <span className="font-bold min-w-[60px] text-center">
                  {settings.hijri_adjustment} Hari
                </span>
                <button
                  type="button"
                  onClick={() =>
                    updateSettings({
                      hijri_adjustment: settings.hijri_adjustment + 1,
                    })
                  }
                  className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-teal-300"
                >
                  <PlusCircle className="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3 text-sm pt-1">
            <span className="text-white/75">Status API:</span>
            <span className="font-semibold text-teal-300">{apiStatus}</span>
            {settings.last_prayer_update && (
              <span className="text-xs text-white/55">
                Terakhir:{' '}
                {new Date(settings.last_prayer_update).toLocaleString('id-ID')}
              </span>
            )}
            <button
              type="button"
              onClick={handleCheckApi}
              disabled={checking}
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-white text-xs"
            >
              <RefreshCw
                className={`w-3.5 h-3.5 ${checking ? 'animate-spin' : ''}`}
              />
              Refresh
            </button>
          </div>
        </div>
      )}

      <div className="p-3.5 rounded-xl bg-white/10 border border-white/15 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2.5">
          <MapPin className="w-5 h-5 text-teal-300 shrink-0" />
          <span className="text-sm font-medium">
            {settings.kota_name ?? 'Belum dipilih (pilih kota untuk API)'}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={openCityPicker}
            className="px-3 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white text-sm font-medium"
          >
            Pilih Kota
          </button>
          {settings.kota_name && (
            <button
              type="button"
              onClick={() => {
                updateSettings({
                  kota_id: null,
                  kota_name: null,
                  use_api_prayer_times: false,
                });
                onToast('Kota dihapus; jadwal manual diaktifkan');
              }}
              className="px-3 py-1.5 rounded-lg bg-red-600/80 hover:bg-red-600 text-white text-sm"
            >
              Hapus
            </button>
          )}
        </div>
      </div>

      <div className="space-y-2.5 pt-2">
        {manualTimes.map((t, idx) => (
          <div
            key={t.name}
            className="flex items-center justify-between bg-white/5 px-4 py-2.5 rounded-lg border border-white/10"
          >
            <span className="font-medium text-lg">{t.name}</span>
            <input
              type="time"
              value={t.time === '--:--' ? '' : t.time}
              onChange={(e) => {
                const copy = [...manualTimes];
                copy[idx] = { ...copy[idx], time: e.target.value };
                setManualTimes(copy);
              }}
              className="px-3 py-1.5 rounded-lg bg-slate-800 border border-white/20 text-white tabular-nums"
            />
          </div>
        ))}
      </div>

      <button
        type="button"
        onClick={() => {
          updateSettings({
            custom_prayer_times: manualTimes,
            use_api_prayer_times: false,
          });
          onToast('Jadwal manual disimpan');
        }}
        className="w-full py-2.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold"
      >
        Simpan Jadwal Manual
      </button>

      {cityModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-white/20 rounded-2xl max-w-lg w-full max-h-[80vh] flex flex-col overflow-hidden">
            <div className="p-4 border-b border-white/15 flex items-center justify-between">
              <h3 className="font-bold text-lg text-white">Pilih Kota / Kabupaten</h3>
              <button
                type="button"
                onClick={() => setCityModalOpen(false)}
                className="p-1 text-white/70 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-3 border-b border-white/10">
              <div className="relative">
                <Search className="w-4 h-4 text-white/50 absolute left-3 top-3" />
                <input
                  type="text"
                  placeholder="Cari nama kota..."
                  value={citySearch}
                  onChange={(e) => setCitySearch(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm outline-none"
                />
              </div>
            </div>
            <div className="flex-1 overflow-y-auto p-2 space-y-1">
              {loadingCities ? (
                <p className="text-center py-8 text-white/60">Memuat daftar kota...</p>
              ) : filteredCities.length === 0 ? (
                <p className="text-center py-8 text-white/60">
                  Tidak ada kota ditemukan.
                </p>
              ) : (
                filteredCities.map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => {
                      updateSettings({
                        kota_id: c.id,
                        kota_name: c.lokasi,
                        use_api_prayer_times: true,
                      });
                      setCityModalOpen(false);
                      onToast(`Kota dipilih: ${c.lokasi}`);
                    }}
                    className="w-full text-left px-3.5 py-2.5 rounded-lg hover:bg-teal-500/20 text-sm text-white flex items-center justify-between"
                  >
                    <span>{c.lokasi}</span>
                    <span className="text-xs text-white/50 font-mono">{c.id}</span>
                  </button>
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 2. Slide Settings View                                                     */
/* -------------------------------------------------------------------------- */
export const SlideSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [editIdx, setEditIdx] = useState<number | null>(null);

  const handleSave = () => {
    if (!title.trim()) {
      onToast('Judul slide tidak boleh kosong');
      return;
    }
    const next = [...settings.slides];
    const item = { title: title.trim(), content: content.trim() };
    if (editIdx !== null) {
      next[editIdx] = item;
    } else {
      next.push(item);
    }
    updateSettings({ slides: next });
    setTitle('');
    setContent('');
    setEditIdx(null);
    onToast(editIdx !== null ? 'Slide diperbarui' : 'Slide ditambahkan');
  };

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Manajemen Slide Info</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
        <input
          type="text"
          placeholder="Judul Slide"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="w-full px-3.5 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
        />
        <textarea
          rows={3}
          placeholder="Isi Pengumuman"
          value={content}
          onChange={(e) => setContent(e.target.value)}
          className="w-full px-3.5 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
        />
        <div className="flex gap-2">
          <button
            type="button"
            onClick={handleSave}
            className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold text-sm"
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
              className="px-4 py-2 rounded-lg bg-slate-700 text-white text-sm"
            >
              Batal
            </button>
          )}
        </div>
      </div>

      <div className="space-y-2.5">
        {settings.slides.map((s, idx) => (
          <div
            key={`${s.title}-${idx}`}
            className="p-4 rounded-xl bg-white/5 border border-white/10 flex items-start justify-between gap-4"
          >
            <div>
              <div className="font-bold text-amber-300">{s.title}</div>
              <div className="text-sm text-white/80 mt-1">{s.content}</div>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <button
                type="button"
                onClick={() => {
                  setTitle(s.title);
                  setContent(s.content);
                  setEditIdx(idx);
                }}
                className="px-3 py-1 rounded bg-slate-700 hover:bg-slate-600 text-xs"
              >
                Edit
              </button>
              <button
                type="button"
                onClick={() => {
                  updateSettings({
                    slides: settings.slides.filter((_, i) => i !== idx),
                  });
                  onToast('Slide dihapus');
                }}
                className="p-1.5 rounded bg-red-600/80 hover:bg-red-600 text-white"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 3. Running Text Settings View                                              */
/* -------------------------------------------------------------------------- */
export const RunningTextSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [text, setText] = useState(settings.running_text);

  useEffect(() => {
    setText(settings.running_text);
  }, [settings.running_text]);

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Running Text</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <textarea
        rows={5}
        value={text}
        onChange={(e) => setText(e.target.value)}
        className="w-full px-3.5 py-2.5 rounded-lg bg-slate-800 border border-white/20 text-white"
        placeholder="Masukkan teks berjalan untuk bagian bawah layar..."
      />

      <button
        type="button"
        onClick={() => {
          updateSettings({ running_text: text.trim() });
          onToast('Running Text disimpan');
        }}
        className="px-6 py-2.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold"
      >
        Simpan
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 4. Theme Settings View                                                     */
/* -------------------------------------------------------------------------- */
export const ThemeSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();

  const handleBgUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const dataUrl = await readImageAsDataUrl(file);
      const patch: Partial<typeof settings> = { bg_dashboard: dataUrl };
      if (settings.bg_apply_all) {
        patch.bg_asset = dataUrl;
        patch.bg_info = dataUrl;
        patch.bg_event = dataUrl;
      }
      updateSettings(patch);
      onToast('Background berhasil diunggah!');
    } catch {
      onToast('Gagal memproses file gambar');
    }
    e.target.value = '';
  };

  const handleLogoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const dataUrl = await readImageAsDataUrl(file, 600);
      updateSettings({ logo_path: dataUrl });
      onToast('Logo masjid disimpan!');
    } catch {
      onToast('Gagal memproses file logo');
    }
    e.target.value = '';
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Tema & Nuansa Warna</h2>
        <div className="h-px bg-white/15 mt-2" />
        <p className="text-sm text-white/70 mt-2">
          Pilih paduan warna untuk efek glassmorphism pada aplikasi.
        </p>
      </div>

      <div className="space-y-3">
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
                onToast('Tema & Warna berhasil disimpan!');
              }}
              className={`w-full text-left p-4 rounded-2xl flex items-center gap-5 border-2 transition-all ${
                isSelected
                  ? 'bg-white/10'
                  : 'bg-black/40 border-transparent hover:border-white/20'
              }`}
              style={{ borderColor: isSelected ? aHex : undefined }}
            >
              <div
                className="w-14 h-14 rounded-full border-2 border-white/25 shrink-0"
                style={{
                  background: `linear-gradient(135deg, ${pHex}, ${aHex})`,
                }}
              />
              <div className="flex-1">
                <div
                  className="text-lg font-bold"
                  style={{ color: isSelected ? aHex : '#ffffff' }}
                >
                  {preset.name}
                </div>
                <div className="text-sm text-white/70">{preset.desc}</div>
              </div>
              {isSelected && (
                <CheckCircle2 className="w-7 h-7 shrink-0" style={{ color: aHex }} />
              )}
            </button>
          );
        })}
      </div>

      <div className="pt-4 border-t border-white/15 space-y-3">
        <h3 className="text-xl font-bold text-white">Background Utama</h3>
        <div className="flex items-center gap-3">
          <input
            type="text"
            readOnly
            value={
              settings.bg_dashboard.startsWith('data:')
                ? '[Gambar Upload Lokal]'
                : settings.bg_dashboard
            }
            className="flex-1 px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white/80 text-sm"
          />
          <label className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-white text-sm font-medium cursor-pointer flex items-center gap-2">
            <Upload className="w-4 h-4" /> Upload
            <input
              type="file"
              accept="image/*"
              onChange={handleBgUpload}
              className="hidden"
            />
          </label>
        </div>
        <label className="flex items-center justify-between p-3 rounded-xl bg-white/5 cursor-pointer">
          <div>
            <div className="font-medium">Terapkan ke Semua Layar</div>
            <div className="text-xs text-white/60">
              Gunakan background ini untuk layar Jadwal, Info, Hadis, dan Petugas
            </div>
          </div>
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
            className="w-5 h-5 accent-teal-400"
          />
        </label>
      </div>

      <div className="pt-4 border-t border-white/15 space-y-3">
        <h3 className="text-xl font-bold text-white">Logo Masjid</h3>
        <label className="flex items-center justify-between p-3 rounded-xl bg-white/5 cursor-pointer">
          <span>Tampilkan Logo Masjid</span>
          <input
            type="checkbox"
            checked={settings.show_logo}
            onChange={(e) => updateSettings({ show_logo: e.target.checked })}
            className="w-5 h-5 accent-teal-400"
          />
        </label>
        <label className="flex items-center justify-between p-3 rounded-xl bg-white/5 cursor-pointer">
          <span>Animasi Logo</span>
          <input
            type="checkbox"
            checked={settings.logo_animation_enabled}
            onChange={(e) =>
              updateSettings({ logo_animation_enabled: e.target.checked })
            }
            className="w-5 h-5 accent-teal-400"
          />
        </label>
        <div className="flex items-center gap-3">
          <input
            type="text"
            value={
              settings.logo_path.startsWith('data:')
                ? '[Logo Upload Lokal]'
                : settings.logo_path
            }
            onChange={(e) => updateSettings({ logo_path: e.target.value })}
            placeholder="URL atau Upload Logo..."
            className="flex-1 px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
          <label className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-white text-sm font-medium cursor-pointer flex items-center gap-2">
            <Upload className="w-4 h-4" /> Upload Logo
            <input
              type="file"
              accept="image/*"
              onChange={handleLogoUpload}
              className="hidden"
            />
          </label>
        </div>
      </div>

      <div className="pt-4 border-t border-white/15 space-y-4">
        <h3 className="text-xl font-bold text-white">Durasi & Efek Slideshow</h3>
        <div className="flex items-center gap-4">
          <input
            type="range"
            min={30}
            max={180}
            step={10}
            value={settings.rotation_duration_seconds}
            onChange={(e) =>
              updateSettings({
                rotation_duration_seconds: Number(e.target.value),
              })
            }
            className="flex-1 accent-teal-400"
          />
          <span className="font-bold tabular-nums w-24 text-right">
            {settings.rotation_duration_seconds} detik
          </span>
        </div>
        <div className="flex gap-2">
          {(['fade', 'slide', 'zoom'] as SlideshowEffect[]).map((eff) => (
            <button
              key={eff}
              type="button"
              onClick={() => {
                updateSettings({ slideshow_effect: eff });
                onToast(`Efek slideshow: ${eff}`);
              }}
              className={`px-4 py-2 rounded-lg text-sm font-medium capitalize border ${
                settings.slideshow_effect === eff
                  ? 'bg-teal-500/25 border-teal-400 text-white'
                  : 'bg-white/5 border-white/15 text-white/70'
              }`}
            >
              {eff}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
