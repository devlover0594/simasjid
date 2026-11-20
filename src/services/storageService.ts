import {
  DEFAULT_TEXT_STYLES,
  createDefaultMurottalSchedule,
  createDefaultSettings,
  PRAYER_NAMES,
} from '../constants/defaults';
import type {
  MurottalSchedule,
  SimasjidSettings,
  TextStyleConfig,
} from '../types/simasjid';

const STORAGE_KEY = 'simasjid_settings_v1';

export function loadSettings(): SimasjidSettings {
  const defaults = createDefaultSettings();
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      saveSettings(defaults);
      return defaults;
    }
    const parsed = JSON.parse(raw) as Partial<SimasjidSettings>;
    const merged: SimasjidSettings = {
      ...defaults,
      ...parsed,
      text_styles: {
        ...DEFAULT_TEXT_STYLES,
        ...(parsed.text_styles ?? {}),
      },
      murottal_schedules: normalizeMurottalSchedules(parsed.murottal_schedules),
    };
    return cleanupExpiredData(merged);
  } catch {
    return defaults;
  }
}

export function saveSettings(settings: SimasjidSettings): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
  } catch (err) {
    console.warn('Gagal menyimpan ke localStorage:', err);
  }
}

export function resetAllSettings(): SimasjidSettings {
  const existing = loadSettings();
  const fresh = createDefaultSettings(existing.displayId);
  saveSettings(fresh);
  return fresh;
}

function normalizeMurottalSchedules(
  input?: MurottalSchedule[],
): MurottalSchedule[] {
  const list = Array.isArray(input) ? [...input] : [];
  return PRAYER_NAMES.map((name) => {
    const found = list.find((s) => s.prayer === name);
    return found
      ? { ...createDefaultMurottalSchedule(name), ...found }
      : createDefaultMurottalSchedule(name);
  });
}

export function cleanupExpiredData(settings: SimasjidSettings): SimasjidSettings {
  const todayStr = getTodayIsoDate();
  const events = (settings.events ?? []).filter(
    (e) => !e.date || e.date >= todayStr,
  );
  const performer_schedules = (settings.performer_schedules ?? []).filter((s) => {
    const endStr = s.endDate || s.date;
    return !endStr || endStr >= todayStr;
  });

  if (
    events.length !== (settings.events ?? []).length ||
    performer_schedules.length !== (settings.performer_schedules ?? []).length
  ) {
    const updated = { ...settings, events, performer_schedules };
    saveSettings(updated);
    return updated;
  }
  return settings;
}

export function getTodayIsoDate(date = new Date()): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Export JSON backup compatible with both Flutter SIMasjid prefs format and React SIMasjid.
 */
export function exportBackupJson(settings: SimasjidSettings): string {
  const flutterCompat: Record<string, unknown> = {
    displayId: settings.displayId,
    mosque_name: settings.mosque_name,
    mosque_address: settings.mosque_address,
    running_text: settings.running_text,
    bg_asset: settings.bg_asset,
    bg_dashboard: settings.bg_dashboard,
    bg_info: settings.bg_info,
    bg_event: settings.bg_event,
    bg_apply_all: settings.bg_apply_all,
    theme_primary_color: settings.theme_primary_color,
    theme_accent_color: settings.theme_accent_color,
    logo_path: settings.logo_path,
    show_logo: settings.show_logo,
    logo_animation_enabled: settings.logo_animation_enabled,
    rotation_duration_seconds: settings.rotation_duration_seconds,
    slideshow_effect: settings.slideshow_effect,
    use_api_prayer_times: settings.use_api_prayer_times,
    api_provider: settings.api_provider,
    kota_id: settings.kota_id,
    kota_name: settings.kota_name,
    custom_prayer_times: JSON.stringify(settings.custom_prayer_times),
    hijri_adjustment: settings.hijri_adjustment,
    notif_adzan_duration: settings.notif_adzan_duration,
    notif_iqomah_delay: settings.notif_iqomah_delay,
    notif_iqomah_duration: settings.notif_iqomah_duration,
    notif_text_adzan: settings.notif_text_adzan,
    notif_text_iqomah: settings.notif_text_iqomah,
    notif_text_iqomah_timer: settings.notif_text_iqomah_timer,
    notif_sholat_duration: settings.notif_sholat_duration,
    notif_text_sholat: settings.notif_text_sholat,
    friday_mode_enabled: settings.friday_mode_enabled,
    friday_khutbah_duration: settings.friday_khutbah_duration,
    friday_khutbah_text: settings.friday_khutbah_text,
    slides: JSON.stringify(settings.slides),
    media_schedules: JSON.stringify(settings.media_schedules),
    media_library: JSON.stringify(settings.media_library),
    media_slideshow_enabled: settings.media_slideshow_enabled,
    murottal_schedules: JSON.stringify(settings.murottal_schedules),
    hadith_show: settings.hadith_show,
    hadith_interval: settings.hadith_interval,
    hadith_speed: settings.hadith_speed,
    custom_hadiths: JSON.stringify(settings.custom_hadiths),
    events: JSON.stringify(settings.events),
    performer_profiles: JSON.stringify(settings.performer_profiles),
    performer_schedules: JSON.stringify(settings.performer_schedules),
    iot_ip: settings.iot_ip,
    iot_path_on: settings.iot_path_on,
    iot_path_off: settings.iot_path_off,
    show_imsakiyah_screen: settings.show_imsakiyah_screen,
    imsakiyah_province: settings.imsakiyah_province,
    imsakiyah_city: settings.imsakiyah_city,
    power_tv_enabled: settings.power_tv_enabled,
    power_schedules: JSON.stringify(settings.power_schedules),
    tunnel_enabled: settings.tunnel_enabled,
    vps_host: settings.vps_host,
    vps_user: settings.vps_user,
    vps_port: settings.vps_port,
  };

  for (const [k, st] of Object.entries(settings.text_styles)) {
    flutterCompat[`${k}_size`] = st.size;
    flutterCompat[`${k}_color`] = st.color;
    flutterCompat[`${k}_font`] = st.font;
  }

  return JSON.stringify(flutterCompat, null, 2);
}

export function importBackupJson(jsonText: string): SimasjidSettings {
  const parsed = JSON.parse(jsonText) as Record<string, unknown>;
  const defaults = createDefaultSettings();

  const parseJsonField = <T>(val: unknown, fallback: T): T => {
    if (typeof val === 'string') {
      try {
        return JSON.parse(val) as T;
      } catch {
        return fallback;
      }
    }
    if (val !== undefined && val !== null) return val as T;
    return fallback;
  };

  // Check if backup is from Flutter SharedPreferences export or React native
  const nextStyles: Record<string, TextStyleConfig> = structuredClone(
    DEFAULT_TEXT_STYLES,
  );
  if (parsed.text_styles && typeof parsed.text_styles === 'object') {
    Object.assign(nextStyles, parsed.text_styles);
  } else {
    for (const key of Object.keys(DEFAULT_TEXT_STYLES)) {
      const sz = parsed[`${key}_size`];
      const cl = parsed[`${key}_color`];
      const fn = parsed[`${key}_font`];
      if (typeof sz === 'number') nextStyles[key].size = sz;
      if (typeof cl === 'number') nextStyles[key].color = cl;
      if (typeof fn === 'string') nextStyles[key].font = fn;
    }
  }

  const restored: SimasjidSettings = {
    ...defaults,
    displayId: typeof parsed.displayId === 'string' ? parsed.displayId : defaults.displayId,
    mosque_name: String(parsed.mosque_name ?? defaults.mosque_name),
    mosque_address: String(parsed.mosque_address ?? defaults.mosque_address),
    running_text: String(parsed.running_text ?? defaults.running_text),
    bg_asset: String(parsed.bg_asset ?? defaults.bg_asset),
    bg_dashboard: String(parsed.bg_dashboard ?? defaults.bg_dashboard),
    bg_info: String(parsed.bg_info ?? defaults.bg_info),
    bg_event: String(parsed.bg_event ?? defaults.bg_event),
    bg_apply_all: Boolean(parsed.bg_apply_all ?? defaults.bg_apply_all),
    theme_primary_color: Number(
      parsed.theme_primary_color ?? defaults.theme_primary_color,
    ),
    theme_accent_color: Number(
      parsed.theme_accent_color ?? defaults.theme_accent_color,
    ),
    logo_path: String(parsed.logo_path ?? defaults.logo_path),
    show_logo: Boolean(parsed.show_logo ?? defaults.show_logo),
    logo_animation_enabled: Boolean(
      parsed.logo_animation_enabled ?? defaults.logo_animation_enabled,
    ),
    rotation_duration_seconds: Number(
      parsed.rotation_duration_seconds ?? defaults.rotation_duration_seconds,
    ),
    slideshow_effect:
      (parsed.slideshow_effect as SimasjidSettings['slideshow_effect']) ??
      defaults.slideshow_effect,
    use_api_prayer_times: Boolean(
      parsed.use_api_prayer_times ?? defaults.use_api_prayer_times,
    ),
    api_provider:
      (parsed.api_provider as SimasjidSettings['api_provider']) ??
      defaults.api_provider,
    kota_id: parsed.kota_id ? String(parsed.kota_id) : defaults.kota_id,
    kota_name: parsed.kota_name ? String(parsed.kota_name) : defaults.kota_name,
    custom_prayer_times: parseJsonField(
      parsed.custom_prayer_times,
      defaults.custom_prayer_times,
    ),
    hijri_adjustment: Number(
      parsed.hijri_adjustment ?? defaults.hijri_adjustment,
    ),
    notif_adzan_duration: Number(
      parsed.notif_adzan_duration ?? defaults.notif_adzan_duration,
    ),
    notif_iqomah_delay: Number(
      parsed.notif_iqomah_delay ?? defaults.notif_iqomah_delay,
    ),
    notif_iqomah_duration: Number(
      parsed.notif_iqomah_duration ?? defaults.notif_iqomah_duration,
    ),
    notif_text_adzan: String(
      parsed.notif_text_adzan ?? defaults.notif_text_adzan,
    ),
    notif_text_iqomah: String(
      parsed.notif_text_iqomah ?? defaults.notif_text_iqomah,
    ),
    notif_text_iqomah_timer: String(
      parsed.notif_text_iqomah_timer ?? defaults.notif_text_iqomah_timer,
    ),
    notif_sholat_duration: Number(
      parsed.notif_sholat_duration ?? defaults.notif_sholat_duration,
    ),
    notif_text_sholat: String(
      parsed.notif_text_sholat ?? defaults.notif_text_sholat,
    ),
    friday_mode_enabled: Boolean(
      parsed.friday_mode_enabled ?? defaults.friday_mode_enabled,
    ),
    friday_khutbah_duration: Number(
      parsed.friday_khutbah_duration ?? defaults.friday_khutbah_duration,
    ),
    friday_khutbah_text: String(
      parsed.friday_khutbah_text ?? defaults.friday_khutbah_text,
    ),
    slides: parseJsonField(parsed.slides, defaults.slides),
    media_schedules: parseJsonField(
      parsed.media_schedules,
      defaults.media_schedules,
    ),
    media_library: parseJsonField(parsed.media_library, defaults.media_library),
    media_slideshow_enabled: Boolean(
      parsed.media_slideshow_enabled ?? defaults.media_slideshow_enabled,
    ),
    murottal_schedules: normalizeMurottalSchedules(
      parseJsonField(parsed.murottal_schedules, defaults.murottal_schedules),
    ),
    hadith_show: Boolean(parsed.hadith_show ?? defaults.hadith_show),
    hadith_interval: Number(parsed.hadith_interval ?? defaults.hadith_interval),
    hadith_speed: Number(parsed.hadith_speed ?? defaults.hadith_speed),
    custom_hadiths: parseJsonField(
      parsed.custom_hadiths,
      defaults.custom_hadiths,
    ),
    events: parseJsonField(parsed.events, defaults.events),
    performer_profiles: parseJsonField(
      parsed.performer_profiles,
      defaults.performer_profiles,
    ),
    performer_schedules: parseJsonField(
      parsed.performer_schedules,
      defaults.performer_schedules,
    ),
    iot_ip: String(parsed.iot_ip ?? defaults.iot_ip),
    iot_path_on: String(parsed.iot_path_on ?? defaults.iot_path_on),
    iot_path_off: String(parsed.iot_path_off ?? defaults.iot_path_off),
    show_imsakiyah_screen: Boolean(
      parsed.show_imsakiyah_screen ?? defaults.show_imsakiyah_screen,
    ),
    imsakiyah_province: parsed.imsakiyah_province
      ? String(parsed.imsakiyah_province)
      : defaults.imsakiyah_province,
    imsakiyah_city: parsed.imsakiyah_city
      ? String(parsed.imsakiyah_city)
      : defaults.imsakiyah_city,
    power_tv_enabled: Boolean(
      parsed.power_tv_enabled ?? defaults.power_tv_enabled,
    ),
    power_schedules: parseJsonField(
      parsed.power_schedules,
      defaults.power_schedules,
    ),
    tunnel_enabled: Boolean(parsed.tunnel_enabled ?? defaults.tunnel_enabled),
    vps_host: String(parsed.vps_host ?? defaults.vps_host),
    vps_user: String(parsed.vps_user ?? defaults.vps_user),
    vps_port: Number(parsed.vps_port ?? defaults.vps_port),
    text_styles: nextStyles,
  };

  saveSettings(restored);
  return restored;
}
