String buildMurottalSection(Map<String, dynamic> params) {
  return '''
    <!-- Murottal -->
    <div id="murottal" class="section">
      <div class="card">
        <h2>Jadwal Murottal Sebelum Adzan</h2>
        <p style="font-size:0.9em; color:#666;">Atur pemutaran audio/video murottal secara otomatis beberapa menit sebelum waktu sholat tiba. Pastikan file sudah ditambahkan di menu <b>Playlist Media</b>.</p>
        <form action="/update_settings" method="post">
          <input type="hidden" name="section" value="murottal">          
          ${params['murottalSchedulesHtml']} <!-- Ini akan berisi semua item accordion -->
          <button type="submit" style="background:#00796b;">Simpan Jadwal Murottal</button>
        </form>
      </div>
    </div>

''';
}
