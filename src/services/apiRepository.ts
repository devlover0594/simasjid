import type {
  ApiProvider,
  CityItem,
  HadithItem,
  ImsakiyahDay,
  SurahItem,
} from '../types/simasjid';
import { HIJRI_MONTH_NAMES } from './hijriCalculator';

async function fetchWithTimeout(
  url: string,
  options: RequestInit = {},
  timeoutMs = 10000,
): Promise<Response> {
  const controller = new AbortController();
  const id = window.setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    window.clearTimeout(id);
  }
}

export async function fetchPrayerTimes(params: {
  kotaId?: string | null;
  kotaName?: string | null;
  provider?: ApiProvider;
}): Promise<Record<string, string> | null> {
  const provider = params.provider ?? 'MyQuran';
  try {
    if (provider === 'AlAdhan') {
      return await fetchAlAdhan(params.kotaName);
    }
    if (provider === 'EQuran') {
      return await fetchEQuranDaily(params.kotaId, params.kotaName);
    }

    const kotaId = params.kotaId;
    if (!kotaId) return null;

    const now = new Date();
    const yyyy = now.getFullYear().toString();
    const mm = String(now.getMonth() + 1).padStart(2, '0');
    const dd = String(now.getDate()).padStart(2, '0');

    const attempts = [
      `https://api.myquran.com/v3/sholat/jadwal/${encodeURIComponent(kotaId)}/today?tz=Asia%2FJakarta`,
      `https://api.myquran.com/v3/sholat/jadwal/${encodeURIComponent(kotaId)}/${yyyy}/${mm}/${dd}`,
      `https://api.myquran.com/v3/sholat?kota=${encodeURIComponent(kotaId)}`,
    ];

    for (const url of attempts) {
      try {
        const resp = await fetchWithTimeout(url, {
          headers: { Accept: 'application/json' },
        });
        if (!resp.ok) continue;
        const decoded = (await resp.json()) as Record<string, unknown>;
        if (!decoded || typeof decoded !== 'object') continue;

        const data = decoded.data as Record<string, unknown> | undefined;
        if (data && typeof data === 'object') {
          const jadwalRaw = data.jadwal;
          if (jadwalRaw && typeof jadwalRaw === 'object' && !Array.isArray(jadwalRaw)) {
            const jadwalGroup = jadwalRaw as Record<string, unknown>;
            const todayKey = `${yyyy}-${mm}-${dd}`;
            let jadwal: Record<string, unknown> | null = null;

            if (
              jadwalGroup[todayKey] &&
              typeof jadwalGroup[todayKey] === 'object'
            ) {
              jadwal = jadwalGroup[todayKey] as Record<string, unknown>;
            } else {
              for (const val of Object.values(jadwalGroup)) {
                if (
                  val &&
                  typeof val === 'object' &&
                  ('subuh' in val || 'Subuh' in val)
                ) {
                  jadwal = val as Record<string, unknown>;
                  break;
                }
              }
            }

            if (!jadwal && ('subuh' in jadwalGroup || 'Subuh' in jadwalGroup)) {
              jadwal = jadwalGroup;
            }

            if (jadwal) {
              const map: Record<string, string> = {};
              const addIf = (k: string, name: string) => {
                if (jadwal && jadwal[k] != null) map[name] = String(jadwal[k]);
              };
              addIf('subuh', 'Subuh');
              addIf('dzuhur', 'Dzuhur');
              addIf('ashar', 'Ashar');
              addIf('maghrib', 'Maghrib');
              addIf('isya', 'Isya');
              if (Object.keys(map).length > 0) return map;
            }
          } else if (Array.isArray(jadwalRaw)) {
            const day = now.getDate();
            const entry = jadwalRaw.find(
              (e) =>
                e &&
                typeof e === 'object' &&
                (e.tanggal === day || String(e.tanggal).includes(dd)),
            ) as Record<string, unknown> | undefined;
            if (entry) {
              const map: Record<string, string> = {};
              if (entry.subuh) map.Subuh = String(entry.subuh);
              if (entry.dzuhur) map.Dzuhur = String(entry.dzuhur);
              if (entry.ashar) map.Ashar = String(entry.ashar);
              if (entry.maghrib) map.Maghrib = String(entry.maghrib);
              if (entry.isya) map.Isya = String(entry.isya);
              if (Object.keys(map).length > 0) return map;
            }
          }
        }

        const found: Record<string, string> = {};
        const scan = (node: unknown) => {
          if (Array.isArray(node)) {
            node.forEach(scan);
          } else if (node && typeof node === 'object') {
            for (const [rawKey, val] of Object.entries(
              node as Record<string, unknown>,
            )) {
              if (val == null) continue;
              const k = rawKey.toLowerCase();
              if (typeof val !== 'object') {
                if (k === 'subuh') found.Subuh = String(val);
                if (k === 'dzuhur' || k === 'dhuhr') found.Dzuhur = String(val);
                if (k === 'ashar' || k === 'asar') found.Ashar = String(val);
                if (k === 'maghrib') found.Maghrib = String(val);
                if (k === 'isya' || k === 'isha') found.Isya = String(val);
              } else {
                scan(val);
              }
            }
          }
        };
        scan(decoded);
        if (Object.keys(found).length > 0) return found;
      } catch {
        continue;
      }
    }
    return null;
  } catch {
    return null;
  }
}

async function fetchAlAdhan(
  kotaName?: string | null,
): Promise<Record<string, string> | null> {
  if (!kotaName) return null;
  const city = kotaName.replace(/(KAB\.|KOTA|ADM\.)\s*/gi, '').trim();
  try {
    const url = `https://api.aladhan.com/v1/timingsByCity?city=${encodeURIComponent(city)}&country=Indonesia&method=20`;
    const resp = await fetchWithTimeout(url);
    if (!resp.ok) return null;
    const decoded = await resp.json();
    const timings = decoded?.data?.timings;
    if (!timings) return null;
    const map: Record<string, string> = {};
    if (timings.Fajr) map.Subuh = String(timings.Fajr).slice(0, 5);
    if (timings.Dhuhr) map.Dzuhur = String(timings.Dhuhr).slice(0, 5);
    if (timings.Asr) map.Ashar = String(timings.Asr).slice(0, 5);
    if (timings.Maghrib) map.Maghrib = String(timings.Maghrib).slice(0, 5);
    if (timings.Isha) map.Isya = String(timings.Isha).slice(0, 5);
    return Object.keys(map).length > 0 ? map : null;
  } catch {
    return null;
  }
}

async function fetchEQuranDaily(
  province?: string | null,
  city?: string | null,
): Promise<Record<string, string> | null> {
  if (!province || !city) return null;
  try {
    const resp = await fetchWithTimeout('https://equran.id/api/v2/shalat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ provinsi: province, kabkota: city }),
    });
    if (!resp.ok) return null;
    const body = await resp.json();
    if (body?.code === 200 && body?.data) {
      const list = body.data.jadwal ?? body.data.imsakiyah;
      if (Array.isArray(list)) {
        const day = new Date().getDate();
        const entry = list.find(
          (e: Record<string, unknown>) =>
            e.tanggal === day || String(e.tanggal) === String(day),
        );
        if (entry) {
          return {
            Subuh: String(entry.subuh),
            Dzuhur: String(entry.dzuhur),
            Ashar: String(entry.ashar),
            Maghrib: String(entry.maghrib),
            Isya: String(entry.isya),
          };
        }
      }
    }
  } catch {
    // ignore
  }
  return null;
}

export async function fetchProvincesShalatEQuran(): Promise<string[] | null> {
  try {
    const resp = await fetchWithTimeout(
      'https://equran.id/api/v2/shalat/provinsi',
    );
    if (!resp.ok) return null;
    const body = await resp.json();
    if (body?.code === 200 && Array.isArray(body.data)) {
      return body.data.map(String);
    }
  } catch {
    // ignore
  }
  return null;
}

export async function fetchCitiesShalatEQuran(
  province: string,
): Promise<string[] | null> {
  try {
    const resp = await fetchWithTimeout(
      'https://equran.id/api/v2/shalat/kabkota',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ provinsi: province }),
      },
    );
    if (!resp.ok) return null;
    const body = await resp.json();
    if (body?.code === 200 && Array.isArray(body.data)) {
      return body.data.map(String);
    }
  } catch {
    // ignore
  }
  return null;
}

export async function fetchMonthlyImsakiyahEQuran(
  province: string,
  city: string,
): Promise<ImsakiyahDay[] | null> {
  try {
    const resp = await fetchWithTimeout(
      'https://equran.id/api/v2/shalat',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ provinsi: province, kabkota: city }),
      },
      15000,
    );
    if (!resp.ok) return null;
    const body = await resp.json();
    if (body?.code === 200 && body?.data) {
      const list = body.data.jadwal ?? body.data.imsakiyah;
      if (Array.isArray(list)) {
        return list.map((e: Record<string, unknown>) => ({
          tanggal: String(e.tanggal_lengkap ?? e.tanggal ?? ''),
          imsak: String(e.imsak ?? ''),
          subuh: String(e.subuh ?? ''),
          terbit: String(e.terbit ?? ''),
          dhuha: String(e.dhuha ?? ''),
          dzuhur: String(e.dzuhur ?? ''),
          ashar: String(e.ashar ?? ''),
          maghrib: String(e.maghrib ?? ''),
          isya: String(e.isya ?? ''),
        }));
      }
    }
  } catch {
    // ignore
  }
  return null;
}

export async function fetchHijriDate(adjustment = -2): Promise<{
  day: number;
  month: number;
  year: number;
  monthName: string;
} | null> {
  try {
    const resp = await fetchWithTimeout(
      `https://api.myquran.com/v2/cal/hijr/?adj=${adjustment}`,
    );
    if (!resp.ok) return null;
    const decoded = await resp.json();
    if (decoded?.status === true && decoded?.data) {
      const data = decoded.data;
      if (Array.isArray(data.num) && data.num.length >= 7) {
        const day = parseInt(String(data.num[4]), 10) || 0;
        const month = parseInt(String(data.num[5]), 10) || 0;
        const year = parseInt(String(data.num[6]), 10) || 0;
        if (year < 1400 || year > 1500) return null;

        let monthName = '';
        if (Array.isArray(data.date) && data.date.length >= 2) {
          const parts = String(data.date[1]).split(' ');
          if (parts.length >= 3) {
            monthName = parts.slice(1, parts.length - 2).join(' ');
          }
        }
        if (!monthName && month >= 1 && month <= 12) {
          monthName = HIJRI_MONTH_NAMES[month - 1];
        }
        return { day, month, year, monthName };
      }
    }
  } catch {
    // ignore
  }
  return null;
}

export async function fetchRandomHadith(): Promise<HadithItem | null> {
  try {
    const resp = await fetchWithTimeout(
      'https://api.myquran.com/v3/hadis/enc/random',
    );
    if (!resp.ok) return null;
    const decoded = await resp.json();
    const data = decoded?.data;
    const text = data?.text?.id ? String(data.text.id) : null;
    const source = data?.takhrij ? String(data.takhrij) : null;
    if (text && source) return { text, source };
  } catch {
    // ignore
  }
  return null;
}

export async function fetchCities(): Promise<CityItem[] | null> {
  try {
    const resp = await fetchWithTimeout(
      'https://api.myquran.com/v3/sholat/kabkota/semua',
      { headers: { Accept: 'application/json' } },
    );
    if (!resp.ok) return null;
    const decoded = await resp.json();
    if (Array.isArray(decoded?.data)) {
      return decoded.data
        .filter((item: unknown) => item && typeof item === 'object')
        .map((item: Record<string, unknown>) => ({
          id: String(item.id ?? ''),
          lokasi: String(item.lokasi ?? ''),
        }));
    }
  } catch {
    // ignore
  }
  return null;
}

export async function fetchSurahsEQuran(): Promise<SurahItem[] | null> {
  try {
    const resp = await fetchWithTimeout('https://equran.id/api/v2/surat');
    if (!resp.ok) return null;
    const decoded = await resp.json();
    if (Array.isArray(decoded?.data)) {
      return decoded.data as SurahItem[];
    }
  } catch {
    // ignore
  }
  return null;
}
