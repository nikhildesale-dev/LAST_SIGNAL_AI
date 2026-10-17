import React from 'react';

/**
 * Reusable Risk Badge Component
 * Displays High (Red), Moderate (Amber), and Low (Green) risk indicators.
 */
export function RiskBadge({ level = 'Low', label, size = 'md', showDot = true }) {
  const normalizedLevel = (level || '').toLowerCase();

  let badgeClass = 'risk-badge-low';
  let dotColor = 'var(--risk-low-solid)';
  let defaultLabel = 'Low Risk';

  if (normalizedLevel.includes('high') || normalizedLevel.includes('critical')) {
    badgeClass = 'risk-badge-high';
    dotColor = 'var(--risk-high-solid)';
    defaultLabel = 'High Risk';
  } else if (normalizedLevel.includes('mod') || normalizedLevel.includes('med') || normalizedLevel.includes('amber')) {
    badgeClass = 'risk-badge-mod';
    dotColor = 'var(--risk-mod-solid)';
    defaultLabel = 'Moderate Risk';
  }

  return (
    <span className={`risk-badge ${badgeClass} risk-badge-${size}`}>
      {showDot && (
        <span
          className="risk-badge-dot"
          style={{ backgroundColor: dotColor }}
          aria-hidden="true"
        />
      )}
      <span className="risk-badge-text">{label || defaultLabel}</span>
    </span>
  );
}

export default RiskBadge;
