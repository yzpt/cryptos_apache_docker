# Deploying a Docker multi-container architecture (Airflow, Kafka, Spark, and Cassandra)

![project diagram](./img/diagram_cryptos_png.png)

<hr>

Project inspired from [Dogukan Ulu](https://dogukanulu.dev/) :

* [Data Engineering End-to-End Project — Spark, Kafka, Airflow, Docker, Cassandra, Python](https://medium.com/@dogukannulu/data-engineering-end-to-end-project-1-7a7be2a3671)

* Github repo : [https://github.com/dogukannulu/kafka_spark_structured_streaming](https://github.com/dogukannulu/kafka_spark_structured_streaming)

I have chosen these images from [Docker Hub](https://hub.docker.com/) for the following services:

<div style="display:flex; justify-content:center; width:100%">
<table>
<tr><th>service</th><th>image</th><th></th></tr>
<tr><td>KRaft</td><td>bitnami/kafka:3.6</td><td>Implementing KRaft mode : <a href="https://developer.confluent.io/learn/kraft/">Kafka Without ZooKeeper</a><br><a href="https://hub.docker.com/r/bitnami/kafka">https://hub.docker.com/r/bitnami/kafka</a></td></tr>
<tr><td>webserver<br>scheduler</td><td>apache/airflow:2.7.2-python3.10</td><td><a href="https://airflow.apache.org/docs/docker-stack/index.html">https://airflow.apache.org/docs/docker-stack/index.html</a></tr>
<tr><td>postgres</td><td>postgres:16</td><td><a href="https://hub.docker.com/_/postgres">https://hub.docker.com/_/postgres</a></td>
<tr><td>spark-master<br>spark-worker</td><td>bitnami/spark:3.4.1</td><td><a href="https://hub.docker.com/r/bitnami/spark">https://hub.docker.com/r/bitnami/spark</td></tr>
<tr><td>cassandra</td><td>cassandra:5.0</td><td><a href="https://hub.docker.com/_/cassandra/tags">https://hub.docker.com/_/cassandra/tags</td></tr>
</table>
</div>

## 1. Source: real-time websocket

## 2. Kafka

## 3. Spark

## 4. Cassandra

## 5. Looker

