# Week 4: Analytics Engineering - dbt (Data Build Tool)

[![dbt](https://img.shields.io/badge/dbt-FF694B?logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![SQL](https://img.shields.io/badge/SQL-CC2927?logo=microsoft-sql-server&logoColor=white)](https://en.wikipedia.org/wiki/SQL)
[![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/bigquery)
[![Jinja](https://img.shields.io/badge/Jinja-B41717?logo=jinja&logoColor=white)](https://jinja.palletsprojects.com/)

## 📋 Module Overview

This module introduces **Analytics Engineering** with **dbt (Data Build Tool)**, a modern framework for transforming data in your warehouse. You'll learn to build modular, tested, and documented data transformation pipelines using SQL and Jinja templating.

### Learning Objectives
- ✅ Understand analytics engineering principles and workflows
- ✅ Build multi-layer dbt projects (staging → intermediate → marts)
- ✅ Create reusable SQL macros with Jinja templating
- ✅ Implement data quality tests (schema, data, custom)
- ✅ Generate and maintain data documentation
- ✅ Use incremental models for large datasets
- ✅ Apply dimensional modeling techniques (facts & dimensions)
- ✅ Version control analytics code with Git

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      RAW DATA SOURCES                            │
│  BigQuery Tables (from Week 2 & 3):                             │
│  • yellow_tripdata (20M+ records)                               │
│  • green_tripdata (5M+ records)                                 │
│  • fhv_tripdata (For-Hire Vehicle data)                         │
│  • taxi_zone_lookup (reference data)                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ dbt source()
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STAGING LAYER                               │
│  Purpose: Clean, standardize, and type-cast raw data            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  stg_yellow_tripdata.sql                                 │  │
│  │  • Rename columns to standard naming                     │  │
│  │  • Cast data types (INTEGER, NUMERIC, TIMESTAMP)         │  │
│  │  • Filter out null vendor_id                             │  │
│  │  • Add service_type = 'yellow'                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  stg_green_tripdata.sql                                  │  │
│  │  • Same transformations as yellow                        │  │
│  │  • Add service_type = 'green'                            │  │
│  │  • Handle green-specific columns (trip_type)             │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  stg_fhv_tripdata.sql                                    │  │
│  │  • For-Hire Vehicle data                                 │  │
│  │  • Different schema from yellow/green                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ dbt ref()
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    INTERMEDIATE LAYER                            │
│  Purpose: Business logic, unions, enrichment                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  int_trips_unioned.sql                                   │  │
│  │  • UNION ALL yellow + green trips                        │  │
│  │  • Standardize column names across taxi types            │  │
│  │  • Handle schema differences                             │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  int_trips.sql                                           │  │
│  │  • Generate surrogate key (trip_id)                      │  │
│  │  • Join with payment_type_lookup                         │  │
│  │  • Calculate trip_duration_minutes (macro)               │  │
│  │  • Data quality filters                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ dbt ref()
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        MARTS LAYER                               │
│  Purpose: Business-ready tables for analytics & BI              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  DIMENSIONS (Slowly Changing Dimensions)                 │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  dim_zones.sql                                     │  │  │
│  │  │  • Zone lookup with borough info                   │  │  │
│  │  │  • Type 1 SCD (overwrite)                          │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  dim_vendors.sql                                   │  │  │
│  │  │  • Vendor master data                              │  │  │
│  │  │  • Hardcoded reference (seed alternative)          │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  FACTS (Transaction Tables)                              │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  fct_trips.sql (Incremental)                       │  │  │
│  │  │  • All trips with enriched zone names              │  │  │
│  │  │  • Star schema: fact + dimension joins             │  │  │
│  │  │  • Incremental strategy for performance            │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  REPORTING (Aggregated Metrics)                          │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  fct_monthly_zone_revenue.sql                      │  │  │
│  │  │  • Monthly revenue by zone                         │  │  │
│  │  │  • Pre-aggregated for dashboard performance        │  │  │
│  │  │  • Business KPIs (avg fare, trip count, revenue)   │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ANALYTICS & BI TOOLS                          │
│  • Looker / Tableau / Power BI                                  │
│  • Jupyter Notebooks                                            │
│  • Custom Applications                                          │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
04-analytics-engineering/
├── README.md                           # This file
├── main.py                            # Entry point script
├── pyproject.toml                     # Python dependencies
├── flows/                             # Kestra workflows (data ingestion)
│   ├── fhv_trip_data_2019.yaml
│   ├── ingest_fhv_to_gcs.yaml
│   └── load_fhv_to_bq.yaml
├── homework/                          # Assignment deliverables
│   ├── best_performing_zone_for_green_taxis_2020.png
│   ├── fhv_records_count.png
│   ├── green_taxi_trip_counts_october_2019.png
│   └── Records in fct_monthly_zone_revenue.png
├── logs/                              # dbt execution logs
│   ├── dbt.log
│   └── query_log.sql
└── taxi_rides_ny/                     # dbt project root
    ├── dbt_project.yml                # Project configuration
    ├── models/                        # SQL transformation models
    │   ├── staging/                   # Layer 1: Raw data cleaning
    │   │   ├── sources.yml            # Source definitions
    │   │   ├── schema.yml             # Model documentation & tests
    │   │   ├── stg_yellow_tripdata.sql
    │   │   ├── stg_green_tripdata.sql
    │   │   └── stg_fhv_tripdata.sql
    │   ├── intermediate/              # Layer 2: Business logic
    │   │   ├── schema.yml
    │   │   ├── int_trips_unioned.sql  # Union yellow + green
    │   │   └── int_trips.sql          # Enrichment & deduplication
    │   └── marts/                     # Layer 3: Analytics-ready
    │       ├── schema.yml
    │       ├── dim_zones.sql          # Dimension: Zones
    │       ├── dim_vendors.sql        # Dimension: Vendors
    │       ├── fct_trips.sql          # Fact: All trips
    │       └── reporting/
    │           ├── schema.yml
    │           └── fct_monthly_zone_revenue.sql
    ├── macros/                        # Reusable SQL functions
    │   ├── macros_properties.yml      # Macro documentation
    │   ├── get_trip_duration_minutes.sql
    │   ├── get_vendor_data.sql
    │   └── safe_cast.sql
    ├── seeds/                         # CSV reference data
    │   └── payment_type_lookup.csv
    ├── tests/                         # Custom data tests
    ├── snapshots/                     # Type 2 SCD tracking
    ├── dbt_packages/                  # Installed packages
    │   ├── dbt_utils/                 # Utility macros
    │   └── codegen/                   # Code generation
    └── target/                        # Compiled SQL (gitignored)
```

## 🛠️ Technology Stack

| Technology | Purpose | Key Features |
|------------|---------|--------------|
| **dbt Core** | Transformation framework | SQL-based, version controlled, tested |
| **BigQuery** | Data warehouse | Serverless, scalable, SQL interface |
| **Jinja** | Templating engine | Dynamic SQL, macros, control flow |
| **Git** | Version control | Collaboration, code review, history |
| **Python** | Scripting & automation | Data ingestion, testing |

## 🚀 Setup & Installation

### Prerequisites

```bash
# Python 3.11+
python --version

# pip or uv package manager
pip --version
# or
uv --version
```

### Step 1: Install dbt

```bash
# Navigate to project directory
cd 04-analytics-engineering

# Install dependencies (includes dbt-bigquery)
pip install dbt-bigquery

# Or using uv
uv sync

# Verify installation
dbt --version
```

### Step 2: Configure dbt Profile

Create `~/.dbt/profiles.yml`:

```yaml
taxi_rides_ny:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: <YOUR_GCP_PROJECT_ID>
      dataset: dbt_gabriel  # Your dev schema
      threads: 4
      timeout_seconds: 300
      location: US
      keyfile: /path/to/service-account-key.json
      
    prod:
      type: bigquery
      method: service-account
      project: <YOUR_GCP_PROJECT_ID>
      dataset: production  # Production schema
      threads: 8
      timeout_seconds: 300
      location: US
      keyfile: /path/to/service-account-key.json
```

### Step 3: Test Connection

```bash
cd taxi_rides_ny

# Test database connection
dbt debug

# Expected output:
# Connection test: [OK connection ok]
```

### Step 4: Install dbt Packages

```bash
# Install packages defined in packages.yml
dbt deps

# This installs:
# - dbt_utils (utility macros)
# - codegen (code generation helpers)
```

## 🎯 Running the Project

### Full Refresh (First Run)

```bash
cd taxi_rides_ny

# Run all models
dbt run

# Run with full refresh (rebuild incremental models)
dbt run --full-refresh

# Run specific model
dbt run --select stg_yellow_tripdata

# Run model and all downstream dependencies
dbt run --select stg_yellow_tripdata+
```

### Testing

```bash
# Run all tests
dbt test

# Test specific model
dbt test --select stg_yellow_tripdata

# Test specific test type
dbt test --select test_type:unique
dbt test --select test_type:not_null
```

### Documentation

```bash
# Generate documentation
dbt docs generate

# Serve documentation site
dbt docs serve

# Opens browser at http://localhost:8080
# Includes:
# - Lineage graph (DAG visualization)
# - Model descriptions
# - Column-level documentation
# - Test results
```

### Development Workflow

```bash
# 1. Create new model
touch models/staging/stg_new_source.sql

# 2. Develop model (use --select for faster iteration)
dbt run --select stg_new_source

# 3. Add tests in schema.yml
# 4. Run tests
dbt test --select stg_new_source

# 5. Generate documentation
dbt docs generate

# 6. Commit to Git
git add models/staging/stg_new_source.sql
git commit -m "Add new staging model"
```

## 📊 Model Examples

### Staging Model: stg_yellow_tripdata.sql

```sql
with source as (
    -- Reference raw source table
    select * from {{ source('wk1_tf_dataset', 'yellow_tripdata') }}
),

renamed as (
    select
        -- Identifiers
        cast(vendorid as integer) as vendor_id,
        {{ dbt.safe_cast('ratecodeid', 'integer') }} as rate_code_id,
        cast(pulocationid as integer) as pickup_location_id,
        cast(dolocationid as integer) as dropoff_location_id,
        
        -- Timestamps
        cast(tpep_pickup_datetime as timestamp) as pickup_datetime,
        cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,
        
        -- Trip info
        cast(store_and_fwd_flag as string) as store_and_fwd_flag,
        cast(passenger_count as integer) as passenger_count,
        cast(trip_distance as numeric) as trip_distance,
         
        -- Payment info
        cast(fare_amount as numeric) as fare_amount,
        cast(extra as numeric) as extra,
        cast(mta_tax as numeric) as mta_tax,
        cast(tip_amount as numeric) as tip_amount,
        cast(tolls_amount as numeric) as tolls_amount,
        cast(improvement_surcharge as numeric) as improvement_surcharge,
        cast(total_amount as numeric) as total_amount,
        {{ dbt.safe_cast('payment_type', 'integer') }} as payment_type,
        
        -- Add service type for union
        'yellow' as service_type

    from source
    -- Data quality: filter out null vendor_id
    where vendorid is not null
)

select * from renamed

-- dbt will compile this to:
-- CREATE OR REPLACE VIEW dbt_gabriel.stg_yellow_tripdata AS (...)
```

### Intermediate Model: int_trips.sql

```sql
with unioned as (
    select * from {{ ref('int_trips_unioned') }}
),

payment_types as (
    select * from {{ ref('payment_type_lookup') }}
),

cleaned_and_enriched as (
    select
        -- Generate surrogate key (MD5 hash of composite key)
        {{ dbt_utils.generate_surrogate_key([
            'u.vendor_id', 
            'u.pickup_datetime', 
            'u.pickup_location_id', 
            'u.service_type'
        ]) }} as trip_id,

        -- Identifiers
        u.vendor_id,
        u.service_type,
        u.rate_code_id,

        -- Locations
        u.pickup_location_id,
        u.dropoff_location_id,

        -- Timestamps
        u.pickup_datetime,
        u.dropoff_datetime,

        -- Trip details
        u.store_and_fwd_flag,
        u.passenger_count,
        u.trip_distance,
        u.trip_type,

        -- Payment breakdown
        u.fare_amount,
        u.extra,
        u.mta_tax,
        u.tip_amount,
        u.tolls_amount,
        u.improvement_surcharge,
        u.total_amount,
        u.payment_type,
        
        -- Enrichment: payment type description
        pt.description as payment_type_description,
        
        -- Calculated field using custom macro
        {{ get_trip_duration_minutes('u.pickup_datetime', 'u.dropoff_datetime') }} as trip_duration_minutes

    from unioned u
    left join payment_types pt on u.payment_type = pt.payment_type
    
    -- Data quality filters
    where u.trip_distance > 0
      and u.fare_amount > 0
      and u.pickup_datetime < u.dropoff_datetime
)

select * from cleaned_and_enriched
```

### Mart Model: fct_trips.sql (Incremental)

```sql
{{
  config(
    materialized='incremental',
    unique_key='trip_id',
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
  )
}}

-- Fact table: All trips with enriched zone information
-- Star schema design: fact + dimension joins

select
    -- Trip identifiers
    trips.trip_id,
    trips.vendor_id,
    trips.service_type,
    trips.rate_code_id,

    -- Location details (enriched with zone names)
    trips.pickup_location_id,
    pz.borough as pickup_borough,
    pz.zone as pickup_zone,
    trips.dropoff_location_id,
    dz.borough as dropoff_borough,
    dz.zone as dropoff_zone,

    -- Trip timing
    trips.pickup_datetime,
    trips.dropoff_datetime,
    trips.trip_duration_minutes,

    -- Trip metrics
    trips.passenger_count,
    trips.trip_distance,
    trips.trip_type,

    -- Payment breakdown
    trips.fare_amount,
    trips.extra,
    trips.mta_tax,
    trips.tip_amount,
    trips.tolls_amount,
    trips.improvement_surcharge,
    trips.total_amount,
    trips.payment_type,
    trips.payment_type_description

from {{ ref('int_trips') }} trips
left join {{ ref('dim_zones') }} pz on trips.pickup_location_id = pz.location_id
left join {{ ref('dim_zones') }} dz on trips.dropoff_location_id = dz.location_id

{% if is_incremental() %}
    -- Only process new records since last run
    where trips.pickup_datetime > (select max(pickup_datetime) from {{ this }})
{% endif %}
```

### Reporting Model: fct_monthly_zone_revenue.sql

```sql
-- Pre-aggregated monthly revenue by zone
-- Optimized for dashboard queries

select
    -- Time dimension
    date_trunc(pickup_datetime, month) as revenue_month,
    
    -- Location dimension
    pickup_zone,
    pickup_borough,
    
    -- Service type
    service_type,
    
    -- Aggregated metrics
    count(*) as trip_count,
    sum(fare_amount) as total_fare_amount,
    sum(extra) as total_extra,
    sum(mta_tax) as total_mta_tax,
    sum(tip_amount) as total_tip_amount,
    sum(tolls_amount) as total_tolls_amount,
    sum(improvement_surcharge) as total_improvement_surcharge,
    sum(total_amount) as total_revenue,
    
    -- Calculated metrics
    avg(fare_amount) as avg_fare_amount,
    avg(trip_distance) as avg_trip_distance,
    avg(trip_duration_minutes) as avg_trip_duration_minutes

from {{ ref('fct_trips') }}
where pickup_zone is not null
group by 
    revenue_month,
    pickup_zone,
    pickup_borough,
    service_type
```

## 🧪 Testing Framework

### Schema Tests (Built-in)

```yaml
# models/staging/schema.yml
version: 2

models:
  - name: stg_yellow_tripdata
    description: "Cleaned and standardized yellow taxi trip data"
    columns:
      - name: vendor_id
        description: "Taxi vendor identifier"
        tests:
          - not_null
          - accepted_values:
              values: [1, 2]
      
      - name: pickup_datetime
        description: "Trip start timestamp"
        tests:
          - not_null
      
      - name: trip_distance
        description: "Trip distance in miles"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      
      - name: fare_amount
        description: "Base fare amount"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "> 0"
```

### Custom Tests

```sql
-- tests/assert_positive_trip_duration.sql
-- Custom test: Ensure trip duration is positive

select *
from {{ ref('int_trips') }}
where trip_duration_minutes <= 0
```

### Data Quality Tests

```yaml
# models/intermediate/schema.yml
models:
  - name: int_trips
    tests:
      # Uniqueness test
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - trip_id
      
      # Referential integrity
      - dbt_utils.relationships_where:
          to: ref('dim_zones')
          field: location_id
          from_condition: pickup_location_id is not null
    
    columns:
      - name: trip_id
        tests:
          - unique
          - not_null
      
      - name: pickup_datetime
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "< dropoff_datetime"
```

## 🔧 Custom Macros

### Macro: get_trip_duration_minutes.sql

```sql
{#
    Calculate trip duration in minutes from pickup and dropoff timestamps.
    Uses dbt's built-in cross-database datediff macro.
    Works across DuckDB, BigQuery, Snowflake, Redshift, PostgreSQL.
#}

{% macro get_trip_duration_minutes(pickup_datetime, dropoff_datetime) %}
    {{ dbt.datediff(pickup_datetime, dropoff_datetime, 'minute') }}
{% endmacro %}

-- Usage in model:
-- {{ get_trip_duration_minutes('pickup_datetime', 'dropoff_datetime') }}
```

### Macro: get_vendor_data.sql

```sql
{#
    Return vendor name based on vendor_id.
    Demonstrates conditional logic in macros.
#}

{% macro get_vendor_data(vendor_id) %}
    case {{ vendor_id }}
        when 1 then 'Creative Mobile Technologies'
        when 2 then 'VeriFone Inc.'
        else 'Unknown'
    end
{% endmacro %}

-- Usage:
-- {{ get_vendor_data('vendor_id') }} as vendor_name
```

## 📈 Performance Optimization

### Incremental Models

```sql
{{
  config(
    materialized='incremental',
    unique_key='trip_id',
    incremental_strategy='merge',  -- or 'append', 'delete+insert'
    partition_by={
      'field': 'pickup_datetime',
      'data_type': 'timestamp',
      'granularity': 'day'
    },
    cluster_by=['pickup_location_id', 'service_type']
  )
}}

select * from {{ ref('source_model') }}

{% if is_incremental() %}
    -- Only process new data
    where pickup_datetime > (select max(pickup_datetime) from {{ this }})
{% endif %}
```

**Benefits**:
- ✅ Processes only new/changed data
- ✅ Reduces build time from hours to minutes
- ✅ Lower compute costs
- ✅ Enables near-real-time updates

### Partitioning & Clustering

```sql
{{
  config(
    partition_by={
      'field': 'pickup_date',
      'data_type': 'date',
      'granularity': 'day'
    },
    cluster_by=['service_type', 'pickup_location_id']
  )
}}
```

**Impact**:
- 70-90% cost reduction for date-filtered queries
- Faster query performance
- Automatic partition management

## 🎯 Homework Assignment

### Question 1: Green Taxi Trip Counts (October 2019)

```sql
-- Query the staging model
select count(*) as trip_count
from {{ ref('stg_green_tripdata') }}
where date(pickup_datetime) between '2019-10-01' and '2019-10-31';
```

**Answer**: See `homework/green_taxi_trip_counts_october_2019.png`

---

### Question 2: FHV Records Count

```sql
-- Count records in FHV staging model
select count(*) as fhv_record_count
from {{ ref('stg_fhv_tripdata') }};
```

**Answer**: See `homework/fhv_records_count.png`

---

### Question 3: Records in fct_monthly_zone_revenue

```sql
-- Count records in reporting model
select count(*) as revenue_record_count
from {{ ref('fct_monthly_zone_revenue') }};
```

**Answer**: See `homework/Records in fct_monthly_zone_revenue.png`

---

### Question 4: Best Performing Zone for Green Taxis (2020)

```sql
-- Find zone with highest revenue
select 
    pickup_zone,
    sum(total_revenue) as total_revenue_2020
from {{ ref('fct_monthly_zone_revenue') }}
where service_type = 'green'
  and extract(year from revenue_month) = 2020
group by pickup_zone
order by total_revenue_2020 desc
limit 1;
```

**Answer**: See `homework/best_performing_zone_for_green_taxis_2020.png`

## 💡 dbt Best Practices

### 1. Model Naming Conventions

```
stg_<source>_<entity>.sql      # Staging: stg_yellow_tripdata.sql
int_<entity>_<verb>.sql         # Intermediate: int_trips_unioned.sql
fct_<entity>.sql                # Fact: fct_trips.sql
dim_<entity>.sql                # Dimension: dim_zones.sql
rpt_<entity>.sql                # Report: rpt_monthly_revenue.sql
```

### 2. Model Organization

```
models/
├── staging/          # 1:1 with source tables
├── intermediate/     # Business logic, not exposed to BI
└── marts/           # Analytics-ready, exposed to BI
    ├── core/        # Shared across business units
    ├── finance/     # Finance-specific
    └── marketing/   # Marketing-specific
```

### 3. Documentation

```yaml
models:
  - name: fct_trips
    description: |
      **Fact table containing all taxi trips**
      
      This table combines yellow, green, and FHV taxi data with enriched
      location information from dim_zones. Updated incrementally daily.
      
      **Grain**: One row per trip
      **Refresh**: Daily at 2 AM UTC
      **Owner**: Analytics Team
    
    columns:
      - name: trip_id
        description: "Unique trip identifier (MD5 hash of composite key)"
        tests:
          - unique
          - not_null
```

### 4. Testing Strategy

```yaml
# Test pyramid: More tests at lower layers

staging/          # Heavy testing (data quality)
  - not_null
  - unique
  - accepted_values
  - relationships

intermediate/     # Business logic testing
  - custom tests
  - expression_is_true

marts/           # Light testing (already tested upstream)
  - unique
  - not_null (key columns only)
```

### 5. Version Control

```bash
# .gitignore
target/
dbt_packages/
logs/
*.pyc
.env

# Commit strategy
git add models/
git commit -m "feat: add monthly revenue reporting model"

# Use branches for development
git checkout -b feature/new-model
# ... develop ...
git push origin feature/new-model
# Create pull request for review
```

## 🐛 Common Issues & Solutions

### Issue 1: Model Not Found

```bash
# Error: Could not find model 'stg_yellow_tripdata'

# Solution: Check ref() syntax
{{ ref('stg_yellow_tripdata') }}  # ✅ Correct
{{ ref('staging.stg_yellow_tripdata') }}  # ❌ Wrong (no schema prefix)

# Verify model exists
ls models/staging/stg_yellow_tripdata.sql
```

### Issue 2: Circular Dependency

```bash
# Error: Circular dependency detected

# Solution: Review model dependencies
dbt list --select +fct_trips+

# Refactor to remove circular reference
# Models should flow: staging → intermediate → marts
```

### Issue 3: Incremental Model Not Updating

```bash
# Problem: Incremental model not picking up new data

# Solution 1: Full refresh
dbt run --select fct_trips --full-refresh

# Solution 2: Check incremental logic
{% if is_incremental() %}
    where pickup_datetime > (select max(pickup_datetime) from {{ this }})
{% endif %}

# Solution 3: Verify unique_key
config(unique_key='trip_id')  # Must be truly unique
```

### Issue 4: Test Failures

```bash
# Error: Test failed: unique_trip_id

# Debug: Run model and inspect
dbt run --select int_trips
dbt test --select int_trips

# Find duplicates
select trip_id, count(*)
from dbt_gabriel.int_trips
group by trip_id
having count(*) > 1;

# Fix: Adjust surrogate key generation
{{ dbt_utils.generate_surrogate_key(['vendor_id', 'pickup_datetime', 'pickup_location_id', 'service_type']) }}
```

## 📚 Learning Resources

### Official Documentation
- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [dbt Discourse Community](https://discourse.getdbt.com/)

### Packages
- [dbt_utils](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/)
- [dbt_expectations](https://hub.getdbt.com/calogica/dbt_expectations/latest/)
- [codegen](https://hub.getdbt.com/dbt-labs/codegen/latest/)

### Tutorials
- [dbt Learn](https://courses.getdbt.com/)
- [Analytics Engineering Guide](https://www.getdbt.com/analytics-engineering/)

## 🎓 Key Takeaways

### Analytics Engineering Principles
- ✅ Transform data in the warehouse (ELT, not ETL)
- ✅ Version control analytics code like software
- ✅ Test data transformations automatically
- ✅ Document models for collaboration
- ✅ Build modular, reusable components

### dbt Core Concepts
- ✅ Models are SELECT statements
- ✅ ref() creates dependencies (DAG)
- ✅ source() connects to raw data
- ✅ Macros enable code reuse
- ✅ Tests ensure data quality

### Data Modeling
- ✅ Staging: Clean and standardize
- ✅ Intermediate: Business logic
- ✅ Marts: Analytics-ready
- ✅ Facts: Transactions (large, growing)
- ✅ Dimensions: Attributes (small, stable)

### Performance
- ✅ Incremental models for large tables
- ✅ Partition by date for time-series
- ✅ Cluster by frequently filtered columns
- ✅ Materialize intermediate results
- ✅ Pre-aggregate for dashboards

## 🔄 Next Steps

After mastering dbt, you're ready for:

1. **Week 5: Data Platforms** - Modern ELT with Bruin
2. **Week 6: Batch Processing** - Large-scale processing with Spark
3. **Advanced dbt**: Snapshots, exposures, metrics

---

<div align="center">

**📖 [Back to Main README](../README.md) | ⬅️ [Previous: Week 3](../03-data-warehouse/README.md) | ➡️ [Next: Week 5](../05-data-platforms/README.md)**

*Transformed with 🔧 dbt*

</div>