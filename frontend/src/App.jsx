import React, { useState } from 'react';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import OverviewScreen from './screens/OverviewScreen';
import RiskAssessmentScreen from './screens/RiskAssessmentScreen';
import EmergencyMapScreen from './screens/EmergencyMapScreen';
import EmergencyPackScreen from './screens/EmergencyPackScreen';
import ReportHazardScreen from './screens/ReportHazardScreen';
import { MeshRadioIcon } from './components/Icons';
import './App.css';

/**
 * LAST SIGNAL AI - Main Application Component
 * Manages active screen routing, mobile drawer open/close, and mesh simulation alerts.
 */
export function App() {
  const [activeTab, setActiveTab] = useState('overview');
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState(null);

  // Screen configuration
  const screens = {
    overview: {
      title: 'Operations Overview',
      subtitle: 'Predictive Disaster Intelligence & Emergency Coordination',
      component: <OverviewScreen onNavigateToScreen={(tab) => setActiveTab(tab)} />
    },
    'risk-assessment': {
      title: 'Risk Assessment & Contributing Factors',
      subtitle: 'Simulated AI Vulnerability Weights & Safety Directives',
      component: <RiskAssessmentScreen />
    },
    'emergency-map': {
      title: 'Emergency Map & Predictive Routing',
      subtitle: 'Offline Elevation-Aware Navigation & Hazard Avoidance',
      component: <EmergencyMapScreen />
    },
    'emergency-pack': {
      title: 'Emergency Pack & Survival Vault',
      subtitle: 'Personal Preparedness Readiness & Offline Protocols',
      component: <EmergencyPackScreen />
    },
    'report-hazard': {
      title: 'Report Local Hazard',
      subtitle: 'Citizen Telemetry & Decentralized P2P Mesh Gossip',
      component: <ReportHazardScreen />
    }
  };

  const currentScreen = screens[activeTab] || screens.overview;

  // Simulate mesh ping toast notification
  const handleSimulateMeshPing = () => {
    setToastMessage('P2P Mesh Ping Broadcasted: 14 nearby nodes acknowledged beacon (Latency: 48ms)');
    setTimeout(() => {
      setToastMessage(null);
    }, 4500);
  };

  return (
    <div className="app-layout">
      {/* Dark Navy Sidebar */}
      <Sidebar
        activeTab={activeTab}
        onSelectTab={(tab) => setActiveTab(tab)}
        isOpen={isMobileMenuOpen}
        onClose={() => setIsMobileMenuOpen(false)}
      />

      {/* Main Light Workspace */}
      <div className="app-workspace">
        {/* Top Header */}
        <Header
          currentScreenTitle={currentScreen.title}
          currentScreenSubtitle={currentScreen.subtitle}
          onOpenMobileMenu={() => setIsMobileMenuOpen(true)}
          onSimulateMeshPing={handleSimulateMeshPing}
        />

        {/* Scrollable Screen Content */}
        <main className="app-main-content">
          {currentScreen.component}
        </main>
      </div>

      {/* Floating Simulated Mesh Toast */}
      {toastMessage && (
        <div className="mesh-toast-notification" role="status">
          <MeshRadioIcon size={18} className="toast-icon" />
          <span>{toastMessage}</span>
          <button
            type="button"
            className="toast-close-btn"
            onClick={() => setToastMessage(null)}
            aria-label="Dismiss message"
          >
            ✕
          </button>
        </div>
      )}
    </div>
  );
}

export default App;
