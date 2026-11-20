import React, { useEffect, useState } from 'react';
import { QrCode, Radio } from 'lucide-react';
import { SHORT_DAYS } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import {
  fetchCitiesShalatEQuran,
  fetchProvincesShalatEQuran,
} from '../../services/apiRepository';

interface AdminToastProps {
  onToast: (msg: string) => void;
}

/* -------------------------------------------------------------------------- */
/* 11. Smart IoT                                                              */
/* -------------------------------------------------------------------------- */
export const AdminIotSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings, triggerRelay } = useKiosk();
  const [ip, setIp] = useState(settings.iot_ip);
  const [pathOn, setPathOn] = useState(settings.iot_path_on);
  const [pathOff, setPathOff] = useState(settings.iot_path_off);

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Smart IoT (Relay Amplifier)
      </h2>

      <div className="space-y-3">
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Alamat IP ESP8266/ESP32
          </label>
          <input
            type="text"
            placeholder="Contoh: 192.168.1.50"
            value={ip}
            onChange={(e) => setIp(e.target.value)}
            className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1">
              Path ON
            </label>
            <input
              type="text"
              value={pathOn}
              onChange={(e) => setPathOn(e.target.value)}
              className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-slate-500 mb-1">
              Path OFF
            </label>
            <input
              type="text"
              value={pathOff}
              onChange={(e) => setPathOff(e.target.value)}
              className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
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
            onToast('Konfigurasi IoT disimpan!');
          }}
          className="flex-1 py-2.5 px-4 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
        >
          Simpan Konfigurasi
        </button>
        <button
          type="button"
          onClick={async () => {
            const ok = await triggerRelay(true);
            onToast(ok ? 'Relay ON dikirim' : 'Gagal menghubungi IoT');
          }}
          className="py-2.5 px-4 rounded-[10px] bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm"
        >
          Tes ON
        </button>
        <button
          type="button"
          onClick={async () => {
            const ok = await triggerRelay(false);
            onToast(ok ? 'Relay OFF dikirim' : 'Gagal menghubungi IoT');
          }}
          className="py-2.5 px-4 rounded-[10px] bg-amber-600 hover:bg-amber-700 text-white font-semibold text-sm"
        >
          Tes OFF
        </button>
      </div>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 14. Power TV                                                               */
/* -------------------------------------------------------------------------- */
export const AdminPowertvSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [onTime, setOnTime] = useState('04:00');
  const [offTime, setOffTime] = useState('21:00');
  const [days, setDays] = useState<number[]>([1, 2, 3, 4, 5, 6, 7]);
  const [editIdx, setEditIdx] = useState<number | null>(null);

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Penjadwalan Power TV
      </h2>

      <label className="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-slate-200 cursor-pointer">
        <span className="text-sm font-semibold text-slate-700">
          Aktifkan Penjadwalan Power TV
        </span>
        <input
          type="checkbox"
          checked={settings.power_tv_enabled}
          onChange={(e) =>
            updateSettings({ power_tv_enabled: e.target.checked })
          }
          className="w-5 h-5 accent-teal-600"
        />
      </label>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Jam Nyala (ON)
          </label>
          <input
            type="time"
            value={onTime}
            onChange={(e) => setOnTime(e.target.value)}
            className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Jam Mati (OFF)
          </label>
          <input
            type="time"
            value={offTime}
            onChange={(e) => setOffTime(e.target.value)}
            className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
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
              className={`px-3 py-1 rounded-full text-xs font-medium border ${
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

      <button
        type="button"
        onClick={() => {
          const next = [...settings.power_schedules];
          const item = {
            on: onTime,
            off: offTime,
            days: days.join(',') || '1,2,3,4,5,6,7',
          };
          if (editIdx !== null) next[editIdx] = item;
          else next.push(item);
          updateSettings({ power_schedules: next });
          setEditIdx(null);
          onToast('Jadwal Power TV disimpan!');
        }}
        className="w-full py-2.5 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
      >
        {editIdx !== null ? 'Update Jadwal Power' : 'Tambah Jadwal Power'}
      </button>

      {settings.power_schedules.length > 0 && (
        <table className="w-full text-sm border-collapse">
          <tbody>
            {settings.power_schedules.map((s, i) => (
              <tr key={`${s.on}-${s.off}-${i}`} className="border-b border-slate-100">
                <td className="py-2.5 px-2">{i + 1}</td>
                <td className="py-2.5 px-2">
                  <strong>ON:</strong> {s.on} | <strong>OFF:</strong> {s.off}
                  <div className="text-xs text-slate-500">Hari: {s.days}</div>
                </td>
                <td className="py-2.5 px-2 text-right whitespace-nowrap">
                  <button
                    type="button"
                    onClick={() => {
                      setOnTime(s.on);
                      setOffTime(s.off);
                      setDays(
                        s.days
                          .split(',')
                          .map((x) => Number(x))
                          .filter(Boolean),
                      );
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
                        power_schedules: settings.power_schedules.filter(
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
  );
};

/* -------------------------------------------------------------------------- */
/* 15. Imsakiyah                                                              */
/* -------------------------------------------------------------------------- */
export const AdminImsakiyahSection: React.FC<AdminToastProps> = ({
  onToast,
}) => {
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
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Jadwal Imsakiyah Bulanan
      </h2>

      <label className="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-slate-200 cursor-pointer">
        <span className="text-sm font-semibold text-slate-700">
          Tampilkan Layar Imsakiyah di TV
        </span>
        <input
          type="checkbox"
          checked={settings.show_imsakiyah_screen}
          onChange={(e) =>
            updateSettings({ show_imsakiyah_screen: e.target.checked })
          }
          className="w-5 h-5 accent-teal-600"
        />
      </label>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Provinsi
          </label>
          <select
            value={prov}
            onChange={(e) => {
              setProv(e.target.value);
              setCity('');
            }}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
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
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Kota / Kabupaten
          </label>
          <select
            value={city}
            onChange={(e) => setCity(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-[10px]"
          >
            <option value="">-- Pilih Kota --</option>
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
          onToast('Pengaturan Imsakiyah disimpan!');
        }}
        className="w-full py-3 rounded-[10px] bg-teal-600 hover:bg-teal-700 text-white font-semibold text-sm"
      >
        Simpan Wilayah Imsakiyah
      </button>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 16. Akses Remote                                                           */
/* -------------------------------------------------------------------------- */
export const AdminRemoteSection: React.FC<AdminToastProps> = ({ onToast }) => {
  const { settings, updateSettings } = useKiosk();
  const [enabled, setEnabled] = useState(settings.tunnel_enabled);
  const [host, setHost] = useState(settings.vps_host);
  const [user, setUser] = useState(settings.vps_user);
  const [pass, setPass] = useState('');
  const [port, setPort] = useState(settings.vps_port || 8089);

  return (
    <div className="max-w-[960px] mx-auto bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
      <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
        <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
        Akses Remote (VPN/Tunnel)
      </h2>
      <p className="text-sm text-slate-500">
        Aktifkan fitur ini agar Web Admin bisa diakses dari mana saja melalui
        internet via server pribadi Anda.
      </p>

      <div className="p-3.5 rounded-lg bg-amber-50 border border-amber-200 text-xs text-amber-800">
        <strong>Catatan Web Browser:</strong> Pada aplikasi web murni di
        browser, koneksi reverse SSH tunnel TCP tidak dapat dijalankan
        langsung dari browser tanpa backend relay. Konfigurasi tetap disimpan di
        penyimpanan lokal.
      </div>

      <div className="space-y-3">
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Aktifkan Tunnel
          </label>
          <select
            value={String(enabled)}
            onChange={(e) => setEnabled(e.target.value === 'true')}
            className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          >
            <option value="true">Ya, Aktifkan</option>
            <option value="false">Tidak, Nonaktifkan</option>
          </select>
        </div>

        <h3 className="font-bold text-slate-800 pt-2">Konfigurasi Server (SSH)</h3>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Alamat IP / Domain VPS
          </label>
          <input
            type="text"
            placeholder="Contoh: 123.45.67.89"
            value={host}
            onChange={(e) => setHost(e.target.value)}
            className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Username SSH
          </label>
          <input
            type="text"
            placeholder="Contoh: simasjid_tunnel"
            value={user}
            onChange={(e) => setUser(e.target.value)}
            className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Password SSH
          </label>
          <input
            type="password"
            value={pass}
            onChange={(e) => setPass(e.target.value)}
            className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 mb-1">
            Port Publik di VPS
          </label>
          <input
            type="number"
            value={port}
            onChange={(e) => setPort(Number(e.target.value) || 8089)}
            className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-[10px]"
          />
        </div>

        <button
          type="button"
          onClick={() => {
            updateSettings({
              tunnel_enabled: enabled,
              vps_host: host.trim(),
              vps_user: user.trim(),
              vps_port: port,
              public_url:
                enabled && host.trim() ? `http://${host.trim()}:${port}` : null,
            });
            onToast('Konfigurasi remote disimpan!');
          }}
          className="w-full py-3 rounded-[10px] bg-pink-600 hover:bg-pink-700 text-white font-semibold text-sm"
        >
          Simpan Konfigurasi
        </button>

        <div className="p-3.5 rounded-lg bg-sky-50 border border-sky-200 text-sm text-sky-900">
          <strong>URL Publik Saat Ini:</strong>{' '}
          {settings.public_url ? settings.public_url : 'Belum terhubung'}
        </div>
      </div>
    </div>
  );
};

/* -------------------------------------------------------------------------- */
/* 17. Donasi & Dukungan                                                      */
/* -------------------------------------------------------------------------- */
export const AdminDonasiSection: React.FC = () => {
  const [qrisErr, setQrisErr] = useState(false);
  const [iotErr, setIotErr] = useState(false);

  return (
    <div className="max-w-[960px] mx-auto space-y-5">
      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
          <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
          💖 Donasi & Dukungan
        </h2>
        <p className="text-sm text-slate-600">
          Aplikasi SIMasjid ini bersifat gratis untuk penggunaan non-komersial
          di masjid. Jika Anda merasa aplikasi ini bermanfaat dan ingin mendukung
          pengembangan fitur-fitur baru di masa depan, Anda dapat memberikan
          donasi sukarela.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-2">
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 flex flex-col items-center text-center">
            <h3 className="font-bold text-slate-900 mb-1">Scan QRIS</h3>
            <p className="text-xs text-slate-500 mb-3">
              Mendukung semua E-Wallet (Dana, OVO, GoPay, ShopeePay) dan Mobile
              Banking.
            </p>
            {!qrisErr ? (
              <img
                src="https://i.ibb.co/yB1PZ27/qris.png"
                alt="QRIS Donasi"
                onError={() => setQrisErr(true)}
                className="w-[220px] rounded-lg"
              />
            ) : (
              <div className="w-[220px] h-[220px] rounded-lg bg-white border border-slate-200 flex flex-col items-center justify-center text-slate-400 p-4">
                <QrCode className="w-16 h-16 mb-2 text-teal-600" />
                <span className="text-xs">QRIS a.n. YUSUF FAISAL</span>
              </div>
            )}
            <p className="font-bold text-sm text-slate-800 mt-2">
              a.n. YUSUF FAISAL
            </p>
          </div>

          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-4">
            <div>
              <h3 className="font-bold text-slate-900 mb-1">Transfer Bank</h3>
              <ul className="text-sm text-slate-700 space-y-1">
                <li>
                  <strong>Bank BCA</strong>
                </li>
                <li>
                  No. Rekening: <strong>5745480940</strong>
                </li>
                <li>
                  Atas Nama: <strong>Yusuf Faisal</strong>
                </li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold text-slate-900 mb-1">E-Wallet</h3>
              <ul className="text-sm text-slate-700 space-y-1">
                <li>
                  <strong>DANA / OVO / GoPay</strong>
                </li>
                <li>
                  Nomor: <strong>085888553394</strong>
                </li>
                <li>
                  Atas Nama: <strong>Yusuf Faisal</strong>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-[14px] border border-slate-200 shadow-sm space-y-4">
        <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2.5">
          <span className="w-1.5 h-5 bg-teal-600 rounded-full inline-block" />
          🔌 Pemesanan Modul IoT (Relay Otomatis)
        </h2>
        <p className="text-sm text-slate-600">
          Otomatiskan sound system masjid Anda! Modul ini akan menyalakan
          amplifier secara otomatis saat Murottal atau Kajian diputar, dan
          mematikannya saat selesai.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 items-center">
          <div className="flex justify-center">
            {!iotErr ? (
              <img
                src="https://i.ibb.co/Vvj2Hk7/modul-iot.png"
                alt="Modul IoT"
                onError={() => setIotErr(true)}
                className="w-[220px] rounded-lg"
              />
            ) : (
              <div className="w-[220px] h-[160px] rounded-lg bg-slate-50 border border-slate-200 flex flex-col items-center justify-center text-slate-400">
                <Radio className="w-12 h-12 text-teal-600 mb-2" />
                <span className="text-xs font-medium text-slate-600">
                  Modul ESP32 Relay
                </span>
              </div>
            )}
          </div>
          <div className="space-y-2 text-sm text-slate-700">
            <h3 className="font-bold text-slate-900 text-base">
              Paket Siap Pakai
            </h3>
            <ul className="space-y-1.5">
              <li>
                <strong>Kontak (WhatsApp):</strong> 08999994994
              </li>
              <li>
                <strong>Paket Termasuk:</strong> Modul ESP32, Modul Relay,
                Casing, dan Adaptor.
              </li>
              <li>
                Cukup hubungkan ke Wi-Fi masjid dan sound system, langsung
                berfungsi.
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};
