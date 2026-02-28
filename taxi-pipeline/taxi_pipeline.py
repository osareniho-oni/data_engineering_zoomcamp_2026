import dlt
import duckdb
from dlt.sources.rest_api import rest_api_source

@dlt.source
def taxi_source():
    config = {
        "client": {
            "base_url": "https://us-central1-dlthub-analytics.cloudfunctions.net",
            "headers": {
                 "Content-Type": "application/json"
            }
        },
        "resources": [
            {
                "name": "taxi",
                "endpoint": {
                    "path": "data_engineering_zoomcamp_api",
                    "paginator": {
                        "type": "page_number",
                        "base_page": 1,
                        "total_path": None # Stops when an empty page is returned
                    }
                }
            }
        ]
    }

    return rest_api_source(config)

pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="duckdb",
    dataset_name="taxi_data",
)

load_info = pipeline.run(taxi_source())
print(load_info)