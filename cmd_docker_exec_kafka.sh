# create a topic
docker compose exec broker  ../../usr/bin/kafka-topics --create --topic new_topic --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092

# list the topics
docker compose exec broker  ../../usr/bin/kafka-topics --list --bootstrap-server localhost:9092

# open prompt to send messages to the topic "test_topic"
docker compose exec broker ../../usr/bin/kafka-console-producer --topic new_topic --bootstrap-server localhost:9092

# get the messages from the topic "test"
docker compose exec broker  ../../usr/bin/kafka-console-consumer --topic test_topic --from-beginning --bootstrap-server localhost:9092

# run Spark shell with PostgreSQL driver and jar file
docker compose exec spark-master ./bin/spark-shell --driver-class-path postgresql-42.6.0.jar --jars jars/postgresql-42.6.0.jar

# same for worker
docker compose exec spark-worker ./bin/spark-shell --driver-class-path postgresql-42.6.0.jar --jars postgresql-42.6.0.jar


