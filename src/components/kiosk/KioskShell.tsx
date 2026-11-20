import React, { useEffect, useRef, useState } from 'react';
import { Globe, Moon, Settings, Volume2 } from 'lucide-react';
import { resolveAssetUrl } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { DashboardScreen } from './DashboardScreen';
import { EventScreen } from './EventScreen';
import { HadithScreen } from './HadithScreen';
import { ImsakiyahScreen } from './ImsakiyahScreen';
import { InfoScreen } from './InfoScreen';
import { MediaOverlay } from './MediaOverlay';
import { NotifOverlay } from './NotifOverlay';
import { PerformerScreen } from './PerformerScreen';

const DESIGN_WIDTH = 1280;
const DESIGN_HEIGHT = 720;

export const KioskShell: React.FC = () => {
  const {
    settings,
    screenIndex,
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
    handleSecretGesture,
    openSettings,
    openAdmin,
    viewMode,
    audioBlockedWarning,
    clearAudioBlockedWarning,
  } = useKiosk();

  const wrapperRef = useRef<HTMLDivElement | null>(null);
  const [scale, setScale] = useState(1);
  const [bgFailed, setBgFailed] = useState(false);
  const [logoFailed, setLogoFailed] = useState(false);

  // Measure viewport to proportionally scale 1280x720 stage like Flutter FittedBox
  useEffect(() => {
    const updateScale = () => {
      const vw = window.innerWidth;
      const vh = window.innerHeight;
      const s = Math.min(vw / DESIGN_WIDTH, vh / DESIGN_HEIGHT);
      setScale(s > 0 ? s : 1);
    };
    updateScale();
    window.addEventListener('resize', updateScale);
    return () => window.removeEventListener('resize', updateScale);
  }, []);

  // Triple Enter / Space keyboard shortcut to open Settings
  useEffect(() => {
    if (viewMode !== 'kiosk') return;
    const onKeyDown = (e: KeyboardEvent) => {
      const tag = (e.target as HTMLElement | null)?.tagName;
      if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;
      if (e.key === 'Enter' || e.key === ' ') {
        handleSecretGesture();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [handleSecretGesture, viewMode]);

  const getCurrentBackground = (): string => {
    const fallback = settings.bg_asset || 'bg.jpg';
    switch (screenIndex) {
      case 1:
      case 2:
        return settings.bg_info || fallback;
      case 3:
        return settings.bg_event || fallback;
      case 0:
      case 4:
      case 5:
      default:
        return settings.bg_dashboard || fallback;
    }
  };

  const bgUrl = resolveAssetUrl(getCurrentBackground());

  useEffect(() => {
    setBgFailed(false);
  }, [bgUrl]);

  useEffect(() => {
    setLogoFailed(false);
  }, [settings.logo_path]);

  const animClass =
    settings.slideshow_effect === 'slide'
      ? 'animate-screen-slide'
      : settings.slideshow_effect === 'zoom'
        ? 'animate-screen-zoom'
        : 'animate-screen-fade';

  const renderScreen = () => {
    switch (screenIndex) {
      case 1:
        return <HadithScreen />;
      case 2:
        return <InfoScreen />;
      case 3:
        return <EventScreen />;
      case 4:
        return <PerformerScreen />;
      case 5:
        return <ImsakiyahScreen />;
      case 0:
      default:
        return <DashboardScreen />;
    }
  };

  return (
    <div
      ref={wrapperRef}
      className="fixed inset-0 bg-black flex items-center justify-center overflow-hidden select-none"
    >
      <div
        className="relative overflow-hidden bg-black shrink-0"
        style={{
          width: `${DESIGN_WIDTH}px`,
          height: `${DESIGN_HEIGHT}px`,
          transform: `scale(${scale})`,
          transformOrigin: 'center center',
        }}
      >
        {/* Background Image */}
        {!bgFailed && (
          <img
            src={bgUrl}
            alt=""
            onError={() => setBgFailed(true)}
            className="absolute inset-0 w-full h-full object-cover transition-opacity duration-700"
          />
        )}

        {/* Top/Bottom Gradient Scrim */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              'linear-gradient(180deg, rgba(0,0,0,0.6) 0%, rgba(0,0,0,0) 45%, rgba(0,0,0,0.8) 100%)',
          }}
        />

        {/* Active Screen */}
        <div key={screenIndex} className={`absolute inset-0 ${animClass}`}>
          {renderScreen()}
        </div>

        {/* Optional Mosque Logo Badge */}
        {settings.show_logo && settings.logo_path && (
          <div
            className={`absolute top-5 left-5 w-[140px] h-[140px] rounded-[24px] bg-black/35 border border-white/25 p-2.5 shadow-[0_6px_16px_rgba(0,0,0,0.5)] flex items-center justify-center z-20 ${
              settings.logo_animation_enabled ? 'animate-logo-pulse' : ''
            }`}
          >
            {!logoFailed && (
              <img
                src={resolveAssetUrl(settings.logo_path)}
                alt="Logo Masjid"
                onError={() => setLogoFailed(true)}
                className="w-full h-full object-contain rounded-[16px]"
              />
            )}
          </div>
        )}

        {/* Watermark */}
        <div
          className="absolute bottom-2 left-5 text-[12px] font-bold text-white z-20"
          style={{ textShadow: '0 0 3px #000000' }}
        >
          KORNET INTER MEDIA | 2026
        </div>

        {/* Hover-revealed discrete controls for TV Settings & Web Admin */}
        <div className="absolute bottom-2 right-5 z-20 flex items-center gap-2 opacity-0 hover:opacity-100 focus-within:opacity-100 transition-opacity duration-200">
          <button
            type="button"
            onClick={openSettings}
            className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-black/70 border border-white/20 text-white/90 hover:text-teal-300 text-xs font-medium backdrop-blur-sm"
          >
            <Settings className="w-3.5 h-3.5" /> Pengaturan TV
          </button>
          <button
            type="button"
            onClick={openAdmin}
            className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-black/70 border border-white/20 text-white/90 hover:text-amber-300 text-xs font-medium backdrop-blur-sm"
          >
            <Globe className="w-3.5 h-3.5" /> Web Admin
          </button>
        </div>

        {/* Media / Murottal Overlay */}
        {activeMedia && notifState === 'none' && (
          <MediaOverlay
            media={activeMedia}
            onFinished={onMediaFinished}
            onManualStop={stopActiveMedia}
          />
        )}

        {/* Notification Overlay */}
        {notifState !== 'none' && (
          <NotifOverlay
            title={notifTitle}
            prayerName={currentPrayerName}
            message={notifMessage}
            countdownSeconds={
              notifState === 'countdown' ? countdownSeconds : null
            }
            onDismiss={dismissNotification}
          />
        )}

        {/* Audio Autoplay Blocked Notice */}
        {audioBlockedWarning && (
          <div className="absolute top-5 right-5 z-50 bg-slate-900/95 border border-amber-400/60 text-white px-4 py-3 rounded-xl shadow-xl flex items-center gap-3 text-sm">
            <Volume2 className="w-5 h-5 text-amber-400 shrink-0" />
            <span>Browser memblokir autoplay audio. Klik di mana saja untuk mengaktifkan suara.</span>
            <button
              type="button"
              onClick={clearAudioBlockedWarning}
              className="px-2 py-1 rounded bg-amber-500 text-black font-semibold text-xs"
            >
              OK
            </button>
          </div>
        )}

        {/* Power TV Simulated Sleep Overlay */}
        {!isScreenPowerOn && (
          <div
            onClick={wakeScreenTemporarily}
            className="absolute inset-0 z-50 bg-black flex flex-col items-center justify-center cursor-pointer"
          >
            <Moon className="w-16 h-16 text-white/25 mb-4" />
            <p className="text-white/40 text-lg font-medium">
              Power TV Mode Tidur Aktif
            </p>
            <p className="text-white/25 text-sm mt-1">
              Klik layar untuk membangunkan sementara (5 menit)
            </p>
          </div>
        )}
      </div>
    </div>
  );
};
