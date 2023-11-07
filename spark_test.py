from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    from_json,
    col,
    explode
)
from pyspark.sql.types import (
    StructType,
    StructField,
    StringType,
    FloatType,
    LongType,
    ArrayType
)


def create_spark_connection():
    s_conn = None

    try:
        s_conn = SparkSession.builder \
            .appName('SparkDataStreaming') \
            .config('spark.jars.packages', "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0") \
            .getOrCreate()

        s_conn.sparkContext.setLogLevel("ERROR")
        print("Spark connection created successfully!")
    except Exception as e:
        print(f"Couldn't create the spark session due to exception {e}")

    return s_conn


def connect_to_kafka(spark_conn):
    spark_df = None
    try:
        spark_df = spark_conn.readStream \
            .format('kafka') \
            .option('kafka.bootstrap.servers', 'localhost:9092') \
            .option('subscribe', 'trades_topic') \
            .option('startingOffsets', 'earliest') \
            .load()
        print("kafka dataframe created successfully")
    except Exception as e:
        print(f"kafka dataframe could not be created because: {e}")

    return spark_df

# === message structure example : =====
# {
#     "data": [
#         {
#             "c": null,
#             "p": 34851.9,
#             "s": "BINANCE:BTCUSDT",
#             "t": 1699351036478,
#             "v": 0.00014
#         },
#         {
#             "c": null,
#             "p": 34851.89,
#             "s": "BINANCE:BTCUSDT",
#             "t": 1699351036955,
#             "v": 0.01
#         },
#         {
#             "c": null,
#             "p": 34851.89,
#             "s": "BINANCE:BTCUSDT",
#             "t": 1699351037011,
#             "v": 0.00029
#         }
#     ],
#     "type": "trade"
# }
# === end of message structure example  =====


def create_selection_df_from_kafka(spark_df):
    inner_schema = StructType([
        StructField("s", StringType(), True),
        StructField("p", FloatType(), True),
        StructField("t", LongType(), True),
        StructField("v", FloatType(), True),
        StructField("c", StringType(), True)
    ])

    outer_schema = StructType([
        StructField("data", ArrayType(inner_schema), True),
        StructField("type", StringType(), True)
    ])

    sel = spark_df.selectExpr("CAST(value AS STRING) as value") \
        .select(from_json(col('value'), outer_schema).alias('data')) \
        .select(explode(col("data.data")).alias("data")) \
        .select("data.*")
    
    return sel



def connect_to_kafka_and_print_raw_data(spark_conn):
    spark_df = None
    try:
        spark_df = spark_conn.readStream \
            .format('kafka') \
            .option('kafka.bootstrap.servers', 'localhost:9092') \
            .option('subscribe', 'trades_topic') \
            .option('startingOffsets', 'earliest') \
            .load()

        raw_query = spark_df \
            .writeStream \
            .format("console") \
            .start()

        raw_query.awaitTermination()

        print("kafka dataframe created successfully")
    except Exception as e:
        print(f"kafka dataframe could not be created because: {e}")

    return spark_df


if __name__ == "__main__":
    # create spark connection
    spark_conn = create_spark_connection()
    
    # connect_to_kafka_and_print_raw_data(spark_conn)

    if spark_conn is not None:
        # connect to kafka with spark connection
        spark_df = connect_to_kafka(spark_conn)
        selection_df = create_selection_df_from_kafka(spark_df)

        print("Streaming is being started...")

        streaming_query = selection_df \
            .writeStream \
            .format("console") \
            .start()

        streaming_query.awaitTermination()
