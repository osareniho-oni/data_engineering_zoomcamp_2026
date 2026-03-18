from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import EnvironmentSettings, StreamTableEnvironment


def create_green_trips_sink_postgres(t_env):
    """Create PostgreSQL sink table for green taxi trips analysis"""
    table_name = 'green_trips_analysis'
    sink_ddl = f"""
        CREATE TABLE {table_name} (
            PULocationID INTEGER,
            DOLocationID INTEGER,
            passenger_count DOUBLE,
            trip_distance DOUBLE,
            tip_amount DOUBLE,
            total_amount DOUBLE,
            pickup_datetime TIMESTAMP(3),
            dropoff_datetime TIMESTAMP(3)
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
    """Create Kafka source table for green taxi trips"""
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
            pickup_timestamp AS TO_TIMESTAMP(lpep_pickup_datetime, 'yyyy-MM-dd''T''HH:mm:ss'),
            dropoff_timestamp AS TO_TIMESTAMP(lpep_dropoff_datetime, 'yyyy-MM-dd''T''HH:mm:ss'),
            WATERMARK FOR pickup_timestamp AS pickup_timestamp - INTERVAL '5' SECOND
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


def process_green_trips():
    """Process green taxi trips and filter trips with distance > 5.0"""
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
        sink_table = create_green_trips_sink_postgres(t_env)
        
        # Insert filtered data (only trips with distance > 5.0) into PostgreSQL
        t_env.execute_sql(f"""
            INSERT INTO {sink_table}
            SELECT
                PULocationID,
                DOLocationID,
                passenger_count,
                trip_distance,
                tip_amount,
                total_amount,
                pickup_timestamp as pickup_datetime,
                dropoff_timestamp as dropoff_datetime
            FROM {source_table}
            WHERE trip_distance > 5.0
        """).wait()

    except Exception as e:
        print("Writing records from Kafka to JDBC failed:", str(e))


if __name__ == '__main__':
    process_green_trips()