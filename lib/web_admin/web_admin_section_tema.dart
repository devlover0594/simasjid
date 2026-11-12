String buildTemaSection(Map<String, dynamic> params) {
  return '''
    <!-- Tema & Background -->
    <div id="tema" class="section">
      <div class="card">
        <h2>Tema & Nuansa Warna</h2>
        <p style="font-size:0.9em; color:#666;">Pilih paduan warna untuk efek glassmorphism dan aksen di layar TV Anda.</p>
        
        <form id="themeForm" action="/update_settings" method="post">
          <input type="hidden" name="section" value="tema">
          <input type="hidden" name="theme_primary" id="theme_primary" value="${params['themePrimaryColor']}">
          <input type="hidden" name="theme_accent" id="theme_accent" value="${params['themeAccentColor']}">
          <div class="theme-grid">
            ${params['themePresetsHtml']}
          </div>
        </form>

        <div class="bg-upload-box">
          <h3>Background Utama</h3>
          <p style="font-size:0.85em; color:#666; margin-bottom:15px;">Upload gambar background dashboard. Anda juga dapat menerapkannya ke semua layar.</p>
          
          <form action="/upload_bg" method="post" enctype="multipart/form-data">
            <input type="hidden" name="section" value="tema">
            <div class="row" style="align-items: center;">
              <div class="col" style="flex: 2;">
                <input type="file" name="bg_file" accept="image/*" required>
              </div>
              <div class="col">
                <button type="submit" style="margin-top:0;">Upload Background</button>
              </div>
            </div>
            
            <div class="toggle-switch">
              <div>
                <b>Terapkan ke Semua Layar</b><br>
                <small>Gunakan background ini untuk Jadwal, Info, Hadis, dan Petugas</small>
              </div>
              <label class="switch">
                <input type="checkbox" name="apply_all" value="true" ${params['bgApplyAll'] ? 'checked' : ''} onchange="this.form.submit()">
                <span class="slider"></span>
              </label>
            </div>
            <input type="hidden" name="action" value="update_apply_all">
          </form>

          <div class="bg-upload-box" style="margin-top:24px;">
            <h3>Logo Masjid</h3>
            <form action="/update_settings" method="post">
              <input type="hidden" name="section" value="tema">
              <input type="hidden" name="action" value="update_theme_settings">
              <div class="row" style="align-items:center; margin-bottom:12px;">
                <div class="col" style="flex:1;">
                  <label><b>Tampilkan Logo Masjid</b></label>
                  <div><label><input type="checkbox" name="show_logo" value="true" ${params['showLogo'] ? 'checked' : ''}> Ya</label></div>
                </div>
                <div class="col" style="flex:1;">
                  <label><b>Animasi Logo</b></label>
                  <div><label><input type="checkbox" name="logo_animation_enabled" value="true" ${params['logoAnimationEnabled'] ? 'checked' : ''}> Ya</label></div>
                </div>
              </div>
              <label>Path Logo Masjid</label>
              <input type="text" name="logo_path" value="${params['logoPathSafe']}" placeholder="Contoh: /storage/emulated/0/logo.png atau logo.png">

              <h3 style="margin-top:20px;">Slideshow</h3>
              <label>Durasi Rotasi Layar (detik)</label>
              <input type="number" name="rotation_duration_seconds" value="${params['rotationDurationSeconds']}" min="30" max="180">

              <label>Efek Slideshow</label>
              <select name="slideshow_effect">
                <option value="fade" ${params['slideshowEffect'] == 'fade' ? 'selected' : ''}>Fade</option>
                <option value="slide" ${params['slideshowEffect'] == 'slide' ? 'selected' : ''}>Slide</option>
                <option value="zoom" ${params['slideshowEffect'] == 'zoom' ? 'selected' : ''}>Zoom</option>
              </select>

              <button type="submit" style="background:#00796b; margin-top:16px;">Simpan Logo & Slideshow</button>
            </form>
          </div>
        </div>
      </div>
    </div>

''';
}
