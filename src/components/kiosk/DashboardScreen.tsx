import React from 'react';
import { argbToCssRgba } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { textConfigToCss } from '../../utils/styleHelpers';

export const DashboardScreen: React.FC = () => {
  const {
    settings,
    timeString,
    dateString,
    hijriDateString,
    prayerTimes,
    nextPrayerIndex,
    handleSecretGesture,
  } = useKiosk();

  const primary = settings.theme_primary_color;
  const accent = settings.theme_accent_color;
  const styles = settings.text_styles;

  const marqueeText = settings.running_text || '';
  // Approximate Flutter 50px/sec scrolling duration
  const durationSeconds = Math.max(12, Math.round((marqueeText.length * 16 + 1280) / 65));

  return (
    <div className="w-full h-full flex flex-col justify-between">
      {/* Header Glassmorphism */}
      <div
        className="mx-5 mt-5 rounded-[25px] backdrop-blur-[15px] px-[30px] py-[22px] flex items-start justify-between shrink-0"
        style={{
          backgroundColor: argbToCssRgba(primary, 0.5),
          border: `1.5px solid ${argbToCssRgba(accent, 0.4)}`,
        }}
      >
        {/* Left: Mosque Name, Address, City (Triple click opens settings) */}
        <div
          onClick={handleSecretGesture}
          title="Ketuk 3x cepat untuk membuka Pengaturan TV"
          className="cursor-pointer select-none max-w-[62%]"
        >
          <div
            className="stroked-text leading-[1.15]"
            style={textConfigToCss(styles.mosque_name, {
              color: argbToCssRgba(accent),
              fontWeight: 700,
              fontStyle: 'italic',
            })}
          >
            {settings.mosque_name}
          </div>
          <div
            className="stroked-text-sm mt-1 leading-snug"
            style={textConfigToCss(styles.mosque_address)}
          >
            {settings.mosque_address}
          </div>
          {settings.kota_name && (
            <div
              className="stroked-text-sm font-bold leading-snug"
              style={textConfigToCss(styles.mosque_address, { fontWeight: 700 })}
            >
              {settings.kota_name}
            </div>
          )}
        </div>

        {/* Right: Digital Clock, Gregorian Date, Hijri Date */}
        <div className="flex flex-col items-end shrink-0">
          <div
            className="stroked-text tabular-nums leading-[1.05]"
            style={textConfigToCss(styles.clock, {
              color: '#ffffff',
              fontWeight: 700,
              fontStyle: 'italic',
              textShadow: `0 0 12px ${argbToCssRgba(accent, 0.5)}, 0 2px 6px rgba(0,0,0,0.85)`,
            })}
          >
            {timeString}
          </div>
          <div
            className="stroked-text-sm leading-tight mt-1"
            style={textConfigToCss(styles.date)}
          >
            {dateString}
          </div>
          {hijriDateString && (
            <div
              className="stroked-text-sm leading-tight mt-1.5"
              style={textConfigToCss(styles.date, {
                color: argbToCssRgba(accent),
              })}
            >
              {hijriDateString}
            </div>
          )}
        </div>
      </div>

      {/* Middle: 5 Prayer Time Cards */}
      <div className="flex-1 flex flex-col justify-end px-5 py-2.5">
        <div className="flex items-stretch justify-evenly gap-3 mb-2.5">
          {prayerTimes.map((p, idx) => {
            const isNext = idx === nextPrayerIndex;
            return (
              <div
                key={p.name}
                className={`flex-1 rounded-[25px] backdrop-blur-[15px] px-2.5 py-6 flex flex-col items-center justify-center transition-transform ${
                  isNext ? 'animate-prayer-next' : ''
                }`}
                style={{
                  background: isNext
                    ? `linear-gradient(135deg, ${argbToCssRgba(accent, 0.4)}, ${argbToCssRgba(primary, 0.8)})`
                    : `linear-gradient(135deg, rgba(255,255,255,0.1), ${argbToCssRgba(primary, 0.4)})`,
                  border: isNext
                    ? `2.5px solid ${argbToCssRgba(accent)}`
                    : `1.5px solid ${argbToCssRgba(accent, 0.3)}`,
                }}
              >
                <div
                  className="font-bold tracking-[2px] uppercase text-center"
                  style={textConfigToCss(styles.prayer_name, {
                    color: isNext ? '#ffffff' : argbToCssRgba(accent),
                    fontWeight: 700,
                    textShadow: '0 2px 4px rgba(0,0,0,0.85)',
                  })}
                >
                  {p.name.toUpperCase()}
                </div>
                <div
                  className="font-bold tabular-nums mt-3 text-center"
                  style={textConfigToCss(styles.prayer_time, {
                    color: '#ffffff',
                    fontWeight: 700,
                    fontSize: `${isNext ? Math.max(46, (styles.prayer_time?.size ?? 32) + 14) : Math.max(38, (styles.prayer_time?.size ?? 32) + 6)}px`,
                    textShadow: '0 2px 8px rgba(0,0,0,0.9)',
                  })}
                >
                  {p.time}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom: Running Text Marquee */}
      <div
        className="mx-5 mb-5 h-[100px] rounded-[25px] backdrop-blur-[15px] px-[30px] flex items-center overflow-hidden shrink-0"
        style={{
          backgroundColor: argbToCssRgba(primary, 0.5),
          border: `1.5px solid ${argbToCssRgba(accent, 0.4)}`,
        }}
      >
        <div className="w-full overflow-hidden">
          <div
            className="marquee-track items-center"
            style={
              {
                '--marquee-duration': `${durationSeconds}s`,
              } as React.CSSProperties
            }
          >
            <span
              className="stroked-text pr-[520px] inline-block"
              style={textConfigToCss(styles.running_text, {
                color: argbToCssRgba(accent),
                fontWeight: 600,
                letterSpacing: '1px',
              })}
            >
              {marqueeText}
            </span>
            <span
              className="stroked-text pr-[520px] inline-block"
              style={textConfigToCss(styles.running_text, {
                color: argbToCssRgba(accent),
                fontWeight: 600,
                letterSpacing: '1px',
              })}
            >
              {marqueeText}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
