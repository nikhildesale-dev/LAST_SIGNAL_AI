import React, { useState } from 'react';
import {
  disasterRiskSummary,
  weatherSummary,
  connectivityStatus,
  prioritizedRecommendations,
  recentHazardReports,
  nearbyEmergencyResources
} from '../data/mockData';
import { StatCard } from '../components/StatCard';
import { RiskBadge } from '../components/RiskBadge';
import {
  RiskIcon,
  CloudRainIcon,
  MeshRadioIcon,
  WifiOffIcon,
  MapPinIcon,
  CheckCircleIcon,
  AlertCircleIcon,
  WindIcon,
  ThermometerIcon,
  ClockIcon,
  BeaconIcon
} from '../components/Icons';

/**
 * OverviewScreen Component
 * Central emergency operations dashboard containing:
 * 1. Global DEMO DATA disclaimer banner
 * 2. Disaster risk summary card
 * 3. Weather summary card
 * 4. P2P Connectivity status card
 * 5. Prioritized emergency recommendations
 * 6. Recent hazard reports with severity filtering
 * 7. Nearby emergency resources
 */
export function OverviewScreen({ onNavigateToScreen }) {
  const [hazardFilter, setHazardFilter] = useState('All');
  const [resourceFilter, setResourceFilter] = useState('All');

  // Filter hazards
  const filteredHazards = recentHazardReports.filter((report) => {
    if (hazardFilter === 'All') return true;
    return report.severity.toLowerCase() === hazardFilter.toLowerCase();
  });

  // Filter resources
  const filteredResources = nearbyEmergencyResources.filter((res) => {
    if (resourceFilter === 'All') return true;
    if (resourceFilter === 'Shelter') return res.type.includes('Shelter');
    if (resourceFilter === 'Medical') return res.type.includes('Medical');
    if (resourceFilter === 'Logistics') return res.type.includes('Logistics') || res.type.includes('Rescue');
    return true;
  });

  return (
    <div className="dashboard-content">
      {/* Compact Demo Notice Banner */}
      <div className="demo-notice-banner" role="alert">
        <span className="demo-notice-icon">⚠️</span>
        <div className="demo-notice-text">
          <strong>DEMO DATA:</strong> Risk scores, weather readings, and hazard alerts are simulated. No live machine learning model or physical sensor network is deployed yet.
        </div>
        <span className="demo-notice-pill">Simulated Environment</span>
      </div>

      {/* 2. Top Summary Cards Row */}
      <div className="summary-cards-grid">
        {/* Card 1: Disaster Risk Summary */}
        <StatCard
          title="Disaster Risk Summary"
          icon={<RiskIcon size={20} />}
          badge={<RiskBadge level={disasterRiskSummary.overallRisk} label="HIGH RISK (DEMO)" size="md" />}
          statusColor="var(--risk-high-solid)"
          mainValue={
            <div className="risk-score-display">
              <span className="risk-score-number">{disasterRiskSummary.score}</span>
              <span className="risk-score-scale">/100</span>
              <span className="risk-score-status">CRITICAL THREAT</span>
            </div>
          }
          subValue={disasterRiskSummary.threatCategory}
          footer={
            <div className="stat-card-action-footer">
              <span className="footer-meta-text">Confidence: {disasterRiskSummary.confidenceScore}</span>
              <button
                type="button"
                className="card-text-button"
                onClick={() => onNavigateToScreen('risk-assessment')}
              >
                Deep-Dive Risk Analysis →
              </button>
            </div>
          }
        >
          <div className="metric-row-list">
            <div className="metric-row-item">
              <span className="metric-row-label">Impact Zone:</span>
              <span className="metric-row-value">{disasterRiskSummary.primaryZone}</span>
            </div>
            <div className="metric-row-item">
              <span className="metric-row-label">Estimated Exposure:</span>
              <span className="metric-row-value highlight-number">~{disasterRiskSummary.estimatedAffectedPeople.toLocaleString()} residents</span>
            </div>
            <div className="metric-row-item">
              <span className="metric-row-label">Trend:</span>
              <span className="metric-row-value risk-text-high">{disasterRiskSummary.trend}</span>
            </div>
          </div>
        </StatCard>

        {/* Card 2: Weather Summary */}
        <StatCard
          title="Weather Conditions"
          icon={<CloudRainIcon size={20} />}
          badge={<span className="weather-badge severe">Torrential Storm</span>}
          statusColor="var(--navy-surface)"
          mainValue={
            <div className="weather-main-display">
              <span className="weather-temp">{weatherSummary.temperature}</span>
              <span className="weather-temp-sub">({weatherSummary.tempFahrenheit})</span>
            </div>
          }
          subValue={weatherSummary.condition}
          footer={
            <div className="stat-card-simple-footer">
              <AlertCircleIcon size={14} className="warning-icon-sm" />
              <span>{weatherSummary.stormAdvisory}</span>
            </div>
          }
        >
          <div className="weather-metrics-grid">
            <div className="weather-metric-cell">
              <div className="cell-top">
                <CloudRainIcon size={15} />
                <span>Precipitation</span>
              </div>
              <span className="cell-value">{weatherSummary.rainfallRate}</span>
              <span className="cell-sub">{weatherSummary.rainfallLevel}</span>
            </div>

            <div className="weather-metric-cell">
              <div className="cell-top">
                <WindIcon size={15} />
                <span>Wind Speed</span>
              </div>
              <span className="cell-value">{weatherSummary.windSpeed}</span>
              <span className="cell-sub">Gusts {weatherSummary.windGusts}</span>
            </div>

            <div className="weather-metric-cell">
              <div className="cell-top">
                <ThermometerIcon size={15} />
                <span>Barometer</span>
              </div>
              <span className="cell-value">{weatherSummary.barometricPressure}</span>
              <span className="cell-sub">Falling Fast</span>
            </div>

            <div className="weather-metric-cell">
              <div className="cell-top">
                <ClockIcon size={15} />
                <span>Humidity</span>
              </div>
              <span className="cell-value">{weatherSummary.humidity}</span>
              <span className="cell-sub">Vis {weatherSummary.visibility}</span>
            </div>
          </div>
        </StatCard>

        {/* Card 3: Connectivity Status */}
        <StatCard
          title="Connectivity Status"
          icon={<MeshRadioIcon size={20} />}
          badge={<span className="mesh-connected-pill">P2P MESH ACTIVE</span>}
          statusColor="var(--teal-accent)"
          mainValue={
            <div className="connectivity-main-display">
              <span className="nodes-count">{connectivityStatus.activeLocalNodes}</span>
              <span className="nodes-label">Active Mesh Nodes</span>
            </div>
          }
          subValue="Cell Grid Severed • Local P2P Relay Operational"
          footer={
            <div className="stat-card-simple-footer">
              <BeaconIcon size={14} className="mesh-icon-sm" />
              <span>{connectivityStatus.lastMeshBeacon}</span>
            </div>
          }
        >
          <div className="connectivity-details-list">
            <div className="connectivity-item warning">
              <div className="conn-icon">
                <WifiOffIcon size={16} />
              </div>
              <div className="conn-text">
                <div className="conn-title">Cellular Infrastructure</div>
                <div className="conn-desc">{connectivityStatus.cellularGrid}</div>
              </div>
            </div>

            <div className="connectivity-item success">
              <div className="conn-icon">
                <MeshRadioIcon size={16} />
              </div>
              <div className="conn-text">
                <div className="conn-title">Last Signal Mesh Network</div>
                <div className="conn-desc">{connectivityStatus.meshRelayRangeKm} km relay radius • {connectivityStatus.packetsTransferred} routed</div>
              </div>
            </div>
          </div>
        </StatCard>
      </div>

      {/* 3. Prioritized Emergency Recommendations Section */}
      <section className="dashboard-section" aria-labelledby="recommendations-heading">
        <div className="section-header">
          <div>
            <div className="section-pre-title">TACTICAL ACTION PLAN (DEMO SIMULATION)</div>
            <h3 id="recommendations-heading" className="section-title">Prioritized Emergency Recommendations</h3>
          </div>
          <span className="section-counter-badge">{prioritizedRecommendations.length} Actions Required</span>
        </div>

        <div className="recommendations-grid">
          {prioritizedRecommendations.map((rec, index) => (
            <div
              key={rec.id}
              className={`recommendation-card priority-border-${rec.priority.toLowerCase()}`}
            >
              <div className="rec-top-bar">
                <div className="rec-rank-pill">#{index + 1}</div>
                <RiskBadge level={rec.priority} label={`${rec.priority} Priority`} size="sm" />
                <span className="rec-category-tag">{rec.category}</span>
                <span className="rec-timeframe">
                  <ClockIcon size={13} />
                  {rec.timeframe}
                </span>
              </div>

              <h4 className="rec-action-title">{rec.action}</h4>
              <p className="rec-rationale">{rec.rationale}</p>

              <div className="rec-target-row">
                <span className="rec-target-label">Target Area / Group:</span>
                <span className="rec-target-text">{rec.targetAudience}</span>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 4. Split Grid: Hazard Reports & Nearby Emergency Resources */}
      <div className="dashboard-two-column-grid">
        {/* Left Column: Recent Hazard Reports */}
        <section className="dashboard-section card-container" aria-labelledby="hazards-heading">
          <div className="section-header">
            <div>
              <div className="section-pre-title">COMMUNITY MESH TELEMETRY</div>
              <h3 id="hazards-heading" className="section-title">Recent Hazard Reports</h3>
            </div>
            
            {/* Filter buttons */}
            <div className="pill-filter-group" role="tablist" aria-label="Hazard Severity Filters">
              {['All', 'High', 'Moderate', 'Low'].map((level) => (
                <button
                  key={level}
                  type="button"
                  className={`pill-filter-btn ${hazardFilter === level ? 'active' : ''}`}
                  onClick={() => setHazardFilter(level)}
                >
                  {level}
                </button>
              ))}
            </div>
          </div>

          <div className="hazards-list">
            {filteredHazards.length === 0 ? (
              <div className="empty-state">No hazard reports found matching "{hazardFilter}".</div>
            ) : (
              filteredHazards.map((hazard) => (
                <article key={hazard.id} className="hazard-list-item">
                  <div className="hazard-item-header">
                    <div className="hazard-title-wrap">
                      <span className="hazard-id">{hazard.id}</span>
                      <h4 className="hazard-name">{hazard.type}</h4>
                    </div>
                    <RiskBadge level={hazard.severity} size="sm" />
                  </div>

                  <p className="hazard-desc">{hazard.description}</p>

                  <div className="hazard-meta-row">
                    <span className="hazard-meta-item">
                      <MapPinIcon size={14} />
                      {hazard.location} ({hazard.distance})
                    </span>
                    <span className="hazard-meta-item">
                      <ClockIcon size={14} />
                      {hazard.timeAgo}
                    </span>
                    <span className="hazard-verification-tag">
                      <CheckCircleIcon size={13} />
                      {hazard.verification}
                    </span>
                  </div>
                </article>
              ))
            )}
          </div>

          <div className="section-bottom-action">
            <button
              type="button"
              className="outline-action-btn"
              onClick={() => onNavigateToScreen('report-hazard')}
            >
              + Submit New Hazard Incident Report
            </button>
          </div>
        </section>

        {/* Right Column: Nearby Emergency Resources */}
        <section className="dashboard-section card-container" aria-labelledby="resources-heading">
          <div className="section-header">
            <div>
              <div className="section-pre-title">ACTIVE LIFE SUPPORT INFRASTRUCTURE</div>
              <h3 id="resources-heading" className="section-title">Nearby Emergency Resources</h3>
            </div>

            {/* Filter buttons */}
            <div className="pill-filter-group" role="tablist" aria-label="Resource Type Filters">
              {['All', 'Shelter', 'Medical', 'Logistics'].map((cat) => (
                <button
                  key={cat}
                  type="button"
                  className={`pill-filter-btn ${resourceFilter === cat ? 'active' : ''}`}
                  onClick={() => setResourceFilter(cat)}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          <div className="resources-list">
            {filteredResources.length === 0 ? (
              <div className="empty-state">No resources found matching "{resourceFilter}".</div>
            ) : (
              filteredResources.map((res) => (
                <article key={res.id} className="resource-card-item">
                  <div className="resource-header">
                    <div>
                      <h4 className="resource-name">{res.name}</h4>
                      <span className="resource-type-label">{res.type}</span>
                    </div>
                    <span className="resource-distance-pill">
                      <MapPinIcon size={13} />
                      {res.distance}
                    </span>
                  </div>

                  <div className="resource-details-grid">
                    <div className="resource-spec">
                      <span className="spec-label">Capacity:</span>
                      <span className="spec-val">{res.capacity}</span>
                    </div>
                    <div className="resource-spec">
                      <span className="spec-label">Power Status:</span>
                      <span className="spec-val">{res.powerStatus}</span>
                    </div>
                    <div className="resource-spec">
                      <span className="spec-label">Medical Staff:</span>
                      <span className="spec-val">{res.medicalSupport}</span>
                    </div>
                    <div className="resource-spec">
                      <span className="spec-label">Radio Contact:</span>
                      <span className="spec-val code-val">{res.contactFrequency}</span>
                    </div>
                  </div>

                  <div className="resource-footer">
                    <span className="resource-mesh-node">
                      <MeshRadioIcon size={13} />
                      {res.meshNodeId}
                    </span>
                    <button
                      type="button"
                      className="resource-route-btn"
                      onClick={() => onNavigateToScreen('emergency-map')}
                    >
                      Route to Shelter →
                    </button>
                  </div>
                </article>
              ))
            )}
          </div>

          <div className="section-bottom-action">
            <button
              type="button"
              className="outline-action-btn"
              onClick={() => onNavigateToScreen('emergency-map')}
            >
              Open Offline Safe Navigation Map →
            </button>
          </div>
        </section>
      </div>
    </div>
  );
}

export default OverviewScreen;
