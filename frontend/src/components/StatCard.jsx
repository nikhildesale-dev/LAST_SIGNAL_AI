import React from 'react';

/**
 * Reusable StatCard Component
 * Provides a clean container with subtle elevation, header icon, badges, and metrics.
 */
export function StatCard({
  title,
  icon,
  badge,
  mainValue,
  subValue,
  statusColor, // optional border accent or dot
  children,
  footer,
  className = ''
}) {
  return (
    <div className={`stat-card ${className}`} style={statusColor ? { borderTop: `3px solid ${statusColor}` } : {}}>
      <div className="stat-card-header">
        <div className="stat-card-title-group">
          {icon && <div className="stat-card-icon">{icon}</div>}
          <h3 className="stat-card-title">{title}</h3>
        </div>
        {badge && <div className="stat-card-badge-wrap">{badge}</div>}
      </div>

      {(mainValue || subValue) && (
        <div className="stat-card-values">
          {mainValue && <div className="stat-card-main-value">{mainValue}</div>}
          {subValue && <div className="stat-card-sub-value">{subValue}</div>}
        </div>
      )}

      {children && <div className="stat-card-body">{children}</div>}

      {footer && <div className="stat-card-footer">{footer}</div>}
    </div>
  );
}

export default StatCard;
