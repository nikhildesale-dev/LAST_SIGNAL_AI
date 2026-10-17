import React from 'react';
import {
  LogoIcon,
  OverviewIcon,
  RiskIcon,
  MapIcon,
  PackIcon,
  HazardIcon,
  CloseIcon,
  MeshRadioIcon
} from './Icons';

/**
 * Sidebar Component for LAST SIGNAL AI
 * Features:
 * - Dark navy theme
 * - Distinct brand header with logo & subtitle
 * - 5 primary navigation routes
 * - Responsive overlay & close button for mobile/tablet screens
 * - Bottom Mesh P2P connection status widget
 */
export function Sidebar({ activeTab, onSelectTab, isOpen, onClose }) {
  const navItems = [
    {
      id: 'overview',
      label: 'Overview',
      icon: <OverviewIcon size={19} />,
      badge: 'Active'
    },
    {
      id: 'risk-assessment',
      label: 'Risk Assessment',
      icon: <RiskIcon size={19} />,
      badge: null
    },
    {
      id: 'emergency-map',
      label: 'Emergency Map',
      icon: <MapIcon size={19} />,
      badge: 'Phase 2'
    },
    {
      id: 'emergency-pack',
      label: 'Emergency Pack',
      icon: <PackIcon size={19} />,
      badge: null
    },
    {
      id: 'report-hazard',
      label: 'Report Hazard',
      icon: <HazardIcon size={19} />,
      badge: 'Demo'
    }
  ];

  return (
    <>
      {/* Mobile Backdrop overlay */}
      {isOpen && (
        <div
          className="sidebar-backdrop"
          onClick={onClose}
          aria-hidden="true"
        />
      )}

      <aside className={`app-sidebar ${isOpen ? 'sidebar-open' : ''}`}>
        {/* Brand Header */}
        <div className="sidebar-brand">
          <div className="sidebar-brand-content">
            <div className="sidebar-logo-icon">
              <LogoIcon size={30} />
            </div>
            <div className="sidebar-brand-text">
              <h1 className="sidebar-title">LAST SIGNAL <span className="sidebar-title-ai">AI</span></h1>
              <p className="sidebar-tagline">Disaster Intelligence & Routing</p>
            </div>
          </div>

          {/* Close button on mobile */}
          <button
            className="sidebar-close-btn"
            onClick={onClose}
            aria-label="Close navigation sidebar"
          >
            <CloseIcon size={20} />
          </button>
        </div>

        {/* System Status Badge */}
        <div className="sidebar-competition-tag">
          <span className="pulse-indicator" />
          <span>Autonomous Emergency Mesh</span>
        </div>

        {/* Navigation Links */}
        <nav className="sidebar-nav" aria-label="Main Navigation">
          <div className="sidebar-nav-label">EMERGENCY OPERATIONS</div>
          <ul className="sidebar-nav-list">
            {navItems.map((item) => {
              const isActive = activeTab === item.id;
              return (
                <li key={item.id} className="sidebar-nav-item">
                  <button
                    type="button"
                    className={`sidebar-nav-link ${isActive ? 'active' : ''}`}
                    onClick={() => {
                      onSelectTab(item.id);
                      if (onClose) onClose();
                    }}
                    aria-current={isActive ? 'page' : undefined}
                  >
                    <span className="sidebar-nav-icon">{item.icon}</span>
                    <span className="sidebar-nav-text">{item.label}</span>
                    {item.badge && (
                      <span className={`sidebar-nav-badge ${item.badge === 'Active' ? 'badge-active' : ''}`}>
                        {item.badge}
                      </span>
                    )}
                  </button>
                </li>
              );
            })}
          </ul>
        </nav>

        {/* Bottom P2P Mesh Connectivity Widget */}
        <div className="sidebar-footer">
          <div className="sidebar-mesh-status">
            <div className="mesh-status-header">
              <span className="mesh-beacon-dot" />
              <div className="mesh-header-text">
                <span className="mesh-title">P2P Mesh Network</span>
                <span className="mesh-pill">OFFLINE READY</span>
              </div>
            </div>
            <p className="mesh-nodes-info">
              <MeshRadioIcon size={14} className="mesh-inline-icon" />
              14 Local Peers Connected
            </p>
            <div className="mesh-offline-badge">
              <span>Backhaul Grid: Down (Mesh Active)</span>
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}

export default Sidebar;
