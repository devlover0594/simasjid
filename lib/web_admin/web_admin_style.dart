const String adminStyleCss = r'''
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap');

    :root {
      --primary: #0d9488;
      --primary-dark: #0f766e;
      --primary-soft: #f0fdfa;
      --primary-glow: rgba(13, 148, 136, 0.18);
      --accent: #f59e0b;
      --danger: #ef4444;
      --danger-soft: rgba(239, 68, 68, 0.10);
      --success: #16a34a;
      --bg: #eef2f6;
      --surface: #ffffff;
      --surface-2: #f8fafc;
      --text: #0f172a;
      --text-muted: #64748b;
      --border: #e2e8f0;
      --radius: 14px;
      --radius-sm: 10px;
      --shadow: 0 1px 2px rgba(15, 23, 42, 0.04), 0 8px 24px rgba(15, 23, 42, 0.06);
      --shadow-sm: 0 1px 2px rgba(15, 23, 42, 0.06);
      --transition: all 0.2s ease;
      --maxw: 960px;
    }

    * { box-sizing: border-box; }

    body {
      font-family: 'Outfit', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      background: var(--bg);
      color: var(--text);
      -webkit-font-smoothing: antialiased;
      line-height: 1.5;
    }

    .main-container { display: flex; min-height: 100vh; }

    /* Content column */
    .content {
      flex-grow: 1;
      min-width: 0;
      padding: 0 0 60px;
      overflow-y: auto;
    }

    /* Sticky topbar */
    .topbar {
      position: sticky;
      top: 0;
      z-index: 50;
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px 24px;
      background: rgba(255, 255, 255, 0.9);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      border-bottom: 1px solid var(--border);
    }
    #page-title {
      margin: 0;
      font-size: 1.35em;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.3px;
    }
    #back-button {
      width: auto;
      margin: 0;
      padding: 8px 14px;
      font-size: 14px;
      background: var(--surface-2);
      color: var(--text);
      border: 1px solid var(--border);
      box-shadow: var(--shadow-sm);
    }
    #back-button:hover { background: var(--border); transform: none; }

    /* Main menu grid */
    #main-menu { padding: 24px; }
    .grid-menu {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
      gap: 16px;
      max-width: var(--maxw);
      margin: 0 auto;
    }
    .menu-item {
      background: var(--surface);
      border-radius: var(--radius);
      padding: 22px 16px;
      text-align: center;
      cursor: pointer;
      transition: var(--transition);
      border: 1px solid var(--border);
      box-shadow: var(--shadow-sm);
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 10px;
    }
    .menu-item:hover {
      transform: translateY(-3px);
      box-shadow: var(--shadow);
      border-color: var(--primary);
    }
    .menu-item:active { transform: translateY(0); }
    .menu-item .icon {
      font-size: 1.9em;
      width: 56px;
      height: 56px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: var(--primary-soft);
      border-radius: 50%;
    }
    .menu-item .title { font-weight: 600; color: var(--text); font-size: 0.95em; }

    /* Sections */
    .section {
      display: none;
      padding: 24px;
      animation: fade-in 0.25s ease;
    }
    .section.active { display: block; }
    @keyframes fade-in { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: none; } }

    /* Card */
    .card {
      background: var(--surface);
      padding: 24px;
      border-radius: var(--radius);
      border: 1px solid var(--border);
      box-shadow: var(--shadow);
      margin-bottom: 20px;
      max-width: var(--maxw);
      margin-left: auto;
      margin-right: auto;
    }

    h2 {
      margin: 0 0 6px;
      font-size: 1.4em;
      font-weight: 700;
      color: var(--text);
      display: flex;
      align-items: center;
      gap: 10px;
    }
    h2::before {
      content: '';
      width: 5px;
      height: 20px;
      background: var(--primary);
      border-radius: 3px;
    }
    h3 {
      margin: 22px 0 10px;
      color: var(--text);
      font-size: 1.05em;
      font-weight: 600;
    }
    h4 { margin: 16px 0 8px; font-size: 0.98em; font-weight: 600; color: var(--text-muted); }
    .card > p:first-of-type, .section .card p.lead { color: var(--text-muted); margin-top: 0; }

    /* Form fields */
    label {
      display: block;
      margin-top: 14px;
      font-weight: 600;
      font-size: 0.85em;
      color: var(--text-muted);
      margin-bottom: 6px;
    }
    input[type=text], input[type=number], input[type=date], input[type=time],
    input[type=password], input[type=email], input[type=color], textarea, select {
      width: 100%;
      padding: 11px 14px;
      background: var(--surface-2);
      border: 1.5px solid var(--border);
      border-radius: var(--radius-sm);
      font-size: 15px;
      font-family: inherit;
      transition: var(--transition);
      color: var(--text);
    }
    input[type=color] { padding: 2px; height: 40px; }
    textarea { resize: vertical; min-height: 72px; }
    input:focus, textarea:focus, select:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px var(--primary-glow);
      background: var(--surface);
    }
    .help { font-size: 0.8em; color: var(--text-muted); margin: 4px 0 0; }

    /* Two-column field grid on wide screens */
    .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0 16px; }
    @media (max-width: 640px) { .form-grid { grid-template-columns: 1fr; } }

    /* Buttons */
    button {
      background: var(--primary);
      color: white;
      padding: 12px 22px;
      border: none;
      border-radius: var(--radius-sm);
      cursor: pointer;
      width: 100%;
      margin-top: 18px;
      font-size: 15px;
      font-weight: 600;
      font-family: inherit;
      transition: var(--transition);
      box-shadow: var(--shadow-sm);
    }
    button:hover { background: var(--primary-dark); transform: translateY(-1px); }
    button:active { transform: translateY(0); }
    button:focus-visible, a:focus-visible, .menu-item:focus-visible, .theme-card:focus-visible {
      outline: 3px solid var(--primary-glow);
      outline-offset: 2px;
    }
    .btn-secondary { background: var(--surface-2); color: var(--text); border: 1px solid var(--border); }
    .btn-secondary:hover { background: var(--border); }
    .btn-danger { background: var(--danger); }
    .btn-danger:hover { background: #dc2626; }

    /* Tables */
    .table-wrap { overflow-x: auto; -webkit-overflow-scrolling: touch; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 14px;
      font-size: 0.92em;
    }
    thead th {
      text-align: left;
      padding: 10px 14px;
      color: var(--text-muted);
      font-weight: 600;
      font-size: 0.78em;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      border-bottom: 2px solid var(--border);
      white-space: nowrap;
    }
    td {
      padding: 12px 14px;
      border-bottom: 1px solid var(--border);
      vertical-align: middle;
    }
    tbody tr:hover { background: var(--surface-2); }
    td small, td .help { color: var(--text-muted); }
    td code { word-break: break-all; }

    /* Badges */
    .badge {
      display: inline-block;
      padding: 2px 10px;
      border-radius: 999px;
      font-size: 0.72em;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.4px;
      background: var(--primary-soft);
      color: var(--primary-dark);
      border: 1px solid var(--primary-glow);
    }
    .badge-image { background: #eff6ff; color: #1d4ed8; border-color: #dbeafe; }
    .badge-video { background: #faf5ff; color: #7c3aed; border-color: #f3e8ff; }
    .badge-audio { background: #fff7ed; color: #c2410c; border-color: #ffedd5; }
    .badge-youtube { background: #fef2f2; color: #b91c1c; border-color: #fee2e2; }

    /* Row action buttons */
    .btn-edit {
      background: var(--surface-2);
      color: var(--text);
      padding: 6px 12px;
      font-size: 13px;
      width: auto;
      margin: 0 6px 0 0;
      border: 1px solid var(--border);
      box-shadow: none;
      display: inline-block;
    }
    .btn-edit:hover { background: var(--primary-soft); border-color: var(--primary); color: var(--primary-dark); transform: none; }
    .btn-delete {
      color: var(--danger);
      text-decoration: none;
      font-weight: 600;
      font-size: 13px;
      padding: 6px 10px;
      border-radius: 8px;
      border: 1px solid var(--danger-soft);
      background: var(--danger-soft);
      transition: var(--transition);
      display: inline-block;
    }
    .btn-delete:hover { background: var(--danger); color: #fff; }
    td:last-child { text-align: right; white-space: nowrap; }

    /* Empty state */
    .empty {
      text-align: center;
      color: var(--text-muted);
      padding: 28px 16px;
      border: 1px dashed var(--border);
      border-radius: var(--radius-sm);
      background: var(--surface-2);
      margin-top: 12px;
    }

    /* Checkbox chips (days etc.) */
    .checkbox-group { margin-top: 8px; display: flex; flex-wrap: wrap; gap: 10px; }
    .checkbox-group label {
      display: inline-flex; align-items: center; margin: 0; font-weight: 500;
      background: var(--surface-2); padding: 8px 14px; border-radius: 999px;
      cursor: pointer; border: 1.5px solid var(--border); transition: var(--transition);
      font-size: 0.85em; color: var(--text);
    }
    .checkbox-group label:hover { border-color: var(--primary); }
    .checkbox-group input { margin-right: 8px; width: 16px; height: 16px; accent-color: var(--primary); }
    .checkbox-group input:checked + span { color: var(--primary-dark); }

    /* Generic responsive row/col */
    .row { display: flex; gap: 14px; flex-wrap: wrap; }
    .col { flex: 1; min-width: 160px; }

    /* Accordion (murottal) */
    .accordion-item {
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      margin-bottom: 12px;
      overflow: hidden;
      background: var(--surface);
    }
    .accordion-header {
      display: flex; align-items: center; justify-content: space-between;
      padding: 14px 18px; cursor: pointer; user-select: none;
      background: var(--surface-2); font-weight: 600;
    }
    .accordion-header h3 { margin: 0; font-size: 1em; }
    .accordion-header:hover { background: var(--primary-soft); }
    .accordion-icon::after { content: '+'; font-size: 1.3em; color: var(--primary); font-weight: 700; }
    .accordion-header.active .accordion-icon::after { content: '\2212'; }
    .accordion-content { padding: 16px 18px; border-top: 1px solid var(--border); }

    /* Theme presets */
    .theme-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 16px; margin-top: 16px; }
    .theme-card {
      background: var(--surface); border: 2px solid var(--border); border-radius: var(--radius-sm);
      padding: 16px; display: flex; align-items: center; cursor: pointer; position: relative; transition: var(--transition);
    }
    .theme-card:hover { border-color: var(--primary); transform: translateY(-2px); box-shadow: var(--shadow); }
    .theme-card.active { border-color: var(--primary); background: var(--primary-soft); }
    .theme-preview { width: 52px; height: 52px; border-radius: 12px; flex-shrink: 0; box-shadow: var(--shadow-sm); }
    .theme-info { margin-left: 14px; flex: 1; }
    .theme-info b { font-size: 0.98em; color: var(--text); }
    .theme-info small { color: var(--text-muted); font-size: 0.8em; display: block; margin-top: 4px; }
    .theme-card .check { position: absolute; right: 14px; top: 14px; color: var(--primary); font-size: 1.1em; }

    .bg-upload-box {
      background: var(--surface-2); padding: 20px; border-radius: var(--radius-sm);
      border: 2px dashed var(--border); margin-top: 18px;
    }

    /* Toggle switch */
    .toggle-switch { display: flex; align-items: center; justify-content: space-between; padding: 14px 0; border-top: 1px solid var(--border); margin-top: 14px; gap: 12px; }
    .switch { position: relative; display: inline-block; width: 48px; height: 26px; flex-shrink: 0; }
    .switch input { opacity: 0; width: 0; height: 0; }
    .slider { position: absolute; inset: 0; cursor: pointer; background-color: var(--border); transition: .3s; border-radius: 26px; }
    .slider:before { position: absolute; content: ""; height: 20px; width: 20px; left: 3px; bottom: 3px; background-color: white; transition: .3s; border-radius: 50%; box-shadow: 0 1px 3px rgba(0,0,0,0.2); }
    input:checked + .slider { background-color: var(--primary); }
    input:checked + .slider:before { transform: translateX(22px); }

    /* Toast */
    .toast { box-shadow: var(--shadow); font-weight: 500; max-width: 320px; }

    /* Mobile */
    @media (max-width: 768px) {
      #main-menu, .section { padding: 16px; }
      .topbar { padding: 12px 16px; }
      .card { padding: 18px; }
      .grid-menu { grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 12px; }
      .row { gap: 10px; }
      .col { min-width: 100%; }
      table { font-size: 0.85em; }
      h2 { font-size: 1.2em; }
    }
  </style>
''';
