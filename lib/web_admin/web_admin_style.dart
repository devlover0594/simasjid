const String adminStyleCss = r'''
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap');

    :root {
      --primary: #009688;
      --primary-glow: rgba(0, 150, 136, 0.3);
      --accent: #FFC107;
      --sidebar-bg: #ffffff;
      --sidebar-hover: rgba(255, 255, 255, 0.05);
      --content-bg: #f1f5f9;
      --card-bg: rgba(255, 255, 255, 0.85);
      --text-primary: #1e293b;
      --text-secondary: #64748b;
      --border-color: rgba(0, 0, 0, 0.05);
      --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    body { 
      font-family: 'Outfit', sans-serif; 
      margin: 0; 
      background: var(--content-bg); 
      color: var(--text-primary); 
      -webkit-font-smoothing: antialiased;
    }
    .main-container {
      display: flex;
    }
    
    /* Sidebar */
    .sidebar { 
      width: 280px; 
      background: var(--sidebar-bg); 
      color: #f8fafc; 
      display: flex; 
      flex-direction: column; 
      flex-shrink: 0;
      box-shadow: 4px 0 20px rgba(0,0,0,0.1);
      z-index: 100;
      position: relative;
    }

    .grid-menu {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 20px;
      padding: 20px;
    }

    .menu-item {
      background: #fff;
      border-radius: 16px;
      padding: 20px;
      text-align: center;
      cursor: pointer;
      transition: all 0.2s ease-in-out;
      border: 1px solid #e2e8f0;
      box-shadow: 0 4px 6px rgba(0,0,0,0.05);
    }
    .menu-item:hover {
      transform: translateY(-5px);
      box-shadow: 0 10px 20px rgba(0,0,0,0.08);
      border-color: var(--primary);
    }
    .menu-item .icon {
      font-size: 2.5em;
      color: var(--primary);
      margin-bottom: 15px;
    }
    .menu-item .title { font-weight: 600; color: var(--text-primary); }
    
    .sidebar::after {
      content: '';
      position: absolute;
      top: 0; right: 0; bottom: 0;
      width: 1px;
      background: linear-gradient(to bottom, transparent, rgba(255,255,255,0.1), transparent);
    }

    .sidebar-header { 
      padding: 30px 20px; 
      background: rgba(255,255,255,0.03); 
      text-align: center; 
      font-size: 1.5em; 
      font-weight: 700; 
      letter-spacing: -0.5px;
      color: var(--primary);
      text-transform: uppercase;
    }

    .sidebar ul { 
      list-style: none; 
      padding: 10px; 
      margin: 0; 
      overflow-y: auto; 
      flex: 1; 
    }

    .sidebar li { 
      padding: 14px 20px; 
      margin-bottom: 4px;
      border-radius: 10px;
      cursor: pointer; 
      transition: var(--transition); 
      display: flex;
      align-items: center;
      font-weight: 500;
      color: #94a3b8;
    }

    .sidebar li:hover { 
      background: var(--sidebar-hover); 
      color: #f8fafc;
      transform: translateX(5px);
    }

    .sidebar li.active { 
      background: var(--primary); 
      color: white; 
      box-shadow: 0 4px 15px var(--primary-glow);
    }
    
    /* Content */
    .content { 
      flex-grow: 1;
      padding: 40px; 
      overflow-y: auto; 
      scroll-behavior: smooth;
    }

    .section { 
      display: none; 
      opacity: 0;
      transform: translateY(10px);
      transition: opacity 0.4s ease, transform 0.4s ease;
    }

    .section.active { 
      display: block; 
      opacity: 1; 
      transform: translateY(0);
    }

    .card { 
      background: var(--card-bg); 
      padding: 35px; 
      border-radius: 20px; 
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border: 1px solid rgba(255, 255, 255, 0.5);
      box-shadow: 0 10px 30px rgba(0,0,0,0.04);
      margin-bottom: 30px; 
      max-width: 1000px; 
      margin-left: auto; 
      margin-right: auto; 
    }

    h2 { 
      margin-top: 0; 
      font-size: 1.8em;
      font-weight: 700;
      color: var(--text-primary);
      margin-bottom: 25px;
      display: flex;
      align-items: center;
      gap: 12px;
    }

    h2::before {
      content: '';
      width: 6px;
      height: 24px;
      background: var(--primary);
      border-radius: 3px;
    }

    h3 { 
      margin-top: 0; 
      color: var(--text-secondary); 
      font-size: 1.1em;
      font-weight: 600;
      margin-bottom: 15px;
    }

    label { 
      display: block; 
      margin-top: 15px; 
      font-weight: 600; 
      font-size: 0.9em; 
      color: var(--text-secondary);
      margin-bottom: 8px;
    }

    input[type=text], input[type=number], input[type=date], input[type=time], textarea, select { 
      width: 100%; 
      padding: 12px 16px; 
      background: #f8fafc;
      border: 1.5px solid #e2e8f0; 
      border-radius: 12px; 
      box-sizing: border-box; 
      font-size: 15px; 
      font-family: inherit;
      transition: var(--transition);
      color: var(--text-primary);
    }

    input:focus, textarea:focus, select:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 4px var(--primary-glow);
      background: white;
    }

    button { 
      background: var(--primary); 
      color: white; 
      padding: 14px 24px; 
      border: none; 
      border-radius: 12px; 
      cursor: pointer; 
      width: 100%; 
      margin-top: 20px; 
      font-size: 16px; 
      font-weight: 600; 
      transition: var(--transition);
      box-shadow: 0 4px 12px var(--primary-glow);
    }

    button:hover { 
      background: var(--primary-dark); 
      transform: translateY(-2px);
      box-shadow: 0 6px 20px var(--primary-glow);
    }
    
    button:active {
      transform: translateY(0);
    }

    table { 
      width: 100%; 
      border-collapse: separate; 
      border-spacing: 0 8px;
      margin-top: 15px; 
    }

    th { 
      text-align: left; 
      padding: 12px 20px; 
      color: var(--text-secondary);
      font-weight: 600;
      font-size: 0.85em;
      text-transform: uppercase;
      letter-spacing: 1px;
    }

    td { 
      padding: 16px 20px; 
      background: #f8fafc;
      border-top: 1px solid #f1f5f9;
      border-bottom: 1px solid #f1f5f9;
    }
    
    td:first-child { border-left: 1px solid #f1f5f9; border-top-left-radius: 12px; border-bottom-left-radius: 12px; }
    td:last-child { border-right: 1px solid #f1f5f9; border-top-right-radius: 12px; border-bottom-right-radius: 12px; }

    .btn-edit { 
      background: rgba(255, 193, 7, 0.1); 
      color: #b45309; 
      padding: 6px 14px; 
      font-size: 13px; 
      width: auto; 
      margin-right: 8px; 
      border: 1px solid rgba(255, 193, 7, 0.3);
      box-shadow: none;
    }
    
    .btn-edit:hover {
      background: var(--accent);
      color: #fff;
    }

    .btn-delete { 
      color: #ef4444; 
      text-decoration: none; 
      font-weight: 600; 
      font-size: 13px; 
      padding: 6px 12px;
      border-radius: 8px;
      transition: var(--transition);
    }
    
    .btn-delete:hover {
      background: rgba(239, 68, 68, 0.1);
    }
    
    .checkbox-group { 
      margin-top: 10px; 
      display: flex; 
      flex-wrap: wrap; 
      gap: 12px; 
    }

    .checkbox-group label { 
      display: flex; 
      align-items: center; 
      margin: 0; 
      font-weight: 500; 
      background: #f1f5f9; 
      padding: 8px 16px; 
      border-radius: 20px; 
      cursor: pointer; 
      border: 1.5px solid transparent;
      transition: var(--transition);
      font-size: 0.85em;
    }
    
    .checkbox-group label:hover {
      background: #e2e8f0;
    }

    .checkbox-group input { 
      margin-right: 10px; 
      width: 18px; 
      height: 18px; 
      accent-color: var(--primary);
      margin-top: 0; 
    }

    .checkbox-group input:checked + span {
      color: var(--primary);
    }

    .row { display: flex; gap: 20px; }
    .col { flex: 1; }
    
    /* Theme Presets */
    .theme-grid { 
      display: grid; 
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); 
      gap: 20px; 
      margin-top: 20px; 
    }

    .theme-card { 
      background: #ffffff; 
      border: 2px solid #f1f5f9; 
      border-radius: 16px; 
      padding: 20px; 
      display: flex; 
      align-items: center; 
      cursor: pointer; 
      position: relative; 
      transition: var(--transition); 
    }

    .theme-card:hover { 
      border-color: var(--primary); 
      transform: translateY(-4px);
      box-shadow: 0 12px 20px rgba(0,0,0,0.05);
    }

    .theme-card.active { 
      border-color: var(--primary); 
      background: #f0fdfa; 
    }

    .theme-preview { 
      width: 60px; 
      height: 60px; 
      border-radius: 16px; 
      flex-shrink: 0; 
      box-shadow: 0 8px 16px rgba(0,0,0,0.1); 
    }

    .theme-info { margin-left: 20px; flex: 1; }
    .theme-info b { font-size: 1em; color: var(--text-primary); }
    .theme-info small { color: var(--text-secondary); font-size: 0.85em; display: block; margin-top: 4px; }
    .theme-card .check { position: absolute; right: 15px; top: 15px; color: var(--primary); font-size: 1.2em; }
    
    .bg-upload-box { 
      background: #f8fafc; 
      padding: 30px; 
      border-radius: 16px; 
      border: 2px dashed #e2e8f0;
      margin-top: 30px; 
    }

    .toggle-switch { 
      display: flex; 
      align-items: center; 
      justify-content: space-between; 
      padding: 20px 0; 
      border-top: 1px solid #f1f5f9; 
      margin-top: 25px; 
    }

    .switch { 
      position: relative; 
      display: inline-block; 
      width: 52px; 
      height: 28px; 
    }

    .switch input { opacity: 0; width: 0; height: 0; }
    
    .slider { 
      position: absolute; 
      cursor: pointer; 
      top: 0; left: 0; right: 0; bottom: 0; 
      background-color: #e2e8f0; 
      transition: .4s; 
      border-radius: 28px; 
    }

    .slider:before { 
      position: absolute; 
      content: ""; 
      height: 22px; 
      width: 22px; 
      left: 3px; 
      bottom: 3px; 
      background-color: white; 
      transition: .4s; 
      border-radius: 50%; 
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    input:checked + .slider { background-color: var(--primary); }
    input:checked + .slider:before { transform: translateX(24px); }

    @media (max-width: 1024px) {
      .main-container { flex-direction: column; }
      .sidebar { display: none; } /* Hide sidebar on mobile, use grid */
      .content { padding: 25px; }
    }

    @media (max-width: 768px) {
      .grid-menu { grid-template-columns: 1fr 1fr; gap: 15px; padding: 15px; }
      .sidebar ul { display: flex; overflow-x: auto; padding: 10px; }
      .sidebar li { margin-bottom: 0; margin-right: 8px; white-space: nowrap; }
      .content { padding: 20px; }
      .row { flex-direction: column; gap: 10px; }
    }
  </style>
''';
