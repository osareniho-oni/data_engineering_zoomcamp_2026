import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from kafka import KafkaConsumer

server = 'localhost:9092'
topic_name = 'green-trips'

def green_ride_deserializer(data):
    """Deserialize JSON bytes to dictionary"""
    json_str = data.decode('utf-8')
    return json.loads(json_str)

consumer = KafkaConsumer(
    topic_name,
    bootstrap_servers=[server],
    auto_offset_reset='earliest',
    group_id='green-trips-analysis',
    value_deserializer=green_ride_deserializer
)

print(f"Reading all messages from {topic_name}...")
print("Counting trips with trip_distance > 5.0...")
print("="*60)

total_count = 0
trips_over_5km = 0

for message in consumer:
    ride = message.value
    total_count += 1
    
    trip_distance = ride.get('trip_distance', 0)
    
    if trip_distance > 5.0:
        trips_over_5km += 1
    
    # Show progress every 5000 messages
    if total_count % 5000 == 0:
        print(f"Processed {total_count} messages... (trips > 5.0: {trips_over_5km})")
    
    # Check if we've consumed all messages by checking if we're caught up
    # This is a simple approach - in production you'd use more sophisticated methods
    if total_count >= 49416:  # We know we sent 49,416 rows
        break

consumer.close()

print("="*60)
print(f"\nResults:")
print(f"Total trips processed: {total_count}")
print(f"Trips with distance > 5.0: {trips_over_5km}")
print(f"Percentage: {(trips_over_5km / total_count * 100):.2f}%")