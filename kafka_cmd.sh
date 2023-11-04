docker compose exec kafka kafka-topics.sh --create --topic test_topic --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1

docker compose exec -it kafka /opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# send a message to the topic "test_topic"
docker compose exec broker /usr/bin/kafka-console-producer.sh --topic test_topic --bootstrap-server localhost:9092

# get the messages from the topic "test_topic"
docker compose exec broker  ../../usr/bin/kafka-console-consumer.sh --topic test_topic --from-beginning --bootstrap-server localhost:9092
docker compose exec broker  --topic test_topic --from-beginning --bootstrap-server localhost:9092
