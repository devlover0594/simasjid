import React, { useEffect, useState } from 'react';
import { argbToCssRgba } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { textConfigToCss } from '../../utils/styleHelpers';
import { FooterPrayerBar } from './FooterPrayerBar';

export const InfoScreen: React.FC = () => {
  const { settings, timeString, prayerTimes } = useKiosk();
  const slides = settings.slides;
  const [currentPage, setCurrentPage] = useState(0);

  const primary = settings.theme_primary_color;
  const accent = settings.theme_accent_color;
  const styles = settings.text_styles;

  useEffect(() => {
    if (slides.length <= 1) return;
    const timer = window.setInterval(() => {
      setCurrentPage((prev) => (prev + 1) % slides.length);
    }, 10000);
    return () => window.clearInterval(timer);
  }, [slides.length]);

  useEffect(() => {
    if (currentPage >= slides.length && slides.length > 0) {
      setCurrentPage(0);
    }
  }, [slides.length, currentPage]);

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
          INFORMASI MASJID
        </span>
        <span className="stroked-text-sm text-[24px] font-bold text-white tabular-nums">
          {timeString}
        </span>
      </div>

      {/* Main Carousel */}
      <div className="flex-1 flex items-center justify-center overflow-hidden px-6">
        {slides.length === 0 ? (
          <p className="text-white/70 text-[24px]">
            Tidak ada informasi saat ini.
          </p>
        ) : (
          <div className="relative w-full h-[500px] flex items-center justify-center overflow-hidden">
            {slides.map((slide, idx) => {
              const offset = idx - currentPage;
              const isActive = idx === currentPage;
              // Wrap circularly if >= 3 slides
              let displayOffset = offset;
              if (slides.length >= 3) {
                if (offset > slides.length / 2) displayOffset = offset - slides.length;
                if (offset < -slides.length / 2) displayOffset = offset + slides.length;
              }
              const visible = Math.abs(displayOffset) <= 1;
              if (!visible) return null;

              const translateX = displayOffset * 74; // %
              const scale = isActive ? 1 : 0.8;
              const opacity = isActive ? 1 : 0.6;
              const zIndex = isActive ? 10 : 5;

              return (
                <div
                  key={`${slide.title}-${idx}`}
                  onClick={() => setCurrentPage(idx)}
                  className="absolute w-[68%] h-[440px] rounded-[25px] backdrop-blur-[10px] p-8 flex flex-col justify-center cursor-pointer transition-all duration-600 ease-out shadow-[0_10px_25px_rgba(0,0,0,0.55)]"
                  style={{
                    transform: `translateX(${translateX}%) scale(${scale})`,
                    opacity,
                    zIndex,
                    backgroundColor: argbToCssRgba(primary, 0.5),
                    border: isActive
                      ? `2px solid ${argbToCssRgba(accent)}`
                      : `1.5px solid ${argbToCssRgba(accent, 0.3)}`,
                  }}
                >
                  <h2
                    className="font-bold text-center line-clamp-2"
                    style={textConfigToCss(styles.slide_title, {
                      color: argbToCssRgba(accent),
                      fontSize: `${Math.max(28, styles.slide_title?.size ?? 32)}px`,
                    })}
                  >
                    {slide.title}
                  </h2>
                  <div className="mt-5 flex-1 flex items-center justify-center overflow-y-auto">
                    <p
                      className="text-center leading-[1.5]"
                      style={textConfigToCss(styles.slide_content, {
                        fontSize: `${Math.max(20, styles.slide_content?.size ?? 22)}px`,
                      })}
                    >
                      {slide.content}
                    </p>
                  </div>
                </div>
              );
            })}
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
