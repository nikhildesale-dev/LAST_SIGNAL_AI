
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


df = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv")

column = "River Water Level Telemetry Hourly (meter)"

df[column] = pd.to_numeric(df[column], errors="coerce")

print("Highest 20 river readings:")
print(
    df.nlargest(20, column)[
        ["Station", "District", "River",
         "Data Acquisition Time", column]
    ].to_string(index=False)
)

print("\nMaximum reading by station:")
print(
    df.groupby("Station")[column]
    .agg(["min", "median", "max", "count"])
    .round(2)
    .to_string()
)
