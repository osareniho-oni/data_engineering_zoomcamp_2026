from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import EnvironmentSettings, StreamTableEnvironment


def create_green_trips_session_sink(t_env):
    """Create PostgreSQL sink table for session window results"""
    table_name = 'green_trips_sessions'
    sink_ddl = f"""
        CREATE TABLE {table_name} (
            window_start TIMESTAMP(3),
            window_end TIMESTAMP(3),
            PULocationID INT,
            num_trips BIGINT,
            PRIMARY KEY (window_start, window_end, PULocationID) NOT ENFORCED
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


def process_green_trips_session_window():
    """Process green taxi trips with 5-minute session window"""
    # Set up the execution environment
    env = StreamExecutionEnvironment.get_execution_environment()
    # Disable checkpointing for session windows to avoid state size issues
    # Session windows can have large state due to maintaining all active sessions
    env.set_parallelism(1)  # Set to 1 since green-trips has 1 partition

    # Set up the table environment
    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    t_env = StreamTableEnvironment.create(env, environment_settings=settings)

    try:
        # Create Kafka source table
        source_table = create_green_trips_source_kafka(t_env)
        
        # Create PostgreSQL sink table
        session_table = create_green_trips_session_sink(t_env)

        # Perform session window aggregation and insert into PostgreSQL
        # SESSION window groups events within 5 minutes of each other
        t_env.execute_sql(f"""
            INSERT INTO {session_table}
            SELECT
                window_start,
                window_end,
                PULocationID,
                COUNT(*) AS num_trips
            FROM TABLE(
                SESSION(TABLE {source_table}, DESCRIPTOR(event_timestamp), INTERVAL '5' MINUTE)
            )
            GROUP BY window_start, window_end, PULocationID
        """).wait()

    except Exception as e:
        print("Writing session window aggregation from Kafka to JDBC failed:", str(e))


if __name__ == '__main__':
    process_green_trips_session_window()