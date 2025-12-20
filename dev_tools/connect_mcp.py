import asyncio
import websockets
import json

async def test_connection():
    uri = "ws://127.0.0.1:9080"
    try:
        print(f"Connecting to {uri}...")
        async with websockets.connect(uri) as websocket:
            print("Connected!")
            
            # Send a command
            command = {
                "type": "get_project_info",
                "commandId": "test_1",
                "params": {}
            }
            
            print(f"Sending command: {json.dumps(command)}")
            await websocket.send(json.dumps(command))
            
            response = await websocket.recv()
            print(f"Received response: {response}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_connection())
