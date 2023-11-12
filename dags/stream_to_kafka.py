import asyncio
import json
import websockets
from kafka import KafkaProducer

# with open('keys/finnhub_api_key.txt') as f:
    # api_key = f.read()
    # f.close()
api_key = 'cl0205hr01qhjei2vk5gcl0205hr01qhjei2vk60'

# Create a Kafka producer
try:
    p = KafkaProducer(bootstrap_servers='kafka:9092')
    print("Kafka producer created")
except Exception as e:
    print(f"Failed to create Kafka producer because {e}")

async def on_message(message):
    # Convert message to bytes
    message_bytes = message.encode('utf-8')

    # Send message to Kafka
    topic = 'users_topic'
    p.send(topic, value=message_bytes)
    p.flush()
    print("=== " + topic + " ==========")
    print(message)

async def on_error(error):
    print(error)

async def on_close():
    print("### closed ###")

async def on_open(ws):
    # ws.send('{"type":"subscribe","symbol":"AAPL"}')
    # ws.send('{"type":"subscribe","symbol":"GOOGL"}')
    # ws.send('{"type":"subscribe","symbol":"MSFT"}')
    # ws.send('{"type":"subscribe","symbol":"AMZN"}')
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

def start_streaming():
    # asyncio.get_event_loop().run_until_complete(handler())
    
    # import requests
    # import json
    # response = requests.get('https://randomuser.me/api/')
    # message = json.dumps(response.json())
    # print(message)
    # p.send('users_topic', value=message.encode('utf-8'))
    p.send('trades_topic', value=b'houhou')
    # p.flush()

# if __name__ == "__main__":
start_streaming()
    