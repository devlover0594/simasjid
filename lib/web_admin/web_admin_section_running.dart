String buildRunningSection(Map<String, dynamic> params) {
  return '''
    <!-- Running Text -->
    <div id="running" class="section">
      <div class="card">
        <h2>Running Text</h2>
        <form action="/update_settings" method="post">
          <label>Isi Teks Berjalan</label>
          <textarea name="running_text" rows="4">${params['runningText']}</textarea>
          <button type="submit">Simpan Teks</button>
        </form>
      </div>
    </div>

''';
}
