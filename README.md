#  --- Work in progress ---

## Deploying and running a multi-container architecture (Airflow, Kafka, Spark, and PostgreSQL) locally, and then migrating it to GCP's Kubernetes Engine

![project diagram](./img/diagram_cryptos_png.png)

<hr>


I am replicating the great project by [Dogukan Ulu](https://dogukanulu.dev/):

* [Data Engineering End-to-End Project — Spark, Kafka, Airflow, Docker, Cassandra, Python](https://medium.com/@dogukannulu/data-engineering-end-to-end-project-1-7a7be2a3671)

* Github repo : [https://github.com/dogukannulu/kafka_spark_structured_streaming](https://github.com/dogukannulu/kafka_spark_structured_streaming)

I have chosen to use some anothers and latest images available on 2023-11-06 from [Docker Hub](https://hub.docker.com/) for the following services:

<table>
<tr><th>service</th><th>image</th></tr>
<tr><td>zookeeper</td><td>confluentinc/cp-zookeeper:7.5.1</td></tr>
<tr><td>broker</td><td>confluentinc/cp-server:7.5.1</td></tr>
<tr><td>schema-registry</td><td>confluentinc/cp-schema-registry:7.5.1</td></tr>
<tr><td>control-center</td><td>confluentinc/cp-enterprise-control-center:7.5.1</td></tr>
<tr><td>webserver<br>scheduler</td><td>apache/airflow:2.7.2-python3.10</td></tr>
<tr><td>postgres</td><td>postgres:14.0</td></tr>
<tr><td>spark-master<br>spark-worker</td><td>bitnami/spark3.5.0</td></tr>
<tr><td>postgresql</td><td>bitnami/postgresql:16</td></tr>
</table>

Here the docker-compose.yml file:

<details>
    <summary>docker-compose.yml</summary>

```yaml
vversion: '3'

services:
  zookeeper:
      image: confluentinc/cp-zookeeper:7.5.1
      hostname: zookeeper
      container_name: zookeeper
      ports:
        - "2181:2181"
      environment:
        ZOOKEEPER_CLIENT_PORT: 2181
        ZOOKEEPER_TICK_TIME: 2000
      healthcheck:
        test: ['CMD', 'bash', '-c', "echo 'ruok' | nc localhost 2181"]
        interval: 10s
        timeout: 5s
        retries: 5
      networks:
        - confluent

  broker:
    image: confluentinc/cp-server:7.5.1
    hostname: broker
    container_name: broker
    depends_on:
      zookeeper:
        condition: service_healthy
    ports:
      - "9092:9092"
      - "9101:9101"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_METRIC_REPORTERS: io.confluent.metrics.reporter.ConfluentMetricsReporter
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_CONFLUENT_LICENSE_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_CONFLUENT_BALANCER_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_JMX_PORT: 9101
      KAFKA_JMX_HOSTNAME: localhost
      KAFKA_CONFLUENT_SCHEMA_REGISTRY_URL: http://schema-registry:8081
      CONFLUENT_METRICS_REPORTER_BOOTSTRAP_SERVERS: broker:29092
      CONFLUENT_METRICS_REPORTER_TOPIC_REPLICAS: 1
      CONFLUENT_METRICS_ENABLE: 'false'
      CONFLUENT_SUPPORT_CUSTOMER_ID: 'anonymous'
    volumes:
    - ./volume_kafka_broker:/var/kafka/data
    networks:
      - confluent
    healthcheck:
      test: [ "CMD", "bash", "-c", 'nc -z localhost 9092' ]
      interval: 10s
      timeout: 5s
      retries: 5

  schema-registry:
    image: confluentinc/cp-schema-registry:7.5.1
    hostname: schema-registry
    container_name: schema-registry
    depends_on:
      broker:
        condition: service_healthy
    ports:
      - "8081:8081"
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: 'broker:29092'
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
    networks:
      - confluent
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:8081/" ]
      interval: 30s
      timeout: 10s
      retries: 5
  control-center:
    image: confluentinc/cp-enterprise-control-center:7.5.1
    hostname: control-center
    container_name: control-center
    depends_on:
      broker:
        condition: service_healthy
      schema-registry:
        condition: service_healthy
    ports:
      - "9021:9021"
    environment:
      CONTROL_CENTER_BOOTSTRAP_SERVERS: 'broker:29092'
      CONTROL_CENTER_SCHEMA_REGISTRY_URL: "http://schema-registry:8081"
      CONTROL_CENTER_REPLICATION_FACTOR: 1
      CONTROL_CENTER_INTERNAL_TOPICS_PARTITIONS: 1
      CONTROL_CENTER_MONITORING_INTERCEPTOR_TOPIC_PARTITIONS: 1
      CONFLUENT_METRICS_TOPIC_REPLICATION: 1
      CONFLIENT_METRICS_ENABLE: 'false'
      PORT: 9021
    networks:
      - confluent
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:9021/health" ]
      interval: 30s
      timeout: 10s
      retries: 5
  webserver:
    image: apache/airflow:2.7.2-python3.10
    command: webserver
    entrypoint: ['/opt/airflow/script/entrypoint.sh']
    depends_on:
      - postgres
    environment:
      - LOAD_EX=n
      - EXECUTOR=Sequential
      - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
      - AIRFLOW_WEBSERVER_SECRET_KEY=this_is_a_very_secured_key
    logging:
      options:
        max-size: 10m
        max-file: "3"
    volumes:
      - ./dags:/opt/airflow/dags
      - ./script/entrypoint.sh:/opt/airflow/script/entrypoint.sh
      - ./requirements.txt:/opt/airflow/requirements.txt
    ports:
      - "8080:8080"
    healthcheck:
      test: ['CMD-SHELL', "[ -f /opt/airflow/airflow-webserver.pid ]"]
      interval: 30s
      timeout: 30s
      retries: 3
    networks:
      - confluent

  scheduler:
    image: apache/airflow:2.7.2-python3.10
    depends_on:
      webserver:
        condition: service_healthy
    volumes:
      - ./dags:/opt/airflow/dags
      - ./script/entrypoint.sh:/opt/airflow/script/entrypoint.sh
      - ./requirements.txt:/opt/airflow/requirements.txt
    environment:
      - LOAD_EX=n
      - EXECUTOR=Sequential
      - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
      - AIRFLOW_WEBSERVER_SECRET_KEY=this_is_a_very_secured_key
    command: bash -c "pip install -r ./requirements.txt && airflow db upgrade && airflow scheduler"
    networks:
      - confluent

  postgres:
    image: postgres:14.0
    environment:
      - POSTGRES_USER=airflow
      - POSTGRES_PASSWORD=airflow
      - POSTGRES_DB=airflow
    logging:
      options:
        max-size: 10m
        max-file: "3"
    networks:
      - confluent

  spark-master:
    image: bitnami/spark:3.5.0
    command: bin/spark-class org.apache.spark.deploy.master.Master
    ports:
      - "9090:8080"
      - "7077:7077"
    volumes:
      - ./volume_spark_master:/opt/bitnami/jars
    networks:
      - confluent
  
  spark-worker:
    image: bitnami/spark:3.5.0
    command: bin/spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077
    depends_on:
      - spark-master
    environment:
      SPARK_MODE: worker
      SPARK_WORKER_CORES: 2
      SPARK_WORKER_MEMORY: 1g
      SPARK_MASTER_URL: spark://spark-master:7077
    volumes:
      - ./volume_spark_worker:/opt/bitnami/jars
    networks:
      - confluent

  postgresql:
    image: bitnami/postgresql:16
    environment:
      - POSTGRES_USER=pgsql_user
      - POSTGRES_PASSWORD=pgsql_user
      - POSTGRES_DB=spark_database
    ports:
      - "5432:5432"
    networks:
      - confluent

networks:
  confluent:
```

</details>

