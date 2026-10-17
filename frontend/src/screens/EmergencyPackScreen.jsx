import React, { useState } from 'react';
import { BeaconIcon } from '../components/Icons';

/**
 * EmergencyPackScreen Component
 * Polished placeholder and interactive preview for Phase 3 Emergency Pack:
 * - Offline Survival Vault & Checklist
 * - Interactive Go-Bag checklist items
 * - Offline emergency protocols
 * - Clear roadmap banner stating storage/sync is planned for Phase 3
 */
export function EmergencyPackScreen() {
  const [checkedItems, setCheckedItems] = useState({
    water: true,
    radio: true,
    meds: false,
    powerbank: true,
    documents: false,
    firstaid: false
  });

  const [sosSent, setSosSent] = useState(false);

  const toggleItem = (key) => {
    setCheckedItems((prev) => ({
      ...prev,
      [key]: !prev[key]
    }));
  };

  const handleTriggerDemoSos = () => {
    setSosSent(true);
    setTimeout(() => {
      setSosSent(false);
    }, 4000);
  };

  const totalCount = Object.keys(checkedItems).length;
  const completedCount = Object.values(checkedItems).filter(Boolean).length;
  const readinessPercent = Math.round((completedCount / totalCount) * 100);

  return (
    <div className="dashboard-content">
      {/* Roadmap Milestone Banner */}
      <div className="roadmap-hero-banner">
        <div className="roadmap-badge-row">
          <span className="roadmap-phase-pill">PHASE 3 DEVELOPMENT PREVIEW</span>
          <span className="roadmap-demo-pill">DEMO UI PLACEHOLDER</span>
        </div>
        <h3 className="roadmap-title">Offline Emergency Pack & Survival Vault</h3>
        <p className="roadmap-subtitle">
          In Phase 3, the Emergency Pack will provide encrypted offline document storage, automated local mesh beacon broadcasting, and verifiable offline triage guides. Full offline IndexedDB/SQLite synchronization will be implemented in subsequent phases.
        </p>
      </div>

      <div className="dashboard-two-column-grid">
        {/* Left Column: Interactive Offline Go-Bag Checklist */}
        <section className="dashboard-section card-container" aria-labelledby="pack-checklist-title">
          <div className="section-header">
            <div>
              <div className="section-pre-title">PERSONAL SURVIVAL READINESS</div>
              <h3 id="pack-checklist-title" className="section-title">Emergency Go-Bag Checklist</h3>
            </div>
            <span className="section-counter-badge">{completedCount} of {totalCount} Ready</span>
          </div>

          {/* Progress Bar */}
          <div className="readiness-bar-box">
            <div className="readiness-header">
              <span>Preparedness Score</span>
              <strong className={readinessPercent > 60 ? 'risk-text-low' : 'risk-text-mod'}>
                {readinessPercent}% Ready
              </strong>
            </div>
            <div className="factor-progress-track">
              <div
                className="factor-progress-fill"
                style={{
                  width: `${readinessPercent}%`,
                  backgroundColor: readinessPercent > 60 ? 'var(--risk-low-solid)' : 'var(--risk-mod-solid)'
                }}
              />
            </div>
            <div className="checklist-actions-bar">
              <button
                type="button"
                className="checklist-action-btn"
                onClick={() => {
                  const allChecked = {};
                  Object.keys(checkedItems).forEach((k) => { allChecked[k] = true; });
                  setCheckedItems(allChecked);
                }}
              >
                ✓ Select All
              </button>
              <button
                type="button"
                className="checklist-action-btn"
                onClick={() => {
                  const allUnchecked = {};
                  Object.keys(checkedItems).forEach((k) => { allUnchecked[k] = false; });
                  setCheckedItems(allUnchecked);
                }}
              >
                ✕ Clear All
              </button>
            </div>
          </div>

          <div className="checklist-items-group">
            {[
              {
                id: 'water',
                title: '3 Liters Potable Drinking Water',
                desc: 'Clean water in sealed bottles + water purification tablets.'
              },
              {
                id: 'radio',
                title: 'Emergency Crank / Battery Radio & Whistle',
                desc: 'Tuned to local civil defense frequency (UHF Ch 1).'
              },
              {
                id: 'meds',
                title: 'Critical Prescription Medications (7-Day Supply)',
                desc: 'Stored in waterproof pouch with written dosage instructions.'
              },
              {
                id: 'powerbank',
                title: 'Charged High-Capacity Power Bank & Cables',
                desc: 'For keeping Last Signal AI mesh node active.'
              },
              {
                id: 'documents',
                title: 'Waterproof Physical & Digital ID Copies',
                desc: 'Government IDs, insurance, medical allergy records.'
              },
              {
                id: 'firstaid',
                title: 'Sterile First-Aid Kit & Trauma Bandages',
                desc: 'Gauze, antiseptic swabs, burn dressing, medical shears.'
              }
            ].map((item) => (
              <label key={item.id} className="checklist-item-row">
                <input
                  type="checkbox"
                  className="checklist-checkbox"
                  checked={!!checkedItems[item.id]}
                  onChange={() => toggleItem(item.id)}
                />
                <div className="checklist-item-content">
                  <span className={`checklist-item-title ${checkedItems[item.id] ? 'checked-strike' : ''}`}>
                    {item.title}
                  </span>
                  <p className="checklist-item-desc">{item.desc}</p>
                </div>
              </label>
            ))}
          </div>
        </section>

        {/* Right Column: SOS Beacon Demo & Offline Protocols */}
        <div className="emergency-pack-right-column">
          {/* Emergency Mesh Beacon Simulator Card */}
          <div className="card-container emergency-beacon-card">
            <div className="section-pre-title">OFFLINE P2P DISTRESS BEACON</div>
            <h3 className="section-title">Emergency SOS Mesh Beacon</h3>
            <p className="section-helper-text">
              In an emergency without cellular service, clicking this triggers an ultra-low-power radio beacon to nearby Last Signal mesh relays.
            </p>

            {sosSent ? (
              <div className="sos-alert-sent" role="alert">
                <BeaconIcon size={20} className="pulse-icon" />
                <div>
                  <strong>DEMO SOS PACKET BROADCASTED:</strong>
                  <p>Synthetic distress beacon routed across 14 simulated local mesh peers.</p>
                </div>
              </div>
            ) : (
              <button
                type="button"
                className="sos-broadcast-btn"
                onClick={handleTriggerDemoSos}
              >
                <BeaconIcon size={20} />
                <span>Simulate Offline SOS Broadcast</span>
              </button>
            )}
            <p className="beacon-disclaimer-note">
              Demo Simulation only. Does not call 911 or emergency services.
            </p>
          </div>

          {/* Quick Offline Survival Protocol Card */}
          <div className="card-container survival-protocols-card">
            <div className="section-pre-title">OFFLINE SURVIVAL PROTOCOLS</div>
            <h3 className="section-title">Flash Flood Action Rules</h3>
            <div className="protocol-list">
              <div className="protocol-item">
                <span className="protocol-badge high">Rule 1</span>
                <div>
                  <strong>Turn Around, Don't Drown:</strong>
                  <p>Never walk or drive into moving water. 15cm of rapid water can knock an adult down; 30cm can float a vehicle.</p>
                </div>
              </div>
              <div className="protocol-item">
                <span className="protocol-badge mod">Rule 2</span>
                <div>
                  <strong>Seek Vertical Evacuation:</strong>
                  <p>If trapped in a structure, proceed to the highest floor. Do not climb into closed attics without rooftop egress.</p>
                </div>
              </div>
              <div className="protocol-item">
                <span className="protocol-badge low">Rule 3</span>
                <div>
                  <strong>Conserve Mobile Battery:</strong>
                  <p>Dim display brightness, disable background sync, and rely on Last Signal AI peer relays.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default EmergencyPackScreen;
