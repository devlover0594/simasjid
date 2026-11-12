String buildDonasiSection(Map<String, dynamic> params) {
  return '''
    <!-- Donasi & Dukungan -->
    <div id="donasi" class="section">
      <div class="card">
        <h2>💖 Donasi & Dukungan</h2>
        <p style="font-size:0.9em; color:#666;">
          Aplikasi SIMasjid ini bersifat gratis untuk penggunaan non-komersial di masjid.
          Jika Anda merasa aplikasi ini bermanfaat dan ingin mendukung pengembangan fitur-fitur baru di masa depan, Anda dapat memberikan donasi sukarela. Setiap dukungan Anda sangat berarti.
        </p>
        <div class="donation-grid">
          <div class="donation-method">
            <h3>Scan QRIS</h3>
            <p>Mendukung semua E-Wallet (Dana, OVO, GoPay, ShopeePay) dan Mobile Banking.</p>
            <img src="https://i.ibb.co/yB1PZ27/qris.png" alt="QRIS Donasi" style="width:250px; height:auto; border-radius:8px; margin-top:10px;">
            <p style="font-weight:bold; margin-top:5px;">a.n. YUSUF FAISAL</p>
          </div>
          <div class="donation-method">
            <h3>Transfer Bank</h3>
            <p>Anda juga bisa berdonasi melalui transfer ke rekening berikut:</p>
            <ul>
              <li><b>Bank BCA</b></li>
              <li>No. Rekening: <strong>5745480940</strong></li>
              <li>Atas Nama: <strong>Yusuf Faisal</strong></li>
            </ul>
            <h3 style="margin-top:20px;">E-Wallet</h3>
            <ul>
              <li><b>DANA / OVO / GoPay</b></li>
              <li>Nomor: <strong>085888553394</strong></li>
              <li>Atas Nama: <strong>Yusuf Faisal</strong></li>
            </ul>
          </div>
        </div>
      </div>

      <div class="card">
        <h2>🔌 Pemesanan Modul IoT (Relay Otomatis)</h2>
        <p style="font-size:0.9em; color:#666;">
          Otomatiskan sound system masjid Anda! Modul ini akan menyalakan amplifier secara otomatis saat Murottal atau Kajian diputar, dan mematikannya saat selesai.
        </p>
        <div class="donation-grid">
          <div class="donation-method">
            <img src="https://i.ibb.co/Vvj2Hk7/modul-iot.png" alt="Modul IoT" style="width:250px; height:auto; border-radius:8px;">
          </div>
          <div class="donation-method">
            <h3>Paket Siap Pakai</h3>
            <p>Hubungi kami untuk pemesanan modul yang sudah dirakit dan siap pasang:</p>
            <ul>
              <li><b>Kontak (WhatsApp):</b> 08999994994</li>
              <li><b>Paket Termasuk:</b> Modul ESP32, Modul Relay, Casing, dan Adaptor.</li>
              <li>Cukup hubungkan ke Wi-Fi masjid dan sound system, langsung berfungsi.</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
''';
}
