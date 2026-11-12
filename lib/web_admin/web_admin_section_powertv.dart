String buildPowertvSection(Map<String, dynamic> params) {
  return '''
    <!-- Power TV -->
    <div id="powertv" class="section">
      <div class="card">
        <h2>Power TV Terjadwal (Sleep Mode)</h2>
        <p style="font-size:0.9em; color:#666;">Atur kapan TV harus masuk ke mode sleep dan bangun secara otomatis.</p>
        
        <form action="/update_settings" method="post">
          <input type="hidden" name="section" value="powertv">
          <label>Aktifkan Penjadwalan</label>
          <select name="power_tv_enabled">
            <option value="true" ${params['powerTvEnabled'] ? 'selected' : ''}>Ya, Aktifkan</option>
            <option value="false" ${!params['powerTvEnabled'] ? 'selected' : ''}>Tidak, Nonaktifkan</option>
          </select>
          <button type="submit" style="background:#009688; margin-top:10px;">Simpan Status Aktif</button>
        </form>

        <hr style="border:0; border-top:1px solid #eee; margin: 20px 0;">
        
        <table>
          <thead><tr><th width="30">#</th><th>Jadwal (Bangun - Tidur)</th><th width="60">Aksi</th></tr></thead>
          <tbody>${params['powerSchedulesHtml']}</tbody>
        </table>

        <h3>Tambah/Edit Jadwal</h3>
        <form name="powerForm" action="/add_power_schedule" method="post">
          <input type="hidden" name="section" value="powertv">
          <input type="hidden" name="index" value="-1">
          <div class="row">
            <div class="col">
              <label>Jam TV Bangun (ON)</label>
              <input type="time" name="on_time" value="04:00" required>
            </div>
            <div class="col">
              <label>Jam TV Tidur (OFF/Sleep)</label>
              <input type="time" name="off_time" value="21:00" required>
            </div>
          </div>
          <label>Hari Aktif</label>
          <div class="checkbox-group">
            <label><input type="checkbox" name="days" value="1" checked> Sen</label>
            <label><input type="checkbox" name="days" value="2" checked> Sel</label>
            <label><input type="checkbox" name="days" value="3" checked> Rab</label>
            <label><input type="checkbox" name="days" value="4" checked> Kam</label>
            <label><input type="checkbox" name="days" value="5" checked> Jum</label>
            <label><input type="checkbox" name="days" value="6" checked> Sab</label>
            <label><input type="checkbox" name="days" value="7" checked> Min</label>
          </div>
          <button id="powerBtn" type="submit" style="background:#E91E63; margin-top:20px;">Simpan Jadwal Power TV</button>
        </form>

        <div style="background:#e3f2fd; padding:15px; border-radius:5px; margin-top:10px; font-size:0.9em;">
          ℹ️ <b>Info:</b> Fitur ini akan mengatur layar TV untuk tetap menyala pada jam aktif dan mengizinkan sistem masuk ke mode sleep di luar jam tersebut. Anda bisa menambahkan lebih dari satu jadwal (misal: Subuh-Dzuhur, dan Ashar-Isya).
        </div>
      </div>
    </div>

''';
}
