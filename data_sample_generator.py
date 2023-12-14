import websocket
import json
from datetime import datetime

with open('keys/finnhub_api_key.txt') as f:
    api_key = f.read()
    f.close()  

 # Write trade data to file
datetime_start = datetime.now()

with open('trades_' + str(datetime_start) + '.json', 'a') as f:
    f.write('[\n')

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
        
        with open('trades' + str(datetime_start) + '.json', 'a') as f:
            f.write(json.dumps(kafka_data) + ',\n')
        

def on_error(ws, error):
    print(error)

def on_close(ws):
    print("### closed ###")

def on_open(ws):
    ws.send('{"type":"subscribe","symbol":"BINANCE:BTCUSDT"}')

if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("wss://ws.finnhub.io?token=" + api_key ,
                              on_message = on_message,
                              on_error = on_error,
                              on_close = on_close)
    ws.on_open = on_open
    ws.run_forever()
    
