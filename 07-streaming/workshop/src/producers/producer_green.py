import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import pandas as pd
from kafka import KafkaProducer

# Path to the green taxi parquet file
parquet_file = Path(__file__).parent.parent.parent / "green_tripdata_2025-10.parquet"

# Read the parquet file with only the required columns
columns = [
    'lpep_pickup_datetime',
    'lpep_dropoff_datetime',
    'PULocationID',
    'DOLocationID',
    'passenger_count',
    'trip_distance',
    'tip_amount',
    'total_amount'
]

print(f"Reading parquet file: {parquet_file}")
df = pd.read_parquet(parquet_file, columns=columns)
print(f"Loaded {len(df)} rows")

def green_ride_serializer(ride_dict):
    """Serialize a dictionary to JSON bytes"""
    json_str = json.dumps(ride_dict)
    return json_str.encode('utf-8')

server = 'localhost:9092'

producer = KafkaProducer(
    bootstrap_servers=[server],
    value_serializer=green_ride_serializer
)

topic_name = 'green-trips'

print(f"Starting to send data to topic: {topic_name}")
t0 = time.time()

for idx, row in df.iterrows():
    # Convert row to dictionary
    ride_dict = {
        'lpep_pickup_datetime': row['lpep_pickup_datetime'].isoformat(),
        'lpep_dropoff_datetime': row['lpep_dropoff_datetime'].isoformat(),
        'PULocationID': int(row['PULocationID']),
        'DOLocationID': int(row['DOLocationID']),
        'passenger_count': float(row['passenger_count']) if pd.notna(row['passenger_count']) else None,
        'trip_distance': float(row['trip_distance']),
        'tip_amount': float(row['tip_amount']),
        'total_amount': float(row['total_amount'])
    }
    
    producer.send(topic_name, value=ride_dict)
    
    # Print progress every 1000 rows
    if (idx + 1) % 1000 == 0:
        print(f"Sent {idx + 1} rows...")

producer.flush()

t1 = time.time()
print(f'took {(t1 - t0):.2f} seconds')
print(f"Successfully sent {len(df)} rows to {topic_name}")