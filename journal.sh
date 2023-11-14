
# === KRaft =====================================================================================================
# compose: kafka
# https://github.com/nanthakumaran-s/Learn-Kafka/

mkdir volume-kafka
sudo chmod -R 777 ./volume-kafka
docker compose up -d

topic=random_names
server=localhost:9092

# create topic
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --create --topic $topic --bootstrap-server $server
# list
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server $server
# describe
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --describe --topic $topic --bootstrap-server $server
# delete
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --delete --topic $topic --bootstrap-server $server

topic=test
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
spark-submit --master local[2] --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1 /opt/bitnami/pyspark_scripts/spark_streaming.py
# ok !

git push --set-upstream origin 341

# merge
git checkout main
git merge 341

# === insert to postgresql =====================================================================
# > docker-compose.yml
docker compose up -d spark-master spark-worker kafka postgres
