## Deploying a Docker multi-container architecture (Airflow, Kafka, Spark, and Cassandra)

![project diagram](./img/diagram_cryptos_png.png)

<hr>

I am replicating and customizing the great project from [Dogukan Ulu](https://dogukanulu.dev/) :

* [Data Engineering End-to-End Project — Spark, Kafka, Airflow, Docker, Cassandra, Python](https://medium.com/@dogukannulu/data-engineering-end-to-end-project-1-7a7be2a3671)

* Github repo : [https://github.com/dogukannulu/kafka_spark_structured_streaming](https://github.com/dogukannulu/kafka_spark_structured_streaming)

I have chosen to use some anothers and latest images available on 2023-11-06 from [Docker Hub](https://hub.docker.com/) for the following services:

<div style="display:flex; justify-content:center; width:100%">
<table>
<tr><th>service</th><th>image</th><th></th></tr>
<tr><td>KRaft</td><td>bitnami/kafka:3.6</td><td>Implementing KRaft mode : <a href="https://developer.confluent.io/learn/kraft/">Kafka Without ZooKeeper</a><br><a href="https://hub.docker.com/r/bitnami/kafka">https://hub.docker.com/r/bitnami/kafka</a></td></tr>
<tr><td>webserver<br>scheduler</td><td>apache/airflow:2.7.2-python3.10</td><td><a href="https://airflow.apache.org/docs/docker-stack/index.html">https://airflow.apache.org/docs/docker-stack/index.html</a></tr>
<tr><td>postgres</td><td>postgres:16</td><td><a href="https://hub.docker.com/_/postgres">https://hub.docker.com/_/postgres</a></td>
<tr><td>spark-master<br>spark-worker</td><td>bitnami/spark:3.5.0</td><td><a href="https://hub.docker.com/r/bitnami/spark">https://hub.docker.com/r/bitnami/spark</td></tr>
<tr><td>postgresql</td><td>bitnami/postgresql:16</td><td><a href="https://hub.docker.com/r/bitnami/spark">https://hub.docker.com/r/bitnami/postgresql</td></tr>
</table>
</div>



Cassandra's driver doesn't support spark 3.5.0 yet, i'll replace it by postgresql or and/or mongoDB.

I gained extensive knowledge about Docker, dependency management while replicating this project, and i liked the CI/CD process. This newfound interest led me to opt for migrating to GCP Kubernetes Engine (see my on going project [Spark on Kubernetes repo](https://github.com/yzpt/spark_on_kubernetes/))


## 1. Kafka

* docker-compose.yml

```yaml
services:
  kafka:
    image: 'bitnami/kafka:latest'
    networks:
      - cluster-network
    environment:
      - KAFKA_CFG_NODE_ID=0
      - KAFKA_CFG_PROCESS_ROLES=controller,broker
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@<localhost>:9093
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093,EXTERNAL://:9094
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092,EXTERNAL://localhost:9094
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT,PLAINTEXT:PLAINTEXT
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
    ports:
      - '9092:9092'
      - '9094:9094'
```

Run the following command to start the Kafka broker:

```bash
docker-compose up -d kafka
```

## 2. Cryptos trades websocket messages python script

### 2.1. Python script

```python
import asyncio
import json
import websockets
from kafka import KafkaProducer

with open('keys/finnhub_api_key.txt') as f:
    api_key = f.read()
    f.close()

# Create a Kafka producer
try:
    p = KafkaProducer(bootstrap_servers='localhost:9092')
except Exception as e:
    print(f"Failed to create Kafka producer because {e}")

async def on_message(message):
    # Convert message to bytes
    message_bytes = message.encode('utf-8')

    # Send message to Kafka
    p.send('my_new_topic', value=message_bytes)
    p.flush()
    print('=== sent: =================================')
    print(message)

async def on_error(error):
    print(error)

async def on_close():
    print("### closed ###")

async def on_open(ws):
    await ws.send('{"type":"subscribe","symbol":"BINANCE:BTCUSDT"}')

async def consumer_handler(websocket):
    async for message in websocket:
        await on_message(message)

async def handler():
    uri = "wss://ws.finnhub.io?token=" + api_key
    async with websockets.connect(uri) as websocket:
        await on_open(websocket)
        await consumer_handler(websocket)
        await on_close()

if __name__ == "__main__":
    asyncio.get_event_loop().run_until_complete(handler())
```

### 2.2. Checking the Kafka topic messages with the kafka-console-consumer

```bash 
TOPIC="my_new_topic"
SERVER="localhost:9092"

# list the topics
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server $SERVER

# send a message to the topic
echo "Hello" | docker compose exec -T kafka opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $TOPIC --bootstrap-server $SERVER

# open prompt to send messages to the topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-producer.sh --topic $TOPIC --bootstrap-server $SERVER

# get the streamed messages from the topic
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-console-consumer.sh --topic $TOPIC --from-beginning --bootstrap-server $SERVER

# delete a topic:
docker compose exec kafka  opt/bitnami/kafka/bin/kafka-topics.sh --delete --topic $TOPIC --bootstrap-server $SERVER
```

