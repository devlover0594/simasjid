import type {
  MurottalSchedule,
  PrayerTime,
  SimasjidSettings,
  SlideItem,
  TextStyleConfig,
  ThemePreset,
} from '../types/simasjid';

export const THEME_PRESETS: ThemePreset[] = [
  {
    name: 'Emerald Gold (Default)',
    primary: 0xff064e3b,
    accent: 0xffffc107,
    desc: 'Nuansa hijau gelap dipadukan dengan aksen emas elegan.',
  },
  {
    name: 'Sapphire Cyan',
    primary: 0xff0b4c8c,
    accent: 0xff00e5ff,
    desc: 'Nuansa biru laut dalam dengan aksen cyan modern.',
  },
  {
    name: 'Amethyst Pink',
    primary: 0xff4a148c,
    accent: 0xffe040fb,
    desc: 'Nuansa ungu karismatik dengan kilauan pink.',
  },
  {
    name: 'Ruby Rose',
    primary: 0xff880e4f,
    accent: 0xffff8a80,
    desc: 'Nuansa merah marun menawan berpadu rose.',
  },
  {
    name: 'Onyx Emerald',
    primary: 0xff121212,
    accent: 0xff00e676,
    desc: 'Nuansa hitam pekat dengan sorotan hijau zamrud.',
  },
  {
    name: 'Crimson Night',
    primary: 0xff6a040f,
    accent: 0xffe0e0e0,
    desc: 'Merah tua yang dalam dengan aksen abu-abu terang.',
  },
  {
    name: 'Oceanic Teal',
    primary: 0xff004d40,
    accent: 0xff80cbc4,
    desc: 'Hijau laut gelap yang menenangkan dengan aksen teal muda.',
  },
  {
    name: 'Royal Indigo',
    primary: 0xff1a237e,
    accent: 0xfff57f17,
    desc: 'Biru indigo yang megah dipadukan dengan oranye cerah.',
  },
];

export const TEXT_STYLE_ELEMENTS: Record<string, string> = {
  mosque_name: 'Nama Masjid',
  mosque_address: 'Alamat',
  clock: 'Jam Digital',
  date: 'Tanggal',
  running_text: 'Running Text',
  slide_title: 'Judul Slide',
  slide_content: 'Isi Slide',
  prayer_name: 'Nama Sholat',
  prayer_time: 'Jam Sholat',
  hadith_text: 'Teks Hadis',
  hadith_source: 'Sumber Hadis',
  performer_event_name: 'Nama Acara (Petugas)',
  performer_event_date: 'Tanggal Acara (Petugas)',
  performer_name: 'Nama Petugas',
  performer_role: 'Peran Petugas',
  footer_prayer_name: 'Nama Sholat (Footer)',
  footer_prayer_time: 'Jam Sholat (Footer)',
};

export const DEFAULT_TEXT_STYLES: Record<string, TextStyleConfig> = {
  mosque_name: {
    size: 48,
    color: 0xff82f102,
    font: 'Cairo',
    bold: true,
    italic: true,
  },
  mosque_address: {
    size: 18,
    color: 0xe6ffffff,
    font: 'Roboto',
  },
  clock: {
    size: 68,
    color: 0xff07ff30,
    font: 'Cairo',
    bold: true,
    italic: true,
  },
  date: {
    size: 30,
    color: 0xffffffff,
    font: 'Roboto',
  },
  running_text: {
    size: 24,
    color: 0xffffffff,
    font: 'Roboto',
    bold: true,
  },
  slide_title: {
    size: 28,
    color: 0xffffc107,
    font: 'Roboto',
    bold: true,
  },
  slide_content: {
    size: 18,
    color: 0xffffffff,
    font: 'Roboto',
  },
  prayer_name: {
    size: 20,
    color: 0xffffd740,
    font: 'Roboto',
    bold: true,
  },
  prayer_time: {
    size: 32,
    color: 0xffffffff,
    font: 'Roboto',
    bold: true,
  },
  hadith_text: {
    size: 28,
    color: 0xffffffff,
    font: 'Roboto',
  },
  hadith_source: {
    size: 22,
    color: 0xffffc107,
    font: 'Roboto',
    bold: true,
    italic: true,
  },
  performer_event_name: {
    size: 36,
    color: 0xffffc107,
    font: 'Roboto',
    bold: true,
  },
  performer_event_date: {
    size: 22,
    color: 0xb3ffffff,
    font: 'Roboto',
  },
  performer_name: {
    size: 32,
    color: 0xffffffff,
    font: 'Roboto',
    bold: true,
  },
  performer_role: {
    size: 24,
    color: 0xffffc107,
    font: 'Roboto',
  },
  footer_prayer_name: {
    size: 20,
    color: 0xffffc107,
    font: 'Roboto',
    bold: true,
  },
  footer_prayer_time: {
    size: 28,
    color: 0xffffffff,
    font: 'Roboto',
    bold: true,
  },
};

export const FONT_FAMILIES = [
  'Roboto',
  'Cairo',
  'Amiri',
  'Oswald',
  'Lato',
  'Open Sans',
];

export const COLOR_SWATCHES: number[] = [
  0xffffffff, // white
  0xff000000, // black
  0xfff44336, // red
  0xffe91e63, // pink
  0xff9c27b0, // purple
  0xff3f51b5, // indigo
  0xff2196f3, // blue
  0xff00bcd4, // cyan
  0xff009688, // teal
  0xff4caf50, // green
  0xff8bc34a, // lightGreen
  0xffcddc39, // lime
  0xffffeb3b, // yellow
  0xffffc107, // amber
  0xffff9800, // orange
  0xff795548, // brown
  0xff9e9e9e, // grey
  0xff82f102, // Default Mosque Name
  0xff07ff30, // Default Clock
];

export const QARIS = [
  'Abdullah-Al-Juhany',
  'Abdulrahman Al-Sudais',
  'Saad Al-Ghamdi',
  'Mishary Al-Afasy',
  'Yasser Al-Dosari',
];

export const PRAYER_NAMES = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'] as const;

export const DEFAULT_PRAYER_TIMES: PrayerTime[] = [
  { name: 'Subuh', time: '04:35' },
  { name: 'Dzuhur', time: '11:55' },
  { name: 'Ashar', time: '15:15' },
  { name: 'Maghrib', time: '17:58' },
  { name: 'Isya', time: '19:10' },
];

export const DEFAULT_SLIDES: SlideItem[] = [
  {
    title: 'Selamat Datang',
    content: 'Mohon luruskan dan rapatkan shaf sholat.',
  },
  {
    title: 'Kajian Rutin',
    content: "Setiap Ahad Ba'da Subuh bersama Ustadz Fulan.",
  },
  {
    title: 'Infaq Pembangunan',
    content: 'Salurkan infaq terbaik anda untuk pembangunan menara.',
  },
];

export function createDefaultMurottalSchedule(prayer: string): MurottalSchedule {
  return {
    prayer,
    enabled: false,
    minutes_before: 10,
    is_random: false,
    loop_count: 1,
    stop_before_adzan: 2,
    path: '',
    source_type: 'file',
    qari: 'Abdullah-Al-Juhany',
    surah_number: 1,
    tarhim_enabled: false,
    tarhim_minutes_before: 20,
    adzan_enabled: false,
    adzan_path: '',
  };
}

export const DEFAULT_MUROTTAL_SCHEDULES: MurottalSchedule[] = PRAYER_NAMES.map(
  (p) => createDefaultMurottalSchedule(p),
);

export const AVAILABLE_ASSETS = [
  'bg.jpg',
  'bgnotif.png',
  'card.png',
  'header.png',
  'jam.png',
  'runningtext.png',
  'slide.png',
  'sidecard.png',
];

export const INDONESIAN_MONTHS_SHORT = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

export const INDONESIAN_MONTHS_LONG = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

export const INDONESIAN_DAYS = [
  'Minggu',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
];

export const SHORT_DAYS = [
  { id: 1, label: 'Sen' },
  { id: 2, label: 'Sel' },
  { id: 3, label: 'Rab' },
  { id: 4, label: 'Kam' },
  { id: 5, label: 'Jum' },
  { id: 6, label: 'Sab' },
  { id: 7, label: 'Ahad' },
];

export const SURAHS_FALLBACK = [
  { nomor: 1, namaLatin: 'Al-Fatihah' },
  { nomor: 2, namaLatin: 'Al-Baqarah' },
  { nomor: 3, namaLatin: "Ali 'Imran" },
  { nomor: 4, namaLatin: "An-Nisa'" },
  { nomor: 5, namaLatin: "Al-Ma'idah" },
  { nomor: 6, namaLatin: "Al-An'am" },
  { nomor: 7, namaLatin: "Al-A'raf" },
  { nomor: 8, namaLatin: 'Al-Anfal' },
  { nomor: 9, namaLatin: 'At-Taubah' },
  { nomor: 10, namaLatin: 'Yunus' },
  { nomor: 11, namaLatin: 'Hud' },
  { nomor: 12, namaLatin: 'Yusuf' },
  { nomor: 13, namaLatin: "Ar-Ra'd" },
  { nomor: 14, namaLatin: 'Ibrahim' },
  { nomor: 15, namaLatin: 'Al-Hijr' },
  { nomor: 16, namaLatin: 'An-Nahl' },
  { nomor: 17, namaLatin: "Al-Isra'" },
  { nomor: 18, namaLatin: 'Al-Kahf' },
  { nomor: 19, namaLatin: 'Maryam' },
  { nomor: 20, namaLatin: 'Taha' },
  { nomor: 21, namaLatin: "Al-Anbiya'" },
  { nomor: 22, namaLatin: 'Al-Hajj' },
  { nomor: 23, namaLatin: "Al-Mu'minun" },
  { nomor: 24, namaLatin: 'An-Nur' },
  { nomor: 25, namaLatin: 'Al-Furqan' },
  { nomor: 26, namaLatin: "Asy-Syu'ara'" },
  { nomor: 27, namaLatin: 'An-Naml' },
  { nomor: 28, namaLatin: 'Al-Qasas' },
  { nomor: 29, namaLatin: "Al-'Ankabut" },
  { nomor: 30, namaLatin: 'Ar-Rum' },
  { nomor: 31, namaLatin: 'Luqman' },
  { nomor: 32, namaLatin: 'As-Sajdah' },
  { nomor: 33, namaLatin: 'Al-Ahzab' },
  { nomor: 34, namaLatin: "Saba'" },
  { nomor: 35, namaLatin: 'Fatir' },
  { nomor: 36, namaLatin: 'Yasin' },
  { nomor: 37, namaLatin: 'As-Saffat' },
  { nomor: 38, namaLatin: 'Sad' },
  { nomor: 39, namaLatin: 'Az-Zumar' },
  { nomor: 40, namaLatin: 'Ghafir' },
  { nomor: 41, namaLatin: 'Fussilat' },
  { nomor: 42, namaLatin: 'Asy-Syura' },
  { nomor: 43, namaLatin: 'Az-Zukhruf' },
  { nomor: 44, namaLatin: 'Ad-Dukhan' },
  { nomor: 45, namaLatin: 'Al-Jasiyah' },
  { nomor: 46, namaLatin: 'Al-Ahqaf' },
  { nomor: 47, namaLatin: 'Muhammad' },
  { nomor: 48, namaLatin: 'Al-Fath' },
  { nomor: 49, namaLatin: 'Al-Hujurat' },
  { nomor: 50, namaLatin: 'Qaf' },
  { nomor: 51, namaLatin: 'Az-Zariyat' },
  { nomor: 52, namaLatin: 'At-Tur' },
  { nomor: 53, namaLatin: 'An-Najm' },
  { nomor: 54, namaLatin: 'Al-Qamar' },
  { nomor: 55, namaLatin: 'Ar-Rahman' },
  { nomor: 56, namaLatin: "Al-Waqi'ah" },
  { nomor: 57, namaLatin: 'Al-Hadid' },
  { nomor: 58, namaLatin: 'Al-Mujadilah' },
  { nomor: 59, namaLatin: 'Al-Hasyr' },
  { nomor: 60, namaLatin: 'Al-Mumtahanah' },
  { nomor: 61, namaLatin: 'As-Saff' },
  { nomor: 62, namaLatin: "Al-Jumu'ah" },
  { nomor: 63, namaLatin: 'Al-Munafiqun' },
  { nomor: 64, namaLatin: 'At-Tagabun' },
  { nomor: 65, namaLatin: 'At-Talaq' },
  { nomor: 66, namaLatin: 'At-Tahrim' },
  { nomor: 67, namaLatin: 'Al-Mulk' },
  { nomor: 68, namaLatin: 'Al-Qalam' },
  { nomor: 69, namaLatin: 'Al-Haqqah' },
  { nomor: 70, namaLatin: "Al-Ma'arij" },
  { nomor: 71, namaLatin: 'Nuh' },
  { nomor: 72, namaLatin: 'Al-Jinn' },
  { nomor: 73, namaLatin: 'Al-Muzzammil' },
  { nomor: 74, namaLatin: 'Al-Muddassir' },
  { nomor: 75, namaLatin: 'Al-Qiyamah' },
  { nomor: 76, namaLatin: 'Al-Insan' },
  { nomor: 77, namaLatin: 'Al-Mursalat' },
  { nomor: 78, namaLatin: "An-Naba'" },
  { nomor: 79, namaLatin: "An-Nazi'at" },
  { nomor: 80, namaLatin: "'Abasa" },
  { nomor: 81, namaLatin: 'At-Takwir' },
  { nomor: 82, namaLatin: 'Al-Infitar' },
  { nomor: 83, namaLatin: 'Al-Mutaffifin' },
  { nomor: 84, namaLatin: 'Al-Insyiqaq' },
  { nomor: 85, namaLatin: 'Al-Buruj' },
  { nomor: 86, namaLatin: 'At-Tariq' },
  { nomor: 87, namaLatin: "Al-A'la" },
  { nomor: 88, namaLatin: 'Al-Ghasyiyah' },
  { nomor: 89, namaLatin: 'Al-Fajr' },
  { nomor: 90, namaLatin: 'Al-Balad' },
  { nomor: 91, namaLatin: 'Asy-Syams' },
  { nomor: 92, namaLatin: 'Al-Lail' },
  { nomor: 93, namaLatin: 'Ad-Duha' },
  { nomor: 94, namaLatin: 'Asy-Syarh' },
  { nomor: 95, namaLatin: 'At-Tin' },
  { nomor: 96, namaLatin: "Al-'Alaq" },
  { nomor: 97, namaLatin: 'Al-Qadr' },
  { nomor: 98, namaLatin: 'Al-Bayyinah' },
  { nomor: 99, namaLatin: 'Az-Zalzalah' },
  { nomor: 100, namaLatin: "Al-'Adiyat" },
  { nomor: 101, namaLatin: "Al-Qari'ah" },
  { nomor: 102, namaLatin: 'At-Takasur' },
  { nomor: 103, namaLatin: "Al-'Asr" },
  { nomor: 104, namaLatin: 'Al-Humazah' },
  { nomor: 105, namaLatin: 'Al-Fil' },
  { nomor: 106, namaLatin: 'Quraisy' },
  { nomor: 107, namaLatin: "Al-Ma'un" },
  { nomor: 108, namaLatin: 'Al-Kausar' },
  { nomor: 109, namaLatin: 'Al-Kafirun' },
  { nomor: 110, namaLatin: 'An-Nasr' },
  { nomor: 111, namaLatin: 'Al-Masad' },
  { nomor: 112, namaLatin: 'Al-Ikhlas' },
  { nomor: 113, namaLatin: 'Al-Falaq' },
  { nomor: 114, namaLatin: 'An-Nas' },
];

export function createDefaultSettings(displayId?: string): SimasjidSettings {
  return {
    displayId:
      displayId ||
      `SIMASJID-${Math.random().toString(16).substring(2, 10).toUpperCase()}`,
    mosque_name: 'MASJID AL MUNTAHA',
    mosque_address: 'Perum Bumi Cipta Laras',
    running_text:
      'Selamat Datang di Masjid Al Muntaha. Mohon luruskan dan rapatkan shaf.',
    bg_asset: 'bg.jpg',
    bg_dashboard: 'bg.jpg',
    bg_info: 'bg.jpg',
    bg_event: 'bg.jpg',
    bg_apply_all: false,
    card_asset: 'card.png',
    header_asset: 'header.png',
    jam_asset: 'jam.png',
    slide_asset: 'slide.png',
    sidecard_asset: 'sidecard.png',
    running_text_asset: 'runningtext.png',
    theme_primary_color: 0xff064e3b,
    theme_accent_color: 0xffffc107,
    logo_path: '',
    show_logo: false,
    logo_animation_enabled: false,
    rotation_duration_seconds: 90,
    slideshow_effect: 'fade',
    use_api_prayer_times: true,
    api_provider: 'MyQuran',
    kota_id: '1301',
    kota_name: 'KOTA JAKARTA',
    custom_prayer_times: DEFAULT_PRAYER_TIMES.map((p) => ({ ...p })),
    api_prayer_cache: null,
    last_prayer_update: null,
    hijri_adjustment: -2,
    hijri_anchor_date: null,
    hijri_anchor_day: null,
    hijri_anchor_month: null,
    hijri_anchor_year: null,
    notif_adzan_duration: 180,
    notif_iqomah_delay: 10,
    notif_iqomah_duration: 60,
    notif_text_adzan: 'MEMASUKI WAKTU',
    notif_text_iqomah: 'LURUSKAN DAN RAPATKAN SHAF',
    notif_text_iqomah_timer: 'DOA ANTARA ADZAN DAN IQOMAH NISCAYA AKAN TERKABUL',
    notif_sholat_duration: 600,
    notif_text_sholat: 'SHOLAT TELAH DIMULAI, HARAP TENANG',
    friday_mode_enabled: true,
    friday_khutbah_duration: 30,
    friday_khutbah_text:
      'Harap tenang saat khutbah berlangsung, nonaktifkan ponsel Anda.',
    slides: DEFAULT_SLIDES.map((s) => ({ ...s })),
    media_schedules: [],
    media_library: [],
    media_slideshow_enabled: false,
    murottal_schedules: DEFAULT_MUROTTAL_SCHEDULES.map((s) => ({ ...s })),
    hadith_show: true,
    hadith_interval: 5,
    hadith_speed: 30,
    custom_hadiths: [],
    events: [],
    performer_profiles: [],
    performer_schedules: [],
    iot_ip: '',
    iot_path_on: '/on',
    iot_path_off: '/off',
    show_imsakiyah_screen: false,
    imsakiyah_province: null,
    imsakiyah_city: null,
    power_tv_enabled: false,
    power_schedules: [],
    tunnel_enabled: false,
    vps_host: '',
    vps_user: '',
    vps_port: 8089,
    vps_pass: '',
    public_url: null,
    custom_assets: [],
    text_styles: structuredClone(DEFAULT_TEXT_STYLES),
  };
}

export function argbToCssRgba(argb: number, overrideAlpha?: number): string {
  const unsigned = argb >>> 0;
  const a = overrideAlpha !== undefined ? overrideAlpha : ((unsigned >>> 24) & 0xff) / 255;
  const r = (unsigned >>> 16) & 0xff;
  const g = (unsigned >>> 8) & 0xff;
  const b = unsigned & 0xff;
  return `rgba(${r}, ${g}, ${b}, ${a.toFixed(3)})`;
}

export function argbToHex(argb: number): string {
  const unsigned = argb >>> 0;
  const rgb = unsigned & 0xffffff;
  return '#' + rgb.toString(16).padStart(6, '0');
}

export function hexToArgbInt(hex: string): number {
  const clean = hex.replace('#', '').trim();
  if (clean.length === 6) {
    return parseInt('ff' + clean, 16) >>> 0;
  }
  if (clean.length === 8) {
    return parseInt(clean, 16) >>> 0;
  }
  return 0xffffffff;
}

export function resolveAssetUrl(path: string | undefined | null, fallback = '/assets/themes/default/bg.jpg'): string {
  if (!path || !path.trim()) return fallback;
  const trimmed = path.trim();
  if (
    trimmed.startsWith('http://') ||
    trimmed.startsWith('https://') ||
    trimmed.startsWith('data:') ||
    trimmed.startsWith('blob:')
  ) {
    return trimmed;
  }
  if (trimmed.startsWith('/assets/')) return trimmed;
  if (trimmed.startsWith('assets/')) return '/' + trimmed;
  if (!trimmed.includes('/')) return `/assets/themes/default/${trimmed}`;
  return fallback;
}
