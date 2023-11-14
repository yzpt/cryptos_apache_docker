
# === KRaft =====================================================================================================
# https://github.com/nanthakumaran-s/Learn-Kafka/

mkdir kafka
sudo chmod -R 777 ./volume-kafka
docker compose up -d

# create topic
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --create --topic test --bootstrap-server localhost:9092
# list
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
# describe
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --describe --topic test --bootstrap-server localhost:9092
# delete
docker exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --delete --topic test --bootstrap-server localhost:9092

# producer
topic="random_names"
echo "allo" | docker exec -i kafka opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $topic --bootstrap-server localhost:9092

# consumer
docker exec kafka opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic $topic --from-beginning --bootstrap-server localhost:9092


# === Airflow =====================================================================================================
# compose: webserver, scheduler, postgres
# > script/entrypoint.sh

# venv
python3 -m venv venv_airflow
source venv_airflow/bin/activate
pip install kafka-python
pip install "apache-airflow[celery]==2.7.2" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.2/constraints-3.10.txt"
pip freeze > requirements_airflow.txt

docker compose down
docker compose up -d
