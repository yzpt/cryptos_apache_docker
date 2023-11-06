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


Cassandra's driver doesn't support spark 3.5.0 yet, i'll try to replace it by postgresql or another database.

I gained extensive knowledge about Docker, dependency management while replicating this project, and i liked the CI/CD process. This newfound interest led me to opt for migrating to GCP Kubernetes Engine. I plan to deploy a container cluster in the cloud, a task not feasible with Cloud Run.