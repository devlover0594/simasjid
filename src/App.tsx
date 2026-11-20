import React from 'react';
import { KioskShell } from './components/kiosk/KioskShell';
import { SettingsScreen } from './components/settings/SettingsScreen';
import { WebAdminScreen } from './components/admin/WebAdminScreen';
import { KioskProvider, useKiosk } from './context/KioskContext';

const AppRouter: React.FC = () => {
  const { viewMode } = useKiosk();

  if (viewMode === 'admin') {
    return <WebAdminScreen />;
  }

  return (
    <>
      <KioskShell />
      {viewMode === 'settings' && <SettingsScreen />}
    </>
  );
};

export function App() {
  return (
    <KioskProvider>
      <AppRouter />
    </KioskProvider>
  );
}

export default App;
