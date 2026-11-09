
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


df = pd.read_csv(PROJECT_ROOT / "data" / "raw" / "river_water_level_krishna.csv")

print("Dataset shape:", df.shape)
print("\nColumns:")
print(df.columns.tolist())

print("\nUnique stations:")
print(
    df[
        ["Station", "District", "River", "Basin", "Latitude", "Longitude"]
    ]
    .drop_duplicates(subset="Station")
    .to_string(index=False)
)

print("\nMissing river/basin metadata:")
for column in ["River", "Basin"]:
    if column in df.columns:
        values = df[column].astype(str).str.strip()
        print(column, "blank or '-' values:", values.isin(["", "-"]).sum())
