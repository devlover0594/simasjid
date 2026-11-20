export async function readImageAsDataUrl(
  file: File,
  maxWidth = 1600,
): Promise<string> {
  if (file.size <= 450 * 1024) {
    return await fileToDataUrl(file);
  }
  return await compressImageFile(file, maxWidth, 0.82);
}

function fileToDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(new Error('Gagal membaca file'));
    reader.readAsDataURL(file);
  });
}

function compressImageFile(
  file: File,
  maxWidth: number,
  quality: number,
): Promise<string> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      try {
        const scale = img.width > maxWidth ? maxWidth / img.width : 1;
        const w = Math.round(img.width * scale);
        const h = Math.round(img.height * scale);
        const canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          URL.revokeObjectURL(url);
          resolve(url);
          return;
        }
        ctx.drawImage(img, 0, 0, w, h);
        const dataUrl = canvas.toDataURL('image/jpeg', quality);
        URL.revokeObjectURL(url);
        resolve(dataUrl);
      } catch (e) {
        URL.revokeObjectURL(url);
        reject(e);
      }
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Gagal memproses gambar'));
    };
    img.src = url;
  });
}

export function detectMediaTypeFromFileName(
  name: string,
): 'image' | 'video' | 'audio' {
  const lower = name.toLowerCase();
  if (/\.(mp4|webm|mkv|mov|avi)$/.test(lower)) return 'video';
  if (/\.(mp3|wav|ogg|m4a|aac)$/.test(lower)) return 'audio';
  return 'image';
}
