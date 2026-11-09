
import pandas as pd
from math import radians, sin, cos, sqrt, atan2

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
INTERMEDIATES_DIR = PROJECT_ROOT / "data" / "audit_intermediates"
INTERMEDIATES_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_FILE = INTERMEDIATES_DIR / "nearest_station_matches.csv"

river = pd.read_csv(PROJECT_ROOT / "data" / "raw" / "river_water_level.csv")
rainfall = pd.read_csv(PROJECT_ROOT / "data" / "raw" / "maharashtra_rainfall.csv")

# Keep one row per station and its location
river_stations = river[
    ["Station", "District", "Latitude", "Longitude"]
].drop_duplicates(subset=["Station"])

rain_stations = rainfall[
    ["Station", "District", "Latitude", "Longitude"]
].drop_duplicates(subset=["Station"])

def distance_km(lat1, lon1, lat2, lon2):
    """Calculate distance between two coordinates in kilometres."""
    earth_radius = 6371

    lat1, lon1, lat2, lon2 = map(
        radians, [lat1, lon1, lat2, lon2]
    )

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = (
        sin(dlat / 2) ** 2
        + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    )

    return 2 * earth_radius * atan2(
        sqrt(a), sqrt(1 - a)
    )

matches = []

for _, river_station in river_stations.iterrows():
    candidates = rain_stations.copy()

    # First, look for rainfall stations in the same district
    candidates = candidates[
        candidates["District"] == river_station["District"]
    ]

    if candidates.empty:
        print(
            f"No rainfall station in district: "
            f"{river_station['District']}"
        )
        continue

    candidates["Distance_km"] = candidates.apply(
        lambda row: distance_km(
            river_station["Latitude"],
            river_station["Longitude"],
            row["Latitude"],
            row["Longitude"]
        ),
        axis=1
    )

    nearest = candidates.sort_values("Distance_km").iloc[0]

    matches.append({
        "River_Station": river_station["Station"],
        "District": river_station["District"],
        "Nearest_Rainfall_Station": nearest["Station"],
        "Distance_km": round(nearest["Distance_km"], 2)
    })

result = pd.DataFrame(matches)

print("\nNEAREST RAINFALL STATIONS")
print(result.to_string(index=False))

result.to_csv("nearest_station_matches.csv", index=False)
print("\nSaved results to nearest_station_matches.csv")
