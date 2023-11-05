# ===== Airflow ==============================================================================

# venv airlfow:
python3 -m venv venv_airflow
source venv_airflow/bin/activate

# pip
pip install requests
pip install websocket
pip install websocket-client
pip install kafka-python
# Airflow: see doc below to install from pypi, we need to adjust the constraint file accordingly to python version
# https://airflow.apache.org/docs/apache-airflow/stable/installation/installing-from-pypi.html
pip install "apache-airflow[celery]==2.7.2" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.2/constraints-3.10.txt"






# ===== Kafka ==============================================================================
# create a topic
docker compose exec broker  ../../usr/bin/kafka-topics --create --topic new_topic --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092

# list the topics
docker compose exec broker  ../../usr/bin/kafka-topics --list --bootstrap-server localhost:9092

# open prompt to send messages to the topic "test_topic"
docker compose exec broker ../../usr/bin/kafka-console-producer --topic test_topic --bootstrap-server localhost:9092

# get the messages from the topic "test"
docker compose exec broker  ../../usr/bin/kafka-console-consumer --topic test_topic --from-beginning --bootstrap-server localhost:9092






# ===== pySpark ==============================================================================
# --> see nb_pyspark.py
