import logging
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType,StructField,FloatType,IntegerType,StringType
from pyspark.sql.functions import from_json,col

# logging.basicConfig(level=logging.INFO,
#                     format='%(asctime)s:%(funcName)s:%(levelname)s:%(message)s')
# logger = logging.getLogger("spark_structured_streaming")


def create_spark_session():
    """
    Creates the Spark Session with suitable configs.
    """
    try:
        # Spark session is established with kafka jars. Suitable versions can be found in Maven repository.
        spark = SparkSession \
                .builder \
                .appName("SparkStructuredStreaming") \
                .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0") \
                .getOrCreate()
        spark.sparkContext.setLogLevel("ERROR")
        # logging.info('Spark session created successfully')
        print('Spark session created successfully')
    except Exception:
        # logging.error("Couldn't create the spark session")
        print("Couldn't create the spark session")

    return spark


def create_initial_dataframe(spark_session):
    """
    Reads the streaming data and creates the initial dataframe accordingly.
    """
    try:
        # Gets the streaming data from topic random_names
        df = spark_session \
              .readStream \
              .format("kafka") \
              .option("kafka.bootstrap.servers", "kafka:9092") \
              .option("subscribe", "random_names") \
              .option("delimeter",",") \
              .option("startingOffsets", "earliest") \
              .load()
            #   .selectExpr("CAST(key AS STRING)", "CAST(value AS STRING)")

        print("Initial dataframe created successfully")
    except Exception as e:
        print(f"Initial dataframe couldn't be created due to exception: {e}")

    return df

def create_final_dataframe(df, spark_session):
    """
    Modifies the initial dataframe, and creates the final dataframe.
    """
    schema = StructType([
                StructField("full_name",StringType(),False),
                StructField("gender",StringType(),False),
                StructField("location",StringType(),False),
                StructField("city",StringType(),False),
                StructField("country",StringType(),False),
                StructField("postcode",StringType(),False),
                StructField("latitude",FloatType(),False),
                StructField("longitude",FloatType(),False),
                StructField("email",StringType(),False)
            ])

    df = df.selectExpr("CAST(value AS STRING)").select(from_json(col("value"),schema).alias("data")).select("data.*")
    print(df)
    return df


def start_streaming(df):
    """
    Starts the streaming to table spark_streaming.random_names on console
    """
    # logging.info("Streaming is being started...")
    print("Streaming is being started...")
    my_query = (df.writeStream
                  .format("console")
                  .outputMode("append")
                  .option("checkpointLocation", "path/to/checkpoint/dir")
                  .start())

    return my_query.awaitTermination()


def write_streaming_data():
    spark = create_spark_session()
    df = create_initial_dataframe(spark)
    df_final = create_final_dataframe(df, spark)
    # df_final = df.selectExpr("CAST(value AS STRING)")
    start_streaming(df_final)


if __name__ == '__main__':

    try:
        write_streaming_data()
    except Exception as e:
        print('error')
        print(e)
