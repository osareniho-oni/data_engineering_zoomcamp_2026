#!/bin/bash

# Script to run the green taxi consumer
# This will read all messages from green-trips topic and count trips with distance > 5.0

echo "=========================================="
echo "Green Taxi Consumer"
echo "=========================================="
echo ""
echo "This will consume all messages from the green-trips topic"
echo "and count how many trips have trip_distance > 5.0"
echo ""

cd "$(dirname "$0")"
uv run python src/consumers/consumer_green.py