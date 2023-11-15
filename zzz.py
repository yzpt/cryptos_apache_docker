import websocket

def on_error(wsapp, err):
    print("EXAMPLE error encountered: ", err)
websocket.setdefaulttimeout(5)
wsapp = websocket.WebSocketApp("ws://nexus-websocket-a.intercom.io", on_error=on_error)
wsapp.run_forever()  