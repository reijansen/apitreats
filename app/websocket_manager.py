from fastapi import WebSocket
import json

connected_clients = []

async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        while True:
            await websocket.receive_text()  # Keep connection alive
    except:
        pass
    finally:
        connected_clients.remove(websocket)

async def broadcast_new_purchase(data):
    message = {"type": "new_purchase", "data": data}
    for client in connected_clients:
        try:
            await client.send_text(json.dumps(message))
        except:
            connected_clients.remove(client)

async def broadcast_stock_update(data):
    message = {"type": "stock_update", "data": data}
    for client in connected_clients:
        try:
            await client.send_text(json.dumps(message))
        except:
            connected_clients.remove(client)