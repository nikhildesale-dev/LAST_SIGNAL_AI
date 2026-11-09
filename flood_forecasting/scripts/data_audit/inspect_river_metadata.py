
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


river = pd.read_csv(PROJECT_ROOT / "data" / "raw" / "river_water_level.csv")

columns = [
    "Station",
    "District",
    "Tehsil",
    "Village",
    "River",
    "Basin",
    "Tributary",
    "Subtributary",
    "Local River",
    "RL_of_zeroGauge",
    "MeanSeaLevel",
]

stations = river[columns].drop_duplicates(subset="Station")

print("===== RIVER STATION METADATA =====")
print(stations.to_string(index=False))

print("\n===== UNIQUE RIVER AND BASIN VALUES =====")

for column in ["River", "Basin", "Tributary", "Local River"]:
    print(f"\n{column}:")
    print(stations[column].value_counts(dropna=False).to_string())
