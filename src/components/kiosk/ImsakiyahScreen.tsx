import React, { useEffect, useRef, useState } from 'react';
import { useKiosk } from '../../context/KioskContext';
import { fetchMonthlyImsakiyahEQuran } from '../../services/apiRepository';
import type { ImsakiyahDay } from '../../types/simasjid';
import { FooterPrayerBar } from './FooterPrayerBar';

const CARD_COLORS = [
  'rgba(0, 150, 136, 0.2)',
  'rgba(76, 175, 80, 0.2)',
  'rgba(33, 150, 243, 0.2)',
  'rgba(63, 81, 181, 0.2)',
  'rgba(156, 39, 176, 0.2)',
];

const HEADERS = [
  { label: 'Tanggal', flex: 3 },
  { label: 'Imsak', flex: 1 },
  { label: 'Subuh', flex: 1 },
  { label: 'Terbit', flex: 1 },
  { label: 'Dhuha', flex: 1 },
  { label: 'Dzuhur', flex: 1 },
  { label: 'Ashar', flex: 1 },
  { label: 'Maghrib', flex: 1 },
  { label: 'Isya', flex: 1 },
];

export const ImsakiyahScreen: React.FC = () => {
  const { settings, prayerTimes } = useKiosk();
  const [data, setData] = useState<ImsakiyahDay[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const userInteractingRef = useRef(false);

  const province = settings.imsakiyah_province;
  const city = settings.imsakiyah_city;

  useEffect(() => {
    let active = true;
    const load = async () => {
      if (!province || !city) {
        setLoading(false);
        setErrorMsg('Provinsi atau Kota belum dipilih di pengaturan.');
        return;
      }
      setLoading(true);
      setErrorMsg(null);
      const res = await fetchMonthlyImsakiyahEQuran(province, city);
      if (!active) return;
      if (res && res.length > 0) {
        setData(res);
      } else {
        setErrorMsg('Gagal mengambil data imsakiyah atau data kosong.');
      }
      setLoading(false);
    };
    void load();
    return () => {
      active = false;
    };
  }, [province, city]);

  useEffect(() => {
    if (loading || data.length === 0) return;
    const el = scrollRef.current;
    if (!el) return;

    const timer = window.setInterval(() => {
      if (userInteractingRef.current || !el) return;
      const maxScroll = el.scrollHeight - el.clientHeight;
      if (maxScroll <= 0) return;
      if (el.scrollTop >= maxScroll - 1) {
        el.scrollTop = 0;
      } else {
        el.scrollTop += 0.8;
      }
    }, 35);

    return () => window.clearInterval(timer);
  }, [loading, data]);

  const now = new Date();
  const dayPad = String(now.getDate()).padStart(2, '0');
  const monthPad = String(now.getMonth() + 1).padStart(2, '0');
  const yearStr = String(now.getFullYear());

  return (
    <div
      className="w-full h-full flex flex-col justify-between"
      style={{
        background:
          'linear-gradient(180deg, rgba(0,0,0,0.87) 0%, rgba(0,0,0,0.54) 50%, rgba(0,0,0,0.87) 100%)',
      }}
    >
      {/* Header */}
      <div className="w-full py-[14px] px-5 bg-black/50 backdrop-blur-[10px] border-b border-white/25 text-center shrink-0">
        <div className="stroked-text-sm text-[28px] font-bold text-amber-400 tracking-[1.5px]">
          JADWAL IMSAKIYAH
        </div>
        {city && (
          <div className="stroked-text-sm text-[16px] text-white font-medium mt-1">
            {city}, {province}
          </div>
        )}
      </div>

      {/* Table Header */}
      <div className="mx-5 my-1.5 py-3.5 px-2.5 bg-teal-900/90 rounded-[15px] border-2 border-amber-400/80 shadow-[0_4px_12px_rgba(0,0,0,0.55)] flex items-center shrink-0">
        {HEADERS.map((h) => (
          <div
            key={h.label}
            style={{ flex: h.flex }}
            className="text-center text-amber-400 font-bold text-[19px] drop-shadow-[0_1px_2px_rgba(0,0,0,0.9)]"
          >
            {h.label}
          </div>
        ))}
      </div>

      {/* Rows */}
      <div
        ref={scrollRef}
        onPointerDown={() => {
          userInteractingRef.current = true;
        }}
        onPointerUp={() => {
          userInteractingRef.current = false;
        }}
        onPointerLeave={() => {
          userInteractingRef.current = false;
        }}
        className="flex-1 overflow-y-auto px-5"
        style={{ scrollbarWidth: 'none' }}
      >
        {loading ? (
          <div className="w-full h-full flex items-center justify-center">
            <div className="w-10 h-10 border-4 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
          </div>
        ) : errorMsg ? (
          <div className="w-full h-full flex items-center justify-center">
            <span className="stroked-text-sm text-red-500 text-[24px] font-bold">
              {errorMsg}
            </span>
          </div>
        ) : (
          <div className="pb-2">
            {data.map((row, idx) => {
              const isToday =
                row.tanggal.includes(`${dayPad}/${monthPad}/${yearStr}`) ||
                row.tanggal.includes(`${yearStr}-${monthPad}-${dayPad}`) ||
                row.tanggal.trim() === String(now.getDate());

              const bgColor = isToday
                ? 'rgba(255, 193, 7, 0.4)'
                : CARD_COLORS[idx % CARD_COLORS.length];

              return (
                <div
                  key={`${row.tanggal}-${idx}`}
                  className="mb-2.5 rounded-[15px] backdrop-blur-[5px] py-3.5 px-2.5 flex items-center"
                  style={{
                    backgroundColor: bgColor,
                    border: isToday
                      ? '3px solid #ffc107'
                      : '1px solid rgba(255,255,255,0.2)',
                    boxShadow: isToday
                      ? '0 0 20px rgba(255, 193, 7, 0.35)'
                      : '0 2px 10px rgba(0,0,0,0.2)',
                  }}
                >
                  <div
                    style={{ flex: 3 }}
                    className="stroked-text-sm text-white text-[18px] font-bold text-center"
                  >
                    {row.tanggal}
                  </div>
                  {(
                    [
                      'imsak',
                      'subuh',
                      'terbit',
                      'dhuha',
                      'dzuhur',
                      'ashar',
                      'maghrib',
                      'isya',
                    ] as const
                  ).map((k) => (
                    <div
                      key={k}
                      style={{ flex: 1 }}
                      className={`stroked-text-sm text-[21px] font-bold tabular-nums text-center ${
                        isToday ? 'text-white' : 'text-amber-300'
                      }`}
                    >
                      {row[k]}
                    </div>
                  ))}
                </div>
              );
            })}
          </div>
        )}
      </div>

      <FooterPrayerBar
        prayerTimes={prayerTimes}
        primaryColor={settings.theme_primary_color}
        accentColor={settings.theme_accent_color}
        textStyles={settings.text_styles}
        darkBg
      />
    </div>
  );
};
