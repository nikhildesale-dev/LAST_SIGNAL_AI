/**
 * LAST SIGNAL AI - Demonstration Dataset
 * 
 * NOTICE:
 * All values and metrics contained in this file are simulated DEMO DATA
 * created solely for the college innovation competition prototype.
 * No trained AI model or live sensor feeds are connected in Phase 1.
 */

export const DEMO_DISCLAIMER = {
  label: "DEMO DATA",
  message: "Simulated emergency scenario for competition demonstration. No live AI model or real-world sensors connected.",
  lastSync: "Just now (Offline Mesh Mode)"
};

export const disasterRiskSummary = {
  overallRisk: "High", // "High" | "Moderate" | "Low"
  score: 78, // out of 100
  threatCategory: "Flash Flood & Mudslide Hazard",
  statusLabel: "CRITICAL ALERT",
  impactRadiusKm: 5.2,
  estimatedAffectedPeople: 4800,
  confidenceScore: "84% (Simulated)",
  trend: "Escalating (+12% in past hour)",
  primaryZone: "Riverside Sector 4 & East Hill Basin",
  contributingFactors: [
    {
      id: "cf-1",
      name: "Precipitation Rate",
      value: "42 mm/hr",
      impact: "High",
      severityPercent: 88,
      description: "Sustained torrential downpour exceeding 10-year local threshold."
    },
    {
      id: "cf-2",
      name: "Soil Moisture Saturation",
      value: "92% Saturated",
      impact: "High",
      severityPercent: 84,
      description: "Severe ground waterlogging drastically increasing mudslide probability."
    },
    {
      id: "cf-3",
      name: "Storm Drainage Congestion",
      value: "76% Capacity",
      impact: "Moderate",
      severityPercent: 68,
      description: "Urban runoff drainage channels blocked with debris near Culvert 9."
    },
    {
      id: "cf-4",
      name: "Topographical Elevation Slope",
      value: "28° Gradient",
      impact: "Moderate",
      severityPercent: 58,
      description: "Unstable hillside settlements exposed to surface runoff cascading."
    }
  ],
  recommendedPrecautions: [
    {
      id: "prec-1",
      priority: "Immediate",
      riskLevel: "High",
      instruction: "Evacuate low-lying riverbank settlements (Zones A & B) toward Apex High-Ground Shelter."
    },
    {
      id: "prec-2",
      priority: "Urgent",
      riskLevel: "High",
      instruction: "Avoid Highway Sector 9 and Underpass 4 due to 1.1m flash flood water accumulation."
    },
    {
      id: "prec-3",
      priority: "Important",
      riskLevel: "Moderate",
      instruction: "Switch personal mobile devices to LAST SIGNAL Offline P2P Mesh Mode to conserve battery."
    },
    {
      id: "prec-4",
      priority: "Advisory",
      riskLevel: "Low",
      instruction: "Store at least 3 liters of potable drinking water per person and prepare grab-and-go emergency bags."
    }
  ]
};

export const weatherSummary = {
  condition: "Severe Torrential Storm",
  temperature: "22°C",
  tempFahrenheit: "71.6°F",
  rainfallRate: "42 mm/h",
  rainfallLevel: "Severe",
  windSpeed: "54 km/h",
  windGusts: "72 km/h",
  windDirection: "ENE",
  barometricPressure: "994 hPa",
  pressureTrend: "Dropping rapidly (-3 hPa/hr)",
  humidity: "94%",
  visibility: "1.2 km",
  stormAdvisory: "Active Tropical Gale Warning issued for the next 6 hours."
};

export const connectivityStatus = {
  cellularGrid: "Offline / Infrastructure Degraded",
  cellularStatus: "Offline",
  internetAccess: "Unavailable (Backhaul Severed)",
  meshNetwork: "LAST SIGNAL P2P Mesh Active",
  meshStatus: "Connected",
  activeLocalNodes: 14,
  meshRelayRangeKm: 2.8,
  packetsTransferred: "1,248 packets",
  batteryOptimization: "Enabled (Ultra-Low Power Beacon)",
  lastMeshBeacon: "14 seconds ago via Node #08-Echo",
  syncStorage: "Local Device Storage (Ready Offline)"
};

export const prioritizedRecommendations = [
  {
    id: "rec-1",
    priority: "High",
    action: "Evacuate Lower Valley Basin (Sector 4)",
    timeframe: "Next 30 - 45 mins",
    rationale: "Flood wave predicted to crest above levee boundary by 20:30.",
    category: "Life Safety",
    targetAudience: "Residents in Sector 4 & East Hill Basin"
  },
  {
    id: "rec-2",
    priority: "High",
    action: "Reroute Evacuees Away From Underpass 4 & River Bridge",
    timeframe: "Immediate",
    rationale: "Sensor reports indicate water depth 1.1m and strong sub-surface currents.",
    category: "Traffic / Transit",
    targetAudience: "All emergency vehicles and civilian evacuees"
  },
  {
    id: "rec-3",
    priority: "Moderate",
    action: "Pre-position Emergency Medical Responders at East Ridge",
    timeframe: "Within 60 mins",
    rationale: "Access corridor likely to become isolated once main road is blocked.",
    category: "Medical Support",
    targetAudience: "Triage & First Aid Volunteer Teams"
  },
  {
    id: "rec-4",
    priority: "Moderate",
    action: "Deploy Battery Backup Pack to Mesh Relay Node 04",
    timeframe: "Within 2 hours",
    rationale: "Relay Node 04 is currently bridging 42% of P2P emergency signals.",
    category: "Communication",
    targetAudience: "Technical mesh coordinators"
  },
  {
    id: "rec-5",
    priority: "Low",
    action: "Inspect Drinking Water Reservoirs at West Tank Hub",
    timeframe: "Next 4 hours",
    rationale: "Precautionary turbidity testing recommended after flash runoff.",
    category: "Public Health",
    targetAudience: "Civil logistics team"
  }
];

export const recentHazardReports = [
  {
    id: "HZ-108",
    type: "Flash Flood Surge",
    location: "Sector 4 Underpass",
    distance: "0.8 km NW",
    severity: "High",
    timeAgo: "6 mins ago",
    verification: "Verified by 4 Mesh Peers",
    status: "Active Threat",
    description: "Water depth approximately 1.1m. Multiple disabled vehicles obstructing passage."
  },
  {
    id: "HZ-107",
    type: "Hillside Mudslide",
    location: "Ridge Road km 14.2",
    distance: "2.1 km NE",
    severity: "High",
    timeAgo: "18 mins ago",
    verification: "Verified by Civil Patrol",
    status: "Road Blocked",
    description: "Earth and heavy boulders collapsed across both vehicular lanes. Heavy equipment required."
  },
  {
    id: "HZ-106",
    type: "Fallen High-Voltage Line",
    location: "Market Square Lane 2",
    distance: "1.4 km S",
    severity: "Moderate",
    timeAgo: "32 mins ago",
    verification: "Community Report (2 Confirmations)",
    status: "Hazardous Area",
    description: "Live power cable downed by fallen tree branch. Area cordoned off with cones."
  },
  {
    id: "HZ-105",
    type: "Severe Waterlogging",
    location: "Central High School Gate",
    distance: "3.2 km W",
    severity: "Moderate",
    timeAgo: "55 mins ago",
    verification: "Verified by Shelter Staff",
    status: "Caution Advised",
    description: "Knee-deep standing water near school perimeter. Pedestrian footbridge remains dry."
  },
  {
    id: "HZ-104",
    type: "Uprooted Tree on Sidewalk",
    location: "North Bypass Junction",
    distance: "4.5 km N",
    severity: "Low",
    timeAgo: "1 hr 20 mins ago",
    verification: "Resolved by Volunteers",
    status: "Cleared",
    description: "Fallen pine tree dragged to curb. Single traffic lane reopened for light vehicles."
  }
];

export const nearbyEmergencyResources = [
  {
    id: "res-1",
    name: "Apex Community High-Ground Shelter",
    type: "Evacuation Shelter",
    distance: "1.2 km",
    status: "Open & Accepting",
    capacity: "68% (170 / 250 Occupied)",
    powerStatus: "Backup Diesel Generator (85% Fuel)",
    medicalSupport: "Paramedic Unit Stationed",
    meshNodeId: "Mesh Node #02 (Online)",
    contactFrequency: "UHF Ch 4 (462.625 MHz)"
  },
  {
    id: "res-2",
    name: "St. Jude Emergency Triage Post",
    type: "Medical / First Aid Hub",
    distance: "2.4 km",
    status: "Operational",
    capacity: "45% (36 / 80 Beds Active)",
    powerStatus: "Lithium Battery Bank (6.2 hrs left)",
    medicalSupport: "2 Doctors, 4 Nurses Present",
    meshNodeId: "Mesh Node #07 (Online)",
    contactFrequency: "VHF Ch 16 (156.800 MHz)"
  },
  {
    id: "res-3",
    name: "Civic Center Water & Rations Depot",
    type: "Logistics & Supplies",
    distance: "1.9 km",
    status: "Open (Rations Available)",
    capacity: "Ample Supply (3-Day Capacity)",
    powerStatus: "Solar Inverter + Battery",
    medicalSupport: "Basic First-Aid Kits Available",
    meshNodeId: "Mesh Node #11 (Online)",
    contactFrequency: "UHF Ch 8 (467.562 MHz)"
  },
  {
    id: "res-4",
    name: "Rescue Station 3 & Boat Depot",
    type: "Search & Rescue Unit",
    distance: "3.1 km",
    status: "Active Deployment",
    capacity: "2 Inflatable Boats, 1 High-Clearance Truck",
    powerStatus: "Dedicated Emergency Generator",
    medicalSupport: "Rapid Extraction Water Rescue Team",
    meshNodeId: "Mesh Node #01 (Master Node)",
    contactFrequency: "UHF Ch 1 (Emergency Command)"
  }
];
