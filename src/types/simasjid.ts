export type NotifState = 'none' | 'adzan' | 'countdown' | 'khutbah' | 'iqomah' | 'sholat';

export type ApiProvider = 'MyQuran' | 'AlAdhan' | 'EQuran';

export type SlideshowEffect = 'fade' | 'slide' | 'zoom';

export type MediaType = 'image' | 'video' | 'audio' | 'youtube';

export interface PrayerTime {
  name: string;
  time: string;
}

export interface SlideItem {
  title: string;
  content: string;
}

export interface MurottalSchedule {
  prayer: string;
  enabled: boolean;
  minutes_before: number;
  is_random: boolean;
  loop_count: number;
  stop_before_adzan: number;
  path?: string;
  source_type: 'file' | 'api';
  qari?: string;
  surah_number?: number;
  current_surah?: number;
  tarhim_enabled: boolean;
  tarhim_minutes_before: number;
  adzan_enabled: boolean;
  adzan_path?: string;
}

export interface MediaLibraryItem {
  id: string;
  name: string;
  path: string;
  type: MediaType;
}

export interface MediaScheduleItem {
  path: string;
  type: MediaType;
  time: string;
  is_loop: boolean;
  play_count: number;
  days: number[]; // 1 = Senin ... 7 = Ahad
}

export interface HadithItem {
  text: string;
  source: string;
}

export interface EventItem {
  title: string;
  date: string; // YYYY-MM-DD
}

export interface PerformerProfile {
  id: string;
  name: string;
  role: string;
  photoPath: string;
}

export interface PerformerSchedule {
  name: string;
  date: string; // YYYY-MM-DD
  endDate?: string; // YYYY-MM-DD
  performerIds: string[];
}

export interface PowerSchedule {
  on: string; // HH:mm
  off: string; // HH:mm
  days: string; // comma-separated 1..7 e.g. '1,2,3,4,5,6,7'
}

export interface TextStyleConfig {
  size: number;
  color: number; // ARGB 32-bit int e.g. 0xFFFFFFFF
  font: string;
  bold?: boolean;
  italic?: boolean;
}

export interface ThemePreset {
  name: string;
  primary: number; // ARGB int
  accent: number; // ARGB int
  desc: string;
}

export interface ActiveMediaPlayback {
  path: string;
  type: MediaType;
  play_count: number;
  stop_before_adzan?: number;
  prayer_time_ms?: number;
  surah_number?: number;
  isMurottal: boolean;
}

export interface CityItem {
  id: string;
  lokasi: string;
}

export interface SurahItem {
  nomor: number;
  nama: string;
  namaLatin: string;
  jumlahAyat: number;
  arti: string;
}

export interface ImsakiyahDay {
  tanggal: string;
  imsak: string;
  subuh: string;
  terbit: string;
  dhuha: string;
  dzuhur: string;
  ashar: string;
  maghrib: string;
  isya: string;
}

export interface SimasjidSettings {
  displayId: string;
  mosque_name: string;
  mosque_address: string;
  running_text: string;

  // Assets & Background
  bg_asset: string;
  bg_dashboard: string;
  bg_info: string;
  bg_event: string;
  bg_apply_all: boolean;
  card_asset: string;
  header_asset: string;
  jam_asset: string;
  slide_asset: string;
  sidecard_asset: string;
  running_text_asset: string;

  // Theme & Logo & Slideshow
  theme_primary_color: number;
  theme_accent_color: number;
  logo_path: string;
  show_logo: boolean;
  logo_animation_enabled: boolean;
  rotation_duration_seconds: number;
  slideshow_effect: SlideshowEffect;

  // Prayer & Location
  use_api_prayer_times: boolean;
  api_provider: ApiProvider;
  kota_id: string | null;
  kota_name: string | null;
  custom_prayer_times: PrayerTime[];
  api_prayer_cache: PrayerTime[] | null;
  last_prayer_update: string | null;
  hijri_adjustment: number;
  hijri_anchor_date: string | null;
  hijri_anchor_day: number | null;
  hijri_anchor_month: number | null;
  hijri_anchor_year: number | null;

  // Notification & Friday Mode
  notif_adzan_duration: number;
  notif_iqomah_delay: number;
  notif_iqomah_duration: number;
  notif_text_adzan: string;
  notif_text_iqomah: string;
  notif_text_iqomah_timer: string;
  notif_sholat_duration: number;
  notif_text_sholat: string;
  friday_mode_enabled: boolean;
  friday_khutbah_duration: number;
  friday_khutbah_text: string;

  // Slides, Media, Murottal
  slides: SlideItem[];
  media_schedules: MediaScheduleItem[];
  media_library: MediaLibraryItem[];
  media_slideshow_enabled: boolean;
  murottal_schedules: MurottalSchedule[];

  // Hadith
  hadith_show: boolean;
  hadith_interval: number;
  hadith_speed: number;
  custom_hadiths: HadithItem[];

  // Events & Performers
  events: EventItem[];
  performer_profiles: PerformerProfile[];
  performer_schedules: PerformerSchedule[];

  // IoT
  iot_ip: string;
  iot_path_on: string;
  iot_path_off: string;

  // Imsakiyah
  show_imsakiyah_screen: boolean;
  imsakiyah_province: string | null;
  imsakiyah_city: string | null;

  // Power TV
  power_tv_enabled: boolean;
  power_schedules: PowerSchedule[];

  // Remote / Tunnel (config persisted; SSH daemon not available in browser)
  tunnel_enabled: boolean;
  vps_host: string;
  vps_user: string;
  vps_port: number;
  vps_pass: string;
  public_url: string | null;

  // Custom Assets & Text Styles
  custom_assets: string[];
  text_styles: Record<string, TextStyleConfig>;
}
