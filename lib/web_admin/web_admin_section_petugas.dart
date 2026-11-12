String buildPetugasSection(Map<String, dynamic> params) {
  return '''
    <!-- Petugas -->
    <div id="petugas" class="section">
      <div class="card">
        <h2>Profil Petugas (Khotib, Imam, dll)</h2>
        <p style="font-size:0.9em; color:#666;">Catatan: Upload foto hanya bisa dilakukan dari menu Pengaturan di perangkat TV/Kiosk.</p>
        <table>
          <thead><tr><th width="30">#</th><th>Nama & Peran</th><th width="60">Aksi</th></tr></thead>
          <tbody>${params['performerProfileHtml']}</tbody>
        </table>
        <hr>
        <h3>Tambah Profil Baru</h3>
        <form name="profileForm" action="/add_performer_profile" method="post" enctype="multipart/form-data">
          <input type="hidden" name="index" value="-1">
          <div class="row">
            <div class="col">
              <label>Nama Lengkap</label>
              <input type="text" name="name" required>
            </div>
            <div class="col">
              <label>Peran</label>
              <input type="text" name="role" placeholder="Khotib, Imam, dll." required>
            </div>
          </div>
          <label>Foto (Opsional)</label>
          <input type="file" name="photo" accept="image/*">
          <button id="profileBtn" type="submit" style="background:#E91E63;">Tambah Profil</button>
        </form>
      </div>

      <div class="card">
        <h2>Jadwal Petugas</h2>
        <table>
          <thead><tr><th>Acara & Tanggal</th><th>Petugas Bertugas</th><th width="60">Aksi</th></tr></thead>
          <tbody>${params['performerScheduleHtml']}</tbody>
        </table>
        <hr>
        <h3>Tambah Jadwal Baru</h3>
        <form name="scheduleForm" action="/add_performer_schedule" method="post">
          <input type="hidden" name="index" value="-1">
          <div class="row">
            <div class="col">
              <label>Nama Acara</label>
              <input type="text" name="name" required>
            </div>
            <div class="col">
              <label>Tanggal Mulai</label>
              <input type="date" name="date" required>
            </div>
            <div class="col">
              <label>Tanggal Selesai</label>
              <input type="date" name="endDate">
            </div>
          </div>
          <label>Pilih Petugas</label>
          <div class="checkbox-group">${params['performerCheckboxes']}</div>
          <button id="scheduleBtn" type="submit" style="background:#9C27B0;">Tambah Jadwal</button>
        </form>
      </div>
    </div>

''';
}
