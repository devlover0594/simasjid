String buildPrayerTimesSection(Map<String, dynamic> params) {
  final bool useApi = params['useApi'];
  final String apiProvider = params['apiProvider'];
  final String kotaName = params['kotaName'];
  final String kotaId = params['kotaId'];
  final List<Map<String, String>> prayerTimes = params['prayerTimes'];
  final int hijriAdjustment = params['hijriAdjustment'];

  return '''
  <div id="prayer_times" class="section">
    <div class="card">
      <h2>Jadwal Sholat</h2>
      <form name="prayerForm" class="ajax-form" data-section="prayer_times">
        <h3>Sumber Data</h3>
        <div class="checkbox-group">
          <input type="radio" id="use_api_true" name="use_api" value="true" ${useApi ? 'checked' : ''} onchange="togglePrayerSource()">
          <label for="use_api_true">Gunakan API (Otomatis)</label>
        </div>
        <div class="checkbox-group">
          <input type="radio" id="use_api_false" name="use_api" value="false" ${!useApi ? 'checked' : ''} onchange="togglePrayerSource()">
          <label for="use_api_false">Manual</label>
        </div>

        <div id="api-settings" class="${useApi ? '' : 'hidden'}">
          <h4>Pengaturan API</h4>
          <div class="form-grid">
            <div class="form-group">
              <label for="api_provider">Penyedia API</label>
              <select id="api_provider" name="api_provider">
                <option value="MyQuran" ${apiProvider == 'MyQuran' ? 'selected' : ''}>MyQuran</option>
                <option value="Kemenag" ${apiProvider == 'Kemenag' ? 'selected' : ''}>Kemenag</option>
              </select>
            </div>
            <div class="form-group">
              <label for="kota_name">Nama Kota</label>
              <input type="text" id="kota_name" name="kota_name" value="$kotaName" placeholder="Contoh: Jakarta">
              <input type="hidden" id="kota_id" name="kota_id" value="$kotaId">
              <div id="city-suggestions"></div>
            </div>
          </div>
        </div>

        <div id="manual-settings" class="${!useApi ? '' : 'hidden'}">
          <h4>Pengaturan Manual</h4>
          <p>Masukkan waktu sholat dalam format HH:mm.</p>
          <div class="form-grid">
            ${prayerTimes.map((p) => '''
              <div class="form-group">
                <label for="prayer_${p['name']}">${p['name']}</label>
                <input type="time" id="prayer_${p['name']}" name="prayer_${p['name']}" value="${p['time']}">
              </div>
            ''').join('')}
          </div>
        </div>

        <hr>
        <h3>Penyesuaian Tanggal Hijriah</h3>
        <div class="form-group">
          <label for="hijri_adjustment">Koreksi Hijriah</label>
          <input type="number" id="hijri_adjustment" name="hijri_adjustment" value="$hijriAdjustment" placeholder="Contoh: -1 atau 1">
          <small>Gunakan angka negatif atau positif untuk menyesuaikan tanggal Hijriah jika tidak sesuai.</small>
        </div>

        <button type="submit">Simpan Pengaturan Jadwal</button>
      </form>
    </div>
  </div>
  ''';
}