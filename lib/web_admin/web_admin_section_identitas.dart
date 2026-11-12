String buildIdentitasSection(Map<String, dynamic> params) {
  return '''
    <!-- Identitas & Notifikasi -->
    <div id="identitas" class="section">
      <div class="card">
        <h2>General Identity</h2>
        <form action="/update_settings" method="post">
          <input type="hidden" name="section" value="identitas">
          <label>Nama Masjid</label>
          <input type="text" name="mosque_name" value="${params['mosqueName']}">
          <label>Alamat</label>
          <input type="text" name="mosque_address" value="${params['mosqueAddress']}">
          <button type="submit">Simpan Identitas</button>
        </form>
      </div>
    </div>

''';
}
