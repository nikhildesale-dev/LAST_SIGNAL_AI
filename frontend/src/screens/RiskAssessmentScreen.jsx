import React, { useState } from 'react';
import { disasterRiskSummary } from '../data/mockData';
import { RiskBadge } from '../components/RiskBadge';
import { ActivityIcon, MapPinIcon } from '../components/Icons';

/**
 * RiskAssessmentScreen Component
 * Detailed deep-dive into simulated risk calculations:
 * - Risk category & score (78/100 High Risk)
 * - Contributing risk factors with visual percentage bars
 * - Recommended safety precautions
 * - Prominent DEMO DATA disclosure
 */
export function RiskAssessmentScreen() {
  const [selectedFactor, setSelectedFactor] = useState(disasterRiskSummary.contributingFactors[0].id);

  return (
    <div className="dashboard-content">
      {/* Compact Demo Notice Banner */}
      <div className="demo-notice-banner" role="alert">
        <span className="demo-notice-icon">⚠️</span>
        <div className="demo-notice-text">
          <strong>DEMO DATA:</strong> Risk scores, predictive factors, and telemetry weights are simulated. No live machine learning model or physical sensor network is deployed yet.
        </div>
        <span className="demo-notice-pill">Simulated Heuristics</span>
      </div>

      {/* Main Risk Overview Banner Card */}
      <div className="risk-hero-card">
        <div className="risk-hero-left">
          <div className="risk-hero-badge-row">
            <RiskBadge level={disasterRiskSummary.overallRisk} label="HIGH RISK LEVEL" size="lg" />
            <span className="demo-pill-badge">DEMO SIMULATION</span>
            <span className="risk-hero-zone">
              <MapPinIcon size={14} />
              {disasterRiskSummary.primaryZone}
            </span>
          </div>

          <h3 className="risk-hero-category">{disasterRiskSummary.threatCategory}</h3>
          <p className="risk-hero-description">
            Heuristic composite risk evaluation synthesized from high precipitation volume, steep hillside saturation, and urban runoff channel constraints.
          </p>

          <div className="risk-hero-stats-row">
            <div className="hero-stat-item">
              <span className="hero-stat-label">Model Confidence</span>
              <span className="hero-stat-value">{disasterRiskSummary.confidenceScore}</span>
            </div>
            <div className="hero-stat-divider" />
            <div className="hero-stat-item">
              <span className="hero-stat-label">Impact Radius</span>
              <span className="hero-stat-value">{disasterRiskSummary.impactRadiusKm} km</span>
            </div>
            <div className="hero-stat-divider" />
            <div className="hero-stat-item">
              <span className="hero-stat-label">Population Exposed</span>
              <span className="hero-stat-value">~{disasterRiskSummary.estimatedAffectedPeople.toLocaleString()}</span>
            </div>
            <div className="hero-stat-divider" />
            <div className="hero-stat-item">
              <span className="hero-stat-label">Trend Dynamic</span>
              <span className="hero-stat-value risk-text-high">{disasterRiskSummary.trend}</span>
            </div>
          </div>
        </div>

        {/* Large Score Visual Dial */}
        <div className="risk-hero-score-panel">
          <div className="score-dial-circle">
            <span className="score-dial-label">COMPOSITE RISK</span>
            <span className="score-dial-number">{disasterRiskSummary.score}</span>
            <span className="score-dial-max">/ 100</span>
            <span className="score-dial-badge">ELEVATED DANGER</span>
          </div>
          <p className="score-disclaimer">Simulated Score (Demo Data)</p>
        </div>
      </div>

      {/* Contributing Factors & Breakdown */}
      <div className="dashboard-two-column-grid">
        {/* Left Column: Contributing Risk Factors */}
        <section className="dashboard-section card-container" aria-labelledby="contributing-factors-title">
          <div className="section-header">
            <div>
              <div className="section-pre-title">TELEMETRY WEIGHT FACTORS (DEMO)</div>
              <h3 id="contributing-factors-title" className="section-title">Contributing Risk Factors</h3>
            </div>
            <span className="section-counter-badge">4 Heuristic Weights</span>
          </div>

          <p className="section-helper-text">
            The composite risk score is derived from weighted environmental indicators. Click any factor to inspect simulated trigger thresholds.
          </p>

          <div className="factors-list">
            {disasterRiskSummary.contributingFactors.map((factor) => {
              const isSelected = selectedFactor === factor.id;
              const severityColor =
                factor.severityPercent >= 75
                  ? 'var(--risk-high-solid)'
                  : factor.severityPercent >= 50
                  ? 'var(--risk-mod-solid)'
                  : 'var(--risk-low-solid)';

              return (
                <div
                  key={factor.id}
                  className={`factor-card ${isSelected ? 'selected' : ''}`}
                  onClick={() => setSelectedFactor(factor.id)}
                  tabIndex={0}
                  role="button"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      setSelectedFactor(factor.id);
                    }
                  }}
                >
                  <div className="factor-header">
                    <div>
                      <h4 className="factor-name">{factor.name}</h4>
                      <span className="factor-value-tag">{factor.value}</span>
                    </div>
                    <RiskBadge level={factor.impact} size="sm" />
                  </div>

                  {/* Severity Progress Bar */}
                  <div className="factor-bar-wrapper">
                    <div className="factor-bar-label-row">
                      <span className="factor-bar-label">Vulnerability Contribution</span>
                      <span className="factor-bar-percent" style={{ color: severityColor }}>
                        {factor.severityPercent}%
                      </span>
                    </div>
                    <div className="factor-progress-track">
                      <div
                        className="factor-progress-fill"
                        style={{
                          width: `${factor.severityPercent}%`,
                          backgroundColor: severityColor
                        }}
                      />
                    </div>
                  </div>

                  <p className="factor-desc">{factor.description}</p>
                </div>
              );
            })}
          </div>
        </section>

        {/* Right Column: Recommended Precautions & Safety Action Steps */}
        <section className="dashboard-section card-container" aria-labelledby="precautions-title">
          <div className="section-header">
            <div>
              <div className="section-pre-title">CIVIL PROTECTION GUIDELINES</div>
              <h3 id="precautions-title" className="section-title">Recommended Precautions</h3>
            </div>
            <span className="section-counter-badge">Priority Directives</span>
          </div>

          <p className="section-helper-text">
            Standard operating procedures automatically triggered for <strong>High Risk / Alert Level 3</strong> scenarios.
          </p>

          <div className="precautions-list">
            {disasterRiskSummary.recommendedPrecautions.map((prec, idx) => (
              <div key={prec.id} className="precaution-item">
                <div className="precaution-item-top">
                  <div className="precaution-number">0{idx + 1}</div>
                  <RiskBadge level={prec.riskLevel} label={`${prec.priority} Action`} size="sm" />
                </div>
                <p className="precaution-instruction">{prec.instruction}</p>
              </div>
            ))}
          </div>

          {/* AI Architecture Competition Note */}
          <div className="architecture-note-card">
            <div className="arch-note-title">
              <ActivityIcon size={16} />
              <span>Future Phase AI Modeling Roadmap</span>
            </div>
            <p className="arch-note-body">
              In upcoming development phases, LAST SIGNAL AI plans to deploy lightweight, edge-optimized Random Forest and Gradient Boosted regression models directly onto mobile and Raspberry Pi nodes to calculate localized threat levels without requiring internet access.
            </p>
          </div>
        </section>
      </div>
    </div>
  );
}

export default RiskAssessmentScreen;
