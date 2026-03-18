#!/bin/bash

# Script to run green taxi analysis with PyFlink
# This will process all messages from green-trips topic and store trips with distance > 5.0

set -e

echo "=========================================="
echo "Green Taxi Analysis with PyFlink"
echo "=========================================="
echo ""

# Step 1: Create PostgreSQL table
echo "Step 1: Creating PostgreSQL table for results..."
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Drop table if exists to start fresh
DROP TABLE IF EXISTS green_trips_analysis;

-- Create table for green taxi trips with distance > 5.0
CREATE TABLE green_trips_analysis (
    PULocationID INTEGER,
    DOLocationID INTEGER,
    passenger_count DOUBLE PRECISION,
    trip_distance DOUBLE PRECISION,
    tip_amount DOUBLE PRECISION,
    total_amount DOUBLE PRECISION,
    pickup_datetime TIMESTAMP,
    dropoff_datetime TIMESTAMP
);

-- Create index for faster counting
CREATE INDEX idx_trip_distance ON green_trips_analysis(trip_distance);
EOF
echo "✓ Table created"
echo ""

# Step 2: Submit Flink job
echo "Step 2: Submitting Flink job..."
echo "This will process all messages from green-trips topic"
echo "and store only trips with distance > 5.0 in PostgreSQL"
echo ""
docker compose exec -T jobmanager ./bin/flink run -py /opt/src/job/green_trips_analysis.py --pyFiles /opt/src -d
echo "✓ Flink job submitted"
echo ""

# Step 3: Wait for processing
echo "Step 3: Waiting for data to be processed..."
echo "The job will run continuously. Waiting 60 seconds for initial results..."
for i in {60..1}; do
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "$i... "
    fi
    sleep 1
done
echo ""
echo "✓ Initial processing should be complete"
echo ""

# Step 4: Query results
echo "Step 4: Querying results from PostgreSQL..."
echo ""
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Count total trips with distance > 5.0
SELECT COUNT(*) as trips_over_5km FROM green_trips_analysis;

-- Show some statistics
SELECT 
    COUNT(*) as total_trips,
    MIN(trip_distance) as min_distance,
    MAX(trip_distance) as max_distance,
    AVG(trip_distance) as avg_distance,
    AVG(total_amount) as avg_amount
FROM green_trips_analysis;

-- Show first 10 trips
SELECT 
    PULocationID,
    DOLocationID,
    trip_distance,
    total_amount,
    pickup_datetime
FROM green_trips_analysis
ORDER BY trip_distance DESC
LIMIT 10;
EOF
echo ""

echo "=========================================="
echo "Analysis Complete!"
echo "=========================================="
echo ""
echo "The Flink job is still running in the background."
echo "To view the Flink dashboard: http://localhost:8081"
echo ""
echo "To query the results again:"
echo "  docker compose exec postgres psql -U postgres -d postgres"
echo "  SELECT COUNT(*) FROM green_trips_analysis;"
echo ""
echo "To cancel the Flink job:"
echo "  Go to http://localhost:8081 and cancel the job from the UI"
echo ""