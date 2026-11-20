import React, { useEffect, useMemo, useState } from 'react';
import { Calendar, User } from 'lucide-react';
import { argbToCssRgba, resolveAssetUrl } from '../../constants/defaults';
import { useKiosk } from '../../context/KioskContext';
import { formatDateRangeId, formatShortDateId, textConfigToCss } from '../../utils/styleHelpers';
import { FooterPrayerBar } from './FooterPrayerBar';

export const PerformerScreen: React.FC = () => {
  const { settings, activePerformerEvent, timeString, prayerTimes } = useKiosk();
  const [selectedEvent, setSelectedEvent] = useState(activePerformerEvent);
  const [currentPage, setCurrentPage] = useState(0);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [pickedDate, setPickedDate] = useState(
    activePerformerEvent?.date ?? new Date().toISOString().slice(0, 10),
  );
  const [toastMsg, setToastMsg] = useState<string | null>(null);
  const [brokenPhotos, setBrokenPhotos] = useState<Record<string, boolean>>({});

  const primary = settings.theme_primary_color;
  const accent = settings.theme_accent_color;
  const styles = settings.text_styles;

  useEffect(() => {
    setSelectedEvent(activePerformerEvent);
    setCurrentPage(0);
    if (activePerformerEvent?.date) {
      setPickedDate(activePerformerEvent.date);
    }
  }, [activePerformerEvent]);

  const performers = useMemo(() => {
    if (!selectedEvent) return [];
    const ids = selectedEvent.performerIds ?? [];
    return settings.performer_profiles.filter((p) => ids.includes(p.id));
  }, [selectedEvent, settings.performer_profiles]);

  useEffect(() => {
    if (performers.length <= 1) return;
    const timer = window.setInterval(() => {
      setCurrentPage((prev) => (prev + 1) % performers.length);
    }, 8000);
    return () => window.clearInterval(timer);
  }, [performers.length]);

  const handleDateLookup = (dateStr: string) => {
    setPickedDate(dateStr);
    setShowDatePicker(false);
    if (!dateStr) return;

    const found = settings.performer_schedules.find((e) => {
      if (!e.date) return false;
      const endStr = e.endDate || e.date;
      return dateStr >= e.date && dateStr <= endStr;
    });

    if (found) {
      setSelectedEvent(found);
      setCurrentPage(0);
    } else {
      setToastMsg(`Tidak ada agenda pada ${formatShortDateId(dateStr)}`);
      window.setTimeout(() => setToastMsg(null), 3500);
    }
  };

  if (!selectedEvent || performers.length === 0) {
    return (
      <div className="w-full h-full flex flex-col justify-between">
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
            AGENDA & PETUGAS
          </span>
          <span className="stroked-text-sm text-[24px] font-bold text-white tabular-nums">
            {timeString}
          </span>
        </div>
        <div className="flex-1 flex items-center justify-center">
          <p className="text-white/70 text-[24px]">
            Tidak ada jadwal pengisi acara saat ini.
          </p>
        </div>
        <FooterPrayerBar
          prayerTimes={prayerTimes}
          primaryColor={primary}
          accentColor={accent}
          textStyles={styles}
        />
      </div>
    );
  }

  return (
    <div className="w-full h-full flex flex-col justify-between relative">
      {/* Top Header */}
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
          AGENDA & PETUGAS
        </span>
        <span className="stroked-text-sm text-[24px] font-bold text-white tabular-nums">
          {timeString}
        </span>
      </div>

      {/* Event Name & Date Range */}
      <div className="px-5 pt-3 text-center shrink-0">
        <h2
          className="font-bold drop-shadow-[2px_2px_10px_rgba(0,0,0,0.9)]"
          style={textConfigToCss(styles.performer_event_name, {
            color: styles.performer_event_name
              ? argbToCssRgba(styles.performer_event_name.color)
              : argbToCssRgba(accent),
          })}
        >
          {selectedEvent.name}
        </h2>
        <div className="mt-1.5 flex items-center justify-center gap-3">
          <span
            style={textConfigToCss(styles.performer_event_date, {
              color: '#ffffff',
              fontWeight: 500,
            })}
          >
            {formatDateRangeId(selectedEvent.date, selectedEvent.endDate)}
          </span>
          <button
            type="button"
            onClick={() => setShowDatePicker((v) => !v)}
            title="Cek Tanggal Lain"
            className="p-1.5 rounded-full bg-white/10 hover:bg-white/20 transition-colors"
            style={{ color: argbToCssRgba(accent) }}
          >
            <Calendar className="w-6 h-6" />
          </button>
        </div>

        {showDatePicker && (
          <div className="mt-2 inline-flex items-center gap-2 bg-slate-900/95 border border-white/20 px-4 py-2 rounded-xl shadow-xl">
            <span className="text-sm text-white/80">Cek Tanggal:</span>
            <input
              type="date"
              value={pickedDate}
              onChange={(e) => handleDateLookup(e.target.value)}
              className="bg-slate-800 text-white text-sm px-2.5 py-1 rounded border border-white/20"
            />
            <button
              type="button"
              onClick={() => setShowDatePicker(false)}
              className="text-xs text-white/70 hover:text-white px-2 py-1"
            >
              Tutup
            </button>
          </div>
        )}
      </div>

      {/* Performer Card Carousel */}
      <div className="flex-1 flex items-center justify-center overflow-hidden px-6">
        <div className="relative w-full h-[380px] flex items-center justify-center overflow-hidden">
          {performers.map((perf, idx) => {
            const isActive = idx === currentPage;
            let offset = idx - currentPage;
            if (performers.length >= 3) {
              if (offset > performers.length / 2) offset -= performers.length;
              if (offset < -performers.length / 2) offset += performers.length;
            }
            if (Math.abs(offset) > 1) return null;

            const photoSrc = perf.photoPath
              ? resolveAssetUrl(perf.photoPath, '/assets/themes/default/avatar.png')
              : '/assets/themes/default/avatar.png';
            const isBroken = brokenPhotos[perf.id];

            return (
              <div
                key={perf.id}
                onClick={() => setCurrentPage(idx)}
                className="absolute w-[74%] h-[340px] rounded-[25px] backdrop-blur-[10px] flex overflow-hidden cursor-pointer transition-all duration-700 ease-out shadow-[0_10px_25px_rgba(0,0,0,0.55)]"
                style={{
                  transform: `translateX(${offset * 78}%) scale(${isActive ? 1 : 0.78})`,
                  opacity: isActive ? 1 : 0.55,
                  zIndex: isActive ? 10 : 5,
                  backgroundColor: argbToCssRgba(primary, 0.5),
                  border: isActive
                    ? `2.5px solid ${argbToCssRgba(accent)}`
                    : `1.5px solid ${argbToCssRgba(accent, 0.3)}`,
                }}
              >
                {/* Left 40%: Photo */}
                <div className="w-[40%] p-4 h-full">
                  <div className="w-full h-full rounded-[20px] overflow-hidden bg-slate-800/80 flex items-center justify-center">
                    {isBroken ? (
                      <User className="w-24 h-24 text-white/50" />
                    ) : (
                      <img
                        src={photoSrc}
                        alt={perf.name}
                        onError={() =>
                          setBrokenPhotos((prev) => ({ ...prev, [perf.id]: true }))
                        }
                        className="w-full h-full object-cover object-top"
                      />
                    )}
                  </div>
                </div>

                {/* Right 60%: Name & Role */}
                <div className="w-[60%] p-6 flex flex-col justify-center">
                  <div
                    className="font-bold text-left line-clamp-2"
                    style={textConfigToCss(styles.performer_name)}
                  >
                    {perf.name || 'Nama Pengisi Acara'}
                  </div>
                  <div
                    className="mt-4 text-left font-medium"
                    style={textConfigToCss(styles.performer_role, {
                      color: styles.performer_role
                        ? argbToCssRgba(styles.performer_role.color)
                        : argbToCssRgba(accent),
                    })}
                  >
                    {perf.role || 'Peran'}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {toastMsg && (
        <div className="absolute bottom-24 left-1/2 -translate-x-1/2 bg-black/85 border border-amber-400/50 text-white px-5 py-2.5 rounded-xl text-base shadow-lg z-30">
          {toastMsg}
        </div>
      )}

      <FooterPrayerBar
        prayerTimes={prayerTimes}
        primaryColor={primary}
        accentColor={accent}
        textStyles={styles}
      />
    </div>
  );
};
