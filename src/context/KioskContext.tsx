import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  INDONESIAN_MONTHS_SHORT,
  PRAYER_NAMES,
} from '../constants/defaults';
import {
  fetchHijriDate,
  fetchPrayerTimes,
} from '../services/apiRepository';
import { advanceHijriDate } from '../services/hijriCalculator';
import {
  cleanupExpiredData,
  getTodayIsoDate,
  importBackupJson,
  loadSettings,
  resetAllSettings,
  saveSettings,
} from '../services/storageService';
import type {
  ActiveMediaPlayback,
  MurottalSchedule,
  NotifState,
  PerformerSchedule,
  PrayerTime,
  SimasjidSettings,
} from '../types/simasjid';

interface KioskContextValue {
  settings: SimasjidSettings;
  updateSettings: (
    updater:
      | Partial<SimasjidSettings>
      | ((prev: SimasjidSettings) => SimasjidSettings),
  ) => void;
  replaceSettings: (next: SimasjidSettings) => void;
  resetSettings: () => void;
  restoreBackup: (jsonText: string) => void;

  // Real-time clock & dates
  timeString: string;
  dateString: string;
  hijriDateString: string;

  // Prayer times
  prayerTimes: PrayerTime[];
  nextPrayerIndex: number;
  refreshPrayerTimes: (overrideSettings?: SimasjidSettings) => Promise<boolean>;
  refreshHijriDate: (adjustment?: number) => Promise<void>;

  // Screen rotation & active performer
  screenIndex: number;
  setScreenIndex: React.Dispatch<React.SetStateAction<number>>;
  activePerformerEvent: PerformerSchedule | null;

  // Notification & audio state
  notifState: NotifState;
  currentPrayerName: string;
  countdownSeconds: number;
  notifTitle: string;
  notifMessage: string;
  dismissNotification: () => void;

  // Media / Murottal overlay
  activeMedia: ActiveMediaPlayback | null;
  onMediaFinished: () => void;
  stopActiveMedia: () => void;

  // Power TV sleep overlay
  isScreenPowerOn: boolean;
  wakeScreenTemporarily: () => void;

  // IoT Relay
  triggerRelay: (turnOn: boolean) => Promise<boolean>;

  // Navigation / modal views
  viewMode: 'kiosk' | 'settings' | 'admin';
  openSettings: () => void;
  closeSettings: () => void;
  openAdmin: () => void;
  openKiosk: () => void;
  handleSecretGesture: () => void;

  // Audio autoplay notice helper
  audioBlockedWarning: boolean;
  clearAudioBlockedWarning: () => void;
}

const KioskContext = createContext<KioskContextValue | null>(null);

function minutesFromHm(hm?: string | null): number | null {
  if (!hm) return null;
  const parts = hm.trim().split(':');
  if (parts.length !== 2) return null;
  const h = parseInt(parts[0], 10);
  const m = parseInt(parts[1], 10);
  if (Number.isNaN(h) || Number.isNaN(m)) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

function getInitialViewMode(): 'kiosk' | 'settings' | 'admin' {
  if (typeof window !== 'undefined' && window.location.hash.startsWith('#/admin')) {
    return 'admin';
  }
  return 'kiosk';
}

export const KioskProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [settings, setSettings] = useState<SimasjidSettings>(() => loadSettings());
  const settingsRef = useRef<SimasjidSettings>(settings);
  settingsRef.current = settings;

  const [viewMode, setViewMode] = useState<'kiosk' | 'settings' | 'admin'>(
    getInitialViewMode,
  );

  const [prayerTimes, setPrayerTimes] = useState<PrayerTime[]>(() => {
    const s = settingsRef.current;
    if (!s.use_api_prayer_times) {
      return s.custom_prayer_times;
    }
    return s.api_prayer_cache ?? s.custom_prayer_times;
  });
  const prayerTimesRef = useRef<PrayerTime[]>(prayerTimes);
  prayerTimesRef.current = prayerTimes;

  const [timeString, setTimeString] = useState('');
  const [dateString, setDateString] = useState('');
  const [hijriDateString, setHijriDateString] = useState('');

  const [screenIndex, setScreenIndex] = useState(0);
  const [notifState, setNotifState] = useState<NotifState>('none');
  const notifStateRef = useRef<NotifState>(notifState);
  notifStateRef.current = notifState;

  const [currentPrayerName, setCurrentPrayerName] = useState('');
  const currentPrayerNameRef = useRef('');
  currentPrayerNameRef.current = currentPrayerName;

  const [countdownSeconds, setCountdownSeconds] = useState(0);
  const [activeMedia, setActiveMedia] = useState<ActiveMediaPlayback | null>(null);
  const activeMediaRef = useRef<ActiveMediaPlayback | null>(activeMedia);
  activeMediaRef.current = activeMedia;

  const [isScreenPowerOn, setIsScreenPowerOn] = useState(true);
  const [powerOverrideUntilMs, setPowerOverrideUntilMs] = useState(0);
  const [audioBlockedWarning, setAudioBlockedWarning] = useState(false);

  const activeMurottalScheduleRef = useRef<MurottalSchedule | null>(null);
  const mediaSlideIndexRef = useRef(0);
  const firedTodayRef = useRef<Set<string>>(new Set());
  const adzanAudioRef = useRef<HTMLAudioElement | null>(null);
  const notifTimerRef = useRef<number | null>(null);
  const countdownTimerRef = useRef<number | null>(null);
  const mediaEndTimerRef = useRef<number | null>(null);
  const tapCountRef = useRef(0);
  const tapResetTimerRef = useRef<number | null>(null);

  // Sync hash routing for #/admin
  useEffect(() => {
    const onHashChange = () => {
      if (window.location.hash.startsWith('#/admin')) {
        setViewMode('admin');
      } else if (viewMode === 'admin') {
        setViewMode('kiosk');
      }
    };
    window.addEventListener('hashchange', onHashChange);
    return () => window.removeEventListener('hashchange', onHashChange);
  }, [viewMode]);

  const stopAdzanAudio = useCallback(() => {
    if (adzanAudioRef.current) {
      try {
        adzanAudioRef.current.pause();
        adzanAudioRef.current.currentTime = 0;
      } catch {
        // ignore
      }
      adzanAudioRef.current = null;
    }
  }, []);

  const triggerRelay = useCallback(async (turnOn: boolean): Promise<boolean> => {
    const ip = settingsRef.current.iot_ip.trim();
    if (!ip) return false;
    const rawPath = turnOn
      ? settingsRef.current.iot_path_on
      : settingsRef.current.iot_path_off;
    const path = rawPath.startsWith('/') ? rawPath.trim() : `/${rawPath.trim()}`;
    const cleanIp = ip.replace(/^https?:\/\//i, '');
    const url = `http://${cleanIp}${path}`;
    try {
      const controller = new AbortController();
      const t = window.setTimeout(() => controller.abort(), 2000);
      await fetch(url, { mode: 'no-cors', signal: controller.signal });
      window.clearTimeout(t);
      return true;
    } catch {
      return false;
    }
  }, []);

  const refreshPrayerTimes = useCallback(
    async (overrideSettings?: SimasjidSettings): Promise<boolean> => {
      const s = overrideSettings ?? settingsRef.current;
      if (!s.use_api_prayer_times) {
        setPrayerTimes(s.custom_prayer_times);
        return true;
      }

      const res = await fetchPrayerTimes({
        kotaId: s.api_provider === 'EQuran' ? s.imsakiyah_province : s.kota_id,
        kotaName: s.api_provider === 'EQuran' ? s.imsakiyah_city : s.kota_name,
        provider: s.api_provider,
      });

      if (res && Object.keys(res).length > 0) {
        const nextList: PrayerTime[] = PRAYER_NAMES.map((name) => ({
          name,
          time: res[name] ?? res[name.toLowerCase()] ?? '--:--',
        }));
        setPrayerTimes(nextList);
        const updated: SimasjidSettings = {
          ...settingsRef.current,
          api_prayer_cache: nextList,
          last_prayer_update: new Date().toISOString(),
        };
        settingsRef.current = updated;
        setSettings(updated);
        saveSettings(updated);
        return true;
      }

      const fallback = s.api_prayer_cache ?? s.custom_prayer_times;
      setPrayerTimes(fallback);
      return false;
    },
    [],
  );

  const refreshHijriDate = useCallback(async (adjustment?: number) => {
    const s = settingsRef.current;
    if (!s.use_api_prayer_times) return;
    const adj = adjustment ?? s.hijri_adjustment;
    const data = await fetchHijriDate(adj);
    if (data) {
      const todayIso = getTodayIsoDate();
      const updated: SimasjidSettings = {
        ...settingsRef.current,
        hijri_anchor_date: todayIso,
        hijri_anchor_day: data.day,
        hijri_anchor_month: data.month,
        hijri_anchor_year: data.year,
      };
      settingsRef.current = updated;
      setSettings(updated);
      saveSettings(updated);
    }
  }, []);

  const updateSettings = useCallback(
    (
      updater:
        | Partial<SimasjidSettings>
        | ((prev: SimasjidSettings) => SimasjidSettings),
    ) => {
      setSettings((prev) => {
        const next =
          typeof updater === 'function' ? updater(prev) : { ...prev, ...updater };
        settingsRef.current = next;
        saveSettings(next);

        if (!next.use_api_prayer_times) {
          setPrayerTimes(next.custom_prayer_times);
        } else if (
          prev.use_api_prayer_times !== next.use_api_prayer_times ||
          prev.api_provider !== next.api_provider ||
          prev.kota_id !== next.kota_id
        ) {
          void refreshPrayerTimes(next);
        }

        if (prev.hijri_adjustment !== next.hijri_adjustment) {
          void refreshHijriDate(next.hijri_adjustment);
        }
        return next;
      });
    },
    [refreshPrayerTimes, refreshHijriDate],
  );

  const replaceSettings = useCallback(
    (next: SimasjidSettings) => {
      const cleaned = cleanupExpiredData(next);
      settingsRef.current = cleaned;
      setSettings(cleaned);
      saveSettings(cleaned);
      if (!cleaned.use_api_prayer_times) {
        setPrayerTimes(cleaned.custom_prayer_times);
      } else {
        void refreshPrayerTimes(cleaned);
      }
      void refreshHijriDate(cleaned.hijri_adjustment);
    },
    [refreshPrayerTimes, refreshHijriDate],
  );

  const resetSettings = useCallback(() => {
    const fresh = resetAllSettings();
    settingsRef.current = fresh;
    setSettings(fresh);
    setPrayerTimes(fresh.custom_prayer_times);
    void refreshPrayerTimes(fresh);
    void refreshHijriDate(fresh.hijri_adjustment);
  }, [refreshPrayerTimes, refreshHijriDate]);

  const restoreBackup = useCallback(
    (jsonText: string) => {
      const restored = importBackupJson(jsonText);
      replaceSettings(restored);
    },
    [replaceSettings],
  );

  // Initial API fetches
  useEffect(() => {
    void refreshPrayerTimes();
    void refreshHijriDate();
  }, [refreshPrayerTimes, refreshHijriDate]);

  const activePerformerEvent = useMemo(() => {
    const todayStr = getTodayIsoDate();
    return (
      settings.performer_schedules.find((ev) => {
        if (!ev.date) return false;
        const endStr = ev.endDate || ev.date;
        return todayStr >= ev.date && todayStr <= endStr;
      }) ?? null
    );
  }, [settings.performer_schedules]);

  // Notification State Machine
  const startSholatSequence = useCallback(() => {
    stopAdzanAudio();
    setNotifState('sholat');
    if (notifTimerRef.current) window.clearTimeout(notifTimerRef.current);
    const durMs = Math.max(5, settingsRef.current.notif_sholat_duration) * 1000;
    notifTimerRef.current = window.setTimeout(() => {
      setNotifState('none');
      void triggerRelay(false);
    }, durMs);
  }, [stopAdzanAudio, triggerRelay]);

  const startIqomahSequence = useCallback(
    (prayerName: string) => {
      setNotifState('iqomah');
      setCurrentPrayerName(prayerName);
      if (notifTimerRef.current) window.clearTimeout(notifTimerRef.current);
      const durMs = Math.max(5, settingsRef.current.notif_iqomah_duration) * 1000;
      notifTimerRef.current = window.setTimeout(() => {
        startSholatSequence();
      }, durMs);
    },
    [startSholatSequence],
  );

  const startKhutbahSequence = useCallback(() => {
    setNotifState('khutbah');
    if (notifTimerRef.current) window.clearTimeout(notifTimerRef.current);
    const durMs = Math.max(1, settingsRef.current.friday_khutbah_duration) * 60000;
    notifTimerRef.current = window.setTimeout(() => {
      startSholatSequence();
    }, durMs);
  }, [startSholatSequence]);

  const startCountdownSequence = useCallback(
    (prayerName: string, delayMinutes: number) => {
      setNotifState('countdown');
      setCountdownSeconds(delayMinutes * 60);
      if (countdownTimerRef.current) {
        window.clearInterval(countdownTimerRef.current);
      }
      countdownTimerRef.current = window.setInterval(() => {
        setCountdownSeconds((prev) => {
          if (prev <= 1) {
            if (countdownTimerRef.current) {
              window.clearInterval(countdownTimerRef.current);
              countdownTimerRef.current = null;
            }
            startIqomahSequence(prayerName);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    },
    [startIqomahSequence],
  );

  const startAdzanSequence = useCallback(
    (prayerName: string) => {
      const now = new Date();
      const isFriday = now.getDay() === 5;
      const isFridayDzuhur =
        prayerName === 'Dzuhur' &&
        isFriday &&
        settingsRef.current.friday_mode_enabled;
      const effectiveName = isFridayDzuhur ? 'Jumat' : prayerName;

      // Cancel active media if adzan starts
      if (mediaEndTimerRef.current) {
        window.clearTimeout(mediaEndTimerRef.current);
        mediaEndTimerRef.current = null;
      }
      activeMurottalScheduleRef.current = null;
      setActiveMedia(null);

      setNotifState('adzan');
      setCurrentPrayerName(effectiveName);
      void triggerRelay(true);

      if (notifTimerRef.current) window.clearTimeout(notifTimerRef.current);
      if (countdownTimerRef.current) {
        window.clearInterval(countdownTimerRef.current);
      }

      const adzanDurMs = Math.max(5, settingsRef.current.notif_adzan_duration) * 1000;
      notifTimerRef.current = window.setTimeout(() => {
        stopAdzanAudio();
        if (isFridayDzuhur) {
          startKhutbahSequence();
        } else if (settingsRef.current.notif_iqomah_delay > 0) {
          startCountdownSequence(
            effectiveName,
            settingsRef.current.notif_iqomah_delay,
          );
        } else {
          startIqomahSequence(effectiveName);
        }
      }, adzanDurMs);
    },
    [
      stopAdzanAudio,
      startKhutbahSequence,
      startCountdownSequence,
      startIqomahSequence,
      triggerRelay,
    ],
  );

  const dismissNotification = useCallback(() => {
    if (notifTimerRef.current) window.clearTimeout(notifTimerRef.current);
    if (countdownTimerRef.current) window.clearInterval(countdownTimerRef.current);
    stopAdzanAudio();
    setNotifState('none');
    void triggerRelay(false);
  }, [stopAdzanAudio, triggerRelay]);

  const playAdzanAudio = useCallback(() => {
    stopAdzanAudio();
    try {
      const audio = new Audio('/assets/audio/adzan.mp3');
      adzanAudioRef.current = audio;
      void audio.play().catch(() => {
        setAudioBlockedWarning(true);
      });
    } catch {
      // ignore
    }
  }, [stopAdzanAudio]);

  const stopActiveMedia = useCallback(() => {
    if (mediaEndTimerRef.current) {
      window.clearTimeout(mediaEndTimerRef.current);
      mediaEndTimerRef.current = null;
    }
    if (activeMediaRef.current?.isMurottal) {
      void triggerRelay(false);
    } else if (activeMediaRef.current) {
      void triggerRelay(false);
    }
    activeMurottalScheduleRef.current = null;
    setActiveMedia(null);
  }, [triggerRelay]);

  const startMurottal = useCallback(
    (item: ActiveMediaPlayback, schedule: MurottalSchedule | null) => {
      activeMurottalScheduleRef.current = schedule;
      setActiveMedia(item);
      if (mediaEndTimerRef.current) window.clearTimeout(mediaEndTimerRef.current);
      void triggerRelay(true);

      const stopMins = item.stop_before_adzan ?? 0;
      if (stopMins > 0 && item.prayer_time_ms) {
        const stopAt = item.prayer_time_ms - stopMins * 60000;
        const waitMs = stopAt - Date.now();
        if (waitMs > 0) {
          mediaEndTimerRef.current = window.setTimeout(() => {
            stopActiveMedia();
          }, waitMs);
        }
      }
    },
    [stopActiveMedia, triggerRelay],
  );

  const onMediaFinished = useCallback(() => {
    const curr = activeMediaRef.current;
    const sched = activeMurottalScheduleRef.current;
    if (curr && curr.isMurottal && sched && sched.source_type === 'api') {
      const stopMins = curr.stop_before_adzan ?? 2;
      const stopAt = (curr.prayer_time_ms ?? 0) - stopMins * 60000;
      if (Date.now() < stopAt) {
        let nextSurah = (curr.surah_number ?? 1) + 1;
        if (nextSurah > 114) nextSurah = 1;
        const qariSlug = (sched.qari || 'Abdullah-Al-Juhany').replace(/ /g, '-');
        const surahPadded = String(nextSurah).padStart(3, '0');
        const nextUrl = `https://cdn.equran.id/audio-full/${qariSlug}/${surahPadded}.mp3`;
        setActiveMedia({
          ...curr,
          path: nextUrl,
          type: 'audio',
          surah_number: nextSurah,
        });
        return;
      }
    }
    stopActiveMedia();
  }, [stopActiveMedia]);

  // 1-second master tick: clock, Hijri, prayer trigger, media trigger, murottal/tarhim, power TV
  useEffect(() => {
    const updateTick = () => {
      const now = new Date();
      const s = settingsRef.current;

      // Clock & Gregorian date
      const hh = String(now.getHours()).padStart(2, '0');
      const mm = String(now.getMinutes()).padStart(2, '0');
      const ss = String(now.getSeconds()).padStart(2, '0');
      setTimeString(`${hh}:${mm}:${ss}`);
      setDateString(
        `${now.getDate()} ${INDONESIAN_MONTHS_SHORT[now.getMonth()]} ${now.getFullYear()}`,
      );

      // Hijri date
      if (
        s.hijri_anchor_date &&
        s.hijri_anchor_day != null &&
        s.hijri_anchor_month != null &&
        s.hijri_anchor_year != null
      ) {
        const anchor = new Date(`${s.hijri_anchor_date}T00:00:00`);
        const todayStart = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
        );
        const diffDays = Math.floor(
          (todayStart.getTime() - anchor.getTime()) / 86400000,
        );
        const hijri = advanceHijriDate(
          s.hijri_anchor_day,
          s.hijri_anchor_month,
          s.hijri_anchor_year,
          diffDays,
        );
        setHijriDateString(hijri.formatted);
      } else {
        setHijriDateString('');
      }

      const currentMin = now.getHours() * 60 + now.getMinutes();
      // Dart weekday: Mon=1..Sun=7. JS getDay(): Sun=0..Sat=6
      const jsDay = now.getDay();
      const weekday = jsDay === 0 ? 7 : jsDay;

      // Midnight reset
      if (now.getHours() === 0 && now.getMinutes() === 0 && now.getSeconds() === 0) {
        firedTodayRef.current.clear();
        const cleaned = cleanupExpiredData(settingsRef.current);
        if (cleaned !== settingsRef.current) {
          settingsRef.current = cleaned;
          setSettings(cleaned);
        }
        void refreshPrayerTimes();
      }

      // Check Power TV
      if (!s.power_tv_enabled || s.power_schedules.length === 0) {
        setIsScreenPowerOn(true);
      } else if (Date.now() > powerOverrideUntilMs) {
        let shouldBeOn = false;
        for (const sched of s.power_schedules) {
          const days = (sched.days || '1,2,3,4,5,6,7').split(',');
          if (!days.includes(String(weekday))) continue;
          const onMin = minutesFromHm(sched.on) ?? 4 * 60;
          const offMin = minutesFromHm(sched.off) ?? 21 * 60;
          if (onMin < offMin) {
            if (currentMin >= onMin && currentMin < offMin) {
              shouldBeOn = true;
              break;
            }
          } else {
            if (currentMin >= onMin || currentMin < offMin) {
              shouldBeOn = true;
              break;
            }
          }
        }
        setIsScreenPowerOn(shouldBeOn);
      }

      // Check Prayer Time
      if (notifStateRef.current === 'none') {
        for (const p of prayerTimesRef.current) {
          const pm = minutesFromHm(p.time);
          if (pm == null || pm !== currentMin) continue;
          const key = `adzan:${p.name}`;
          if (firedTodayRef.current.has(key)) continue;
          firedTodayRef.current.add(key);

          const hasAdzanAudio = s.murottal_schedules.some(
            (ms) => ms.prayer === p.name && ms.adzan_enabled,
          );
          if (hasAdzanAudio) {
            playAdzanAudio();
          }
          startAdzanSequence(p.name);
          break;
        }
      }

      // Check Media Schedules
      if (notifStateRef.current === 'none' && activeMediaRef.current === null) {
        for (let i = 0; i < s.media_schedules.length; i++) {
          const item = s.media_schedules[i];
          const tm = minutesFromHm(item.time);
          if (tm == null || tm !== currentMin) continue;
          if (!Array.isArray(item.days) || !item.days.includes(weekday)) continue;
          const key = `media:${i}`;
          if (firedTodayRef.current.has(key)) continue;
          firedTodayRef.current.add(key);

          setActiveMedia({
            path: item.path,
            type: item.type,
            play_count: item.play_count || 1,
            isMurottal: false,
          });
          void triggerRelay(true);
          break;
        }
      }

      // Check Tarhim & Murottal Schedules
      if (notifStateRef.current === 'none' && activeMediaRef.current === null) {
        for (const sched of s.murottal_schedules) {
          const prayer = prayerTimesRef.current.find((p) => p.name === sched.prayer);
          const pm = minutesFromHm(prayer?.time);
          if (pm == null) continue;
          const prayerDt = new Date(
            now.getFullYear(),
            now.getMonth(),
            now.getDate(),
          );
          prayerDt.setMinutes(pm);

          if (sched.tarhim_enabled) {
            const tarhimDt = new Date(
              prayerDt.getTime() - sched.tarhim_minutes_before * 60000,
            );
            if (
              now.getHours() === tarhimDt.getHours() &&
              now.getMinutes() === tarhimDt.getMinutes()
            ) {
              const tKey = `tarhim:${sched.prayer}`;
              if (!firedTodayRef.current.has(tKey)) {
                firedTodayRef.current.add(tKey);
                startMurottal(
                  {
                    path: '/assets/audio/tarhim.mp3',
                    type: 'audio',
                    play_count: 1,
                    stop_before_adzan: 0,
                    prayer_time_ms: prayerDt.getTime(),
                    isMurottal: true,
                  },
                  null,
                );
                break;
              }
            }
          }

          if (!sched.enabled) continue;
          const murottalDt = new Date(
            prayerDt.getTime() - sched.minutes_before * 60000,
          );
          if (
            now.getHours() === murottalDt.getHours() &&
            now.getMinutes() === murottalDt.getMinutes()
          ) {
            const mKey = `murottal:${sched.prayer}`;
            if (firedTodayRef.current.has(mKey)) continue;

            let mediaPath = '';
            let mediaType: ActiveMediaPlayback['type'] = 'audio';
            let surahNumber: number | undefined;

            if (sched.source_type === 'api') {
              const qariSlug = (sched.qari || 'Abdullah-Al-Juhany').replace(
                / /g,
                '-',
              );
              let surah = sched.surah_number || 1;
              if (sched.is_random) {
                surah = (Date.now() % 114) + 1;
              }
              surahNumber = surah;
              mediaPath = `https://cdn.equran.id/audio-full/${qariSlug}/${String(surah).padStart(3, '0')}.mp3`;
              mediaType = 'audio';
            } else {
              mediaPath = sched.path || '';
              if (sched.is_random) {
                const playable = s.media_library.filter(
                  (m) => m.type === 'audio' || m.type === 'video',
                );
                if (playable.length > 0) {
                  const chosen = playable[Date.now() % playable.length];
                  mediaPath = chosen.path;
                  mediaType = chosen.type;
                }
              } else if (mediaPath) {
                const libItem = s.media_library.find((m) => m.path === mediaPath);
                mediaType = libItem?.type ?? 'video';
              }
            }

            if (mediaPath) {
              firedTodayRef.current.add(mKey);
              startMurottal(
                {
                  path: mediaPath,
                  type: mediaType,
                  play_count: sched.loop_count || 1,
                  stop_before_adzan: sched.stop_before_adzan ?? 2,
                  prayer_time_ms: prayerDt.getTime(),
                  surah_number: surahNumber,
                  isMurottal: true,
                },
                sched,
              );
              break;
            }
          }
        }
      }
    };

    updateTick();
    const timer = window.setInterval(updateTick, 1000);
    return () => window.clearInterval(timer);
  }, [
    playAdzanAudio,
    powerOverrideUntilMs,
    refreshPrayerTimes,
    startAdzanSequence,
    startMurottal,
    triggerRelay,
  ]);

  // Screen rotation timer
  useEffect(() => {
    const durationMs = Math.max(10, settings.rotation_duration_seconds) * 1000;
    const timer = window.setInterval(() => {
      if (
        notifStateRef.current !== 'none' ||
        activeMediaRef.current !== null ||
        viewMode !== 'kiosk'
      ) {
        return;
      }
      const s = settingsRef.current;
      const activeScreens = [0];
      if (s.hadith_show) activeScreens.push(1);
      activeScreens.push(2);
      activeScreens.push(3);
      if (activePerformerEvent) activeScreens.push(4);
      if (s.show_imsakiyah_screen) activeScreens.push(5);
      if (s.media_slideshow_enabled && s.media_library.length > 0) {
        activeScreens.push(6);
      }

      setScreenIndex((prev) => {
        const currPos = activeScreens.indexOf(prev);
        const nextPos = currPos === -1 ? 0 : (currPos + 1) % activeScreens.length;
        const nextScreen = activeScreens[nextPos];

        if (nextScreen === 6 && s.media_library.length > 0) {
          const item =
            s.media_library[mediaSlideIndexRef.current % s.media_library.length];
          mediaSlideIndexRef.current =
            (mediaSlideIndexRef.current + 1) % s.media_library.length;
          if (item?.path) {
            setActiveMedia({
              path: item.path,
              type: item.type,
              play_count: 1,
              isMurottal: false,
            });
          }
        }
        return nextScreen;
      });
    }, durationMs);

    return () => window.clearInterval(timer);
  }, [
    settings.rotation_duration_seconds,
    settings.hadith_show,
    settings.show_imsakiyah_screen,
    settings.media_slideshow_enabled,
    settings.media_library.length,
    activePerformerEvent,
    viewMode,
  ]);

  // Cleanup timers on unmount
  useEffect(() => {
    return () => {
      if (notifTimerRef.current) window.clearTimeout(notifTimerRef.current);
      if (countdownTimerRef.current) window.clearInterval(countdownTimerRef.current);
      if (mediaEndTimerRef.current) window.clearTimeout(mediaEndTimerRef.current);
      if (tapResetTimerRef.current) window.clearTimeout(tapResetTimerRef.current);
      stopAdzanAudio();
    };
  }, [stopAdzanAudio]);

  const nextPrayerIndex = useMemo(() => {
    const parts = timeString.split(':');
    const h = parseInt(parts[0] ?? '', 10);
    const m = parseInt(parts[1] ?? '', 10);
    const currentMin = Number.isNaN(h) || Number.isNaN(m) ? 0 : h * 60 + m;
    for (let i = 0; i < prayerTimes.length; i++) {
      const pm = minutesFromHm(prayerTimes[i].time);
      if (pm !== null && pm > currentMin) return i;
    }
    return 0;
  }, [prayerTimes, timeString]);

  const notifTitle = useMemo(() => {
    switch (notifState) {
      case 'adzan':
        return settings.notif_text_adzan;
      case 'iqomah':
        return 'IQOMAH';
      case 'sholat':
        return 'SHOLAT BERJAMAAH';
      case 'khutbah':
        return 'KHUTBAH JUMAT';
      case 'countdown':
        return 'MENUJU IQOMAH';
      default:
        return '';
    }
  }, [notifState, settings.notif_text_adzan]);

  const notifMessage = useMemo(() => {
    switch (notifState) {
      case 'khutbah':
        return settings.friday_khutbah_text;
      case 'iqomah':
        return settings.notif_text_iqomah;
      case 'sholat':
        return settings.notif_text_sholat;
      case 'countdown': {
        const isFriday = new Date().getDay() === 5;
        if (currentPrayerName === 'Dzuhur' && isFriday) return '';
        return settings.notif_text_iqomah_timer;
      }
      case 'adzan':
        return 'Mari Segera Menuju Masjid';
      default:
        return '';
    }
  }, [notifState, settings, currentPrayerName]);

  const openSettings = useCallback(() => {
    setViewMode('settings');
  }, []);

  const closeSettings = useCallback(() => {
    setViewMode('kiosk');
  }, []);

  const openAdmin = useCallback(() => {
    window.location.hash = '#/admin';
    setViewMode('admin');
  }, []);

  const openKiosk = useCallback(() => {
    window.location.hash = '#/';
    setViewMode('kiosk');
  }, []);

  const handleSecretGesture = useCallback(() => {
    tapCountRef.current += 1;
    if (tapCountRef.current >= 3) {
      tapCountRef.current = 0;
      if (tapResetTimerRef.current) window.clearTimeout(tapResetTimerRef.current);
      setViewMode('settings');
    } else {
      if (tapResetTimerRef.current) window.clearTimeout(tapResetTimerRef.current);
      tapResetTimerRef.current = window.setTimeout(() => {
        tapCountRef.current = 0;
      }, 500);
    }
  }, []);

  const wakeScreenTemporarily = useCallback(() => {
    setPowerOverrideUntilMs(Date.now() + 5 * 60000);
    setIsScreenPowerOn(true);
  }, []);

  const value: KioskContextValue = {
    settings,
    updateSettings,
    replaceSettings,
    resetSettings,
    restoreBackup,
    timeString,
    dateString,
    hijriDateString,
    prayerTimes,
    nextPrayerIndex,
    refreshPrayerTimes,
    refreshHijriDate,
    screenIndex,
    setScreenIndex,
    activePerformerEvent,
    notifState,
    currentPrayerName,
    countdownSeconds,
    notifTitle,
    notifMessage,
    dismissNotification,
    activeMedia,
    onMediaFinished,
    stopActiveMedia,
    isScreenPowerOn,
    wakeScreenTemporarily,
    triggerRelay,
    viewMode,
    openSettings,
    closeSettings,
    openAdmin,
    openKiosk,
    handleSecretGesture,
    audioBlockedWarning,
    clearAudioBlockedWarning: () => setAudioBlockedWarning(false),
  };

  return (
    <KioskContext.Provider value={value}>{children}</KioskContext.Provider>
  );
};

// eslint-disable-next-line react-refresh/only-export-components
export function useKiosk(): KioskContextValue {
  const ctx = useContext(KioskContext);
  if (!ctx) throw new Error('useKiosk must be used inside KioskProvider');
  return ctx;
}
