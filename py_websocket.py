#https://pypi.org/project/websocket_client/
import websocket
import datetime
import json
from confluent_kafka import Producer
import time

with open('keys/finnhub_api_key.txt') as f:
    api_key = f.read()
    f.close()

# Create a Kafka producer
try:
    p = Producer({'bootstrap.servers': 'localhost:9092'})
except Exception as e:
    print(f"Failed to create Kafka producer because {e}")

def on_message(ws, message):
    # Send message to Kafka
    p.produce('trades_topic', value=message)
    p.flush()
    # print('==================================')
    # print(message)
    # print('==================================')


def on_error(ws, error):
    print(error)

def on_close(ws):
    print("### closed ###")

def on_open(ws):
    # ws.send('{"type":"subscribe","symbol":"AAPL"}')
    # ws.send('{"type":"subscribe","symbol":"GOOGL"}')
    # ws.send('{"type":"subscribe","symbol":"MSFT"}')
    # ws.send('{"type":"subscribe","symbol":"AMZN"}')
    ws.send('{"type":"subscribe","symbol":"BINANCE:BTCUSDT"}')

if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("wss://ws.finnhub.io?token=" + api_key ,
                              on_message = on_message,
                              on_error = on_error,
                              on_close = on_close)
    ws.on_open = on_open

    ws.run_forever()