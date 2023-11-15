import logging
from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json,col,from_unixtime
from pyspark.sql.functions import unix_timestamp
from pyspark.sql.types import StructType,StructField,FloatType,IntegerType,StringType, LongType
from pyspark.sql.functions import from_unixtime, col, substring
import uuid
from pyspark.sql.functions import monotonically_increasing_id
from pyspark.sql.functions import udf

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
                .config("spark.jars.packages", "com.datastax.spark:spark-cassandra-connector_2.12:3.4.1,org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1") \
                .config("spark.cassandra.connection.host", "cassandra") \
                .config("spark.cassandra.connection.port","9042")\
                .config("spark.cassandra.auth.username", "cassandra") \
                .config("spark.cassandra.auth.password", "cassandra") \
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
              .option("subscribe", "crypto_trades") \
              .option("delimeter",",") \
              .option("startingOffsets", "earliest") \
              .option("failOnDataLoss", "false") \
              .load()

        print("Initial dataframe created successfully")
    except Exception as e:
        print(f"Initial dataframe couldn't be created due to exception: {e}")

    return df



def create_final_dataframe(df, spark_session):
    """
    Modifies the initial dataframe, and creates the final dataframe.
    """
    schema = StructType([
                StructField("symbol",StringType(),False),
                StructField("price",FloatType(),False),
                StructField("volume",FloatType(),False),
                StructField("timestamp_unix",LongType(),False),
                StructField("conditions",StringType(),False)        
            ])

    df = df.selectExpr("CAST(value AS STRING)").select(from_json(col("value"),schema).alias("data")).select("data.*")
    # df = df.withColumn("datetime",from_unixtime(col("timestamp_unix")/1000))
    # df = df.withColumn("datetime", from_unixtime(col("timestamp_unix")/1000, 'yyyy-MM-dd HH:mm:ss.SSS'))
    # df drop column timestamp_unix:
    # df = df.drop("timestamp_unix")
    # df = df.withColumn("id", monotonically_increasing_id())
    uuidUdf= udf(lambda : str(uuid.uuid4()),StringType())
    df = df.withColumn("id", uuidUdf())    
    print(df)
    return df



def start_console_streaming(df):
    """
    Starts the streaming to table spark_streaming.random_names on console
    """
    # logging.info("Streaming is being started...")
    print("Streaming is being started...")
    my_query = (df.writeStream
                  .format("console")
                  .outputMode("append")
                  .start())

    return my_query.awaitTermination()

def print_to_console(df, epoch_id):
    df.show()

def start_cassandra_streaming(df):
    """
    Starts the streaming to table spark_streaming.random_names in cassandra
    """
    logging.info("Streaming is being started...")
    my_query = (df.writeStream
                  .format("org.apache.spark.sql.cassandra")
                  .outputMode("append")
                  .option("checkpointLocation", "checkpoint")
                  .options(table="crypto_trades", keyspace="spark_streaming")
                  .foreachBatch(print_to_console)
                  .start())

    return my_query.awaitTermination()


def write_streaming_data():
    spark = create_spark_session()
    df = create_initial_dataframe(spark)
    df_final = create_final_dataframe(df, spark)
    start_cassandra_streaming(df_final)
    # start_console_streaming(df_final)

if __name__ == '__main__':
    try:
        write_streaming_data()
    except Exception as e:
        print('error')
        print(e)
