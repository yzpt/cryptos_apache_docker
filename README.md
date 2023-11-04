#  --- Work in progress ---

### ETL w/ :

* on GCP : Pub/Sub, Function, Cloud SQL(PostgreSQL), Dataproc, Composer
* on Ubuntu-based Docker containers : Kafka, PostgresSQL, Spark, Airflow
* Looker

<hr>

## 1. Git, Virtual Environment, and Pip

```sh
# git 
git init
git add .
git commit -m "1st commit"
git remote add origin https://github.com/yzpt/cryptos_apache_docker.git
git push -u origin master

# venv
python3 -m venv venv_a
source ./venv_a/bin/activate

# pip 
pip install requests
pip install pandas
pip install ipykernel
pip install google-cloud-storage
pip install google-cloud-bigquery
pip install pyspark
pip install websocket
pip install websocket-client
pip install kafka-python

# Airflow: see doc below to install from pypi, we need to adjust the constraint file accordingly to python version
# https://airflow.apache.org/docs/apache-airflow/stable/installation/installing-from-pypi.html
pip install "apache-airflow[celery]==2.7.2" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.2/constraints-3.10.txt"
```

## 2. Google Cloud Platform configuration

```sh
# log with browser:
gcloud auth login

# get config list
gcloud config list

# set project
PROJECT_ID='cryptos-gcp'
gcloud projects create $PROJECT_ID
gcloud config set project $PROJECT_ID

# create service account
gcloud iam service-accounts create \
    $PROJECT_ID-sa \
    --display-name $PROJECT_ID-sa 

SERVICE_ACCOUNT_EMAIL=$PROJECT_ID-sa@$PROJECT_ID.iam.gserviceaccount.com

# create key
gcloud iam service-accounts keys create \
    ./keys/key.json \
    --iam-account=$SERVICE_ACCOUNT_EMAIL \
    --key-file-type=json

# grant access to service account
gcloud projects add-iam-policy-binding \
    $PROJECT_ID \
    --member="serviceAccount:"$SERVICE_ACCOUNT_EMAIL \
    --role="roles/owner"

# retrieve your billing account ID with:
gcloud billing accounts list
# save acount id into a file:
gcloud beta billing accounts list --format="value(ACCOUNT_ID)" > ./keys/gcloud_account_id.txt
ACCOUNT_ID=$(cat keys/gcloud_account_id.txt)

gcloud billing projects link $PROJECT_ID --billing-account $ACCOUNT_ID
```

## 3. PostgreSQL configuration

```sh
### Step 1: Install PostgreSQL on Ubuntu

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

### 3.1. Start and Enable PostgreSQL Service

PostgreSQL should start automatically after installation. If it doesn't, you can start the service with:

```bash
sudo systemctl start postgresql
```

To enable PostgreSQL to start on boot, use:

```bash
sudo systemctl enable postgresql
```

### 3.2. Set Up a PostgreSQL Database and User

a. **Access the PostgreSQL prompt:**

   ```bash
   sudo -u postgres psql
   ```

b. **Create a new database:**

   ```sql
   CREATE DATABASE mydatabase;
   
   \c mydatabase;
   
   CREATE TABLE trades (
    symbol TEXT,
    price FLOAT,
    volume FLOAT,
    conditions TEXT,
    timestamp BIGINT
    );

    --delete table
    DROP TABLE trades;
   ```

   Replace `mydatabase` with your desired database name.

c. **Create a new user and grant privileges:**

   ```sql
   CREATE USER myuser WITH PASSWORD 'mypassword';
   ALTER ROLE myuser SET client_encoding TO 'utf8';
   ALTER ROLE myuser SET default_transaction_isolation TO 'read committed';
   ALTER ROLE myuser SET timezone TO 'Europe/Paris';
   GRANT ALL PRIVILEGES ON DATABASE mydatabase TO myuser;
   ```

d. **Exit the PostgreSQL prompt:**

   ```sql
   \q
   ```

### 3.3. Install psycopg2 Python Package

`psycopg2` is a PostgreSQL adapter for Python. You can install it using `pip`:

```bash
pip install psycopg2-binary
```

### 3.4. Insert Data Into PostgreSQL database

Source : finnhub.io

* [https://finnhub.io/docs/api](https://finnhub.io/docs/api)

* [https://finnhub.io/docs/api/crypto-candles](https://finnhub.io/docs/api/crypto-candles)

* [https://finnhub.io/docs/api/websocket-trades](https://finnhub.io/docs/api/websocket-trades)

```python
#https://pypi.org/project/websocket_client/
import websocket
import datetime
import psycopg2
import json


# Establish a connection to the PostgreSQL database
conn = psycopg2.connect(
    database="mydatabase",
    user="myuser",
    password="mypassword",
    host="localhost",
    port="5432"
)

with open('keys/finnhub_api_key.txt') as f:
    api_key = f.read()
    f.close()

def on_message(ws, message):
    
    message = json.loads(message)
    data = message['data']
    
    # Create a cursor object to execute SQL queries
    cur = conn.cursor()

    for trade in data:
        insert_query = "INSERT INTO trades (symbol, price, timestamp, volume, conditions) VALUES (%s, %s, %s, %s, %s);"
        data_to_insert = (trade['s'], trade['p'], trade['t'], trade['v'], trade['c'])
        cur.execute(insert_query, data_to_insert)

    # Commit the transaction
    conn.commit()

def on_error(ws, error):
    print(error)

def on_close(ws):
    print("### closed ###")

def on_open(ws):
    ws.send('{"type":"subscribe","symbol":"AAPL"}')
    ws.send('{"type":"subscribe","symbol":"GOOGL"}')
    ws.send('{"type":"subscribe","symbol":"MSFT"}')
    ws.send('{"type":"subscribe","symbol":"AMZN"}')
    ws.send('{"type":"subscribe","symbol":"BINANCE:BTCUSDT"}')

if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("wss://ws.finnhub.io?token=" + api_key ,
                              on_message = on_message,
                              on_error = on_error,
                              on_close = on_close)
    ws.on_open = on_open
    ws.run_forever()
```

## 4. Kafka on Ubuntu 22.04 LTS

### 4.1. Install Kafka

* [https://www.devopshint.com/how-to-install-apache-kafka-on-ubuntu-22-04-lts/](https://www.devopshint.com/how-to-install-apache-kafka-on-ubuntu-22-04-lts/)

```sh
sudo apt-get update
sudo apt install openjdk-8-jdk

# get the latest version of Kafka
# https://kafka.apache.org/downloads
sudo wget https://downloads.apache.org/kafka/3.6.0/kafka-3.6.0-src.tgz

# unzip archive and move files
sudo tar xzf kafka-3.6.0-src.tgz
sudo mv kafka-3.6.0-src /opt/kafka
```

### 4.2. Creating Zookeeper and Kafka Systemd Unit Files in Ubuntu 22.04 LTS

```sh
# Create the systemd unit file for zookeeper service
sudo nano  /etc/systemd/system/zookeeper.service
```

* Paste the following content :

```txt
[Unit]
Description=Apache Zookeeper service
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
```

* Reload the daemon to take effect:

```sh
sudo systemctl daemon-reload
```

* Create the systemd unit file for kafka service

```sh
sudo nano /etc/systemd/system/kafka.service
```

* paste the below lines, <u>be sure to set the correct JAVA_HOME path</u>:

```txt
[Unit]
Description=Apache Kafka Service
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service

[Service]
Type=simple
Environment="JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh

[Install]
WantedBy=multi-user.target
```

### automating the creation of the systemd unit files:

```sh
    #!/bin/bash

    # Define the systemd service content
    read -r -d '' SERVICE_CONTENT << EOM
    [Unit]
    Description=Apache Kafka Service
    Documentation=http://kafka.apache.org/documentation.html
    Requires=zookeeper.service

    [Service]
    Type=simple
    Environment="JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64"
    ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
    ExecStop=/opt/kafka/bin/kafka-server-stop.sh

    [Install]
    WantedBy=multi-user.target
    EOM

    # Write the content to the systemd service file
    echo "${SERVICE_CONTENT}" | sudo tee /etc/systemd/system/kafka.service > /dev/null

    # Give execute permissions to the kafka service
    sudo chmod +x /etc/systemd/system/kafka.service
```

* Reload the daemon to take effect:

```sh
sudo systemctl daemon-reload
```

### 4.3. Start Zookeeper and Kafka Services

```sh
# Build Kafka
cd /opt/kafka
sudo su
./gradlew jar -PscalaVersion=2.13.11

# Start zookeeper
sudo systemctl start zookeeper

# Check the status of zookeeper
sudo systemctl status zookeeper

# Stop zookeeper
sudo systemctl stop zookeeper

# Start kafka service
sudo systemctl start kafka

# Check the status of kafka service
sudo systemctl status kafka

# Stop kafka service
sudo systemctl stop kafka
```

* To Start Kafka And ZooKeeper Server in the background(without creating systemd unit file)

There is a shell script to run the kafka and zookeeper server in backend:

* Create a file named kafkastart.sh and copy the below script:

    ```sh
    #!/bin/bash
    sudo nohup /opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties > /dev/null 2>&1 &
    sleep 5
    sudo nohup /opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties > /dev/null 2>&1 &
    ```

* After give the executable permissions to the file:

    ```sh
    sudo chmod +x kafkastart.sh
    ```

## 4.4. Creating Kafka Topic and send messages

* Create a topic named testtopic with single partition and single replica:

```sh
cd /opt/kafka
bin/kafka-topics.sh --create --topic cryptos_topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# list topics
bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# Prompt to type and send messages for created topic
bin/kafka-console-producer.sh --topic cryptos_topic --bootstrap-server localhost:9092

# Kafka Consumer: command to see the list of messages
bin/kafka-console-consumer.sh --topic cryptos_topic --from-beginning --bootstrap-server localhost:9092
```



## 5. Docker : a much better way

Creating architecture using docker compose and bitnami's and confluent's images.

see tuto : [https://www.youtube.com/watch?v=GqAcTrqKcrY&t=4451s&ab_channel=CodeWithYu](https://www.youtube.com/watch?v=GqAcTrqKcrY&t=4451s&ab_channel=CodeWithYu)

from [Yusuf Ganiyu](https://github.com/airscholar)

