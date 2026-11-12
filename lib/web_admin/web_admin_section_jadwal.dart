String buildJadwalSection(Map<String, dynamic> params) {
  return '''
    <!-- Jadwal Sholat -->
    <div id="jadwal" class="section">
      <div class="card">
        <h2>Prayer Schedule Settings</h2>
        <form action="/update_settings" method="post">
          <label>Mode Jadwal</label>
          <select name="use_api">
            <option value="true" ${params['useApi'] ? 'selected' : ''}>Otomatis (API)</option>
            <option value="false" ${!params['useApi'] ? 'selected' : ''}>Manual</option>
          </select>

          <div style="background:#e0f2f1; padding:15px; border-radius:5px; margin-top:10px;">
            <h3>Pengaturan API</h3>
            
            <div class="row" style="margin-bottom:15px;">
              <div class="col">
                <label>Provider API</label>
                <select name="api_provider" id="api_provider_select" onchange="onProviderChange(this.value)">
                  <option value="MyQuran" ${params['apiProvider'] == 'MyQuran' ? 'selected' : ''}>MyQuran</option>
                  <option value="AlAdhan" ${params['apiProvider'] == 'AlAdhan' ? 'selected' : ''}>AlAdhan</option>
                  <option value="EQuran" ${params['apiProvider'] == 'EQuran' ? 'selected' : ''}>EQuran.id</option>
                </select>
              </div>
              <div class="col" style="display:flex; align-items:flex-end;">
                <button type="button" id="searchCityBtn" onclick="var p=document.getElementById('api_provider_select').value; if(p=='EQuran') loadEQuranProvinces(); else loadMyQuranCities();" style="margin-top:0; background:#00796b;">Cari Kota / Wilayah</button>
              </div>
            </div>

            <!-- MyQuran Flat Selector -->
            <div id="myquran_selector" style="display:none; margin-bottom:15px; background:white; padding:10px; border-radius:5px; border:1px solid #ccc;">
              <label>Pilih Kota (MyQuran)</label>
              <select id="myquran_city_select" onchange="applyCity(this.value, this.options[this.selectedIndex].text)"></select>
            </div>

            <!-- EQuran Province/City Selector -->
            <div id="equran_selector" style="display:none; margin-bottom:15px; background:white; padding:10px; border-radius:5px; border:1px solid #ccc;">
              <label>Provinsi</label>
              <select id="equran_prov_select" onchange="loadEQuranCities(this.value); applyCity(this.value, '')"></select>
              <label>Kabupaten/Kota</label>
              <select id="equran_city_select" onchange="applyCity(document.getElementById('equran_prov_select').value, this.value)"></select>
            </div>

            <div class="row">
              <div class="col">
                <label>ID Kota / Provinsi (Gunakan tombol 'Cari' di atas)</label>
                <input type="text" name="kota_id" id="kota_id_input" value="${params['kotaId']}" readonly style="background:#f0f0f0;">
              </div>
              <div class="col">
                <label>Nama Kota</label>
                <input type="text" name="kota_name" id="kota_name_input" value="${params['kotaName']}" readonly style="background:#f0f0f0;">
              </div>
            </div>

            <label>Penyesuaian Tanggal Hijriyah (Hari)</label>
            <input type="number" name="hijri_adjustment" value="${params['hijriAdjustment']}" placeholder="-2" style="width: 120px;">
          </div>

          <div style="background:#fff3e0; padding:15px; border-radius:5px; margin-top:10px;">
            <h3>Jadwal Manual (Jika API Mati)</h3>
            ${params['prayerInputs']}
          </div>

          <button type="submit" style="background:#FF9800; margin-top:20px;">Simpan Jadwal</button>
        </form>
      </div>
    </div>

''';
}
