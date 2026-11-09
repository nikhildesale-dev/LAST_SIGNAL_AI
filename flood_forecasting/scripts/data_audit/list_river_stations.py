
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


# Load the cleaned river dataset
river = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv")

# Keep one row for each unique river station
stations = (
    river[
        [
            "Station",
            "District",
            "River",
            "Basin",
            "Latitude",
            "Longitude",
        ]
    ]
    .drop_duplicates(subset=["Station"])
    .sort_values("Station")
)

print("===== UNIQUE RIVER STATIONS =====")
print("Total stations:", len(stations))
print(stations.to_string(index=False))
