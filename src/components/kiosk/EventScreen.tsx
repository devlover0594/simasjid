import React, { useEffect, useMemo, useRef } from 'react';
import { argbToCssRgba } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { getTodayIsoDate } from '../../services/storageService';
import { formatShortDateId } from '../../utils/styleHelpers';
import { FooterPrayerBar } from './FooterPrayerBar';

export const EventScreen: React.FC = () => {
  const { settings, timeString, prayerTimes } = useKiosk();
  const scrollRef = useRef<HTMLDivElement | null>(null);

  const primary = settings.theme_primary_color;
  const accent = settings.theme_accent_color;
  const styles = settings.text_styles;

  const upcomingEvents = useMemo(() => {
    const todayStr = getTodayIsoDate();
    return [...settings.events]
      .sort((a, b) => (a.date || '').localeCompare(b.date || ''))
      .filter((e) => (e.date || '') >= todayStr);
  }, [settings.events]);

  useEffect(() => {
    const el = scrollRef.current;
    if (!el || upcomingEvents.length === 0) return;

    const timer = window.setInterval(() => {
      const maxScroll = el.scrollHeight - el.clientHeight;
      if (maxScroll <= 0) return;
      if (el.scrollTop >= maxScroll - 1) {
        el.scrollTop = 0;
      } else {
        el.scrollTop += 1;
      }
    }, 50);

    return () => window.clearInterval(timer);
  }, [upcomingEvents]);

  return (
    <div className="w-full h-full flex flex-col justify-between">
      {/* Header */}
      <div
        className="w-full py-[15px] px-5 backdrop-blur-[10px] flex items-center justify-between shrink-0"
        style={{
          backgroundColor: argbToCssRgba(primary, 0.5),
          borderBottom: `1.5px solid ${argbToCssRgba(accent, 0.5)}`,
        }}
      >
        <span
          className="stroked-text-sm text-[24px] font-bold"
          style={{ color: argbToCssRgba(accent) }}
        >
          AGENDA KEGIATAN
        </span>
        <span className="stroked-text-sm text-[24px] font-bold text-white tabular-nums">
          {timeString}
        </span>
      </div>

      {/* Main Grid */}
      <div className="flex-1 overflow-hidden p-5">
        {upcomingEvents.length === 0 ? (
          <div className="w-full h-full flex items-center justify-center">
            <p className="text-white/70 text-[24px]">
              Tidak ada agenda kegiatan mendatang.
            </p>
          </div>
        ) : (
          <div
            ref={scrollRef}
            className="w-full h-full overflow-y-auto grid grid-cols-3 gap-5 content-start"
            style={{ scrollbarWidth: 'none' }}
          >
            {upcomingEvents.map((ev, idx) => (
              <div
                key={`${ev.title}-${ev.date}-${idx}`}
                className="aspect-[1.6] rounded-[15px] backdrop-blur-[5px] p-4 flex flex-col items-center justify-center shadow-[0_3px_10px_rgba(0,0,0,0.3)]"
                style={{
                  backgroundColor: argbToCssRgba(primary, 0.5),
                  border: `1.5px solid ${argbToCssRgba(accent, 0.6)}`,
                }}
              >
                <span
                  className="px-3 py-1 rounded-[20px] text-[18px] font-bold text-black"
                  style={{ backgroundColor: argbToCssRgba(accent) }}
                >
                  {formatShortDateId(ev.date)}
                </span>
                <p className="mt-3.5 text-center text-[24px] font-bold text-white leading-[1.2] line-clamp-3">
                  {ev.title}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      <FooterPrayerBar
        prayerTimes={prayerTimes}
        primaryColor={primary}
        accentColor={accent}
        textStyles={styles}
      />
    </div>
  );
};
