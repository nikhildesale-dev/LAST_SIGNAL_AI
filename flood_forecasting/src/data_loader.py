"""
LAST_SIGNAL_AI: Selective Data Loading and Ingestion Module

Provides memory-efficient, validated loading of river level and rainfall datasets.
"""

import os
from typing import List, Optional, Set, Union
import pandas as pd
import numpy as np


def load_river_gauge_records(
    csv_path: str = "data/raw/river_water_level_krishna.csv",
    station_names: Optional[List[str]] = None,
    usecols: Optional[List[str]] = None
) -> pd.DataFrame:
    """
    Selectively load Krishna Basin river water level records.
    
    Args:
        csv_path: Path to river_water_level_krishna.csv (default: data/raw/river_water_level_krishna.csv)
        station_names: List of station names to filter (e.g. ['Ankali Bridge', 'Shigaon', 'Koyna_1'])
        usecols: Specific columns to load.
        
    Returns:
        Filtered and timestamp-parsed DataFrame.
    """
    if not os.path.exists(csv_path):
        # Resolve relative to project root
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        alt_path = os.path.join(repo_root, csv_path)
        if os.path.exists(alt_path):
            csv_path = alt_path
        else:
            raise FileNotFoundError(f"River gauge dataset not found at: {csv_path}")
        
    default_cols = [
        "Station_Name", "Date_Time", "Water_Level",
        "River", "Basin", "Latitude", "Longitude"
    ]
    cols_to_load = usecols if usecols is not None else default_cols
    
    # Read CSV
    df = pd.read_csv(csv_path, usecols=cols_to_load, low_memory=False)
    
    # Filter stations
    if station_names is not None:
        station_set = set(station_names)
        df = df[df["Station_Name"].isin(station_set)].copy()
        
    # Standardize timestamps
    if "Date_Time" in df.columns:
        df["timestamp"] = pd.to_datetime(df["Date_Time"], errors="coerce")
        df = df.dropna(subset=["timestamp"])
        df = df.sort_values(["Station_Name", "timestamp"]).reset_index(drop=True)
        
    return df


def load_rainfall_records(
    csv_path: str = "data/cleaned/maharashtra_rainfall_cleaned.csv",
    station_names: Optional[List[str]] = None
) -> pd.DataFrame:
    """
    Selectively load cleaned Maharashtra rainfall records.
    
    Args:
        csv_path: Path to maharashtra_rainfall_cleaned.csv (default: data/cleaned/maharashtra_rainfall_cleaned.csv)
        station_names: List of rainfall station names (e.g. ['SANGLI'])
        
    Returns:
        Filtered, sorted DataFrame with parsed timestamps.
    """
    if not os.path.exists(csv_path):
        # Resolve relative to project root
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        alt_path = os.path.join(repo_root, csv_path)
        if os.path.exists(alt_path):
            csv_path = alt_path
        else:
            raise FileNotFoundError(f"Rainfall dataset not found at: {csv_path}")
        
    df = pd.read_csv(csv_path, low_memory=False)
    
    if station_names is not None:
        df = df[df["Station"].isin(set(station_names))].copy()
        
    if "Timestamp" in df.columns:
        df["timestamp"] = pd.to_datetime(df["Timestamp"], errors="coerce")
        df = df.dropna(subset=["timestamp"])
        df = df.sort_values("timestamp").reset_index(drop=True)
        
    return df


def load_processed_pilot(csv_path: str = "data/processed/multistation_upstream_pilot.csv") -> pd.DataFrame:
    """
    Load the unified hourly multi-station time series dataset.
    """
    if not os.path.exists(csv_path):
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        alt_path = os.path.join(repo_root, csv_path)
        if os.path.exists(alt_path):
            csv_path = alt_path
        else:
            raise FileNotFoundError(f"Processed pilot dataset not found: {csv_path}")
        
    df = pd.read_csv(csv_path)
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    return df.sort_values("timestamp").reset_index(drop=True)

