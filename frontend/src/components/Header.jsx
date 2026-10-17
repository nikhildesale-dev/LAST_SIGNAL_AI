import React from 'react';
import { MenuIcon, MeshRadioIcon } from './Icons';

/**
 * Header Component for LAST SIGNAL AI
 * Displays current section title, mobile menu trigger, and prominent DEMO DATA notice.
 */
export function Header({
  currentScreenTitle = 'Operations Overview',
  currentScreenSubtitle = 'Predictive Disaster Intelligence & Emergency Coordination',
  onOpenMobileMenu,
  onSimulateMeshPing
}) {
  return (
    <header className="app-header">
      <div className="header-left">
        <button
          type="button"
          className="header-mobile-toggle"
          onClick={onOpenMobileMenu}
          aria-label="Open navigation menu"
        >
          <MenuIcon size={22} />
        </button>

        <div className="header-titles">
          <h2 className="header-screen-title">{currentScreenTitle}</h2>
          {currentScreenSubtitle && (
            <p className="header-screen-subtitle">{currentScreenSubtitle}</p>
          )}
        </div>
      </div>

      <div className="header-right">
        {/* Professional Demo Data Badge */}
        <div
          className="header-demo-chip"
          title="Simulated emergency readings — No live AI model or physical sensors connected"
        >
          <span className="demo-chip-dot" aria-hidden="true" />
          <span className="demo-chip-label">DEMO DATA</span>
        </div>

        {/* P2P Mesh Ping simulation button */}
        <button
          type="button"
          className="header-mesh-ping-btn"
          onClick={onSimulateMeshPing}
          title="Click to simulate an offline P2P beacon broadcast"
        >
          <MeshRadioIcon size={16} />
          <span>Mesh Beacon Ping</span>
        </button>
      </div>
    </header>
  );
}

export default Header;
