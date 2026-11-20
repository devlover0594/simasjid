import React, { useEffect, useRef, useState } from 'react';
import { AlertCircle, ImageOff, Music, Volume2, X } from 'lucide-react';
import { resolveAssetUrl } from '../../constants/defaults';
import type { ActiveMediaPlayback } from '../../types/simasjid';

interface MediaOverlayProps {
  media: ActiveMediaPlayback;
  onFinished: () => void;
  onManualStop: () => void;
}

function extractYouTubeEmbedUrl(url: string): string | null {
  const match = url.match(
    /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/|shorts\/))([A-Za-z0-9_-]{11})/,
  );
  if (match && match[1]) {
    return `https://www.youtube.com/embed/${match[1]}?autoplay=1`;
  }
  return null;
}

export const MediaOverlay: React.FC<MediaOverlayProps> = ({
  media,
  onFinished,
  onManualStop,
}) => {
  const [hasError, setHasError] = useState(false);
  const [autoplayBlocked, setAutoplayBlocked] = useState(false);
  const loopCountRef = useRef(0);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);

  const resolvedPath = resolveAssetUrl(media.path, media.path);
  const playCount = Math.max(1, media.play_count || 1);

  useEffect(() => {
    setHasError(false);
    setAutoplayBlocked(false);
    loopCountRef.current = 0;

    if (media.type === 'image') {
      const timer = window.setTimeout(() => {
        onFinished();
      }, 15000 * playCount);
      return () => window.clearTimeout(timer);
    }

    if (media.type === 'audio' && audioRef.current) {
      audioRef.current
        .play()
        .catch(() => setAutoplayBlocked(true));
    }

    if (media.type === 'video' && videoRef.current) {
      videoRef.current
        .play()
        .catch(() => setAutoplayBlocked(true));
    }
  }, [media.path, media.type, playCount, onFinished]);

  useEffect(() => {
    if (!hasError) return;
    const t = window.setTimeout(() => {
      onFinished();
    }, 3000);
    return () => window.clearTimeout(t);
  }, [hasError, onFinished]);

  const handleEnded = (el: HTMLMediaElement | null) => {
    loopCountRef.current += 1;
    if (loopCountRef.current < playCount && el) {
      el.currentTime = 0;
      void el.play().catch(() => setAutoplayBlocked(true));
    } else {
      onFinished();
    }
  };

  const fileName = media.path.split('/').pop() || media.path;

  return (
    <div className="absolute inset-0 bg-black z-30 flex items-center justify-center">
      {/* Discrete stop button on hover so operators can exit long playback */}
      <button
        type="button"
        onClick={onManualStop}
        title="Hentikan Media"
        className="absolute top-4 right-4 z-40 p-2 rounded-full bg-black/60 text-white/70 hover:text-white hover:bg-black/90 opacity-0 hover:opacity-100 focus:opacity-100 transition-opacity"
      >
        <X className="w-5 h-5" />
      </button>

      {media.type === 'youtube' ? (
        (() => {
          const embed = extractYouTubeEmbedUrl(media.path);
          return embed ? (
            <iframe
              src={embed}
              title="YouTube Media"
              className="w-full h-full border-0"
              allow="autoplay; encrypted-media"
              allowFullScreen
            />
          ) : (
            <div className="text-white text-[24px] px-6 text-center">
              YouTube: {media.path}
            </div>
          );
        })()
      ) : hasError ? (
        <div className="flex flex-col items-center gap-3 text-white">
          <AlertCircle className="w-14 h-14 text-red-500" />
          <p className="text-xl">Gagal memuat media</p>
        </div>
      ) : media.type === 'audio' ? (
        <div className="flex flex-col items-center justify-center px-8 text-center">
          <Music className="w-24 h-24 text-teal-400 animate-pulse" />
          <p className="mt-5 text-white/80 text-[20px]">Now Playing</p>
          <p className="mt-2.5 text-white text-[26px] font-bold max-w-[900px] break-all">
            {fileName}
          </p>
          <audio
            ref={audioRef}
            src={resolvedPath}
            onEnded={() => handleEnded(audioRef.current)}
            onError={() => setHasError(true)}
          />
          {autoplayBlocked && (
            <button
              type="button"
              onClick={() => {
                setAutoplayBlocked(false);
                void audioRef.current?.play();
              }}
              className="mt-6 inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-teal-600 hover:bg-teal-500 text-white font-semibold"
            >
              <Volume2 className="w-5 h-5" /> Klik untuk Memutar Audio
            </button>
          )}
        </div>
      ) : media.type === 'video' ? (
        <div className="w-full h-full flex items-center justify-center relative">
          <video
            ref={videoRef}
            src={resolvedPath}
            className="max-w-full max-h-full object-contain"
            playsInline
            onEnded={() => handleEnded(videoRef.current)}
            onError={() => setHasError(true)}
          />
          {autoplayBlocked && (
            <button
              type="button"
              onClick={() => {
                setAutoplayBlocked(false);
                void videoRef.current?.play();
              }}
              className="absolute inset-0 m-auto w-fit h-fit inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-teal-600/95 text-white font-semibold shadow-xl"
            >
              <Volume2 className="w-5 h-5" /> Klik untuk Memutar Video
            </button>
          )}
        </div>
      ) : (
        <img
          src={resolvedPath}
          alt={fileName}
          onError={() => setHasError(true)}
          className="max-w-full max-h-full object-contain"
        />
      )}

      {hasError && media.type === 'image' && (
        <ImageOff className="w-20 h-20 text-white/60" />
      )}
    </div>
  );
};
