
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


df = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv")

column = "River Water Level Telemetry Hourly (meter)"
time_column = "Data Acquisition Time"

df[time_column] = pd.to_datetime(df[time_column], errors="coerce")
df[column] = pd.to_numeric(df[column], errors="coerce")

# Inspect readings around the unusual maximum
station_data = df[df["Station"] == "Khadakwasala_1"].copy()

station_data = station_data.sort_values(time_column)

max_index = station_data[column].idxmax()
max_time = station_data.loc[max_index, time_column]

print("Maximum reading:", station_data.loc[max_index, column])
print("Timestamp:", max_time)

print("\nReadings within 24 hours of the maximum:")

nearby = station_data[
    (station_data[time_column] >= max_time - pd.Timedelta(hours=24))
    & (station_data[time_column] <= max_time + pd.Timedelta(hours=24))
]

print(
    nearby[[time_column, column]]
    .to_string(index=False)
)

print("\nReadings above 700:")
print(
    station_data[station_data[column] > 700][[time_column, column]]
    .to_string(index=False)
)
