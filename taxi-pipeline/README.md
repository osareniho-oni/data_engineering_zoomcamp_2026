# NYC Taxi Data Pipeline - dlt (Data Load Tool)

[![dlt](https://img.shields.io/badge/dlt-FF6B6B?logo=python&logoColor=white)](https://dlthub.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?logo=duckdb&logoColor=black)](https://duckdb.org/)

## 📋 Project Overview

This project demonstrates **modern data ingestion** using **dlt (Data Load Tool)**, a Python library that simplifies building data pipelines. The pipeline fetches NYC taxi data from a REST API and loads it into DuckDB with automatic schema inference and incremental loading capabilities.

### What is dlt?

**dlt** is an open-source Python library that makes data loading simple and robust:
- ✅ **Declarative**: Define sources with simple Python decorators
- ✅ **Automatic Schema**: Infers and evolves schemas automatically
- ✅ **Incremental Loading**: Built-in support for incremental updates
- ✅ **Multiple Destinations**: DuckDB, BigQuery, Snowflake, PostgreSQL, and more
- ✅ **Data Quality**: Automatic validation and error handling
- ✅ **Observability**: Built-in logging and monitoring

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      DATA SOURCE                                 │
│  REST API: https://us-central1-dlthub-analytics.cloudfunctions  │
│  Endpoint: /data_engineering_zoomcamp_api                       │
│  • Paginated responses (page_number pagination)                 │
│  • JSON format                                                  │
│  • NYC taxi trip data                                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ dlt REST API Source
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DLT PIPELINE                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  @dlt.source: taxi_source()                              │  │
│  │  • REST API configuration                                │  │
│  │  • Pagination logic                                      │  │
│  │  • Resource definition                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│                             │ Extract & Transform                │
│                             ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  dlt.pipeline()                                          │  │
│  │  • Pipeline name: taxi_pipeline                          │  │
│  │  • Destination: DuckDB                                   │  │
│  │  • Dataset: taxi_data                                    │  │
│  │  • Automatic schema inference                            │  │
│  │  • Incremental loading support                           │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Load
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DUCKDB DATABASE                             │
│  File: taxi_pipeline.duckdb                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Schema: taxi_data                                       │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Table: taxi                                       │  │  │
│  │  │  • Auto-inferred schema                            │  │  │
│  │  │  • Normalized data                                 │  │  │
│  │  │  • Ready for analytics                             │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Table: _dlt_loads                                 │  │  │
│  │  │  • Load metadata                                   │  │  │
│  │  │  • Timestamps, status, row counts                  │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
taxi-pipeline/
├── README.md                    # This file
├── taxi_pipeline.py            # Main dlt pipeline script
├── main.py                     # Entry point
├── pyproject.toml              # Python dependencies
├── uv.lock                     # Dependency lock file
├── .python-version             # Python version specification
├── .gitignore                  # Git ignore rules
├── taxi_pipeline.duckdb        # DuckDB database (created after run)
├── .dlt/                       # dlt configuration directory
│   ├── config.toml            # Pipeline configuration
│   └── secrets.toml           # Credentials (gitignored)
├── .continue/                  # Continue.dev configuration
└── querying with gemini/       # Query examples and analysis
```

## 🛠️ Technology Stack

| Technology | Purpose | Key Features |
|------------|---------|--------------|
| **dlt** | Data loading framework | Schema inference, incremental loading |
| **DuckDB** | Embedded analytics database | Fast, SQL interface, no server needed |
| **Python** | Programming language | Simple, readable, extensive libraries |
| **REST API** | Data source | Paginated, JSON responses |

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

### Step 1: Install Dependencies

```bash
# Navigate to project directory
cd taxi-pipeline

# Install dependencies
pip install dlt[duckdb] duckdb

# Or using uv
uv sync

# Verify installation
python -c "import dlt; print(dlt.__version__)"
```

### Step 2: Run the Pipeline

```bash
# Run the pipeline
python taxi_pipeline.py

# Expected output:
# Pipeline taxi_pipeline load step completed in X.XX seconds
# 1 load package(s) were loaded to destination duckdb and into dataset taxi_data
# The duckdb destination used duckdb:////path/to/taxi_pipeline.duckdb location to store data
# Load package XXXX is LOADED and contains no failed jobs
```

## 📊 Pipeline Code Explained

### taxi_pipeline.py

```python
import dlt
import duckdb
from dlt.sources.rest_api import rest_api_source

# Define data source using @dlt.source decorator
@dlt.source
def taxi_source():
    """
    Configure REST API source for NYC taxi data.
    
    Returns:
        dlt source object with REST API configuration
    """
    config = {
        "client": {
            # Base URL for the API
            "base_url": "https://us-central1-dlthub-analytics.cloudfunctions.net",
            "headers": {
                "Content-Type": "application/json"
            }
        },
        "resources": [
            {
                "name": "taxi",  # Resource name (becomes table name)
                "endpoint": {
                    "path": "data_engineering_zoomcamp_api",  # API endpoint
                    "paginator": {
                        "type": "page_number",  # Pagination type
                        "base_page": 1,         # Start from page 1
                        "total_path": None      # Stop when empty page returned
                    }
                }
            }
        ]
    }
    
    return rest_api_source(config)

# Create pipeline
pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",  # Pipeline identifier
    destination="duckdb",           # Target database
    dataset_name="taxi_data",       # Schema/dataset name
)

# Run pipeline (extract, normalize, load)
load_info = pipeline.run(taxi_source())

# Print load information
print(load_info)
```

### Key Components

1. **@dlt.source Decorator**: Marks function as a dlt data source
2. **rest_api_source()**: Built-in dlt helper for REST APIs
3. **Pagination**: Automatically handles paginated responses
4. **pipeline.run()**: Executes the full ETL process
5. **load_info**: Contains metadata about the load operation

## 🔍 Querying the Data

### Using Python

```python
import duckdb

# Connect to DuckDB database
conn = duckdb.connect('taxi_pipeline.duckdb')

# Query the data
result = conn.execute("""
    SELECT COUNT(*) as total_records
    FROM taxi_data.taxi
""").fetchall()

print(f"Total records: {result[0][0]}")

# Explore schema
schema = conn.execute("""
    DESCRIBE taxi_data.taxi
""").fetchall()

for column in schema:
    print(f"{column[0]}: {column[1]}")

# Sample data
sample = conn.execute("""
    SELECT * FROM taxi_data.taxi LIMIT 5
""").fetchdf()  # Returns pandas DataFrame

print(sample)

conn.close()
```

### Using DuckDB CLI

```bash
# Open DuckDB CLI
duckdb taxi_pipeline.duckdb

# List tables
SHOW TABLES;

# Describe table schema
DESCRIBE taxi_data.taxi;

# Query data
SELECT COUNT(*) FROM taxi_data.taxi;

SELECT * FROM taxi_data.taxi LIMIT 10;

# Check load metadata
SELECT * FROM taxi_data._dlt_loads;

# Exit
.quit
```

### Common Queries

```sql
-- Total records
SELECT COUNT(*) as total_records FROM taxi_data.taxi;

-- Records by vendor
SELECT 
    VendorID,
    COUNT(*) as trip_count
FROM taxi_data.taxi
GROUP BY VendorID;

-- Average fare by passenger count
SELECT 
    passenger_count,
    AVG(fare_amount) as avg_fare,
    COUNT(*) as trip_count
FROM taxi_data.taxi
WHERE passenger_count > 0
GROUP BY passenger_count
ORDER BY passenger_count;

-- Top pickup locations
SELECT 
    PULocationID,
    COUNT(*) as pickup_count
FROM taxi_data.taxi
GROUP BY PULocationID
ORDER BY pickup_count DESC
LIMIT 10;

-- Load history
SELECT 
    load_id,
    schema_name,
    status,
    inserted_at,
    finished_at
FROM taxi_data._dlt_loads
ORDER BY inserted_at DESC;
```

## 🔧 Advanced Features

### 1. Incremental Loading

```python
import dlt
from dlt.sources.rest_api import rest_api_source

@dlt.source
def taxi_source_incremental():
    config = {
        "client": {
            "base_url": "https://us-central1-dlthub-analytics.cloudfunctions.net",
        },
        "resources": [
            {
                "name": "taxi",
                "endpoint": {
                    "path": "data_engineering_zoomcamp_api",
                    "paginator": {
                        "type": "page_number",
                        "base_page": 1,
                    }
                },
                # Enable incremental loading
                "write_disposition": "append",  # or "merge", "replace"
                "primary_key": "trip_id",       # Unique identifier
            }
        ]
    }
    return rest_api_source(config)

# Run with incremental loading
pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="duckdb",
    dataset_name="taxi_data",
)

load_info = pipeline.run(
    taxi_source_incremental(),
    write_disposition="append"  # Append new data
)
```

### 2. Custom Transformations

```python
import dlt
from dlt.sources.rest_api import rest_api_source

@dlt.source
def taxi_source_with_transform():
    config = {
        # ... API configuration ...
    }
    
    # Get raw data
    source = rest_api_source(config)
    
    # Apply transformation
    @dlt.transformer(data_from=source.taxi)
    def add_calculated_fields(item):
        """Add calculated fields to each record"""
        # Calculate trip duration
        if 'pickup_datetime' in item and 'dropoff_datetime' in item:
            from datetime import datetime
            pickup = datetime.fromisoformat(item['pickup_datetime'])
            dropoff = datetime.fromisoformat(item['dropoff_datetime'])
            item['trip_duration_minutes'] = (dropoff - pickup).total_seconds() / 60
        
        # Calculate tip percentage
        if item.get('fare_amount', 0) > 0:
            item['tip_percentage'] = (item.get('tip_amount', 0) / item['fare_amount']) * 100
        
        return item
    
    return add_calculated_fields

pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="duckdb",
    dataset_name="taxi_data",
)

load_info = pipeline.run(taxi_source_with_transform())
```

### 3. Multiple Destinations

```python
# Load to BigQuery instead of DuckDB
pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="bigquery",
    dataset_name="taxi_data",
)

# Load to Snowflake
pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="snowflake",
    dataset_name="taxi_data",
)

# Load to PostgreSQL
pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="postgres",
    dataset_name="taxi_data",
)
```

### 4. Configuration Management

```toml
# .dlt/config.toml

[sources.taxi_source]
base_url = "https://us-central1-dlthub-analytics.cloudfunctions.net"

[destination.duckdb]
credentials = "taxi_pipeline.duckdb"

[destination.bigquery]
location = "US"
```

```toml
# .dlt/secrets.toml (gitignored)

[destination.bigquery.credentials]
project_id = "your-project-id"
private_key = "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
client_email = "your-service-account@project.iam.gserviceaccount.com"
```

## 📈 Monitoring & Observability

### Load Information

```python
load_info = pipeline.run(taxi_source())

# Print detailed load information
print(f"Pipeline: {load_info.pipeline.pipeline_name}")
print(f"Destination: {load_info.pipeline.destination}")
print(f"Dataset: {load_info.pipeline.dataset_name}")
print(f"Load ID: {load_info.loads_ids[0]}")

# Check for errors
if load_info.has_failed_jobs:
    print("Load failed!")
    for job in load_info.load_packages[0].jobs['failed_jobs']:
        print(f"Failed job: {job.job_file_info.job_id()}")
        print(f"Error: {job.failed_message}")
else:
    print("Load successful!")
    
# Row counts
for package in load_info.load_packages:
    for table_name, table_metrics in package.schema_update.items():
        print(f"Table: {table_name}")
        print(f"Rows: {table_metrics}")
```

### Logging

```python
import logging

# Enable dlt logging
logging.basicConfig(level=logging.INFO)

# Run pipeline with logging
load_info = pipeline.run(taxi_source())
```

### Load History

```sql
-- Query load history
SELECT 
    load_id,
    schema_name,
    status,
    inserted_at,
    finished_at,
    TIMESTAMPDIFF('second', inserted_at, finished_at) as duration_seconds
FROM taxi_data._dlt_loads
ORDER BY inserted_at DESC;

-- Failed loads
SELECT * FROM taxi_data._dlt_loads
WHERE status = 'failed';
```

## 💡 dlt Best Practices

### 1. Use Explicit Schemas

```python
from dlt.common.schema.typing import TTableSchema

# Define explicit schema
taxi_schema: TTableSchema = {
    "name": "taxi",
    "columns": {
        "trip_id": {"data_type": "bigint", "nullable": False},
        "vendor_id": {"data_type": "bigint"},
        "pickup_datetime": {"data_type": "timestamp"},
        "fare_amount": {"data_type": "double"},
    },
    "primary_key": ["trip_id"]
}

# Use in pipeline
pipeline.run(taxi_source(), schema=taxi_schema)
```

### 2. Handle Errors Gracefully

```python
try:
    load_info = pipeline.run(taxi_source())
    
    if load_info.has_failed_jobs:
        # Log errors
        for job in load_info.load_packages[0].jobs['failed_jobs']:
            print(f"Error: {job.failed_message}")
        # Optionally retry
        load_info = pipeline.run(taxi_source())
        
except Exception as e:
    print(f"Pipeline failed: {e}")
    # Implement retry logic or alerting
```

### 3. Use Incremental Loading

```python
# For large datasets, use incremental loading
@dlt.resource(
    write_disposition="merge",
    primary_key="trip_id",
    merge_key="pickup_datetime"
)
def taxi_incremental():
    # Fetch only new data
    last_load = pipeline.last_trace.finished_at
    # ... fetch data since last_load ...
```

### 4. Test with Sample Data

```python
# Test with limited data first
@dlt.source
def taxi_source_sample():
    config = {
        # ... configuration ...
        "resources": [
            {
                "name": "taxi",
                "endpoint": {
                    "path": "data_engineering_zoomcamp_api",
                    "params": {
                        "limit": 100  # Limit for testing
                    }
                }
            }
        ]
    }
    return rest_api_source(config)
```

## 🐛 Common Issues & Solutions

### Issue 1: Connection Timeout

```python
# Solution: Increase timeout
config = {
    "client": {
        "base_url": "...",
        "timeout": 300  # 5 minutes
    }
}
```

### Issue 2: Schema Evolution Errors

```python
# Solution: Enable schema evolution
pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="duckdb",
    dataset_name="taxi_data",
    dev_mode=True  # Allows schema changes
)
```

### Issue 3: Memory Issues with Large Datasets

```python
# Solution: Use batching
@dlt.resource(
    write_disposition="append",
    batch_size=1000  # Process in batches
)
def taxi_batched():
    # ... fetch data in batches ...
```

## 📚 Learning Resources

### Official Documentation
- [dlt Documentation](https://dlthub.com/docs)
- [dlt REST API Source](https://dlthub.com/docs/dlt-ecosystem/verified-sources/rest_api)
- [DuckDB Documentation](https://duckdb.org/docs/)

### Tutorials
- [dlt Quickstart](https://dlthub.com/docs/getting-started)
- [Building REST API Sources](https://dlthub.com/docs/tutorial/rest-api)
- [Incremental Loading Guide](https://dlthub.com/docs/general-usage/incremental-loading)

### Community
- [dlt Slack Community](https://dlthub.com/community)
- [GitHub Repository](https://github.com/dlt-hub/dlt)

## 🎓 Key Takeaways

### dlt Advantages
- ✅ **Simple API**: Pythonic, decorator-based design
- ✅ **Automatic Schema**: No manual schema definition needed
- ✅ **Incremental Loading**: Built-in support for updates
- ✅ **Multiple Destinations**: Easy to switch between databases
- ✅ **Data Quality**: Automatic validation and normalization
- ✅ **Observability**: Built-in logging and monitoring

### When to Use dlt
- ✅ Rapid prototyping of data pipelines
- ✅ Loading data from REST APIs
- ✅ Simple ETL workflows
- ✅ Local development with DuckDB
- ✅ Cloud deployment to BigQuery, Snowflake, etc.

### dlt vs Other Tools
| Feature | dlt | Airbyte | Fivetran |
|---------|-----|---------|----------|
| **Open Source** | ✅ Yes | ✅ Yes | ❌ No |
| **Python-native** | ✅ Yes | ❌ No | ❌ No |
| **Schema Inference** | ✅ Automatic | ⚠️ Manual | ✅ Automatic |
| **Custom Logic** | ✅ Easy | ⚠️ Complex | ❌ Limited |
| **Cost** | Free | Free/Paid | Paid |

## 🔄 Next Steps

After mastering dlt, explore:

1. **Advanced Transformations**: Complex data cleaning and enrichment
2. **Custom Sources**: Build sources for proprietary APIs
3. **Production Deployment**: Deploy pipelines to cloud platforms
4. **Monitoring**: Integrate with observability tools
5. **Data Quality**: Implement comprehensive validation rules

---

<div align="center">

**📖 [Back to Main README](../README.md)**

*Built with 🚀 dlt (Data Load Tool)*

</div>