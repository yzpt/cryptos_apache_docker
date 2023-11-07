from kafka import KafkaProducer

producer = KafkaProducer(bootstrap_servers=['localhost:9092'])
producer.send('new topic', 'Hello, World!')
producer.flush()

