from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import EnvironmentSettings, StreamTableEnvironment


def create_hourly_tips_sink(t_env):
    """Create PostgreSQL sink table for hourly tip aggregation"""
    table_name = 'green_trips_hourly_tips'
    sink_ddl = f"""
        CREATE TABLE {table_name} (
            window_start TIMESTAMP(3),
            total_tip_amount DOUBLE,
            PRIMARY KEY (window_start) NOT ENFORCED
        ) WITH (
            'connector' = 'jdbc',
            'url' = 'jdbc:postgresql://postgres:5432/postgres',
            'table-name' = '{table_name}',
            'username' = 'postgres',
            'password' = 'postgres',
            'driver' = 'org.postgresql.Driver'
        );
        """
    t_env.execute_sql(sink_ddl)
    return table_name


def create_green_trips_source_kafka(t_env):
    """Create Kafka source table for green taxi trips with watermark"""
    table_name = "green_trips_source"
    source_ddl = f"""
        CREATE TABLE {table_name} (
            lpep_pickup_datetime STRING,
            lpep_dropoff_datetime STRING,
            PULocationID INT,
            DOLocationID INT,
            passenger_count DOUBLE,
            trip_distance DOUBLE,
            tip_amount DOUBLE,
            total_amount DOUBLE,
            event_timestamp AS TO_TIMESTAMP(lpep_pickup_datetime, 'yyyy-MM-dd''T''HH:mm:ss'),
            WATERMARK FOR event_timestamp AS event_timestamp - INTERVAL '5' SECOND
        ) WITH (
            'connector' = 'kafka',
            'properties.bootstrap.servers' = 'redpanda:29092',
            'topic' = 'green-trips',
            'scan.startup.mode' = 'earliest-offset',
            'properties.auto.offset.reset' = 'earliest',
            'format' = 'json',
            'json.fail-on-missing-field' = 'false',
            'json.ignore-parse-errors' = 'true'
        );
        """
    t_env.execute_sql(source_ddl)
    return table_name


def process_hourly_tips():
    """Process green taxi trips with 1-hour tumbling window for tip aggregation"""
    # Set up the execution environment
    env = StreamExecutionEnvironment.get_execution_environment()
    env.enable_checkpointing(10 * 1000)
    env.set_parallelism(1)  # Set to 1 since green-trips has 1 partition

    # Set up the table environment
    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    t_env = StreamTableEnvironment.create(env, environment_settings=settings)

    try:
        # Create Kafka source table
        source_table = create_green_trips_source_kafka(t_env)
        
        # Create PostgreSQL sink table
        tips_table = create_hourly_tips_sink(t_env)

        # Perform 1-hour tumbling window aggregation on tip_amount
        t_env.execute_sql(f"""
            INSERT INTO {tips_table}
            SELECT
                window_start,
                SUM(tip_amount) AS total_tip_amount
            FROM TABLE(
                TUMBLE(TABLE {source_table}, DESCRIPTOR(event_timestamp), INTERVAL '1' HOUR)
            )
            GROUP BY window_start
        """).wait()

    except Exception as e:
        print("Writing hourly tip aggregation from Kafka to JDBC failed:", str(e))


if __name__ == '__main__':
    process_hourly_tips()