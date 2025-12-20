import asyncio
import websockets
import json

async def test_connection():
    uri = "ws://127.0.0.1:9080"
    try:
        async with websockets.connect(uri) as websocket:
            # Wait for welcome message
            welcome = await websocket.recv()
            print(f"Initial: {welcome}")
            
            # Send command
            command = {
                "type": "get_project_info",
                "commandId": "info_1",
                "params": {}
            }
            await websocket.send(json.dumps(command))
            
            # Get response
            response = await websocket.recv()
            print(f"Response: {response}")
            
            # Send another command: List files
            command = {
                "type": "get_project_structure",
                "commandId": "struct_1",
                "params": {}
            }
            await websocket.send(json.dumps(command))
            response = await websocket.recv()
            print(f"Structure: {response}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_connection())
