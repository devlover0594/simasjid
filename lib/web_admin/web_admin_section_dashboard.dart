String buildDashboardSection(Map<String, dynamic> params) {
  final String displayId = params['displayId'];
  final String mosqueName = params['mosqueName'];
  final String mosqueAddress = params['mosqueAddress'];
  final String runningText = params['runningText'];

  return '''
  <div id="dashboard" class="section active">
    <div class="card">
      <h2>Dashboard & Info Umum</h2>
      <p>Selamat datang di panel admin SIMasjid. Gunakan menu di samping untuk mengelola konten dan pengaturan tampilan.</p>
      <div class="form-grid">
        <div class="form-group">
          <label>ID Tampilan</label>
          <input type="text" value="$displayId" readonly>
        </div>
        <div class="form-group">
          <label>Status Remote</label>
          <div style="padding: 10px; border: 1px solid #ccc; border-radius: 4px;">
            <span id="ssh-status-dot" class="status-dot disconnected"></span>
            <span id="ssh-status-text">Tidak Terhubung</span><br>
            <small id="ssh-public-url"></small>
          </div>
        </div>
      </div>
      <hr>
      <h3>Informasi Masjid</h3>
      <form name="infoForm" class="ajax-form" data-section="dashboard">
        <div class="form-group">
          <label for="mosque_name">Nama Masjid</label>
          <input type="text" id="mosque_name" name="mosque_name" value="$mosqueName" required>
        </div>
        <div class="form-group">
          <label for="mosque_address">Alamat Masjid</label>
          <input type="text" id="mosque_address" name="mosque_address" value="$mosqueAddress" required>
        </div>
        <div class="form-group">
          <label for="running_text">Running Text</label>
          <textarea id="running_text" name="running_text" rows="3" required>$runningText</textarea>
        </div>
        <button type="submit">Simpan Perubahan</button>
      </form>
    </div>
  </div>
  ''';
}