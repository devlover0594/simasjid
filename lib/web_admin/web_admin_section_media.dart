String buildMediaSection(Map<String, dynamic> params) {
  return '''
    <!-- Jadwal Media -->
    <div id="media" class="section">
      <div class="card">
        <h2>Jadwal Tayang Media</h2>
        <table>
          <thead><tr><th width="30">#</th><th>File</th><th>Jadwal</th><th width="60">Aksi</th></tr></thead>
          <tbody>${params['mediaHtml']}</tbody>
        </table>
        <hr style="border:0; border-top:1px solid #eee; margin: 20px 0;">
        <h3>Tambah Jadwal Tayang</h3>
        <form name="mediaForm" action="/add_media" method="post" enctype="multipart/form-data">
          <input type="hidden" name="index" value="-1">
          <label>Pilih dari Playlist (Opsional)</label>
          <select onchange="onLibrarySelect(this)">
            ${params['mediaLibOptions']}
          </select>

          <label>Path File (Lokal) atau URL (YouTube)</label>
          <input type="text" name="path" placeholder="Contoh: /storage/emulated/0/Download/video.mp4">
          
          <label>ATAU Upload File (Akan menimpa path di atas)</label>
          <input type="file" name="media_file" accept="image/*,video/*,audio/*">

          <div class="row">
            <div class="col">
              <label>Tipe</label>
              <select name="type">
                <option value="image">Gambar</option>
                <option value="video">Video</option>
                <option value="audio">Audio (MP3)</option>
              </select>
            </div>
            <div class="col">
              <label>Jam Mulai (HH:MM)</label>
              <input type="time" name="time" value="12:00" required>
            </div>
          </div>

          <div style="margin-top:10px; background:#f9f9f9; padding:10px; border-radius:5px;">
            <label style="display:inline-flex; align-items:center; cursor:pointer;"><input type="checkbox" name="is_loop" value="true" onchange="toggleLoopInput(this)" style="width:auto; margin-right:10px;"> Loop Media (Putar Berulang)?</label>
            <div id="loop_count_div" style="display:none; margin-top:10px;">
              <label>Jumlah Putar (Kali)</label>
              <input type="number" name="play_count" value="2" min="1">
            </div>
          </div>

          <label>Hari Aktif</label>
          <div class="checkbox-group">
            <label><input type="checkbox" name="day_1" checked> Sen</label>
            <label><input type="checkbox" name="day_2" checked> Sel</label>
            <label><input type="checkbox" name="day_3" checked> Rab</label>
            <label><input type="checkbox" name="day_4" checked> Kam</label>
            <label><input type="checkbox" name="day_5" checked> Jum</label>
            <label><input type="checkbox" name="day_6" checked> Sab</label>
            <label><input type="checkbox" name="day_7" checked> Ahd</label>
          </div>

          <button id="mediaBtn" type="submit" style="background:#2196F3;">Tambah Jadwal</button>
        </form>
      </div>

      <div class="card">
        <h2>Playlist Media (Library)</h2>
        <table>
          <thead><tr><th width="30">#</th><th>Nama & Tipe</th><th>Path</th><th width="60">Aksi</th></tr></thead>
          <tbody>${params['mediaLibHtml']}</tbody>
        </table>
        <hr style="border:0; border-top:1px solid #eee; margin: 20px 0;">
        <h3>Tambah ke Playlist</h3>
        <form name="mediaLibForm" action="/add_media_library" method="post" enctype="multipart/form-data">
          <input type="hidden" name="index" value="-1">
          <input type="hidden" name="id" value="">
          
          <label>Nama Media</label>
          <input type="text" name="name" required placeholder="Contoh: Kajian Subuh">
          
          <label>Path File / URL</label>
          <input type="text" name="path" placeholder="Path atau URL">
          <label>ATAU Upload File</label>
          <input type="file" name="media_file" accept="image/*,video/*,audio/*">
          
          <label>Tipe</label>
          <select name="type"><option value="image">Gambar</option><option value="video">Video</option><option value="audio">Audio (MP3)</option><option value="youtube">YouTube</option></select>
          
          <button id="mediaLibBtn" type="submit" style="background:#009688;">Simpan Playlist</button>
        </form>
        <hr style="border:0; border-top:1px solid #eee; margin: 20px 0;">
        <h3>Impor dari Folder</h3>
        <p style="font-size:0.9em; color:#666;">Masukkan path absolut ke folder di perangkat TV, dan semua media di dalamnya akan ditambahkan ke playlist secara otomatis.</p>
        <form name="importFolderForm" action="/import_folder" method="post">
          <input type="hidden" name="section" value="media">
          <label>Path Folder</label>
          <input type="text" name="folder_path" required placeholder="Contoh: /storage/emulated/0/Download/Kajian">
          <button type="submit" style="background:#FF9800;">Impor Otomatis</button>
        </form>

      </div>
    </div>

''';
}
