String buildSlideSection(Map<String, dynamic> params) {
  return '''
    <!-- Slide Informasi -->
    <div id="slide" class="section">
      <div class="card">
        <h2>Slide Informasi</h2>
        <table>
          <thead><tr><th width="30">#</th><th>Konten</th><th width="60">Aksi</th></tr></thead>
          <tbody>${params['slidesHtml']}</tbody>
        </table>
        <hr style="border:0; border-top:1px solid #eee; margin: 20px 0;">
        <h3>Tambah Slide Baru</h3>
        <form name="slideForm" action="/add_slide" method="post">
          <input type="hidden" name="index" value="-1">
          <label>Judul</label>
          <input type="text" name="title" required placeholder="Contoh: Kajian Rutin">
          <label>Isi Informasi</label>
          <textarea name="content" rows="2" required placeholder="Contoh: Setiap hari Ahad ba'da Subuh..."></textarea>
          <button id="slideBtn" type="submit" style="background:#4CAF50;">Tambah Slide</button>
        </form>
      </div>
    </div>

''';
}
