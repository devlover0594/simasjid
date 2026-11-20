import React from 'react';
import { argbToCssRgba } from '../../constants/defaults';
import type { PrayerTime, TextStyleConfig } from '../../types/simasjid';
import { textConfigToCss } from '../../utils/styleHelpers';

interface FooterPrayerBarProps {
  prayerTimes: PrayerTime[];
  primaryColor: number;
  accentColor: number;
  textStyles: Record<string, TextStyleConfig>;
  darkBg?: boolean;
}

export const FooterPrayerBar: React.FC<FooterPrayerBarProps> = ({
  prayerTimes,
  primaryColor,
  accentColor,
  textStyles,
  darkBg = false,
}) => {
  if (!prayerTimes.length) return null;

  return (
    <div
      className="w-full py-[14px] px-5 flex items-center justify-evenly shrink-0"
      style={{
        backgroundColor: darkBg
          ? 'rgba(0, 0, 0, 0.8)'
          : argbToCssRgba(primaryColor, 0.8),
      }}
    >
      {prayerTimes.map((pt) => (
        <div key={pt.name} className="flex flex-col items-center">
          <span
            className="stroked-text-sm font-bold leading-tight"
            style={textConfigToCss(textStyles.footer_prayer_name, {
              color: textStyles.footer_prayer_name
                ? argbToCssRgba(textStyles.footer_prayer_name.color)
                : argbToCssRgba(accentColor),
            })}
          >
            {pt.name}
          </span>
          <span
            className="stroked-text-sm font-bold tabular-nums leading-tight mt-0.5"
            style={textConfigToCss(textStyles.footer_prayer_time)}
          >
            {pt.time}
          </span>
        </div>
      ))}
    </div>
  );
};
