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
