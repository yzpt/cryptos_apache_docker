
# === KRaft =====================================================================================================
# compose: kafka
# https://github.com/nanthakumaran-s/Learn-Kafka/

mkdir volume-kafka
sudo chmod -R 777 ./volume-kafka
docker compose up kafka -d

topic=crypto_trades
server=localhost:9092

# create topic
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --create --topic $topic --bootstrap-server $server
# list
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server $server
# describe
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --describe --topic $topic --bootstrap-server $server
# delete
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --delete --topic $topic --bootstrap-server $server

topic=crypto_trades
server=localhost:9092
# producer
echo "bjr bjr" | docker exec -i kafka opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $topic --bootstrap-server $server
echo "============================" | docker exec -i kafka opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $topic --bootstrap-server $server

# consumer
docker exec kafka opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic $topic --from-beginning --bootstrap-server $server


# === Airflow =====================================================================================================
# compose: webserver, scheduler, postgres
# > script/entrypoint.sh

# venv
python3 -m venv venv_airflow
source venv_airflow/bin/activate
pip install kafka-python
pip install "apache-airflow[celery]==2.7.2" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.2/constraints-3.10.txt"
pip freeze > requirements_airflow.txt

docker compose up -d


# === Spark =====================================================================================================
# compose: spark-master, spark-worker
pip install pyspark


# === running pyspark script localy
# need to add the line 
# 127.0.0.1 kafka
# inside the /etc/hosts file

python3 spark_streaming.py
# ok



# === running pyspark scrpt inside the container
curl -O https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.5.0/spark-sql-kafka-0-10_2.12-3.5.0.jar
docker cp ./spark-sql-kafka-0-10_2.12-3.5.0.jar kraft-spark-master-1:/opt/bitnami/spark/jars/


docker cp ./spark_streaming.py kraft-spark-master-1:/opt/bitnami/pyspark_scripts/
# docker cp ./kafka-clients-3.6.0.jar kraft-spark-master-1:/opt/bitnami/spark/jars/

docker exec -it kraft-spark-master-1 /bin/bash
# ===> inside container
spark-shell --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,org.apache.kafka:kafka-clients:3.6.0
spark-shell --jars opt/bitnami/spark/jars/spark-sql-kafka-0-10_2.12-3.5.0.jar,opt/bitnami/spark/jars/kafka-clients-3.6.0.jar


spark-shell --jars opt/bitnami/spark/jars/
val df = spark.readStream.format("kafka").option("kafka.bootstrap.servers", "kafka:9092").option("subscribe", "random_names").option("delimeter",",").option("startingOffsets", "earliest").load()


spark-submit --master local[2] --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,org.apache.kafka:kafka-clients:3.6.0 /opt/bitnami/pyspark_scripts/spark_streaming.py
spark-submit --master local[2] --jars /opt/bitnami/spark/jars/spark-sql-kafka-0-10_2.12-3.5.0.jar,/opt/bitnami/spark/jars/kafka-clients-3.6.0.jar /opt/bitnami/pyspark_scripts/spark_streaming.py
spark-submit --jars /jars/spark-sql-kafka-0-10_2.12-3.5.0,jar,/jars/kafka-clients-3.6.0.jar ../pyspark_scripts/spark_streaming.py

spark-submit --master local[2] --jars /opt/bitnami/spark/jars/spark-sql-kafka-0-10_2.12-3.5.0.jar /opt/bitnami/pyspark_scripts/spark_streaming.py

pwd

# An error occurred while calling o34.load.
# : java.lang.NoClassDefFoundError: org/apache/kafka/common/serialization/ByteArraySerializer
#         at org.apache.spark.sql.kafka010.KafkaSourceProvider$.<init>(KafkaSourceProvider.scala:601)


pip uninstall pyspark -y
pip install pyspark

python3 spark_streaming.py



# === try avec spark 3.4.1 =====================================================================
# new branch 341
git checkout -b 341

# > docker-compose.yml
# spark-master:
#     image: bitnami/spark:3.4.1
# spark-worker:
#     image: bitnami/spark:3.4.1

docker compose up spark-master spark-worker kafka -d

# > spark_streaming.py
#                 .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1") \

pip uninstall pyspark -y
pip install pyspark==3.4.1

docker cp ./spark_streaming.py kraft-spark-master-1:/opt/bitnami/pyspark_scripts/

# === inside container
docker exec -it kraft-spark-master-1 /bin/bash
spark-shell
spark-submit --master local[2] --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,com.datastax.spark:spark-cassandra-connector_2.12:3.4.1 /opt/bitnami/pyspark_scripts/spark_streaming.py
# ok !

git push --set-upstream origin 341

# merge
git checkout main
git merge 341

# === insert to postgresql =====================================================================
curl -sSL https://raw.githubusercontent.com/bitnami/containers/main/bitnami/postgresql/docker-compose.yml > docker-compose-postgresql.yml

# > docker-compose.yml
docker compose up -d spark-master spark-worker kafka postgresql

docker exec -it kraft-postgresql-1 /bin/bash
psql -U postgres

# create spark_db database
CREATE DATABASE spark_db;

# connect to spark_db database
\c spark_db

# create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    gender VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    postcode VARCHAR(255) NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    email VARCHAR(255) NOT NULL
);

# https://blog.knoldus.com/streaming-from-kafka-to-postgresql-through-spark-structured-streaming/


python3 spark_streaming.py
# org.postgresql.util.PSQLException: ERROR: schema "spark_db" does not exist



# === Cassandra =====================================================================
docker exec -it cassandra /bin/bash
cqlsh -u cassandra -p cassandra
CREATE KEYSPACE spark_streaming WITH replication = {'class':'SimpleStrategy','replication_factor':1};
CREATE TABLE spark_streaming.random_names(full_name text primary key, gender text, location text, city text, country text, postcode text, latitude float, longitude float, email text);
DESCRIBE spark_streaming.random_names;

# ERROR CassandraConnectorConf: Unknown host 'cassandra'
# java.net.UnknownHostException: cassandra: Temporary failure in name resolution
# ---> etc/hosts aad line :
127.0.0.1 cassandra

SELECT * FROM spark_streaming.random_names;



# =================== crypto branch ==================================================
# === websockets =====================================================================
pip install websockets
# > websocket_to_kafka.py

# > spark_streaming.py

# cassandra :
docker compose up -d kafka spark-master spark-worker cassandra
docker exec -it cassandra /bin/bash
cqlsh -u cassandra -p cassandra
# create keyspace
CREATE KEYSPACE spark_streaming WITH replication = {'class':'SimpleStrategy','replication_factor':1};

CREATE TABLE spark_streaming.crypto_trades(
    id uuid primary key,
    symbol text,
    price float,
    volume float,
    timestamp_unix bigint,
    conditions text
);

docker exec -it cassandra /bin/bash
cqlsh -u cassandra -p cassandra
select * from spark_streaming.crypto_trades;

# delete keyspace
DROP KEYSPACE spark_streaming;



# candlesticks charts
# https://coderzcolumn.com/tutorials/data-science/candlestick-chart-in-python-mplfinance-plotly-bokeh



# extract container
mkdir extract
# > main.py
# > Dockerfile
# > requirements_extract.txt

docker build -t ws_extract_to_kafka .




# === reprise mardi 12/12/23

cp -r keys extract/

docker compose down --remove-orphans
docker compose up -d extract kafka
docker compose up -d extract kafka spark-master spark-worker cassandra

docker exec -it cassandra /bin/bash
cqlsh -u cassandra -p cassandra
select * from spark_streaming.crypto_trades;

# cassandra delete all lines of a table
TRUNCATE spark_streaming.crypto_trades;

# exec spark-master container
docker exec -it kraft-spark-master-1 /bin/bash
cd ..
cd pyspark_scripts/
cat spark_streaming.py
spark-submit --master local[2] --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,com.datastax.spark:spark-cassandra-connector_2.12:3.4.1 /opt/bitnami/pyspark_scripts/spark_streaming.py
# --> console streaming ok


# errors with cassandra streaming :
# error
# An error occurred while calling o86.start.
# : java.io.IOException: mkdir of file:/opt/bitnami/pyspark_scripts/checkpoint failed

# compose spark-master volume add line:
- ./checkpoint:/opt/bitnami/pyspark_scripts/checkpoint

mkdir checkpoint

docker compose down --remove-orphans
docker compose up -d extract kafka spark-master spark-worker cassandra
# ->  spark-submit
docker exec -it kraft-spark-master-1 /bin/bash && cd .. && cd pyspark_scripts/ && spark-submit --master local[2] --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,com.datastax.spark:spark-cassandra-connector_2.12:3.4.1 /opt/bitnami/pyspark_scripts/spark_streaming.py
#  ERROR MicroBatchExecution: Query [id = 18f12a31-3f8f-4420-a84b-8ea41628d0d5, runId = 394a1a20-7a37-4914-8b23-c8a58f00fa76] terminated with error
# java.io.FileNotFoundException: /opt/bitnami/pyspark_scripts/checkpoint/commits/.200.30bd3235-b4c0-44f8-8f22-0079cbc19b16.tmp (Permission denied)
chmod -R 777 checkpoint/
spark-submit --master local[2] --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,com.datastax.spark:spark-cassandra-connector_2.12:3.4.1 /opt/bitnami/pyspark_scripts/spark_streaming.py

docker exec -it cassandra /bin/bash
cqlsh -u cassandra -p cassandra
select * from spark_streaming.crypto_trades;

# ok !!!