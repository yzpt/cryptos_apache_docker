from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, BinaryType, IntegerType, LongType, TimestampType

# Create Spark session
def create_spark_connection():
    s_conn = None

    try:
        s_conn = SparkSession.builder \
            .appName('SparkDataStreaming') \
            .config('spark.jars.packages', 'org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,org.postgresql:postgresql:42.6.0') \
            .getOrCreate()

        print("Spark connection created successfully!")
    except Exception as e:
        print(f"Couldn't create the Spark session due to exception: {e}")

    return s_conn

spark_conn = create_spark_connection()

# Define Kafka schema
kafka_schema = StructType([
    StructField("key", BinaryType(), True),
    StructField("value", BinaryType(), True),
    StructField("topic", StringType(), True),
    StructField("partition", IntegerType(), True),
    StructField("offset", LongType(), True),
    StructField("timestamp", TimestampType(), True),
    StructField("timestampType", IntegerType(), True)
])

# Connect to Kafka
def connect_to_kafka(spark_conn):
    spark_df = None
    try:
        spark_df = spark_conn.readStream \
            .format('kafka') \
            .option('kafka.bootstrap.servers', 'localhost:9092') \
            .option('subscribe', 'new_topic') \
            .option('startingOffsets', 'earliest') \
            .load()
        print("Kafka DataFrame created successfully")
    except Exception as e:
        print(f"Kafka DataFrame could not be created because: {e}")

    return spark_df

# Define the function to write each batch to PostgreSQL

def write_to_postgres(spark_df, batch_id):
    try:
        spark_df.write \
            .format("jdbc") \
            .option("url", "jdbc:postgresql://localhost:5432/spark") \
            .option("dbtable", "spark_table") \
            .option("user", "spark") \
            .option("password", "spark") \
            .mode("append") \
            .save()
    except Exception as e:
        print(f"Couldn't write to PostgreSQL due to exception: {e}")

# Connect to Kafka and write to PostgreSQL using streaming
if __name__ == "__main__":
    spark_df = connect_to_kafka(spark_conn)

    # Deserialize the 'value' column from Kafka as a string and 'timestamp' as a timestamp
    deserialized_df = spark_df.selectExpr("CAST(value AS STRING)", "CAST(timestamp AS TIMESTAMP)")

    # Define the streaming query
    query = deserialized_df \
        .writeStream \
        .outputMode('append') \
        .foreachBatch(write_to_postgres) \
        .start()

    # Wait for the termination of the query
    query.awaitTermination()
