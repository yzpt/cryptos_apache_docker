# venv
python3 -m venv venv6
source venv6/bin/activate

# Install dependencies
pip install websockets
pip install kafka-python
pip install pyspark

git init
git add .
#rename branch
git branch -M compose
git commit -m "first commit"
git remote add origin https://github.com/yzpt/docker_cluster_streaming.git
git push -u origin compose

# run docker compose
docker compose up -d

# get websocket messages and send to kafka @localhost:9092
python3 websocket.py

# consume kafka messages to check
TOPIC="my_new_topic"
SERVER="localhost:9092"
# list
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server $SERVER
# get the messages streamed from the topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic $TOPIC --from-beginning --bootstrap-server $SERVER
# delete a topic:
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --delete --topic $TOPIC --bootstrap-server $SERVER


# === spark =========
python3 spark_stream.py

