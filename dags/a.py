print('=== start ===')

from kafka import KafkaProducer

# Create a Kafka producer
try:
    p = KafkaProducer(bootstrap_servers='kafka:9092')
    print("Kafka producer created")
except Exception as e:
    print(f"Failed to create Kafka producer because {e}")

try:
    topic = 'trades_topic'
    p.send(topic, value=b'allo')
    print('message sent, topic: ' + topic)
except Exception as e:
    print(f"Failed to send message because {e}")

print("=== end ===")

