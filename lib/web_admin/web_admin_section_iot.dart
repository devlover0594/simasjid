String buildIotSection(Map<String, dynamic> params) {
  return '''
    <!-- IoT -->
    <div id="iot" class="section">
      <div class="card">
        <h2>Smart IoT (Relay Control)</h2>
        <p style="font-size:0.9em; color:#666;">Halaman ini menampilkan status koneksi ke modul ESP32 relay secara otomatis setiap 4 detik.</p>

        <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap; margin-bottom:15px;">
          <span style="font-weight:bold;">Status:</span>
          <span id="iot-status-text" class="iot-badge" style="padding:5px 12px; border-radius:999px; color:#fff; background:#9ca3af;">Memeriksa...</span>
          <button type="button" onclick="iotSendRelayCmd(true)" style="width:auto; padding:8px 14px; background:#16a34a; margin-right:6px;">Test Relay ON (/on)</button>
          <button type="button" onclick="iotSendRelayCmd(false)" style="width:auto; padding:8px 14px; background:#dc2626;">Test Relay OFF (/off)</button>
        </div>

        <form action="/update_settings" method="post">
          <label>IP Address ESP32</label>
          <input type="text" name="iot_ip" value="${params['iotIp']}" placeholder="192.168.1.200" oninput="window.simasjidIotCheck && window.simasjidIotCheck();">
          <div class="row">
            <div class="col">
              <label>Path ON</label>
              <input type="text" name="iot_path_on" value="${params['iotPathOn']}">
            </div>
            <div class="col">
              <label>Path OFF</label>
              <input type="text" name="iot_path_off" value="${params['iotPathOff']}">
            </div>
          </div>
          <button type="submit" style="background:#607D8B;">Simpan IoT</button>
        </form>
      </div>

      <script>
        (function () {
          var checker = null;

          function getIotIp() {
            var input = document.querySelector('input[name="iot_ip"]');
            return input ? (input.value || '').trim() : '';
          }

          function setStatus(txt, cls) {
            var el = document.getElementById('iot-status-text');
            if (!el) return;
            el.textContent = txt;
            el.style.background = ({ ok: '#16a34a', bad: '#dc2626', checking: '#9ca3af' })[cls] || '#9ca3af';
            el.style.display = 'inline-block';
          }

          function cleanup() {
            if (!checker) return;
            if (window[checker.cb]) delete window[checker.cb];
            if (checker.script && checker.script.parentNode) {
              checker.script.parentNode.removeChild(checker.script);
            }
            window.clearTimeout(checker.timer);
            checker = null;
          }

          function checkIotStatus() {
            var ip = getIotIp();
            if (ip === '') { setStatus('Isi IP Address dulu', 'checking'); return; }

            setStatus('Memeriksa...', 'checking');
            cleanup();

            var cb = 'iotcb' + new Date().getTime();
            var done = false;
            checker = { cb: cb };
            window[cb] = function (data) {
              done = true;
              if (data && data.relay === 'on') setStatus('Terhubung • Relay ON', 'ok');
              else if (data && data.relay === 'off') setStatus('Terhubung • Relay OFF', 'ok');
              else setStatus('Terhubung', 'ok');
            };

            var s = document.createElement('script');
            s.async = true;
            s.src = 'http://' + ip + '/status?cb=' + cb;
            s.onload = function () { if (!done) setStatus('Tidak Terhubung', 'bad'); cleanup(); };
            s.onerror = function () { if (!done) setStatus('Tidak Terhubung', 'bad'); cleanup(); };
            checker.script = s;
            document.body.appendChild(s);
            checker.timer = window.setTimeout(function () {
              if (!done) { setStatus('Tidak Terhubung', 'bad'); cleanup(); }
            }, 3000);
          }

          window.iotSendRelayCmd = function (turnOn) {
            var ip = getIotIp();
            if (ip === '') { setStatus('Isi IP Address dulu', 'checking'); return; }
            var cmd = turnOn ? 'on' : 'off';
            setStatus('Mengirim ' + cmd.toUpperCase() + '...', 'checking');
            fetch('http://' + ip + '/' + cmd + '?_=' + new Date().getTime(), { mode: 'no-cors' })
              .then(function () {
                setStatus('Perintah ' + cmd.toUpperCase() + ' terkirim', 'ok');
                setTimeout(checkIotStatus, 1200);
              })
              .catch(function () {
                setStatus('Gagal mengirim ' + cmd.toUpperCase() + ' (tidak terhubung)', 'bad');
              });
          };

          // Cek setiap 4 detik + sekali langsung
          window.simasjidIotCheck = checkIotStatus;
          setInterval(checkIotStatus, 4000);
          checkIotStatus();
        })();
      </script>
    </div>
  ''';
}