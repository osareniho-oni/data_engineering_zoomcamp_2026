#!/bin/bash

# Script to query session window analysis results from PostgreSQL

echo "=========================================="
echo "Green Taxi Session Window Results"
echo "=========================================="
echo ""

echo "Question: Which PULocationID had the longest session (most trips)?"
echo "-------------------------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Find the session with the most trips
SELECT 
    window_start,
    window_end,
    PULocationID,
    num_trips,
    ROUND(EXTRACT(EPOCH FROM (window_end - window_start))/60::numeric, 2) as session_duration_minutes
FROM green_trips_sessions
ORDER BY num_trips DESC
LIMIT 1;
EOF
echo ""

echo "Top 10 Longest Sessions by Trip Count"
echo "--------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    window_start,
    window_end,
    PULocationID,
    num_trips,
    ROUND(EXTRACT(EPOCH FROM (window_end - window_start))/60::numeric, 2) as duration_minutes
FROM green_trips_sessions
ORDER BY num_trips DESC
LIMIT 10;
EOF
echo ""

echo "Session Statistics"
echo "------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    COUNT(*) as total_sessions,
    COUNT(DISTINCT PULocationID) as unique_locations,
    SUM(num_trips) as total_trips,
    ROUND(AVG(num_trips)::numeric, 2) as avg_trips_per_session,
    MAX(num_trips) as max_trips_in_session,
    ROUND(AVG(EXTRACT(EPOCH FROM (window_end - window_start))/60)::numeric, 2) as avg_session_duration_minutes
FROM green_trips_sessions;
EOF
echo ""

echo "Top 5 Locations by Total Sessions"
echo "----------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    PULocationID,
    COUNT(*) as num_sessions,
    SUM(num_trips) as total_trips,
    ROUND(AVG(num_trips)::numeric, 2) as avg_trips_per_session
FROM green_trips_sessions
GROUP BY PULocationID
ORDER BY num_sessions DESC
LIMIT 5;
EOF
echo ""

echo "=========================================="
echo "To see all results:"
echo "  docker compose exec postgres psql -U postgres -d postgres"
echo "  SELECT * FROM green_trips_sessions ORDER BY num_trips DESC;"
echo "=========================================="