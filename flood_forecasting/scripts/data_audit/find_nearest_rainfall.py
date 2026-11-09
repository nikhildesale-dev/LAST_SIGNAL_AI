
import pandas as pd
from math import radians, sin, cos, asin, sqrt

# Load cleaned datasets
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
INTERMEDIATES_DIR = PROJECT_ROOT / "data" / "audit_intermediates"
INTERMEDIATES_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_FILE = INTERMEDIATES_DIR / "nearest_rainfall_stations.csv"

river = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv")
rain = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv")

# Get unique stations and their coordinates
river_stations = river[
    ["Station", "District", "Latitude", "Longitude"]
].drop_duplicates(subset="Station")

rain_stations = rain[
    ["Station", "District", "Latitude", "Longitude"]
].drop_duplicates(subset="Station")

# Calculate geographic distance in kilometres
def distance_km(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(
        radians, [lat1, lon1, lat2, lon2]
    )

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = (
        sin(dlat / 2) ** 2
        + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    )

    return 6371 * 2 * asin(sqrt(a))

results = []

for _, r in river_stations.iterrows():
    candidates = rain_stations.copy()

    candidates["Distance_km"] = candidates.apply(
        lambda s: distance_km(
            r["Latitude"],
            r["Longitude"],
            s["Latitude"],
            s["Longitude"],
        ),
        axis=1,
    )

    # Keep the 3 geographically nearest rainfall stations
    nearest = candidates.nsmallest(3, "Distance_km")

    for _, s in nearest.iterrows():
        results.append({
            "River_Station": r["Station"],
            "River_District": r["District"],
            "Rainfall_Station": s["Station"],
            "Rainfall_District": s["District"],
            "Distance_km": round(s["Distance_km"], 2),
        })

result_df = pd.DataFrame(results)
result_df.to_csv("nearest_rainfall_stations.csv", index=False)

print("===== 3 NEAREST RAINFALL STATIONS PER RIVER STATION =====")
print(result_df.to_string(index=False))
print("\nSaved to nearest_rainfall_stations.csv")
