String buildNotifSection(Map<String, dynamic> params) {
  return '''
    <!-- Notifikasi -->
    <div id="notif" class="section">
      <div class="card">
        <h2>Pengaturan Notifikasi</h2>
      <form action="/update_settings" method="post">
        <input type="hidden" name="section" value="notif">
        <div class="row">
          <div class="col">
            <label>Durasi Adzan (detik)</label>
            <input type="number" name="adzan_duration" value="${params['notifAdzanDuration']}">
          </div>
          <div class="col">
            <label>Jeda Iqomah (menit)</label>
            <input type="number" name="iqomah_delay" value="${params['notifIqomahDelay']}">
          </div>
          <div class="col">
            <label>Durasi Iqomah (detik)</label>
            <input type="number" name="iqomah_duration" value="${params['notifIqomahDuration']}">
          </div>
        </div>
        <label>Teks Saat Adzan</label>
        <input type="text" name="text_adzan" value="${params['notifTextAdzan']}">
        <label>Teks Saat Iqomah</label>
        <input type="text" name="text_iqomah" value="${params['notifTextIqomah']}">
        <label>Teks Timer Iqomah</label>
        <input type="text" name="notif_text_iqomah_timer" value="${params['notifTextIqomahTimer']}">
        
        <hr style="margin-top: 20px; margin-bottom: 20px;">
        <h3>Mode Sholat Berjamaah</h3>
        <p style="font-size:0.9em; color:#666;">Layar akan menampilkan pesan ini saat sholat dimulai dan kembali normal setelah durasi yang ditentukan.</p>
        <div class="row">
          <div class="col">
            <label>Durasi Mode Sholat (detik)</label>
            <input type="number" name="notif_sholat_duration" value="${params['notifSholatDuration']}">
          </div>
          <div class="col">
            <label>Pesan Saat Sholat</label>
            <input type="text" name="notif_text_sholat" value="${params['notifTextSholat']}">
          </div>
        </div>
        <button type="submit" style="background:#4CAF50;">Simpan Notifikasi & Mode Sholat</button>
      </form>
      <hr style="margin-top: 20px; margin-bottom: 20px;">
      <h3>Mode Sholat Jumat</h3>
      <form action="/update_settings" method="post">
        <input type="hidden" name="section" value="notif">
        <label>Aktifkan Mode Jumat</label>
        <select name="friday_mode_enabled">
          <option value="true" ${params['fridayModeEnabled'] ? 'selected' : ''}>Ya</option>
          <option value="false" ${!params['fridayModeEnabled'] ? 'selected' : ''}>Tidak</option>
        </select>
        <label>Durasi Khutbah (menit)</label>
        <input type="number" name="friday_khutbah_duration" value="${params['fridayKhutbahDuration']}">
        <label>Pesan Khutbah</label>
        <textarea name="friday_khutbah_text" rows="2">${params['fridayKhutbahText']}</textarea>
        <button type="submit" style="background:#00796b;">Simpan Mode Jumat</button>
      </form>
      </div>
    </div>

''';
}
