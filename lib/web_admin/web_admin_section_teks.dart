String buildTeksSection(Map<String, dynamic> params) {
  return '''
    <!-- Pengaturan Teks & Font -->
    <div id="teks" class="section">
      <div class="card">
        <h2>Pengaturan Teks & Font</h2>
        <form action="/update_settings" method="post">
          <table>
            <thead><tr><th>Elemen</th><th>Ukuran</th><th>Warna</th><th>Font</th></tr></thead>
            <tbody>${params['textSettingsHtml']}</tbody>
          </table>
          <button type="submit" style="background:#673AB7;">Simpan Tampilan</button>
        </form>
      </div>
    </div>

''';
}
