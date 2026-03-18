#!/bin/bash

# Script to run green taxi windowed aggregation with PyFlink
# This will count trips per PULocationID using 5-minute tumbling windows

set -e

echo "=========================================="
echo "Green Taxi Windowed Aggregation"
echo "5-Minute Tumbling Window by PULocationID"
echo "=========================================="
echo ""

# Step 1: Create PostgreSQL table
echo "Step 1: Creating PostgreSQL table for windowed results..."
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Drop table if exists to start fresh
DROP TABLE IF EXISTS green_trips_windowed;

-- Create table for windowed aggregation results
CREATE TABLE green_trips_windowed (
    window_start TIMESTAMP,
    PULocationID INTEGER,
    num_trips BIGINT,
    PRIMARY KEY (window_start, PULocationID)
);

-- Create index for faster queries
CREATE INDEX idx_num_trips ON green_trips_windowed(num_trips DESC);
CREATE INDEX idx_window_start ON green_trips_windowed(window_start);
EOF
echo "✓ Table created"
echo ""

# Step 2: Submit Flink job
echo "Step 2: Submitting Flink windowed aggregation job..."
echo "This will process all messages from green-trips topic"
echo "and aggregate trips per PULocationID in 5-minute windows"
echo ""
docker compose exec -T jobmanager ./bin/flink run -py /opt/src/job/green_trips_window_aggregation.py --pyFiles /opt/src -d
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

# Step 4: Query results - Top 3 PULocationIDs by trip count
echo "Step 4: Querying top 3 PULocationIDs by trip count..."
echo ""
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Top 3 PULocationIDs by total trip count across all windows
SELECT 
    PULocationID, 
    SUM(num_trips) as total_trips
FROM green_trips_windowed
GROUP BY PULocationID
ORDER BY total_trips DESC
LIMIT 3;

-- Show some window details for the top location
SELECT 
    window_start,
    PULocationID,
    num_trips
FROM green_trips_windowed
WHERE PULocationID = (
    SELECT PULocationID 
    FROM green_trips_windowed 
    GROUP BY PULocationID 
    ORDER BY SUM(num_trips) DESC 
    LIMIT 1
)
ORDER BY window_start
LIMIT 10;

-- Overall statistics
SELECT 
    COUNT(DISTINCT PULocationID) as unique_locations,
    COUNT(DISTINCT window_start) as unique_windows,
    SUM(num_trips) as total_trips,
    AVG(num_trips) as avg_trips_per_window
FROM green_trips_windowed;
EOF
echo ""

echo "=========================================="
echo "Windowed Aggregation Complete!"
echo "=========================================="
echo ""
echo "The Flink job is still running in the background."
echo "To view the Flink dashboard: http://localhost:8081"
echo ""
echo "To query specific results:"
echo "  docker compose exec postgres psql -U postgres -d postgres"
echo "  SELECT PULocationID, num_trips FROM green_trips_windowed ORDER BY num_trips DESC LIMIT 3;"
echo ""
echo "To cancel the Flink job:"
echo "  Go to http://localhost:8081 and cancel the job from the UI"
echo ""