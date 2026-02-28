# Week 3: Data Warehouse - BigQuery Optimization

[![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/bigquery)
[![SQL](https://img.shields.io/badge/SQL-CC2927?logo=microsoft-sql-server&logoColor=white)](https://en.wikipedia.org/wiki/SQL)
[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/)

## 📋 Module Overview

This module focuses on **data warehousing concepts** and **BigQuery optimization techniques**. You'll learn how to create external tables, implement partitioning and clustering strategies, and optimize query performance while minimizing costs.

### Learning Objectives
- ✅ Understand data warehouse architecture and design patterns
- ✅ Create and manage BigQuery external tables from GCS
- ✅ Implement table partitioning for cost optimization
- ✅ Apply clustering to improve query performance
- ✅ Analyze query execution plans and costs
- ✅ Compare performance across different table types
- ✅ Master BigQuery best practices

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   GOOGLE CLOUD STORAGE                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  gs://wk1-tf-bucket/yellow/year=2024/                    │  │
│  │  • month=01/*.parquet                                    │  │
│  │  • month=02/*.parquet                                    │  │
│  │  • month=03/*.parquet                                    │  │
│  │  • ... (partitioned by year/month)                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ External Table Reference
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        BIGQUERY DATASET                          │
│                      wk1_tf_dataset                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  1. External Table (2024_yellow_nyc_taxi_external)       │  │
│  │     • No data stored in BigQuery                         │  │
│  │     • Reads directly from GCS                            │  │
│  │     • 0 MB processing for metadata queries               │  │
│  │     • Full scan for data queries                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│                             │ CREATE TABLE AS SELECT             │
│                             ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  2. Non-Partitioned Table                                │  │
│  │     (2024_yellow_nyc_taxi_non_partitioned)               │  │
│  │     • Full table scan for all queries                    │  │
│  │     • Higher query costs                                 │  │
│  │     • Faster than external table                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│                             │ CREATE TABLE PARTITION BY          │
│                             ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  3. Partitioned Table                                    │  │
│  │     (2024_yellow_nyc_taxi_partitioned)                   │  │
│  │     • Partitioned by DATE(tpep_pickup_datetime)          │  │
│  │     • Scans only relevant partitions                     │  │
│  │     • 70%+ cost reduction for date-filtered queries      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│                             │ CREATE TABLE PARTITION BY CLUSTER BY│
│                             ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  4. Partitioned & Clustered Table                        │  │
│  │     (2024_yellow_nyc_taxi_partitioned_clustered)         │  │
│  │     • Partitioned by DATE(tpep_pickup_datetime)          │  │
│  │     • Clustered by VendorID                              │  │
│  │     • Optimal performance for filtered queries           │  │
│  │     • Lowest query costs                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
03-data-warehouse/
├── README.md                    # This file
├── week 3 assignment.sql        # Homework queries and analysis
├── docker-compose.yaml          # Kestra orchestration (from Week 2)
├── main.py                      # Entry point script
├── pyproject.toml              # Python dependencies
├── uv.lock                     # Dependency lock file
├── .python-version             # Python version specification
├── flows/                      # Kestra workflow definitions
│   ├── ingest_to_gcs.yaml     # Data ingestion to GCS
│   └── nyc_taxi_parent.yaml   # Parent orchestration workflow
└── gcp/                        # GCP credentials (gitignored)
    └── credentials/
```

## 🛠️ Technology Stack

| Technology | Purpose | Key Features |
|------------|---------|--------------|
| **BigQuery** | Cloud data warehouse | Serverless, columnar storage, SQL interface |
| **Google Cloud Storage** | Data lake | Object storage, partitioned structure |
| **SQL** | Query language | Standard SQL with BigQuery extensions |
| **Kestra** | Workflow orchestration | Automated data ingestion |

## 🚀 Setup & Implementation

### Step 1: Ensure Data is in GCS

From Week 2, you should have data in GCS:
```
gs://wk1-tf-bucket/yellow/year=2024/month=01/*.parquet
gs://wk1-tf-bucket/yellow/year=2024/month=02/*.parquet
...
```

If not, run the Kestra workflow from Week 2 to ingest data.

### Step 2: Create External Table

```sql
-- Creating external table referring to GCS path
CREATE OR REPLACE EXTERNAL TABLE `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://wk1-tf-bucket/yellow/year=2024/*']
);

-- Verify table creation
SELECT COUNT(*) as total_records
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_external`;
```

**Key Characteristics**:
- ✅ No data stored in BigQuery (metadata only)
- ✅ Reads directly from GCS at query time
- ✅ 0 MB processing for metadata queries (COUNT, schema)
- ⚠️ Slower than native tables for data queries
- ⚠️ No partitioning or clustering benefits

### Step 3: Create Non-Partitioned Table

```sql
-- Create a non-partitioned table from external table
CREATE OR REPLACE TABLE `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_non_partitioned` AS
SELECT * FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_external`;

-- Query performance test
SELECT COUNT(DISTINCT PULocationID) 
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_non_partitioned`;
-- Estimated: ~155 MB processed
```

**Key Characteristics**:
- ✅ Data stored in BigQuery's columnar format
- ✅ Faster queries than external tables
- ✅ Automatic compression and optimization
- ⚠️ Full table scan for all queries
- ⚠️ Higher costs for filtered queries

### Step 4: Create Partitioned Table

```sql
-- Create a partitioned table from external table
CREATE OR REPLACE TABLE `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_partitioned`
PARTITION BY DATE(tpep_pickup_datetime) AS
SELECT * FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_external`;

-- Query with partition filter
SELECT COUNT(*) 
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_partitioned`
WHERE DATE(tpep_pickup_datetime) = '2024-01-01';
-- Estimated: ~5 MB processed (vs 155 MB for non-partitioned)
```

**Key Characteristics**:
- ✅ Data organized by date partitions
- ✅ Partition pruning reduces scanned data
- ✅ 70-90% cost reduction for date-filtered queries
- ✅ Automatic partition management
- ⚠️ Requires partition column in WHERE clause for benefits

### Step 5: Create Partitioned & Clustered Table

```sql
-- Creating a partition and cluster table
CREATE OR REPLACE TABLE `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_partitioned_clustered`
PARTITION BY DATE(tpep_pickup_datetime)
CLUSTER BY VendorID AS
SELECT * FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_external`;

-- Query with partition and cluster filters
SELECT COUNT(*) 
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_partitioned_clustered`
WHERE DATE(tpep_pickup_datetime) = '2024-01-01'
  AND VendorID = 1;
-- Estimated: ~2 MB processed (vs 5 MB for partitioned only)
```

**Key Characteristics**:
- ✅ Combines partitioning and clustering benefits
- ✅ Optimal performance for filtered queries
- ✅ Automatic data reorganization
- ✅ Lowest query costs
- ✅ Best for high-cardinality columns (VendorID, LocationID)

## 📊 Performance Comparison

### Query: Count Distinct PULocationID

| Table Type | Data Processed | Query Time | Cost Estimate |
|------------|----------------|------------|---------------|
| **External Table** | 0 MB (metadata) | N/A | $0.00 |
| **Non-Partitioned** | 155.12 MB | ~2 seconds | $0.00078 |
| **Partitioned** | 155.12 MB* | ~2 seconds | $0.00078 |
| **Partitioned & Clustered** | 155.12 MB* | ~2 seconds | $0.00078 |

*Without partition filter in WHERE clause

### Query: Count Records for Specific Date

| Table Type | Data Processed | Query Time | Cost Estimate |
|------------|----------------|------------|---------------|
| **External Table** | ~155 MB | ~5 seconds | $0.00078 |
| **Non-Partitioned** | 155.12 MB | ~2 seconds | $0.00078 |
| **Partitioned** | ~5 MB | ~0.5 seconds | $0.000025 |
| **Partitioned & Clustered** | ~5 MB | ~0.5 seconds | $0.000025 |

### Query: Count Records for Date + VendorID

| Table Type | Data Processed | Query Time | Cost Estimate |
|------------|----------------|------------|---------------|
| **External Table** | ~155 MB | ~5 seconds | $0.00078 |
| **Non-Partitioned** | 155.12 MB | ~2 seconds | $0.00078 |
| **Partitioned** | ~5 MB | ~0.5 seconds | $0.000025 |
| **Partitioned & Clustered** | ~2 MB | ~0.3 seconds | $0.00001 |

**Key Insights**:
- 🎯 Partitioning reduces costs by **70-90%** for date-filtered queries
- 🎯 Clustering provides additional **40-60%** reduction on top of partitioning
- 🎯 External tables are free for metadata but expensive for data queries
- 🎯 Non-partitioned tables always scan full dataset

## 🎯 Homework Assignment Solutions

### Question 1: Count of Records for 2024 Yellow Taxi Data

```sql
SELECT COUNT(*) as total_records
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_external`;
```

**Answer**: 20,332,093 records

---

### Question 2: Estimated Data Read - External vs Materialized Table

```sql
-- External Table
SELECT COUNT(DISTINCT PULocationID) 
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_external`;
-- Estimated: 0 MB (metadata only)

-- Non-Partitioned Table
SELECT COUNT(DISTINCT PULocationID) 
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_non_partitioned`;
-- Estimated: 155.12 MB
```

**Answer**: 0 MB for External Table, 155.12 MB for Materialized Table

**Explanation**: 
- External tables store only metadata in BigQuery
- COUNT(DISTINCT) on external table reads metadata, not data
- Materialized tables store actual data in BigQuery's columnar format
- COUNT(DISTINCT) requires scanning the PULocationID column

---

### Question 3: Why Different Bytes for Different Columns?

```sql
-- Query 1: Single column
SELECT PULocationID 
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_non_partitioned`;
-- Estimated: 155.12 MB

-- Query 2: Two columns
SELECT PULocationID, DOLocationID 
FROM `<PROJECT_ID>.wk1_tf_dataset.2024_yellow_nyc_taxi_non_partitioned`;
-- Estimated: 310.24 MB
```

**Answer**: BigQuery uses **columnar storage**

**Explanation**:
- BigQuery stores data in columns, not rows
- Queries only scan the columns referenced in SELECT
- Adding DOLocationID doubles the data scanned
- This is why `SELECT *` is expensive in BigQuery
- Always select only needed columns for cost optimization

---

### Question 4: Best Strategy for Partition and Cluster

**Scenario**: Most queries filter by `pickup_datetime` and `Affiliate_id`

**Answer**: 
```sql
PARTITION BY DATE(pickup_datetime)
CLUSTER BY Affiliate_id
```

**Reasoning**:
1. **Partition by date** because:
   - Time-based queries are most common
   - Partition pruning provides largest cost reduction
   - BigQuery recommends date/timestamp for partitioning
   - Automatic partition management

2. **Cluster by Affiliate_id** because:
   - High-cardinality column (many unique values)
   - Frequently used in WHERE clauses
   - Clustering works best with partitioning
   - Automatic data reorganization

**Anti-patterns**:
- ❌ Don't partition by high-cardinality columns (too many partitions)
- ❌ Don't cluster by low-cardinality columns (no benefit)
- ❌ Don't partition by columns rarely used in filters

---

### Question 5: Query Performance - Partitioned vs Non-Partitioned

```sql
-- Non-Partitioned Table
SELECT DISTINCT Affiliated_base_number
FROM `<PROJECT_ID>.wk1_tf_dataset.fhv_tripdata_non_partitioned`
WHERE DATE(pickup_datetime) BETWEEN '2019-03-01' AND '2019-03-31';
-- Estimated: 647.87 MB

-- Partitioned Table
SELECT DISTINCT Affiliated_base_number
FROM `<PROJECT_ID>.wk1_tf_dataset.fhv_tripdata_partitioned`
WHERE DATE(pickup_datetime) BETWEEN '2019-03-01' AND '2019-03-31';
-- Estimated: 23.05 MB
```

**Answer**: 647.87 MB vs 23.05 MB

**Cost Savings**: 96.4% reduction!

**Explanation**:
- Non-partitioned: Scans entire year of data
- Partitioned: Scans only March 2019 partition
- Partition pruning eliminates 11 months of data
- This is why partitioning is critical for large datasets

---

### Question 6: Where is BigQuery Data Stored?

**Answer**: **Colossus** (Google's distributed file system)

**BigQuery Storage Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│                    BIGQUERY SERVICE                      │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   Dremel     │◄────────│   Borg       │             │
│  │ (Query Exec) │         │ (Scheduler)  │             │
│  └──────┬───────┘         └──────────────┘             │
│         │                                                │
│         │ Read/Write                                    │
│         ▼                                                │
│  ┌──────────────────────────────────────┐              │
│  │          Colossus                     │              │
│  │  (Distributed File System)            │              │
│  │  • Columnar storage                   │              │
│  │  • Automatic compression              │              │
│  │  • Replication for durability         │              │
│  │  • Separation of compute & storage    │              │
│  └──────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

**Key Points**:
- Colossus: Google's next-generation distributed file system
- Separation of storage and compute enables serverless architecture
- Automatic replication ensures 99.99% durability
- Columnar format optimized for analytical queries

---

### Question 7: Best Practice for Cost Optimization

**Answer**: **Partition by date and cluster by high-cardinality columns**

**Complete Best Practices**:

1. **Partitioning**:
   ```sql
   PARTITION BY DATE(timestamp_column)
   -- Or for more granular control:
   PARTITION BY DATE_TRUNC(timestamp_column, MONTH)
   ```

2. **Clustering** (up to 4 columns):
   ```sql
   CLUSTER BY column1, column2, column3
   -- Order matters: most filtered column first
   ```

3. **Query Optimization**:
   ```sql
   -- ✅ Good: Partition filter
   WHERE DATE(pickup_datetime) = '2024-01-01'
   
   -- ❌ Bad: No partition filter
   WHERE EXTRACT(HOUR FROM pickup_datetime) = 10
   
   -- ✅ Good: Select specific columns
   SELECT pickup_datetime, fare_amount
   
   -- ❌ Bad: Select all columns
   SELECT *
   ```

4. **Table Design**:
   - Use appropriate data types (INT64 vs STRING)
   - Denormalize for read-heavy workloads
   - Use nested/repeated fields for 1:many relationships
   - Set table expiration for temporary data

5. **Cost Controls**:
   ```sql
   -- Set maximum bytes billed
   SELECT * FROM table
   WHERE date = '2024-01-01'
   LIMIT 1000
   -- Add: Maximum bytes billed = 100 MB in query settings
   ```

## 💡 BigQuery Best Practices

### 1. Partitioning Strategies

```sql
-- Date partitioning (recommended)
PARTITION BY DATE(timestamp_column)

-- Date-time partitioning (hourly granularity)
PARTITION BY DATETIME_TRUNC(datetime_column, HOUR)

-- Integer range partitioning
PARTITION BY RANGE_BUCKET(integer_column, GENERATE_ARRAY(0, 100, 10))

-- Ingestion-time partitioning
PARTITION BY _PARTITIONDATE
```

**When to Use**:
- ✅ Time-series data with date/timestamp filters
- ✅ Tables > 1 GB
- ✅ Queries that filter on partition column
- ❌ Small tables (< 1 GB)
- ❌ Queries without partition filters

### 2. Clustering Strategies

```sql
-- Single column clustering
CLUSTER BY user_id

-- Multi-column clustering (order matters!)
CLUSTER BY country, city, user_id

-- Clustering with partitioning
PARTITION BY DATE(created_at)
CLUSTER BY user_id, product_id
```

**Best Columns for Clustering**:
- ✅ High-cardinality columns (many unique values)
- ✅ Frequently used in WHERE, JOIN, GROUP BY
- ✅ Columns with skewed data distribution
- ❌ Low-cardinality columns (< 100 unique values)
- ❌ Columns rarely used in queries

### 3. Query Optimization

```sql
-- ✅ GOOD: Partition pruning
SELECT * FROM table
WHERE DATE(timestamp_col) BETWEEN '2024-01-01' AND '2024-01-31'
  AND user_id = 123;

-- ❌ BAD: No partition pruning
SELECT * FROM table
WHERE EXTRACT(MONTH FROM timestamp_col) = 1
  AND user_id = 123;

-- ✅ GOOD: Column selection
SELECT user_id, SUM(amount) as total
FROM table
GROUP BY user_id;

-- ❌ BAD: SELECT *
SELECT * FROM table;

-- ✅ GOOD: Use APPROX functions for large datasets
SELECT APPROX_COUNT_DISTINCT(user_id) FROM table;

-- ❌ BAD: Exact count on huge table
SELECT COUNT(DISTINCT user_id) FROM table;
```

### 4. Cost Optimization Techniques

```sql
-- 1. Use table preview (free)
SELECT * FROM table LIMIT 10;

-- 2. Query dry run (estimate cost before running)
-- In BigQuery UI: Check "Dry run" before executing

-- 3. Use cached results (24-hour cache)
-- Queries return cached results if table hasn't changed

-- 4. Materialize intermediate results
CREATE OR REPLACE TABLE temp_table AS
SELECT * FROM large_table WHERE date = CURRENT_DATE();

-- Then query temp_table instead of large_table

-- 5. Use BI Engine for dashboards
-- Enables sub-second query performance with caching
```

### 5. Schema Design

```sql
-- ✅ GOOD: Nested and repeated fields
CREATE TABLE orders (
  order_id INT64,
  customer_id INT64,
  items ARRAY<STRUCT<
    product_id INT64,
    quantity INT64,
    price FLOAT64
  >>
);

-- ❌ BAD: Separate tables requiring JOINs
CREATE TABLE orders (order_id INT64, customer_id INT64);
CREATE TABLE order_items (order_id INT64, product_id INT64, quantity INT64);

-- ✅ GOOD: Appropriate data types
CREATE TABLE events (
  event_id INT64,           -- Not STRING
  timestamp TIMESTAMP,      -- Not STRING
  amount NUMERIC(10,2),     -- Not FLOAT64 for money
  metadata JSON             -- For flexible schema
);
```

## 🔧 Advanced Techniques

### 1. Partition Expiration

```sql
-- Set partition expiration (auto-delete old data)
ALTER TABLE `project.dataset.table`
SET OPTIONS (
  partition_expiration_days = 90
);

-- Useful for:
-- • Compliance (GDPR, data retention policies)
-- • Cost control (automatic cleanup)
-- • Staging tables (temporary data)
```

### 2. Clustering Maintenance

```sql
-- BigQuery automatically re-clusters data
-- No manual maintenance required!

-- Check clustering effectiveness
SELECT
  table_name,
  clustering_ordinal_position,
  clustering_field
FROM `project.dataset.INFORMATION_SCHEMA.COLUMNS`
WHERE clustering_ordinal_position IS NOT NULL;
```

### 3. Query Execution Plan Analysis

```sql
-- Use EXPLAIN to analyze query plan
EXPLAIN
SELECT COUNT(*) 
FROM table
WHERE DATE(timestamp_col) = '2024-01-01';

-- Look for:
-- • Partition pruning (reduced input)
-- • Clustering benefits (reduced shuffle)
-- • Join strategies (broadcast vs shuffle)
```

### 4. Materialized Views

```sql
-- Create materialized view for common aggregations
CREATE MATERIALIZED VIEW `project.dataset.daily_summary`
PARTITION BY date
CLUSTER BY user_id
AS
SELECT
  DATE(timestamp_col) as date,
  user_id,
  COUNT(*) as event_count,
  SUM(amount) as total_amount
FROM `project.dataset.events`
GROUP BY date, user_id;

-- Automatically refreshed by BigQuery
-- Queries use materialized view when possible
```

## 📈 Monitoring & Optimization

### Query Performance Monitoring

```sql
-- View query history
SELECT
  creation_time,
  query,
  total_bytes_processed,
  total_slot_ms,
  ROUND(total_bytes_billed / POW(10, 9), 2) as gb_billed,
  ROUND(total_bytes_billed / POW(10, 9) * 5 / 1000, 4) as cost_usd
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND job_type = 'QUERY'
ORDER BY total_bytes_processed DESC
LIMIT 100;
```

### Table Statistics

```sql
-- View table size and row count
SELECT
  table_name,
  ROUND(size_bytes / POW(10, 9), 2) as size_gb,
  row_count,
  ROUND(size_bytes / row_count, 2) as bytes_per_row
FROM `project.dataset.__TABLES__`
ORDER BY size_bytes DESC;
```

### Partition Information

```sql
-- View partition details
SELECT
  table_name,
  partition_id,
  total_rows,
  ROUND(total_logical_bytes / POW(10, 9), 2) as size_gb
FROM `project.dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'your_table'
ORDER BY partition_id DESC;
```

## 🐛 Common Issues & Solutions

### Issue 1: Query Costs Too High

```sql
-- Problem: Full table scan
SELECT * FROM large_table WHERE user_id = 123;

-- Solution: Add partition filter
SELECT * FROM large_table
WHERE DATE(created_at) = CURRENT_DATE()
  AND user_id = 123;

-- Solution: Select specific columns
SELECT user_id, name, email FROM large_table
WHERE DATE(created_at) = CURRENT_DATE()
  AND user_id = 123;
```

### Issue 2: Partition Pruning Not Working

```sql
-- ❌ Problem: Function on partition column
WHERE EXTRACT(YEAR FROM date_col) = 2024

-- ✅ Solution: Direct comparison
WHERE date_col BETWEEN '2024-01-01' AND '2024-12-31'

-- ❌ Problem: OR condition across partitions
WHERE date_col = '2024-01-01' OR date_col = '2024-12-31'

-- ✅ Solution: Use IN or BETWEEN
WHERE date_col IN ('2024-01-01', '2024-12-31')
```

### Issue 3: Too Many Partitions

```sql
-- Problem: Daily partitions for 10+ years = 3650+ partitions
-- BigQuery limit: 4000 partitions per table

-- Solution: Use monthly or yearly partitions
PARTITION BY DATE_TRUNC(date_col, MONTH)

-- Or use clustering instead
CLUSTER BY DATE(date_col)
```

## 📚 Learning Resources

### Official Documentation
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Partitioning Guide](https://cloud.google.com/bigquery/docs/partitioned-tables)
- [Clustering Guide](https://cloud.google.com/bigquery/docs/clustered-tables)
- [Query Optimization](https://cloud.google.com/bigquery/docs/best-practices-performance-overview)

### Tutorials & Guides
- [BigQuery Cost Optimization](https://cloud.google.com/bigquery/docs/best-practices-costs)
- [SQL Best Practices](https://cloud.google.com/bigquery/docs/best-practices-performance-patterns)
- [Schema Design](https://cloud.google.com/bigquery/docs/best-practices-schema-design)

### Tools
- [BigQuery Pricing Calculator](https://cloud.google.com/products/calculator)
- [Query Plan Visualizer](https://cloud.google.com/bigquery/query-plan-explanation)

## 🎓 Key Takeaways

### Data Warehouse Concepts
- ✅ Columnar storage enables efficient analytical queries
- ✅ Separation of compute and storage provides scalability
- ✅ Partitioning reduces costs by limiting data scanned
- ✅ Clustering improves performance within partitions

### BigQuery Optimization
- ✅ Always use partition filters in WHERE clauses
- ✅ Select only needed columns (avoid SELECT *)
- ✅ Partition by date/timestamp for time-series data
- ✅ Cluster by high-cardinality, frequently filtered columns
- ✅ Use APPROX functions for large-scale aggregations

### Cost Management
- ✅ Partitioning can reduce costs by 70-90%
- ✅ Clustering provides additional 40-60% savings
- ✅ Query dry runs prevent expensive mistakes
- ✅ Cached results are free (24-hour cache)
- ✅ Table expiration automates data lifecycle

### Performance Tuning
- ✅ Analyze query execution plans with EXPLAIN
- ✅ Monitor query history for optimization opportunities
- ✅ Use materialized views for common aggregations
- ✅ Denormalize for read-heavy workloads
- ✅ Use nested/repeated fields to avoid JOINs

## 🔄 Next Steps

After mastering BigQuery optimization, you're ready for:

1. **Week 4: Analytics Engineering** - Transform data with dbt
2. **Week 5: Data Platforms** - Build production ELT pipelines
3. **Week 6: Batch Processing** - Process large datasets with Spark

---

<div align="center">

**📖 [Back to Main README](../README.md) | ⬅️ [Previous: Week 2](../02-workflow-orchestration/README.md) | ➡️ [Next: Week 4](../04-analytics-engineering/README.md)**

*Optimized with 🚀 BigQuery*

</div>