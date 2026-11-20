import React, { useEffect, useState } from 'react';
import {
  Calendar,
  Moon,
  Power,
  Radio,
  Save,
  Trash2,
  Upload,
  User,
} from 'lucide-react';
import { resolveAssetUrl, SHORT_DAYS } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import {
  fetchCitiesShalatEQuran,
  fetchProvincesShalatEQuran,
} from '../../services/apiRepository';
import { readImageAsDataUrl } from './fileHelper';

interface ToastProps {
  onToast: (msg: string) => void;
}

/* -------------------------------------------------------------------------- */
/* 10. Performer Settings View                                                */
/* -------------------------------------------------------------------------- */
export const PerformerSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [pName, setPName] = useState('');
  const [pRole, setPRole] = useState('');
  const [pPhoto, setPPhoto] = useState('');

  const [evName, setEvName] = useState('');
  const [evDate, setEvDate] = useState(new Date().toISOString().slice(0, 10));
  const [evEndDate, setEvEndDate] = useState('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const dataUrl = await readImageAsDataUrl(file, 600);
      setPPhoto(dataUrl);
      onToast('Foto petugas siap disimpan');
    } catch {
      onToast('Gagal membaca foto');
    }
    e.target.value = '';
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Manajemen Petugas & Pengisi Acara</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      {/* Add Performer Profile */}
      <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
        <h3 className="font-bold text-teal-300">Profil Petugas</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <input
            type="text"
            placeholder="Nama Petugas / Ustadz"
            value={pName}
            onChange={(e) => setPName(e.target.value)}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
          <input
            type="text"
            placeholder="Peran (Imam / Khotib / Bilal / Penceramah)"
            value={pRole}
            onChange={(e) => setPRole(e.target.value)}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
        </div>
        <div className="flex items-center gap-3">
          <input
            type="text"
            placeholder="URL Foto (opsional)"
            value={pPhoto.startsWith('data:') ? '[Foto Lokal]' : pPhoto}
            onChange={(e) => setPPhoto(e.target.value)}
            className="flex-1 px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
          <label className="px-3.5 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 text-xs font-medium cursor-pointer flex items-center gap-1.5">
            <Upload className="w-4 h-4" /> Upload Foto
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
              onToast('Nama dan peran wajib diisi');
              return;
            }
            updateSettings({
              performer_profiles: [
                ...settings.performer_profiles,
                {
                  id: String(Date.now()),
                  name: pName.trim(),
                  role: pRole.trim(),
                  photoPath: pPhoto.trim(),
                },
              ],
            });
            setPName('');
            setPRole('');
            setPPhoto('');
            onToast('Profil petugas ditambahkan');
          }}
          className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-sm font-semibold"
        >
          Tambah Petugas
        </button>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-2">
          {settings.performer_profiles.map((p) => (
            <div
              key={p.id}
              className="flex items-center justify-between bg-black/30 p-2.5 rounded-lg"
            >
              <div className="flex items-center gap-3">
                {p.photoPath ? (
                  <img
                    src={resolveAssetUrl(p.photoPath, '/assets/themes/default/avatar.png')}
                    alt={p.name}
                    className="w-10 h-10 rounded-full object-cover"
                  />
                ) : (
                  <div className="w-10 h-10 rounded-full bg-slate-700 flex items-center justify-center">
                    <User className="w-5 h-5 text-white/60" />
                  </div>
                )}
                <div>
                  <div className="font-semibold text-sm">{p.name}</div>
                  <div className="text-xs text-amber-300">{p.role}</div>
                </div>
              </div>
              <button
                type="button"
                onClick={() => {
                  updateSettings({
                    performer_profiles: settings.performer_profiles.filter(
                      (x) => x.id !== p.id,
                    ),
                  });
                  onToast('Profil petugas dihapus');
                }}
                className="p-1 text-red-400"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Add Performer Schedule */}
      <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
        <h3 className="font-bold text-amber-300">Jadwal Acara & Petugas</h3>
        <input
          type="text"
          placeholder="Nama Acara (mis: Sholat Jumat / Tarawih)"
          value={evName}
          onChange={(e) => setEvName(e.target.value)}
          className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
        />
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs text-white/70 mb-1">Tanggal Mulai</label>
            <input
              type="date"
              value={evDate}
              onChange={(e) => setEvDate(e.target.value)}
              className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-white/70 mb-1">
              Tanggal Selesai (Opsional)
            </label>
            <input
              type="date"
              value={evEndDate}
              onChange={(e) => setEvEndDate(e.target.value)}
              className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs text-white/70 mb-1.5">
            Pilih Petugas yang Bertugas
          </label>
          <div className="flex flex-wrap gap-2">
            {settings.performer_profiles.map((p) => {
              const checked = selectedIds.includes(p.id);
              return (
                <button
                  key={p.id}
                  type="button"
                  onClick={() =>
                    setSelectedIds((prev) =>
                      checked ? prev.filter((id) => id !== p.id) : [...prev, p.id],
                    )
                  }
                  className={`px-3 py-1.5 rounded-lg text-xs border ${
                    checked
                      ? 'bg-teal-600/30 border-teal-400 text-white'
                      : 'bg-slate-800 border-white/15 text-white/70'
                  }`}
                >
                  {p.name} ({p.role})
                </button>
              );
            })}
          </div>
        </div>

        <button
          type="button"
          onClick={() => {
            if (!evName.trim() || !evDate) {
              onToast('Nama acara dan tanggal wajib diisi');
              return;
            }
            updateSettings({
              performer_schedules: [
                ...settings.performer_schedules,
                {
                  name: evName.trim(),
                  date: evDate,
                  endDate: evEndDate || evDate,
                  performerIds: selectedIds,
                },
              ],
            });
            setEvName('');
            setSelectedIds([]);
            onToast('Jadwal petugas ditambahkan');
          }}
          className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-sm font-semibold"
        >
          Simpan Jadwal Petugas
        </button>

        {settings.performer_schedules.map((sch, idx) => (
          <div
            key={`${sch.name}-${idx}`}
            className="flex items-center justify-between bg-black/30 p-3 rounded-lg text-sm"
          >
            <div>
              <div className="font-bold text-white">{sch.name}</div>
              <div className="text-xs text-white/60">
                {sch.date} {sch.endDate && sch.endDate !== sch.date ? `s/d ${sch.endDate}` : ''}
              </div>
            </div>
            <button
              type="button"
              onClick={() =>
                updateSettings({
                  performer_schedules: settings.performer_schedules.filter(
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
/* 11. Event (Agenda) Settings View                                           */
/* -------------------------------------------------------------------------- */
export const EventSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [title, setTitle] = useState('');
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Manajemen Agenda Kegiatan</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <input
            type="text"
            placeholder="Nama Kegiatan"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="sm:col-span-2 px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white text-sm"
          />
        </div>
        <button
          type="button"
          onClick={() => {
            if (!title.trim() || !date) {
              onToast('Nama kegiatan dan tanggal wajib diisi');
              return;
            }
            updateSettings({
              events: [...settings.events, { title: title.trim(), date }],
            });
            setTitle('');
            onToast('Agenda ditambahkan');
          }}
          className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-sm font-semibold inline-flex items-center gap-1.5"
        >
          <Calendar className="w-4 h-4" /> Tambah Agenda
        </button>
      </div>

      <div className="space-y-2">
        {settings.events.map((ev, idx) => (
          <div
            key={`${ev.title}-${idx}`}
            className="flex items-center justify-between bg-white/5 px-4 py-3 rounded-xl border border-white/10"
          >
            <div>
              <div className="font-semibold text-white">{ev.title}</div>
              <div className="text-xs text-amber-300">{ev.date}</div>
            </div>
            <button
              type="button"
              onClick={() =>
                updateSettings({
                  events: settings.events.filter((_, i) => i !== idx),
                })
              }
              className="p-1.5 text-red-400 hover:text-red-300"
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
/* 12. Smart IoT Settings View                                                */
/* -------------------------------------------------------------------------- */
export const IotSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings, triggerRelay } = useKiosk();
  const [ip, setIp] = useState(settings.iot_ip);
  const [pathOn, setPathOn] = useState(settings.iot_path_on);
  const [pathOff, setPathOff] = useState(settings.iot_path_off);
  const [statusLabel, setStatusLabel] = useState('Belum dicek');

  const checkStatus = async () => {
    const clean = ip.trim().replace(/^https?:\/\//i, '');
    if (!clean) {
      setStatusLabel('IP belum diisi');
      return;
    }
    try {
      await fetch(`http://${clean}/status`, { mode: 'no-cors' });
      setStatusLabel('Permintaan status terkirim (mode no-cors)');
    } catch {
      setStatusLabel('Tidak dapat menjangkau perangkat IoT');
    }
  };

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Smart IoT (Kontrol Amplifier)</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <div className="space-y-3">
        <div>
          <label className="block text-sm text-white/75 mb-1">
            Alamat IP Perangkat IoT (ESP8266/ESP32)
          </label>
          <input
            type="text"
            placeholder="192.168.1.50"
            value={ip}
            onChange={(e) => setIp(e.target.value)}
            className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
          />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm text-white/75 mb-1">Path Relay ON</label>
            <input
              type="text"
              value={pathOn}
              onChange={(e) => setPathOn(e.target.value)}
              className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
            />
          </div>
          <div>
            <label className="block text-sm text-white/75 mb-1">Path Relay OFF</label>
            <input
              type="text"
              value={pathOff}
              onChange={(e) => setPathOff(e.target.value)}
              className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
            />
          </div>
        </div>
      </div>

      <div className="flex flex-wrap gap-3">
        <button
          type="button"
          onClick={() => {
            updateSettings({
              iot_ip: ip.trim(),
              iot_path_on: pathOn.trim() || '/on',
              iot_path_off: pathOff.trim() || '/off',
            });
            onToast('Pengaturan Smart IoT disimpan');
          }}
          className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 font-semibold text-sm flex items-center gap-2"
        >
          <Save className="w-4 h-4" /> Simpan
        </button>
        <button
          type="button"
          onClick={async () => {
            const ok = await triggerRelay(true);
            onToast(ok ? 'Perintah Relay ON dikirim' : 'Gagal mengirim perintah ON');
          }}
          className="px-4 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-500 font-semibold text-sm"
        >
          Tes Nyala (ON)
        </button>
        <button
          type="button"
          onClick={async () => {
            const ok = await triggerRelay(false);
            onToast(ok ? 'Perintah Relay OFF dikirim' : 'Gagal mengirim perintah OFF');
          }}
          className="px-4 py-2 rounded-lg bg-orange-600 hover:bg-orange-500 font-semibold text-sm"
        >
          Tes Mati (OFF)
        </button>
        <button
          type="button"
          onClick={checkStatus}
          className="px-4 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 text-sm flex items-center gap-1.5"
        >
          <Radio className="w-4 h-4" /> Cek Status
        </button>
      </div>
      <p className="text-xs text-white/60">Status: {statusLabel}</p>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 13. Imsakiyah Settings View                                                */
/* -------------------------------------------------------------------------- */
export const ImsakiyahSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [provinces, setProvinces] = useState<string[]>([]);
  const [cities, setCities] = useState<string[]>([]);
  const [prov, setProv] = useState(settings.imsakiyah_province ?? '');
  const [city, setCity] = useState(settings.imsakiyah_city ?? '');

  useEffect(() => {
    void fetchProvincesShalatEQuran().then((res) => {
      if (res) setProvinces(res);
    });
  }, []);

  useEffect(() => {
    if (!prov) return;
    void fetchCitiesShalatEQuran(prov).then((res) => {
      if (res) setCities(res);
    });
  }, [prov]);

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Pengaturan Jadwal Imsakiyah</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <label className="flex items-center justify-between p-3.5 rounded-xl bg-white/5 border border-white/15 cursor-pointer">
        <div>
          <div className="font-semibold">Tampilkan Layar Jadwal Imsakiyah</div>
          <div className="text-xs text-white/60">
            Menampilkan tabel jadwal Imsakiyah bulanan dari EQuran.id dalam rotasi layar
          </div>
        </div>
        <input
          type="checkbox"
          checked={settings.show_imsakiyah_screen}
          onChange={(e) =>
            updateSettings({ show_imsakiyah_screen: e.target.checked })
          }
          className="w-5 h-5 accent-teal-400"
        />
      </label>

      <div className="space-y-3">
        <div>
          <label className="block text-sm text-white/75 mb-1">Provinsi</label>
          <select
            value={prov}
            onChange={(e) => {
              setProv(e.target.value);
              setCity('');
            }}
            className="w-full px-3 py-2.5 rounded-lg bg-slate-800 border border-white/20 text-white"
          >
            <option value="">-- Pilih Provinsi --</option>
            {provinces.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm text-white/75 mb-1">Kota / Kabupaten</label>
          <select
            value={city}
            onChange={(e) => setCity(e.target.value)}
            className="w-full px-3 py-2.5 rounded-lg bg-slate-800 border border-white/20 text-white"
          >
            <option value="">-- Pilih Kota / Kabupaten --</option>
            {cities.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>
      </div>

      <button
        type="button"
        onClick={() => {
          updateSettings({
            imsakiyah_province: prov || null,
            imsakiyah_city: city || null,
          });
          onToast('Pengaturan Imsakiyah disimpan');
        }}
        className="px-6 py-2.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-semibold"
      >
        Simpan
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 14. Power TV Settings View                                                 */
/* -------------------------------------------------------------------------- */
export const PowerTvSettingsView: React.FC<ToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [onTime, setOnTime] = useState('04:00');
  const [offTime, setOffTime] = useState('21:00');
  const [days, setDays] = useState<number[]>([1, 2, 3, 4, 5, 6, 7]);

  return (
    <div className="space-y-5 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Penjadwalan Power TV</h2>
        <div className="h-px bg-white/15 mt-2" />
      </div>

      <div className="p-3.5 rounded-xl bg-amber-500/15 border border-amber-400/40 text-xs text-amber-200 flex items-center gap-2.5">
        <Moon className="w-4 h-4 shrink-0" />
        <span>
          Pada versi web browser, Power TV mematikan layar dengan mode tidur hitam
          penuh secara otomatis sesuai jadwal.
        </span>
      </div>

      <label className="flex items-center justify-between p-3.5 rounded-xl bg-white/5 border border-white/15 cursor-pointer">
        <span>Aktifkan Penjadwalan Power TV</span>
        <input
          type="checkbox"
          checked={settings.power_tv_enabled}
          onChange={(e) =>
            updateSettings({ power_tv_enabled: e.target.checked })
          }
          className="w-5 h-5 accent-teal-400"
        />
      </label>

      <div className="p-4 rounded-xl bg-white/5 border border-white/15 space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-xs text-white/70 mb-1">Jam Nyala (ON)</label>
            <input
              type="time"
              value={onTime}
              onChange={(e) => setOnTime(e.target.value)}
              className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
            />
          </div>
          <div>
            <label className="block text-xs text-white/70 mb-1">Jam Mati (OFF)</label>
            <input
              type="time"
              value={offTime}
              onChange={(e) => setOffTime(e.target.value)}
              className="w-full px-3 py-2 rounded-lg bg-slate-800 border border-white/20 text-white"
            />
          </div>
        </div>
        <div className="flex flex-wrap gap-1.5">
          {SHORT_DAYS.map((d) => {
            const active = days.includes(d.id);
            return (
              <button
                key={d.id}
                type="button"
                onClick={() =>
                  setDays((prev) =>
                    active ? prev.filter((x) => x !== d.id) : [...prev, d.id],
                  )
                }
                className={`px-3 py-1 rounded text-xs ${
                  active ? 'bg-teal-600 text-white' : 'bg-slate-800 text-white/60'
                }`}
              >
                {d.label}
              </button>
            );
          })}
        </div>
        <button
          type="button"
          onClick={() => {
            updateSettings({
              power_schedules: [
                ...settings.power_schedules,
                { on: onTime, off: offTime, days: days.join(',') || '1,2,3,4,5,6,7' },
              ],
            });
            onToast('Jadwal Power TV ditambahkan');
          }}
          className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-500 text-sm font-semibold inline-flex items-center gap-1.5"
        >
          <Power className="w-4 h-4" /> Tambah Jadwal Power
        </button>
      </div>

      <div className="space-y-2">
        {settings.power_schedules.map((s, idx) => (
          <div
            key={`${s.on}-${s.off}-${idx}`}
            className="flex items-center justify-between bg-white/5 px-4 py-3 rounded-xl border border-white/10"
          >
            <div>
              <div className="font-semibold text-white tabular-nums">
                ON: {s.on} | OFF: {s.off}
              </div>
              <div className="text-xs text-white/60">Hari: {s.days}</div>
            </div>
            <button
              type="button"
              onClick={() =>
                updateSettings({
                  power_schedules: settings.power_schedules.filter(
                    (_, i) => i !== idx,
                  ),
                })
              }
              className="p-1.5 text-red-400"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};
