import React, { useState } from 'react';
import { CheckCircleIcon } from '../components/Icons';
import { RiskBadge } from '../components/RiskBadge';

/**
 * EmergencyMapScreen Component
 * Polished placeholder and preview for Phase 2 Emergency Map:
 * - Clear roadmap banner stating map features are planned for Phase 2
 * - Interactive mockup of offline routing UI
 * - Simulated vector tile cache status
 */
export function EmergencyMapScreen() {
  const [selectedRoute, setSelectedRoute] = useState('alpha');

  return (
    <div className="dashboard-content">
      {/* Roadmap Milestone Banner */}
      <div className="roadmap-hero-banner">
        <div className="roadmap-badge-row">
          <span className="roadmap-phase-pill">PHASE 2 DEVELOPMENT PREVIEW</span>
          <span className="roadmap-demo-pill">DEMO UI PLACEHOLDER</span>
        </div>
        <h3 className="roadmap-title">Offline Predictive Emergency Routing Map</h3>
        <p className="roadmap-subtitle">
          In Phase 2, this module will integrate vector map tiles, offline Dijkstra/A* routing algorithms, and live peer-to-peer hazard avoidance. External map APIs and tiles are intentionally excluded in Phase 1 per competition constraints.
        </p>
      </div>

      {/* Interactive Mock Map Canvas & Controls */}
      <div className="map-preview-grid">
        {/* Left Side: Mock Interactive Radar/GIS Map View */}
        <div className="mock-map-canvas-container">
          <div className="mock-map-header">
            <div className="mock-map-title">
              <span className="map-live-dot" />
              <span>OFFLINE MESH RADAR CANVAS (SIMULATED)</span>
            </div>
            <span className="mock-map-zoom-label">Scale: 1:25,000 • Sector 4 Grid</span>
          </div>

          {/* Graphical Mock Map Visualization */}
          <div className="mock-map-canvas">
            {/* Grid Lines */}
            <div className="mock-map-grid-overlay" />

            {/* Simulated Hazard Exclusion Zone */}
            <div className="mock-hazard-zone high-hazard-zone">
              <span className="zone-label">⚠️ FLASH FLOOD SURGE ZONE (IMPASSABLE)</span>
            </div>

            <div className="mock-hazard-zone moderate-hazard-zone">
              <span className="zone-label">⚠️ HILLSIDE MUDSLIDE RISK</span>
            </div>

            {/* Simulated Route Paths */}
            <svg className="mock-route-svg" viewBox="0 0 600 360">
              {/* Dangerous / Blocked direct path */}
              <path
                d="M 80 290 Q 220 220 320 200 T 510 90"
                fill="none"
                stroke="#EF4444"
                strokeWidth={selectedRoute === 'beta' ? '5' : '3'}
                strokeDasharray="6 6"
                opacity={selectedRoute === 'beta' ? '1' : '0.6'}
              />
              {/* Recommended safe high-ground bypass path */}
              <path
                d="M 80 290 Q 90 120 240 80 T 510 90"
                fill="none"
                stroke="#10B981"
                strokeWidth={selectedRoute === 'alpha' ? '5' : '3'}
                opacity={selectedRoute === 'alpha' ? '1' : '0.6'}
              />
            </svg>

            {/* Map Markers */}
            <div className="map-marker user-location" style={{ left: '12%', top: '78%' }}>
              <div className="marker-dot user" />
              <div className="marker-callout">
                <span className="callout-name">You (Sector 4)</span>
                <span className="callout-sub">Elev: 42m (Low Ground)</span>
              </div>
            </div>

            <div className="map-marker hazard-blocker" style={{ left: '50%', top: '52%' }}>
              <div className="marker-dot hazard" />
              <div className="marker-callout alert">
                <span className="callout-name">Underpass Flooded</span>
                <span className="callout-sub">1.1m Deep • Blocked</span>
              </div>
            </div>

            <div className="map-marker safe-destination" style={{ left: '82%', top: '22%' }}>
              <div className="marker-dot destination" />
              <div className="marker-callout safe">
                <span className="callout-name">Apex Shelter</span>
                <span className="callout-sub">Elev: 185m • Safe Haven</span>
              </div>
            </div>

            {/* Map Canvas Legend */}
            <div className="mock-map-legend">
              <div className="legend-item">
                <span className="legend-line safe" />
                <span>AI Recommended Safe Corridor</span>
              </div>
              <div className="legend-item">
                <span className="legend-line danger" />
                <span>Blocked Inundation Route</span>
              </div>
              <div className="legend-item">
                <span className="legend-dot shelter" />
                <span>Evacuation Shelter</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Side: Route Planner Preview & Phase 2 Technical Specs */}
        <div className="map-sidebar-details">
          {/* Simulated Route Options */}
          <div className="card-container routing-plan-card">
            <h4 className="card-sub-heading">Simulated Safe Route Navigation</h4>
            
            <div
              className={`route-select-box ${selectedRoute === 'alpha' ? 'selected' : ''}`}
              onClick={() => setSelectedRoute('alpha')}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') setSelectedRoute('alpha'); }}
            >
              <div className="route-select-header">
                <span className="route-name">Route Alpha: High-Ground Bypass</span>
                <RiskBadge level="Low" label="Safe Corridor" size="sm" />
              </div>
              <p className="route-desc">
                Reroutes via North Ridge Spine. Adds 1.4 km but maintains elevation &gt; 120m, completely circumventing low-lying underpasses.
              </p>
              <div className="route-specs">
                <span>Distance: <strong>4.2 km</strong></span>
                <span>Est. Walking Time: <strong>48 mins</strong></span>
                <span>Hazard Clearance: <strong>100%</strong></span>
              </div>
            </div>

            <div
              className={`route-select-box ${selectedRoute === 'beta' ? 'disabled selected' : 'disabled'}`}
              onClick={() => setSelectedRoute('beta')}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') setSelectedRoute('beta'); }}
            >
              <div className="route-select-header">
                <span className="route-name">Route Beta: Direct Valley Avenue</span>
                <RiskBadge level="High" label="BLOCKED" size="sm" />
              </div>
              <p className="route-desc">
                Direct route impassable due to Underpass 4 flash flooding (water level 1.1m).
              </p>
              <div className="route-specs">
                <span>Distance: <strong>2.8 km</strong></span>
                <span>Status: <strong className="risk-text-high">Hazard Active</strong></span>
              </div>
            </div>
          </div>

          {/* Phase 2 Feature Roadmap Card */}
          <div className="card-container phase2-specs-card">
            <h4 className="card-sub-heading">Phase 2 Engineering Roadmap</h4>
            <ul className="phase2-feature-list">
              <li>
                <CheckCircleIcon size={16} className="feature-check-icon" />
                <div>
                  <strong>Offline MapLibre Vector Cache:</strong>
                  <p>Pre-caching regional topographies into IndexedDB to function with zero cellular coverage.</p>
                </div>
              </li>
              <li>
                <CheckCircleIcon size={16} className="feature-check-icon" />
                <div>
                  <strong>Predictive Flood Inundation Overlay:</strong>
                  <p>Dynamic polygon rendering of predicted water levels based on precipitation rates.</p>
                </div>
              </li>
              <li>
                <CheckCircleIcon size={16} className="feature-check-icon" />
                <div>
                  <strong>P2P Route Syncing:</strong>
                  <p>Devices exchange verified passable road segments over Bluetooth and Wi-Fi Direct mesh.</p>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}

export default EmergencyMapScreen;
