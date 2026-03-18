#!/bin/bash

# Script to output homework answers in one-liner format
# Run this after all analyses are complete

echo "=========================================="
echo "Data Engineering Zoomcamp - Homework Answers"
echo "Module 7: Stream Processing with PyFlink"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Question 3: Trips with distance > 5
echo "Question 3: How many trips have trip_distance > 5?"
ANSWER_Q3=$(docker compose exec -T postgres psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM green_trips_analysis;" | tr -d ' ')
echo "Answer: $ANSWER_Q3"
echo ""

# Question 4: Top 3 PULocationIDs
echo "Question 4: Top 3 PULocationIDs by trip count (5-min tumbling windows)"
echo "Answer:"
docker compose exec -T postgres psql -U postgres -d postgres -t -c "
SELECT PULocationID || ': ' || SUM(num_trips) || ' trips'
FROM green_trips_windowed 
GROUP BY PULocationID 
ORDER BY SUM(num_trips) DESC 
LIMIT 3;" | sed 's/^[ \t]*//'
echo ""

# Question 4b: Most trips in single window
echo "Question 4b: Which PULocationID had the most trips in a single 5-minute window?"
ANSWER_Q4B=$(docker compose exec -T postgres psql -U postgres -d postgres -t -c "
SELECT PULocationID || ' (' || num_trips || ' trips at ' || window_start || ')'
FROM green_trips_windowed
ORDER BY num_trips DESC
LIMIT 1;" | sed 's/^[ \t]*//')
echo "Answer: $ANSWER_Q4B"
echo ""

# Question 5: Longest session
echo "Question 5: How many trips were in the longest session?"
ANSWER_Q5=$(docker compose exec -T postgres psql -U postgres -d postgres -t -c "
SELECT num_trips FROM green_trips_sessions ORDER BY num_trips DESC LIMIT 1;" | tr -d ' ')
echo "Answer: $ANSWER_Q5 trips"
echo ""

# Question 6: Hour with highest tips
echo "Question 6: Which hour had the highest total tip amount?"
ANSWER_Q6=$(docker compose exec -T postgres psql -U postgres -d postgres -t -c "
SELECT window_start || ' ($' || ROUND(total_tip_amount::numeric, 2) || ')'
FROM green_trips_hourly_tips
ORDER BY total_tip_amount DESC
LIMIT 1;" | sed 's/^[ \t]*//')
echo "Answer: $ANSWER_Q6"
echo ""

echo "=========================================="
echo "Summary of Answers:"
echo "=========================================="
echo "Q3: $ANSWER_Q3 trips with distance > 5.0"
echo "Q4: See top 3 locations above"
echo "Q4b: $ANSWER_Q4B"
echo "Q5: $ANSWER_Q5 trips in longest session"
echo "Q6: $ANSWER_Q6"
echo ""
echo "Note: Run ./run_all_analyses.sh first to generate all results"
echo "=========================================="