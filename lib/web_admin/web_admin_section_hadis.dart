String buildHadisSection(Map<String, dynamic> params) {
  return '''
    <!-- Hadis -->
    <div id="hadis" class="section">
      <div class="card">
        <h2>Pengaturan Hadis</h2>
        <form action="/update_settings" method="post">
          <input type="hidden" name="section" value="hadis">
          <div class="row">
            <div class="col">
              <label>Tampilkan Hadis</label>
              <select name="hadith_show">
                <option value="true" ${params['showHadith'] ? 'selected' : ''}>Ya</option>
                <option value="false" ${!params['showHadith'] ? 'selected' : ''}>Tidak</option>
              </select>
            </div>
            <div class="col">
              <label>Interval (menit)</label>
              <input type="number" name="hadith_interval" value="${params['hadithInterval']}">
            </div>
            <div class="col">
              <label>Kecepatan Scroll (detik)</label>
              <input type="number" name="hadith_speed" value="${params['hadithSpeed']}">
            </div>
          </div>
          <button type="submit" style="margin-top:10px;">Simpan Pengaturan Hadis</button>
        </form>
        
        <hr style="border:0; border-top:1px solid #eee; margin: 20px 0;">
        <h3>Hadis Manual (Offline)</h3>
        <table>
          <thead><tr><th width="30">#</th><th>Isi Hadis</th><th width="60">Aksi</th></tr></thead>
          <tbody>${params['hadithHtml']}</tbody>
        </table>
        
        <h3>Tambah Hadis Manual</h3>
        <form name="hadithForm" action="/add_hadith" method="post">
          <input type="hidden" name="index" value="-1">
          <label>Isi Hadis</label>
          <textarea name="text" rows="2" required></textarea>
          <label>Sumber (Perawi)</label>
          <input type="text" name="source" required placeholder="HR. Bukhari">
          <button id="hadithBtn" type="submit" style="background:#8BC34A;">Tambah Hadis</button>
        </form>
      </div>
    </div>

''';
}
