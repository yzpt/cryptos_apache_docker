
# === KRaft =====================================================================================================
# compose: kafka
# https://github.com/nanthakumaran-s/Learn-Kafka/

mkdir volume-kafka
sudo chmod -R 777 ./volume-kafka
docker compose up -d

topic=test
server=localhost:9092

# create topic
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --create --topic $topic --bootstrap-server $server
# list
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server $server
# describe
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --describe --topic $topic --bootstrap-server $server
# delete
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --delete --topic $topic --bootstrap-server $server

topic=random_names
server=localhost:9092
# producer
echo "bjr" | docker exec -i kafka opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $topic --bootstrap-server $server
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

docker cp ./spark_streaming.py kraft-spark-master-1:/opt/bitnami/pyspark_scripts/

curl -O https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.5.0/spark-sql-kafka-0-10_2.12-3.5.0.jar

docker cp ./spark-sql-kafka-0-10_2.12-3.5.0.jar kraft-spark-master-1:/opt/bitnami/spark/jars/


docker exec -it kraft-spark-master-1 /bin/bash
# ===> inside container
# spark-submit --master local[2] --jars /opt/bitnami/spark/jars/spark-sql-kafka-0-10_2.12-3.5.0.jar ../pyspark_scripts/spark_streaming.py

# create_initial_dataframe:WARNING:Initial dataframe couldn't be created due to exception: An error occurred while calling o34.load.
# : java.lang.NoClassDefFoundError: org/apache/kafka/common/serialization/ByteArraySerializer
