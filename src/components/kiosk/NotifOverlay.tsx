import React, { useState } from 'react';
import { X } from 'lucide-react';
import { formatMmSs } from '../../utils/styleHelpers';

interface NotifOverlayProps {
  title: string;
  prayerName: string;
  message: string;
  countdownSeconds?: number | null;
  onDismiss?: () => void;
}

export const NotifOverlay: React.FC<NotifOverlayProps> = ({
  title,
  prayerName,
  message,
  countdownSeconds,
  onDismiss,
}) => {
  const [imgFailed, setImgFailed] = useState(false);

  return (
    <div className="absolute inset-0 z-40 flex items-center justify-center overflow-hidden bg-black">
      {!imgFailed && (
        <img
          src="/assets/themes/default/bgnotif.png"
          alt=""
          onError={() => setImgFailed(true)}
          className="absolute inset-0 w-full h-full object-cover"
        />
      )}
      {/* 70% dark dimmer */}
      <div className="absolute inset-0 bg-black/70" />

      {onDismiss && (
        <button
          type="button"
          onClick={onDismiss}
          title="Tutup Notifikasi"
          className="absolute top-4 right-4 z-50 p-2 rounded-full bg-black/50 text-white/70 hover:text-white opacity-0 hover:opacity-100 focus:opacity-100 transition-opacity"
        >
          <X className="w-5 h-5" />
        </button>
      )}

      <div className="relative z-10 flex flex-col items-center text-center px-10 max-w-[1120px]">
        <div className="text-[42px] font-bold text-amber-400 tracking-[2px]">
          {title}
        </div>
        <div
          className="mt-5 text-[72px] font-bold text-white leading-none"
          style={{ textShadow: '2px 2px 10px #000000' }}
        >
          {prayerName}
        </div>
        <div className="mt-7 min-h-[90px] flex items-center justify-center">
          {message && (
            <p className="text-[30px] text-white/75 italic leading-snug">
              {message}
            </p>
          )}
        </div>
        {countdownSeconds != null && (
          <div className="mt-8 px-10 py-2.5 rounded-[20px] bg-black/45 border border-white/30">
            <span className="text-[90px] font-bold text-amber-400 tabular-nums leading-none">
              {formatMmSs(countdownSeconds)}
            </span>
          </div>
        )}
      </div>
    </div>
  );
};
