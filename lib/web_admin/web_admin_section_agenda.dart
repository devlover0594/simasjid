String buildAgendaSection(Map<String, dynamic> params) {
  return '''
    <!-- Agenda -->
    <div id="agenda" class="section">
      <div class="card">
        <h2>Agenda & Event</h2>
        <table>
          <thead><tr><th width="30">#</th><th>Kegiatan</th><th>Tanggal</th><th width="60">Aksi</th></tr></thead>
          <tbody>${params['eventHtml']}</tbody>
        </table>
        
        <hr style="border:0; border-top:1px solid #eee; margin: 20px 0;">
        <h3>Tambah Agenda</h3>
        <form name="eventForm" action="/add_event" method="post">
          <input type="hidden" name="index" value="-1">
          <label>Nama Kegiatan</label>
          <input type="text" name="title" required>
          <label>Tanggal</label>
          <input type="date" name="date" required>
          <button id="eventBtn" type="submit" style="background:#9C27B0;">Tambah Agenda</button>
        </form>
      </div>
    </div>

''';
}
