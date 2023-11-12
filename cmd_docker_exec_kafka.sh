# === with bitnami:kafka image ===============================================================================================

TOPIC="trades_topic"
SERVER="kafka:9092"

docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic $TOPIC --from-beginning --bootstrap-server $SERVER

# create a topic
docker compose exec kafka opt/bitnami/kafka/bin/kafka-topics.sh \
    --create \
    --topic $TOPIC \
    --partitions 1 \
    --replication-factor 1 \
    --bootstrap-server $SERVER

# list
docker compose exec kafka opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server $SERVER

python3 stream_to_kafka.py

# send a messgae to the topic
echo "Hello" | docker compose exec -T kafka opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $TOPIC --bootstrap-server $SERVER

# open prompt to send messages to the topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $TOPIC --bootstrap-server $SERVER

# get the messages streamed from the topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic $TOPIC --from-beginning --bootstrap-server $SERVER

# delete a topic:
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --delete --topic $TOPIC --bootstrap-server $SERVER

# max-messages
MAX_MESSAGES=2
#bash increment $MAX_MESSAGE
MAX_MESSAGES=$((MAX_MESSAGES+1)) && docker compose exec kafka opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic new_topic --from-beginning --bootstrap-server localhost:9092 --max-messages $MAX_MESSAGES

