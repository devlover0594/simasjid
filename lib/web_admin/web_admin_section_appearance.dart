String buildAppearanceSection(Map<String, dynamic> params) {
  final int themePrimaryColor = params['themePrimaryColor'];
  final int themeAccentColor = params['themeAccentColor'];
  final List<String> availableAssets = params['availableAssets'];
  final String logoPath = params['logoPath'];
  final bool showLogo = params['showLogo'];
  final bool logoAnimationEnabled = params['logoAnimationEnabled'];
  final int rotationDurationSeconds = params['rotationDurationSeconds'];
  final String slideshowEffect = params['slideshowEffect'];
  final Map<String, Map<String, dynamic>> textStyles = params['textStyles'];
  final Map<String, String> currentAssets = params['currentAssets'];

  return '''
  <div id="appearance" class="section">
    <div class="card">
      <h2>Tampilan & Tema</h2>
      <form name="themeForm" class="ajax-form" data-section="appearance">
        <input type="hidden" name="action" value="update_theme_settings">
        <h3>Tema Warna</h3>
        <div class="form-grid">
            <div class="form-group color-picker">
                <label for="theme_primary">Warna Primer</label>
                <input type="color" id="theme_primary_picker" value="#${(themePrimaryColor & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}">
                <input type="hidden" id="theme_primary" name="theme_primary" value="$themePrimaryColor">
            </div>
            <div class="form-group color-picker">
                <label for="theme_accent">Warna Aksen</label>
                <input type="color" id="theme_accent_picker" value="#${(themeAccentColor & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}">
                <input type="hidden" id="theme_accent" name="theme_accent" value="$themeAccentColor">
            </div>
        </div>
        
        <h3>Logo Masjid</h3>
        <div class="form-group">
            <label>File Logo</label>
            <select name="logo_path">
                <option value="">-- Tidak ada logo --</option>
                ${availableAssets.map((asset) => '<option value="$asset" ${logoPath == asset ? 'selected' : ''}>$asset</option>').join('')}
            </select>
            <small>Upload file logo di menu Media > Aset Tambahan.</small>
        </div>
        <div class="checkbox-group">
            <input type="checkbox" id="show_logo" name="show_logo" value="true" ${showLogo ? 'checked' : ''}>
            <label for="show_logo">Tampilkan Logo</label>
        </div>
        <div class="checkbox-group">
            <input type="checkbox" id="logo_animation_enabled" name="logo_animation_enabled" value="true" ${logoAnimationEnabled ? 'checked' : ''}>
            <label for="logo_animation_enabled">Aktifkan Animasi Logo</label>
        </div>

        <h3>Rotasi & Efek Layar</h3>
        <div class="form-grid">
            <div class="form-group">
                <label for="rotation_duration_seconds">Durasi Rotasi Layar (detik)</label>
                <input type="number" name="rotation_duration_seconds" value="$rotationDurationSeconds">
            </div>
            <div class="form-group">
                <label for="slideshow_effect">Efek Transisi</label>
                <select name="slideshow_effect">
                    <option value="fade" ${slideshowEffect == 'fade' ? 'selected' : ''}>Fade</option>
                    <option value="slide" ${slideshowEffect == 'slide' ? 'selected' : ''}>Slide</option>
                    <option value="zoom" ${slideshowEffect == 'zoom' ? 'selected' : ''}>Zoom</option>
                </select>
            </div>
        </div>
        <button type="submit">Simpan Pengaturan Tampilan</button>
      </form>
    </div>
    <div class="card">
        <h3>Pengaturan Teks & Font</h3>
        <form name="styleForm" class="ajax-form" data-section="appearance">
            <div class="form-grid">
                ${textStyles.entries.map((entry) {
                  String key = entry.key;
                  Map<String, dynamic> style = entry.value;
                  String color = '#${((style['color'] as int) & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
                  return '''
                    <div class="form-group">
                        <label>${key.replaceAll('_', ' ').toUpperCase()}</label>
                        <input type="number" name="style_${key}_size" value="${style['size']}" placeholder="Ukuran Font">
                        <input type="text" name="style_${key}_font" value="${style['font']}" placeholder="Nama Font">
                        <input type="color" name="style_${key}_color" value="$color">
                    </div>
                  ''';
                }).join('')}
            </div>
            <button type="submit">Simpan Gaya Teks</button>
        </form>
    </div>
    <div class="card">
        <h3>Aset Visual (Gambar Latar, dll)</h3>
        <form name="assetForm" class="ajax-form" data-section="appearance">
            <div class="form-grid">
                ${currentAssets.entries.map((entry) {
                  String key = entry.key;
                  String value = entry.value;
                  return '''
                    <div class="form-group">
                        <label for="$key">${key.replaceAll('_', ' ').toUpperCase()}</label>
                        <select id="$key" name="$key">
                            ${availableAssets.map((asset) => '<option value="$asset" ${value == asset ? 'selected' : ''}>$asset</option>').join('')}
                        </select>
                    </div>
                  ''';
                }).join('')}
            </div>
            <button type="submit">Simpan Aset</button>
        </form>
    </div>
  </div>
  ''';
}