String buildRemoteSection(Map<String, dynamic> params) {
  final vpsHost = params['vpsHost'] ?? '';
  final vpsUser = params['vpsUser'] ?? '';
  final vpsPort = params['vpsPort'] ?? '8089';
  final tunnelEnabled = params['tunnelEnabled'] as bool? ?? false;
  final publicUrl = params['publicUrl'] as String? ?? 'Belum terhubung';

  return '''
    <!-- Remote Access -->
    <div id="remote" class="section">
      <div class="card">
        <h2>Akses Remote (VPN/Tunnel)</h2>
        <p style="font-size:0.9em; color:#666;">Aktifkan fitur ini agar Web Admin bisa diakses dari mana saja melalui internet via server pribadi Anda.</p>
        
        <form action="/update_settings" method="post">
          <input type="hidden" name="section" value="remote">
          
          <label>Aktifkan Tunnel</label>
          <select name="tunnel_enabled">
            <option value="true" ${tunnelEnabled ? 'selected' : ''}>Ya, Aktifkan</option>
            <option value="false" ${!tunnelEnabled ? 'selected' : ''}>Tidak, Nonaktifkan</option>
          </select>

          <h3>Konfigurasi Server (SSH)</h3>
          <label>Alamat IP / Domain VPS</label>
          <input type="text" name="vps_host" value="$vpsHost" placeholder="Contoh: 123.45.67.89">
          <label>Username SSH</label>
          <input type="text" name="vps_user" value="$vpsUser" placeholder="Contoh: simasjid_tunnel">
          <label>Password SSH</label>
          <input type="password" name="vps_pass" value="">
          <label>Port Publik di VPS</label>
          <input type="number" name="vps_port" value="$vpsPort" placeholder="Contoh: 8089">
          <button type="submit" style="background:#E91E63; margin-top:20px;">Simpan & Hubungkan</button>
        </form>
        <div style="background:#e3f2fd; padding:15px; border-radius:5px; margin-top:10px; font-size:0.9em;">
          <b>URL Publik Saat Ini:</b> <a href="$publicUrl" target="_blank">$publicUrl</a>
        </div>
      </div>
    </div>
  ''';
}