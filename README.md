## Deploying a Docker multi-container architecture (Airflow, Kafka, Spark, and Cassandra)

![project diagram](./img/diagram_cryptos_png.png)

<hr>

I am replicating and customizing the great project from [Dogukan Ulu](https://dogukanulu.dev/) :

* [Data Engineering End-to-End Project — Spark, Kafka, Airflow, Docker, Cassandra, Python](https://medium.com/@dogukannulu/data-engineering-end-to-end-project-1-7a7be2a3671)

* Github repo : [https://github.com/dogukannulu/kafka_spark_structured_streaming](https://github.com/dogukannulu/kafka_spark_structured_streaming)

I have chosen to use some anothers and latest images available on 2023-11-06 from [Docker Hub](https://hub.docker.com/) for the following services:

<div style="display:flex; justify-content:center; width:100%">
<table>
<tr><th>service</th><th>image</th><th></th></tr>
<tr><td>KRaft</td><td>bitnami/kafka:3.6</td><td>Implementing KRaft mode : <a href="https://developer.confluent.io/learn/kraft/">Kafka Without ZooKeeper</a><br><a href="https://hub.docker.com/r/bitnami/kafka">https://hub.docker.com/r/bitnami/kafka</a></td></tr>
<tr><td>webserver<br>scheduler</td><td>apache/airflow:2.7.2-python3.10</td><td><a href="https://airflow.apache.org/docs/docker-stack/index.html">https://airflow.apache.org/docs/docker-stack/index.html</a></tr>
<tr><td>postgres</td><td>postgres:16</td><td><a href="https://hub.docker.com/_/postgres">https://hub.docker.com/_/postgres</a></td>
<tr><td>spark-master<br>spark-worker</td><td>bitnami/spark:3.5.0</td><td><a href="https://hub.docker.com/r/bitnami/spark">https://hub.docker.com/r/bitnami/spark</td></tr>
<tr><td>postgresql</td><td>bitnami/postgresql:16</td><td><a href="https://hub.docker.com/r/bitnami/spark">https://hub.docker.com/r/bitnami/postgresql</td></tr>
</table>
</div>



Cassandra's driver doesn't support spark 3.5.0 yet, i'll replace it by postgresql or and/or mongoDB.

I gained extensive knowledge about Docker, dependency management while replicating this project, and i liked the CI/CD process. This newfound interest led me to opt for migrating to GCP Kubernetes Engine (see my on going project [Spark on Kubernetes repo](https://github.com/yzpt/spark_on_kubernetes/))

## 1. Airflow

### 1.1. Setup

```bash
pip install "apache-airflow[celery]==2.7.2" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.2/constraints-3.10.txt"
```


### 1.1. DAG

## -- work in progress --


## 2. Kafka

### 2.1. yaml file

```yaml
services:
  kafka:
    image: 'bitnami/kafka:latest'
    networks:
      - cluster-network
    environment:
      - KAFKA_CFG_NODE_ID=0
      - KAFKA_CFG_PROCESS_ROLES=controller,broker
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@<localhost>:9093
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093,EXTERNAL://:9094
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092,EXTERNAL://localhost:9094
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT,PLAINTEXT:PLAINTEXT
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
    ports:
      - '9092:9092'
      - '9094:9094'
```

### 2.2. Start the Kafka broker with docker-compose

```bash
docker-compose up -d kafka
```

### 2.3. Checking the Kafka topic messages with the kafka-console-consumer

```bash 
TOPIC="trades_topic"
SERVER="kafka:9092"

# list the topics
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server $SERVER

# send a message to the topic
echo "Hello" | docker compose exec -T kafka opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $TOPIC --bootstrap-server $SERVER

# open prompt to send messages to the topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $TOPIC --bootstrap-server $SERVER

# get the streamed messages from the topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic $TOPIC --from-beginning --bootstrap-server $SERVER

# delete a topic:
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --delete --topic $TOPIC --bootstrap-server $SERVER
```

## 3. Spark

### 3.1. yaml file
    
```yaml
  spark-master:
    image: bitnami/spark:3.5.0
    command: bin/spark-class org.apache.spark.deploy.master.Master
    ports:
      - "9090:8080"
      - "7077:7077"
    volumes:
      - ./volume_spark_master_jars:/opt/bitnami/jars
      - ./volume_spark_master_scripts:/opt/bitnami/pyspark_scripts
    networks:
      - cluster-network
  
  spark-worker:
    image: bitnami/spark:3.5.0
    command: bin/spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077
    depends_on:
      - spark-master
    environment:
      SPARK_MODE: worker
      SPARK_WORKER_CORES: 2
      SPARK_WORKER_MEMORY: 1g
      SPARK_MASTER_URL: spark://spark-master:7077
    volumes:
      - ./volume_spark_worker_jars:/opt/bitnami/jars
    networks:
      - cluster-network
```

### 3.2. Spark script: spark_streaming.py

```python
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
            .option('kafka.bootstrap.servers', 'kafka:9092') \
            .option('subscribe', 'my_new_topic') \
            .option('starting   Offsets', 'earliest') \
            .load()
        print("kafka dataframe created successfully")
    except Exception as e:
        print(f"kafka dataframe could not be created because: {e}")

    return spark_df

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

if __name__ == "__main__":
    # create spark connection
    spark_conn = create_spark_connection()
    
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
```

