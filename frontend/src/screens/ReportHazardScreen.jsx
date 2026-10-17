import React, { useState } from 'react';
import { CheckCircleIcon, MapPinIcon, MeshRadioIcon } from '../components/Icons';
import { RiskBadge } from '../components/RiskBadge';

/**
 * ReportHazardScreen Component
 * Interactive form for citizen hazard reporting:
 * - Hazard category selection
 * - Severity level picker (High/Moderate/Low)
 * - Location input with demo GPS autofill
 * - Offline P2P mesh broadcast simulation
 * - Submission confirmation state with clear DEMO DATA label
 */
export function ReportHazardScreen() {
  const [hazardType, setHazardType] = useState('Flash Flood Surge');
  const [severity, setSeverity] = useState('High');
  const [location, setLocation] = useState('Sector 4 Underpass (Low Ground)');
  const [description, setDescription] = useState('');
  const [errors, setErrors] = useState({});
  const [submittedReport, setSubmittedReport] = useState(null);

  const handleSubmit = (e) => {
    e.preventDefault();

    const newErrors = {};
    if (!location.trim()) {
      newErrors.location = 'Incident location is required. Enter coordinates or click Auto-Fill Demo GPS.';
    }
    if (!description.trim()) {
      newErrors.description = 'Please provide details or observations about the hazard.';
    } else if (description.trim().length < 5) {
      newErrors.description = 'Please provide a more descriptive observation (at least 5 characters).';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setErrors({});
    const newReport = {
      id: `HZ-${Math.floor(100 + Math.random() * 900)}`,
      type: hazardType,
      severity,
      location: location.trim(),
      description: description.trim(),
      timestamp: 'Just now',
      syncStatus: 'Queued to Local Mesh Relay (14 Peers)'
    };

    setSubmittedReport(newReport);
  };

  const handleAutofillDemoGPS = () => {
    setLocation('Latitude: 28.5355° N, Longitude: 77.3910° E (Ridge Spine)');
    if (errors.location) {
      setErrors((prev) => ({ ...prev, location: null }));
    }
  };

  return (
    <div className="dashboard-content">
      {/* Roadmap Milestone Banner */}
      <div className="roadmap-hero-banner">
        <div className="roadmap-badge-row">
          <span className="roadmap-phase-pill">PHASE 2 PROTOCOL PREVIEW</span>
          <span className="roadmap-demo-pill">DEMO INTERFACE</span>
        </div>
        <h3 className="roadmap-title">Citizen Hazard & Incident Reporting</h3>
        <p className="roadmap-subtitle">
          In Phase 2, hazard submissions will be cryptographically signed and broadcast across local Wi-Fi Direct and Bluetooth mesh radios using an epidemic gossip protocol. Form submissions below operate in interactive demo mode.
        </p>
      </div>

      <div className="dashboard-two-column-grid">
        {/* Left Column: Report Form */}
        <section className="dashboard-section card-container" aria-labelledby="report-hazard-title">
          <div className="section-header">
            <div>
              <div className="section-pre-title">COMMUNITY SAFETY TELEMETRY</div>
              <h3 id="report-hazard-title" className="section-title">Submit Local Hazard Incident</h3>
            </div>
            <span className="section-counter-badge">Offline Queue Ready</span>
          </div>

          {submittedReport ? (
            <div className="report-success-card" role="alert">
              <div className="success-icon-wrap">
                <CheckCircleIcon size={32} />
              </div>
              <h4 className="success-title">DEMO REPORT BROADCASTED</h4>
              <p className="success-desc">
                Incident <strong>{submittedReport.id}</strong> has been successfully simulated. In a live deployment, this packet is stored in local IndexedDB and relayed to all connected mesh peers.
              </p>

              <div className="submitted-summary-box">
                <div className="summary-row">
                  <span>Type:</span>
                  <strong>{submittedReport.type}</strong>
                </div>
                <div className="summary-row">
                  <span>Severity:</span>
                  <RiskBadge level={submittedReport.severity} size="sm" />
                </div>
                <div className="summary-row">
                  <span>Location:</span>
                  <span>{submittedReport.location}</span>
                </div>
                <div className="summary-row">
                  <span>Description:</span>
                  <span>{submittedReport.description}</span>
                </div>
                <div className="summary-row">
                  <span>Broadcast:</span>
                  <span className="text-teal">{submittedReport.syncStatus}</span>
                </div>
              </div>

              <button
                type="button"
                className="outline-action-btn"
                onClick={() => {
                  setSubmittedReport(null);
                  setDescription('');
                  setErrors({});
                }}
              >
                + Submit Another Demo Hazard Report
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} noValidate className="hazard-form">
              {/* Hazard Category */}
              <div className="form-group">
                <label className="form-label" htmlFor="hazard-type-select">
                  Hazard Classification:
                </label>
                <select
                  id="hazard-type-select"
                  className="form-select"
                  value={hazardType}
                  onChange={(e) => setHazardType(e.target.value)}
                >
                  <option value="Flash Flood Surge">Flash Flood Surge (Water accumulation &gt; 0.5m)</option>
                  <option value="Hillside Mudslide">Hillside Mudslide / Landslide</option>
                  <option value="Fallen High-Voltage Line">Fallen High-Voltage Line / Electrical Danger</option>
                  <option value="Structural Collapse">Bridge / Building Structural Damage</option>
                  <option value="Road Inaccessible">Road Blocked by Debris or Trees</option>
                  <option value="Other Hazard">Other Threat to Public Safety</option>
                </select>
              </div>

              {/* Severity Level Picker */}
              <div className="form-group">
                <label className="form-label">
                  Estimated Severity Level:
                </label>
                <div className="severity-button-group">
                  {[
                    { level: 'High', desc: 'Life-threatening / Impassable' },
                    { level: 'Moderate', desc: 'Caution / Restrictive' },
                    { level: 'Low', desc: 'Minor delay / Informational' }
                  ].map((item) => (
                    <button
                      key={item.level}
                      type="button"
                      className={`severity-choice-btn severity-${item.level.toLowerCase()} ${severity === item.level ? 'active' : ''}`}
                      onClick={() => setSeverity(item.level)}
                    >
                      <RiskBadge level={item.level} size="sm" />
                      <span className="severity-choice-desc">{item.desc}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Location Input with Demo GPS Button */}
              <div className="form-group">
                <div className="label-with-action">
                  <label className="form-label" htmlFor="location-input">
                    Incident Location / Coordinates: <span className="required-star">*</span>
                  </label>
                  <button
                    type="button"
                    className="demo-gps-link"
                    onClick={handleAutofillDemoGPS}
                  >
                    <MapPinIcon size={12} />
                    Auto-Fill Demo GPS
                  </button>
                </div>
                <input
                  id="location-input"
                  type="text"
                  className={`form-input ${errors.location ? 'input-error' : ''}`}
                  value={location}
                  onChange={(e) => {
                    setLocation(e.target.value);
                    if (errors.location) {
                      setErrors((prev) => ({ ...prev, location: null }));
                    }
                  }}
                  placeholder="e.g. Underpass 4, Highway Sector 9"
                  aria-invalid={!!errors.location}
                  aria-describedby={errors.location ? 'location-error' : undefined}
                />
                {errors.location && (
                  <p id="location-error" className="field-error-msg" role="alert">
                    <span>⚠️</span> {errors.location}
                  </p>
                )}
              </div>

              {/* Description */}
              <div className="form-group">
                <label className="form-label" htmlFor="description-input">
                  Details & Observations: <span className="required-star">*</span>
                </label>
                <textarea
                  id="description-input"
                  className={`form-textarea ${errors.description ? 'input-error' : ''}`}
                  rows={3}
                  value={description}
                  onChange={(e) => {
                    setDescription(e.target.value);
                    if (errors.description) {
                      setErrors((prev) => ({ ...prev, description: null }));
                    }
                  }}
                  placeholder="Describe water depth, impassable lanes, or stranded individuals..."
                  aria-invalid={!!errors.description}
                  aria-describedby={errors.description ? 'description-error' : undefined}
                />
                {errors.description && (
                  <p id="description-error" className="field-error-msg" role="alert">
                    <span>⚠️</span> {errors.description}
                  </p>
                )}
              </div>

              {/* Submit Button */}
              <button type="submit" className="primary-submit-btn">
                <MeshRadioIcon size={18} />
                <span>Queue & Broadcast to Mesh (Demo)</span>
              </button>

              <p className="form-disclaimer">
                All submitted reports are stored in local browser state as DEMO DATA for system demonstration.
              </p>
            </form>
          )}
        </section>

        {/* Right Column: Local Mesh Dispatch Architecture */}
        <section className="dashboard-section card-container" aria-labelledby="dispatch-protocol-title">
          <div className="section-header">
            <div>
              <div className="section-pre-title">DECENTRALIZED ARCHITECTURE</div>
              <h3 id="dispatch-protocol-title" className="section-title">How P2P Verification Works</h3>
            </div>
          </div>

          <div className="verification-steps-list">
            <div className="step-item">
              <div className="step-number">1</div>
              <div className="step-content">
                <strong>Offline Local Storage</strong>
                <p>When the user hits submit without internet, the incident report is serialized into an encrypted SQLite / IndexedDB packet.</p>
              </div>
            </div>

            <div className="step-item">
              <div className="step-number">2</div>
              <div className="step-content">
                <strong>Multi-Hop Mesh Gossip Protocol</strong>
                <p>The device periodically broadcasts packet headers to neighboring smartphones within Wi-Fi Direct and BLE range.</p>
              </div>
            </div>

            <div className="step-item">
              <div className="step-number">3</div>
              <div className="step-content">
                <strong>Consensus & Peer Verification</strong>
                <p>Once two or more nearby independent devices corroborate the hazard, its status upgrades from "Reported" to "Peer Verified".</p>
              </div>
            </div>

            <div className="step-item">
              <div className="step-number">4</div>
              <div className="step-content">
                <strong>Dynamic Rerouting Integration</strong>
                <p>Verified hazard polygons immediately flag intersecting routes as impassable on the offline navigation map.</p>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}

export default ReportHazardScreen;
