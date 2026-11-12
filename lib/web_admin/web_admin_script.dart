const String adminScriptJs = r'''
  <script>
    // Fungsi untuk menampilkan toast message
    function showToast(message, type = 'success') {
        const toastContainer = document.getElementById('toast-container');
        if (!toastContainer) {
            const newContainer = document.createElement('div');
            newContainer.id = 'toast-container';
            newContainer.style.position = 'fixed';
            newContainer.style.bottom = '20px';
            newContainer.style.right = '20px';
            newContainer.style.zIndex = '1000';
            newContainer.style.display = 'flex';
            newContainer.style.flexDirection = 'column';
            newContainer.style.alignItems = 'flex-end';
            document.body.appendChild(newContainer);
        }

        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        toast.style.backgroundColor = type === 'success' ? '#4CAF50' : '#f44336';
        toast.style.color = 'white';
        toast.style.padding = '10px 20px';
        toast.style.borderRadius = '5px';
        toast.style.marginBottom = '10px';
        toast.style.opacity = '0';
        toast.style.transition = 'opacity 0.5s ease-in-out';

        document.getElementById('toast-container').appendChild(toast);

        setTimeout(() => { toast.style.opacity = '1'; }, 100);
        setTimeout(() => { toast.style.opacity = '0'; toast.addEventListener('transitionend', () => toast.remove()); }, 3000); // Hilang setelah 3 detik
    }

    function showSection(id, el) {
      document.getElementById('main-menu').style.display = 'none';
      document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
      document.getElementById(id).classList.add('active');
      document.getElementById('back-button').style.display = 'block';
      document.getElementById('page-title').innerText = el.querySelector('.title').innerText;
    }
    function toggleLoopInput(checkbox) {
      var inputDiv = document.getElementById('loop_count_div');
      if (checkbox.checked) {
        inputDiv.style.display = 'block';
      } else {
        inputDiv.style.display = 'none';
      }
    }
    
    function showMainMenu() {
      document.getElementById('main-menu').style.display = 'block';
      document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
      document.getElementById('back-button').style.display = 'none';
      document.getElementById('page-title').innerText = 'Dashboard';
    }
    
    function toggleAccordion(headerElement) {
        headerElement.classList.toggle('active');
        const content = headerElement.nextElementSibling;
        if (content.style.display === 'block') {
            content.style.display = 'none';
        } else {
            content.style.display = 'block';
        }
    }


    function selectTheme(primary, accent, el) {
      document.querySelectorAll('.theme-card').forEach(c => c.classList.remove('active'));
      el.classList.add('active');
      document.getElementById('theme_primary').value = primary;
      document.getElementById('theme_accent').value = accent;
      // Trigger save automatically or show save button
      document.getElementById('themeForm').submit();
    }

    function toggleMurottalSource(selectElement, prayerName) {
      const selectedType = selectElement.value;
      document.getElementById('murottal_source_file_' + prayerName).style.display = 'none';
      document.getElementById('murottal_source_api_' + prayerName).style.display = 'none';
      if (selectedType === 'file') {
        document.getElementById('murottal_source_file_' + prayerName).style.display = 'block';
      } else if (selectedType === 'api') {
        document.getElementById('murottal_source_api_' + prayerName).style.display = 'flex';
      }
    }

    // --- Edit Functions ---
    function editSlide(index, title, content) {
      var f = document.forms['slideForm'];
      f.index.value = index;
      f.title.value = title;
      f.content.value = content;
      document.getElementById('slideBtn').innerText = 'Simpan Perubahan Slide';
      f.scrollIntoView({behavior: 'smooth'});
    }

    function editMedia(index, path, type, time, isLoop, playCount, days) {
      var f = document.forms['mediaForm'];
      f.index.value = index;
      f.path.value = path;
      f.type.value = type;
      f.time.value = time;
      f.is_loop.checked = isLoop;
      toggleLoopInput(f.is_loop);
      f.play_count.value = playCount;
      
      var dayArr = days.split(',');
      for(var i=1; i<=7; i++) {
        if(f['day_'+i]) f['day_'+i].checked = dayArr.includes(i.toString());
      }
      document.getElementById('mediaBtn').innerText = 'Simpan Perubahan Media';
      f.scrollIntoView({behavior: 'smooth'});
    }
    
    function onLibrarySelect(select) {
      var option = select.options[select.selectedIndex];
      if(option.value) {
        var f = document.forms['mediaForm'];
        f.path.value = option.getAttribute('data-path');
        f.type.value = option.getAttribute('data-type');
      }
    }

    function editHadith(index, text, source) {
      var f = document.forms['hadithForm'];
      f.index.value = index;
      f.text.value = text;
      f.source.value = source;
      document.getElementById('hadithBtn').innerText = 'Simpan Perubahan Hadis';
      f.scrollIntoView({behavior: 'smooth'});
    }

    function editEvent(index, title, date) {
      var f = document.forms['eventForm'];
      f.index.value = index;
      f.title.value = title;
      f.date.value = date;
      document.getElementById('eventBtn').innerText = 'Simpan Perubahan Agenda';
      f.scrollIntoView({behavior: 'smooth'});
    }

    function editProfile(index, name, role) {
      var f = document.forms['profileForm'];
      f.index.value = index;
      f.name.value = name;
      f.role.value = role;
      document.getElementById('profileBtn').innerText = 'Simpan Perubahan Profil';
      f.scrollIntoView({behavior: 'smooth'});
    }

    function editSchedule(index, name, date, endDate, ids) {
      var f = document.forms['scheduleForm'];
      f.index.value = index;
      f.name.value = name;
      f.date.value = date;
      if(f.endDate) f.endDate.value = endDate;
      
      var idArr = ids.split(',');
      var checkboxes = f.elements['performer_ids'];
      if(checkboxes) {
        if(checkboxes.length) {
           for(var i=0; i<checkboxes.length; i++) {
             checkboxes[i].checked = idArr.includes(checkboxes[i].value);
           }
        } else {
           checkboxes.checked = idArr.includes(checkboxes.value);
        }
      }
      document.getElementById('scheduleBtn').innerText = 'Simpan Perubahan Jadwal';
      f.scrollIntoView({behavior: 'smooth'});
    }

    function editMediaLib(index, name, path, type, id) {
      var f = document.forms['mediaLibForm'];
      f.index.value = index;
      f.name.value = name;
      f.path.value = path;
      f.type.value = type;
      f.id.value = id;
      document.getElementById('mediaLibBtn').innerText = 'Simpan Perubahan Playlist';
      f.scrollIntoView({behavior: 'smooth'});
    }
    
    function editPowerSchedule(index, onTime, offTime, days) {
      var f = document.forms['powerForm'];
      f.index.value = index;
      f.on_time.value = onTime;
      f.off_time.value = offTime;
      
      // Reset checkboxes
      var cbs = f.querySelectorAll('input[name="days"]');
      cbs.forEach(cb => cb.checked = false);
      
      // Check active days
      var active = days.split(',');
      active.forEach(d => {
        var cb = f.querySelector('input[name="days"][value="' + d + '"]');
        if (cb) cb.checked = true;
      });
      
      document.getElementById('powerBtn').innerText = 'Simpan Perubahan Jadwal';
      f.scrollIntoView({behavior: 'smooth'});
    }

    // --- Shalat API Functions ---
    async function loadMyQuranCities() {
      const btn = document.getElementById('searchCityBtn');
      btn.innerText = 'Loading...';
      try {
        const resp = await fetch('https://api.myquran.com/v3/sholat/kabkota/semua');
        const json = await resp.json();
        const cities = json.data;
        const select = document.getElementById('myquran_city_select');
        select.innerHTML = '<option value="">-- Pilih Kota --</option>';
        cities.forEach(c => {
          const opt = document.createElement('option');
          opt.value = c.id;
          opt.innerText = c.lokasi;
          if (c.id == document.getElementById('kota_id_input').value) opt.selected = true;
          select.appendChild(opt);
        });
        document.getElementById('myquran_selector').style.display = 'block';
        document.getElementById('equran_selector').style.display = 'none';
      } catch (e) { alert('Gagal memuat kota MyQuran: ' + e); }
      btn.innerText = 'Cari Kota';
    }

    async function loadEQuranProvinces() {
      const btn = document.getElementById('searchCityBtn');
      btn.innerText = 'Loading...';
      try {
        const resp = await fetch('https://equran.id/api/v2/shalat/provinsi');
        const json = await resp.json();
        const provinces = json.data;
        const select = document.getElementById('equran_prov_select');
        select.innerHTML = '<option value="">-- Pilih Provinsi --</option>';
        provinces.forEach(p => {
          const opt = document.createElement('option');
          opt.value = p;
          opt.innerText = p;
          if (p == document.getElementById('kota_id_input').value) opt.selected = true;
          select.appendChild(opt);
        });
        document.getElementById('equran_selector').style.display = 'block';
        document.getElementById('myquran_selector').style.display = 'none';
        
        if (select.value) loadEQuranCities(select.value);
      } catch (e) { alert('Gagal memuat provinsi EQuran: ' + e); }
      btn.innerText = 'Cari Kota';
    }

    async function loadEQuranCities(prov) {
      if (!prov) return;
      const select = document.getElementById('equran_city_select');
      select.innerHTML = '<option value="">Loading...</option>';
      try {
        const resp = await fetch('https://equran.id/api/v2/shalat/kabkota', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ provinsi: prov })
        });
        const json = await resp.json();
        const cities = json.data;
        select.innerHTML = '<option value="">-- Pilih Kab/Kota --</option>';
        cities.forEach(c => {
          const opt = document.createElement('option');
          opt.value = c;
          opt.innerText = c;
          if (c == document.getElementById('kota_name_input').value) opt.selected = true;
          select.appendChild(opt);
        });
      } catch (e) { alert('Gagal memuat kota EQuran: ' + e); }
    }

    function onProviderChange(val) {
      document.getElementById('myquran_selector').style.display = 'none';
      document.getElementById('equran_selector').style.display = 'none';
    }

    function applyCity(id, name, targetPrefix = '') {
      if (targetPrefix === 'imsak_') {
        document.getElementById('imsakiyah_province_input').value = id; // Province for imsak
        document.getElementById('imsakiyah_city_input').value = name;
      } else {
        document.getElementById('kota_id_input').value = id;
        document.getElementById('kota_name_input').value = name;
      }
    }

    // --- Shalat API Functions ---
    let currentTargetPrefix = '';

    async function loadMyQuranCities() {
      const btn = document.getElementById('searchCityBtn');
      btn.innerText = 'Loading...';
      try {
        const resp = await fetch('https://api.myquran.com/v3/sholat/kabkota/semua');
        const json = await resp.json();
        const cities = json.data;
        const select = document.getElementById('myquran_city_select');
        select.innerHTML = '<option value="">-- Pilih Kota --</option>';
        cities.forEach(c => {
          const opt = document.createElement('option');
          opt.value = c.id;
          opt.innerText = c.lokasi;
          select.appendChild(opt);
        });
        document.getElementById('myquran_selector').style.display = 'block';
        document.getElementById('equran_selector').style.display = 'none';
      } catch (e) { alert('Gagal memuat kota MyQuran: ' + e); }
      btn.innerText = 'Cari Kota';
    }

    async function loadEQuranProvinces(target = '') {
      currentTargetPrefix = target;
      const btnId = target === 'imsak_' ? 'searchImsakCityBtn' : 'searchCityBtn';
      const btn = document.getElementById(btnId);
      const selId = target === 'imsak_' ? 'equran_imsak_selector' : 'equran_selector';
      const provSelId = target === 'imsak_' ? 'equran_imsak_prov_select' : 'equran_prov_select';
      
      btn.innerText = 'Loading...';
      try {
        const resp = await fetch('https://equran.id/api/v2/shalat/provinsi');
        const json = await resp.json();
        const provinces = json.data;
        const select = document.getElementById(provSelId);
        select.innerHTML = '<option value="">-- Pilih Provinsi --</option>';
        provinces.forEach(p => {
          const opt = document.createElement('option');
          opt.value = p;
          opt.innerText = p;
          select.appendChild(opt);
        });
        document.getElementById(selId).style.display = 'block';
        if (target !== 'imsak_') document.getElementById('myquran_selector').style.display = 'none';
      } catch (e) { alert('Gagal memuat provinsi EQuran: ' + e); }
      btn.innerText = 'Cari Wilayah';
    }

    async function loadEQuranCities(prov, target = '') {
      if (!prov) return;
      const citySelId = target === 'imsak_' ? 'equran_imsak_city_select' : 'equran_city_select';
      const select = document.getElementById(citySelId);
      select.innerHTML = '<option value="">Loading...</option>';
      try {
        const resp = await fetch('https://equran.id/api/v2/shalat/kabkota', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ provinsi: prov })
        });
        const json = await resp.json();
        const cities = json.data;
        select.innerHTML = '<option value="">-- Pilih Kab/Kota --</option>';
        cities.forEach(c => {
          const opt = document.createElement('option');
          opt.value = c;
          opt.innerText = c;
          select.appendChild(opt);
        });
      } catch (e) { alert('Gagal memuat kota EQuran: ' + e); }
    }

    function onProviderChange(val) {
      document.getElementById('myquran_selector').style.display = 'none';
      document.getElementById('equran_selector').style.display = 'none';
    }

    document.addEventListener('DOMContentLoaded', () => {
        // Tangani semua form submission secara asynchronous
        document.querySelectorAll('form').forEach(form => {
            form.addEventListener('submit', async (event) => {
                event.preventDefault(); // Mencegah default form submission (full page reload)

                const formData = new FormData(form);
                const url = form.action;
                const method = form.method;
                const section = formData.get('section'); // Ambil section untuk redirect

                // Khusus untuk upload file, gunakan FormData langsung
                let bodyData;
                let contentType = 'application/x-www-form-urlencoded';

                if (form.enctype === 'multipart/form-data') {
                    bodyData = formData;
                    contentType = null; // Biarkan browser set Content-Type untuk multipart
                } else {
                    bodyData = new URLSearchParams(formData).toString();
                }

                try {
                    const fetchOptions = { method: method, body: bodyData };
                    if (contentType) {
                        fetchOptions.headers = { 'Content-Type': contentType };
                    }

                    const response = await fetch(url, fetchOptions);
                    const result = await response.json(); // Asumsi server selalu merespons JSON

                    if (result.status === 'success') {
                        showToast(result.message || 'Operasi berhasil!', 'success');
                        // Setelah sukses, redirect ke section yang sama untuk me-refresh data
                        setTimeout(() => {
                            window.location.href = `/#${section}`;
                            window.location.reload(); // Reload halaman untuk memuat data terbaru
                        }, 1000); // Beri waktu toast muncul
                    } else {
                        showToast(result.message || 'Operasi gagal!', 'error');
                    }
                } catch (error) {
                    console.error('Error submitting form:', error);
                    showToast('Terjadi kesalahan saat memproses permintaan.', 'error');
                }
            });
        });

        // Tambahkan event listener untuk link hapus dengan konfirmasi
        document.querySelectorAll('a[href*="/delete_"]').forEach(link => {
            link.addEventListener('click', (event) => {
                if (!confirm('Apakah Anda yakin ingin menghapus item ini?')) {
                    event.preventDefault(); // Mencegah navigasi jika dibatalkan
                }
            });
        });
    });
  </script>
''';
