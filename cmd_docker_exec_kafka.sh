# create a topic
docker compose exec broker  ../../usr/bin/kafka-topics --create --topic new_topic --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092

# list the topics
docker compose exec broker  ../../usr/bin/kafka-topics --list --bootstrap-server localhost:9092

# open prompt to send messages to the topic "test_topic"
docker compose exec broker ../../usr/bin/kafka-console-producer --topic new_topic --bootstrap-server localhost:9092

# get the messages from the topic 
docker compose exec broker  ../../usr/bin/kafka-console-consumer --topic new_topic --from-beginning --bootstrap-server localhost:9092


# === with bitnami:kafka image ===============================================================================================

# create a topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --create --topic new_topic --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092
# list
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
# send a messgae to the topic 'new_topic'
echo "This is a unique message" | docker compose exec -T kafka opt/bitnami/kafka/bin/kafka-console-producer.sh --topic new_topic --bootstrap-server localhost:9092


# open prompt to send messages to the topic "new_topic"
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-producer.sh --topic new_topic --bootstrap-server localhost:9092
# get the messages streamed from the topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic new_topic --from-beginning --bootstrap-server localhost:9092

# max-messages 1
docker compose exec kafka opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic new_topic --from-beginning --bootstrap-server localhost:9092 --max-messages 1

