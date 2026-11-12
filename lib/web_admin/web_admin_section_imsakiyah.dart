String buildImsakiyahSection(Map<String, dynamic> params) {
  return '''
    <!-- Imsakiyah -->
    <div id="imsakiyah" class="section">
      <div class="card">
        <h2>Pengaturan Imsakiyah</h2>
        <p style="font-size:0.9em; color:#666;">Pengaturan untuk menampilkan layar jadwal imsakiyah bulanan. Data diambil dari API EQuran.id.</p>
        <form action="/update_settings" method="post">
          <label>Tampilkan Layar Imsakiyah</label>
          <select name="show_imsakiyah_screen">
            <option value="true" ${params['showImsakiyahScreen'] ? 'selected' : ''}>Ya, Tampilkan</option>
            <option value="false" ${!params['showImsakiyahScreen'] ? 'selected' : ''}>Tidak, Sembunyikan</option>
          </select>

          <div style="background:#e8f5e9; padding:15px; border-radius:5px; margin-top:10px; margin-bottom:15px;">
            <h3>Wilayah Imsakiyah</h3>
            <button type="button" id="searchImsakCityBtn" onclick="loadEQuranProvinces('imsak_')" style="background:#2e7d32; width:auto; padding:8px 15px; margin-bottom:10px;">Cari Wilayah (EQuran.id)</button>
            
            <div id="equran_imsak_selector" style="display:none; margin-bottom:15px; background:white; padding:10px; border-radius:5px; border:1px solid #ccc;">
              <label>Pilih Provinsi</label>
              <select id="equran_imsak_prov_select" onchange="loadEQuranCities(this.value, 'imsak_')"></select>
              <label>Pilih Kab/Kota</label>
              <select id="equran_imsak_city_select" onchange="applyCity(document.getElementById('equran_imsak_prov_select').value, this.value, 'imsak_')"></select>
            </div>

            <div class="row">
              <div class="col">
                <label>Provinsi</label>
                <input type="text" name="imsakiyah_province" id="imsakiyah_province_input" value="${params['imsakiyahProvince']}" readonly style="background:#f0f0f0;">
              </div>
              <div class="col">
                <label>Kabupaten/Kota</label>
                <input type="text" name="imsakiyah_city" id="imsakiyah_city_input" value="${params['imsakiyahCity']}" readonly style="background:#f0f0f0;">
              </div>
            </div>
            <p style="font-size:0.8em; color:#888; margin-top:5px;">ℹ️ Gunakan tombol cari untuk memastikan nama wilayah sesuai dengan API EQuran.id.</p>
          </div>

          <button type="submit">Simpan Pengaturan Imsakiyah</button>
        </form>
      </div>
    </div>

''';
}
