import '../../models/slide_item.dart';

String buildContentSection(Map<String, dynamic> params) {
  final List<SlideItem> slidesData = params['slidesData'];
  final bool showHadith = params['showHadith'];
  final int hadithInterval = params['hadithInterval'];
  final int hadithSpeed = params['hadithSpeed'];
  final List<Map<String, String>> manualHadiths = params['manualHadiths'];
  final List<Map<String, String>> events = params['events'];
  final bool showImsakiyahScreen = params['showImsakiyahScreen'];
  final String imsakiyahProvince = params['imsakiyahProvince'];
  final String imsakiyahCity = params['imsakiyahCity'];

  String slidesHtml = slidesData.asMap().entries.map((entry) {
    int i = entry.key;
    SlideItem slide = entry.value;
    return '''
      <tr>
        <td>${i + 1}</td>
        <td>
          <strong>${slide.title}</strong><br>
          <small>${slide.content}</small>
        </td>
        <td>
          <button class="edit-btn" onclick="editSlide($i, '${slide.title}', '${slide.content}')">✏️</button>
          <a href="/delete_slide?i=$i&section=content" onclick="return confirm('Yakin ingin menghapus slide ini?');">🗑️</a>
        </td>
      </tr>
    ''';
  }).join('');

  return '''
  <div id="content" class="section">
    <div class="card">
      <h2>Slide Informasi</h2>
      <table>
        <thead><tr><th width="30">#</th><th>Konten</th><th width="60">Aksi</th></tr></thead>
        <tbody>$slidesHtml</tbody>
      </table>
      <hr>
      <h3>Tambah/Edit Slide</h3>
      <form name="slideForm" class="ajax-form" data-section="content">
        <input type="hidden" name="index" value="-1">
        <label>Judul</label>
        <input type="text" name="title" required placeholder="Contoh: Kajian Rutin">
        <label>Isi Informasi</label>
        <textarea name="content" rows="2" required placeholder="Contoh: Setiap hari Ahad ba'da Subuh..."></textarea>
        <button id="slideBtn" type="submit">Tambah Slide</button>
      </form>
    </div>
    
    <div class="card">
      <h2>Hadis & Tausiyah</h2>
      <form name="hadithForm" class="ajax-form" data-section="content">
        <div class="checkbox-group">
          <input type="checkbox" id="hadith_show" name="hadith_show" value="true" ${showHadith ? 'checked' : ''}>
          <label for="hadith_show">Tampilkan Layar Hadis/Tausiyah</label>
        </div>
        <div class="form-grid">
          <div class="form-group">
            <label for="hadith_interval">Interval (menit)</label>
            <input type="number" id="hadith_interval" name="hadith_interval" value="$hadithInterval">
          </div>
          <div class="form-group">
            <label for="hadith_speed">Kecepatan Scroll (detik)</label>
            <input type="number" id="hadith_speed" name="hadith_speed" value="$hadithSpeed">
          </div>
        </div>
        <button type="submit">Simpan Pengaturan Hadis</button>
      </form>
      <hr>
      <h3>Daftar Hadis Manual</h3>
      <table>
        <thead><tr><th>#</th><th>Teks</th><th>Sumber</th><th>Aksi</th></tr></thead>
        <tbody>
          ${manualHadiths.asMap().entries.map((entry) {
            int i = entry.key;
            var hadith = entry.value;
            return '''
              <tr>
                <td>${i + 1}</td>
                <td>${hadith['text']}</td>
                <td>${hadith['source']}</td>
                <td>
                  <button onclick="editHadith($i, '${Uri.encodeComponent(hadith['text']!)}', '${Uri.encodeComponent(hadith['source']!)}')">✏️</button>
                  <a href="/delete_hadith?i=$i&section=content" onclick="return confirm('Hapus hadis ini?');">🗑️</a>
                </td>
              </tr>
            ''';
          }).join('')}
        </tbody>
      </table>
      <hr>
      <h3>Tambah/Edit Hadis Manual</h3>
      <form name="hadithAddForm" class="ajax-form" data-section="content">
        <input type="hidden" name="index" value="-1">
        <div class="form-group">
          <label>Teks Hadis</label>
          <textarea name="text" rows="3" required></textarea>
        </div>
        <div class="form-group">
          <label>Sumber (Contoh: HR. Bukhari)</label>
          <input type="text" name="source" required>
        </div>
        <button type="submit" id="hadithBtn">Tambah Hadis</button>
      </form>
    </div>

    <div class="card">
      <h2>Agenda Kegiatan</h2>
      <table>
        <thead><tr><th>#</th><th>Nama Kegiatan</th><th>Tanggal</th><th>Aksi</th></tr></thead>
        <tbody>
          ${events.asMap().entries.map((entry) {
            int i = entry.key;
            var event = entry.value;
            return '''
              <tr>
                <td>${i + 1}</td>
                <td>${event['title']}</td>
                <td>${event['date']}</td>
                <td>
                  <button onclick="editEvent($i, '${event['title']}', '${event['date']}')">✏️</button>
                  <a href="/delete_event?i=$i&section=content" onclick="return confirm('Hapus agenda ini?');">🗑️</a>
                </td>
              </tr>
            ''';
          }).join('')}
        </tbody>
      </table>
      <hr>
      <h3>Tambah/Edit Agenda</h3>
      <form name="eventAddForm" class="ajax-form" data-section="content">
        <input type="hidden" name="index" value="-1">
        <div class="form-group">
          <label>Nama Kegiatan</label>
          <input type="text" name="title" required>
        </div>
        <div class="form-group">
          <label>Tanggal</label>
          <input type="date" name="date" required>
        </div>
        <button type="submit" id="eventBtn">Tambah Agenda</button>
      </form>
    </div>

    <div class="card">
      <h2>Jadwal Imsakiyah</h2>
      <form name="imsakiyahForm" class="ajax-form" data-section="content">
        <div class="checkbox-group">
          <input type="checkbox" id="show_imsakiyah_screen" name="show_imsakiyah_screen" value="true" ${showImsakiyahScreen ? 'checked' : ''}>
          <label for="show_imsakiyah_screen">Tampilkan Layar Imsakiyah (Selama Bulan Ramadhan)</label>
        </div>
        <div class="form-grid">
          <div class="form-group">
            <label for="imsakiyah_province">Provinsi</label>
            <input type="text" id="imsakiyah_province" name="imsakiyah_province" value="$imsakiyahProvince">
          </div>
          <div class="form-group">
            <label for="imsakiyah_city">Kota/Kabupaten</label>
            <input type="text" id="imsakiyah_city" name="imsakiyah_city" value="$imsakiyahCity">
          </div>
        </div>
        <button type="submit">Simpan Pengaturan Imsakiyah</button>
      </form>
    </div>
  </div>
  ''';
}