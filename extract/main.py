#https://pypi.org/project/websocket_client/
import websocket
import json
from kafka import KafkaProducer, KafkaConsumer
import time


def wait_for_kafka():
    while True:
        try:
            consumer = KafkaConsumer(bootstrap_servers='kafka:9092')
            # If the above line doesn't throw an exception, Kafka is ready
            break
        except Exception:
            print("Waiting for Kafka to start...")
            time.sleep(1)
  

def on_message(ws, message):
    json_message = json.loads(message)
    trades = json_message['data']

    for trade in trades:
        kafka_data = {}
        kafka_data["symbol"] = trade['s']
        kafka_data["price"] = trade['p']
        kafka_data["volume"] = trade['v']
        kafka_data["timestamp_unix"] = trade['t']
        kafka_data["conditions"] = trade['c']
        producer.send('crypto_trades', json.dumps(kafka_data).encode('utf-8'))

def on_error(ws, error):
    print(error)

def on_close(ws):
    print("### closed ###")

def on_open(ws):
    ws.send('{"type":"subscribe","symbol":"BINANCE:BTCUSDT"}')

if __name__ == "__main__":
    try:
        with open('keys/finnhub_api_key.txt') as f:
            api_key = f.read()
            f.close()

        # displaying messages on console: True/False
        websocket.enableTrace(False)

        wait_for_kafka()

        producer = KafkaProducer(bootstrap_servers=['kafka:9092'])

        ws = websocket.WebSocketApp("wss://ws.finnhub.io?token=" + api_key ,
                                on_message = on_message,
                                on_error = on_error,
                                on_close = on_close)
        ws.on_open = on_open
        ws.run_forever()
    
    except Exception as e:
        print(e)