import React, { useCallback, useEffect, useRef, useState } from 'react';
import { argbToCssRgba } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { fetchRandomHadith } from '../../services/apiRepository';
import type { HadithItem } from '../../types/simasjid';
import { textConfigToCss } from '../../utils/styleHelpers';
import { FooterPrayerBar } from './FooterPrayerBar';

const FALLBACK_HADITH: HadithItem = {
  text: "Sebaik-baik kalian adalah orang yang mempelajari Al-Qur'an dan mengajarkannya.",
  source: 'HR. Bukhari',
};

export const HadithScreen: React.FC = () => {
  const { settings, timeString, prayerTimes } = useKiosk();
  const [hadith, setHadith] = useState<HadithItem | null>(null);
  const [loading, setLoading] = useState(true);
  const scrollRef = useRef<HTMLDivElement | null>(null);

  const primary = settings.theme_primary_color;
  const accent = settings.theme_accent_color;
  const styles = settings.text_styles;

  const loadHadith = useCallback(async () => {
    setLoading(true);
    let result = await fetchRandomHadith();
    if (!result && settings.custom_hadiths.length > 0) {
      const idx = Math.floor(Math.random() * settings.custom_hadiths.length);
      result = settings.custom_hadiths[idx];
    }
    setHadith(result ?? FALLBACK_HADITH);
    setLoading(false);
  }, [settings.custom_hadiths]);

  useEffect(() => {
    void loadHadith();
    const intervalMs = Math.max(1, settings.hadith_interval) * 60000;
    const timer = window.setInterval(() => {
      void loadHadith();
    }, intervalMs);
    return () => window.clearInterval(timer);
  }, [loadHadith, settings.hadith_interval]);

  // Auto vertical crawl (30px/s after 3s pause)
  useEffect(() => {
    const el = scrollRef.current;
    if (!el || !hadith) return;
    el.scrollTop = 0;

    let animTimer: number | null = null;
    let pauseTimer: number | null = null;
    let cancelled = false;

    const startCrawl = () => {
      if (cancelled || !el) return;
      const maxScroll = el.scrollHeight - el.clientHeight;
      if (maxScroll <= 4) return;

      pauseTimer = window.setTimeout(() => {
        if (cancelled) return;
        const speedPxPerSec = settings.hadith_speed || 30;
        const stepPx = speedPxPerSec / 25; // 40ms interval
        animTimer = window.setInterval(() => {
          if (cancelled || !el) return;
          if (el.scrollTop >= maxScroll) {
            if (animTimer) window.clearInterval(animTimer);
            pauseTimer = window.setTimeout(() => {
              if (!cancelled && el) {
                el.scrollTop = 0;
                startCrawl();
              }
            }, 3000);
          } else {
            el.scrollTop += stepPx;
          }
        }, 40);
      }, 3000);
    };

    const initDelay = window.setTimeout(startCrawl, 250);
    return () => {
      cancelled = true;
      window.clearTimeout(initDelay);
      if (animTimer) window.clearInterval(animTimer);
      if (pauseTimer) window.clearTimeout(pauseTimer);
    };
  }, [hadith, settings.hadith_speed]);

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
          MUTIARA HADIS
        </span>
        <span className="stroked-text-sm text-[24px] font-bold text-white tabular-nums">
          {timeString}
        </span>
      </div>

      {/* Main Glassmorphism Hadith Card */}
      <div className="flex-1 flex items-center justify-center p-10 overflow-hidden">
        <div
          className="w-full h-full rounded-[24px] backdrop-blur-[10px] p-8 flex flex-col justify-center shadow-[0_6px_24px_rgba(0,0,0,0.35)] overflow-hidden"
          style={{
            backgroundColor: argbToCssRgba(primary, 0.5),
            border: `1.5px solid ${argbToCssRgba(accent, 0.4)}`,
          }}
        >
          {loading && !hadith ? (
            <div className="flex items-center justify-center">
              <div className="w-10 h-10 border-4 border-white/30 border-t-white rounded-full animate-spin" />
            </div>
          ) : (
            <div
              ref={scrollRef}
              className="w-full h-full overflow-y-auto flex flex-col items-center justify-start px-4"
              style={{ scrollbarWidth: 'none' }}
            >
              <div className="my-auto py-5 text-center">
                <p
                  className="leading-[1.55] drop-shadow-[0_2px_4px_rgba(0,0,0,0.65)]"
                  style={textConfigToCss(styles.hadith_text)}
                >
                  "{hadith?.text}"
                </p>
                <p
                  className="mt-7 font-bold italic"
                  style={textConfigToCss(styles.hadith_source, {
                    color: styles.hadith_source
                      ? argbToCssRgba(styles.hadith_source.color)
                      : argbToCssRgba(accent),
                  })}
                >
                  ({hadith?.source})
                </p>
              </div>
            </div>
          )}
        </div>
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
