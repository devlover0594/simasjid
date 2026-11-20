import type { CSSProperties } from 'react';
import {
  argbToCssRgba,
  INDONESIAN_DAYS,
  INDONESIAN_MONTHS_LONG,
  INDONESIAN_MONTHS_SHORT,
} from '../constants/defaults';
import type { TextStyleConfig } from '../types/simasjid';

export function textConfigToCss(
  cfg?: TextStyleConfig,
  overrides?: CSSProperties,
): CSSProperties {
  if (!cfg) return overrides ?? {};
  return {
    fontSize: `${cfg.size}px`,
    color: argbToCssRgba(cfg.color),
    fontFamily: `'${cfg.font}', sans-serif`,
    fontWeight: cfg.bold ? 700 : undefined,
    fontStyle: cfg.italic ? 'italic' : undefined,
    ...overrides,
  };
}

export function formatShortDateId(isoDate: string): string {
  const parts = isoDate.split('-');
  if (parts.length !== 3) return isoDate;
  const year = parts[0];
  const monthIdx = parseInt(parts[1], 10) - 1;
  const day = parseInt(parts[2], 10);
  if (monthIdx < 0 || monthIdx > 11 || Number.isNaN(day)) return isoDate;
  return `${day} ${INDONESIAN_MONTHS_SHORT[monthIdx]} ${year}`;
}

export function formatDateRangeId(dateStr: string, endDateStr?: string): string {
  try {
    const dt = new Date(`${dateStr}T00:00:00`);
    if (Number.isNaN(dt.getTime())) return dateStr;

    const fullFmt = (d: Date) =>
      `${INDONESIAN_DAYS[d.getDay()]}, ${d.getDate()} ${INDONESIAN_MONTHS_LONG[d.getMonth()]} ${d.getFullYear()}`;
    const shortFmt = (d: Date) =>
      `${d.getDate()} ${INDONESIAN_MONTHS_SHORT[d.getMonth()]} ${d.getFullYear()}`;

    if (endDateStr && endDateStr !== dateStr) {
      const endDt = new Date(`${endDateStr}T00:00:00`);
      if (!Number.isNaN(endDt.getTime())) {
        return `${shortFmt(dt)} - ${fullFmt(endDt)}`;
      }
    }
    return fullFmt(dt);
  } catch {
    return dateStr;
  }
}

export function formatMmSs(totalSeconds: number): string {
  const safe = Math.max(0, totalSeconds);
  const m = Math.floor(safe / 60);
  const s = safe % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}
