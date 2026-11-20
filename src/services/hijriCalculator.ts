export const HIJRI_MONTH_NAMES = [
  'Muharram',
  'Safar',
  'Rabiul Awal',
  'Rabiul Akhir',
  'Jumadil Awal',
  'Jumadil Akhir',
  'Rajab',
  "Sya'ban",
  'Ramadhan',
  'Syawwal',
  'Dzulqaidah',
  'Dzulhijah',
] as const;

export interface HijriDate {
  day: number;
  month: number;
  year: number;
  monthName: string;
  formatted: string;
}

export function advanceHijriDate(
  anchorDay: number,
  anchorMonth: number,
  anchorYear: number,
  diffDays: number,
): HijriDate {
  let hDay = anchorDay + Math.max(0, diffDays);
  let hMonth = anchorMonth;
  let hYear = anchorYear;

  while (true) {
    const daysInMonth = hMonth % 2 !== 0 ? 30 : 29;
    if (hDay <= daysInMonth) break;
    hDay -= daysInMonth;
    hMonth++;
    if (hMonth > 12) {
      hMonth = 1;
      hYear++;
    }
  }

  const monthName =
    hMonth >= 1 && hMonth <= 12 ? HIJRI_MONTH_NAMES[hMonth - 1] : '';
  return {
    day: hDay,
    month: hMonth,
    year: hYear,
    monthName,
    formatted: `${hDay} ${monthName} ${hYear} H`,
  };
}
