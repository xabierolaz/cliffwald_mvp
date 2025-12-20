import asyncio
import websockets
import json

async def inspect_scenes():
    uri = "ws://127.0.0.1:9080"
    try:
        async with websockets.connect(uri) as websocket:
            await websocket.recv()
            
            # Inspect Player Client Scene
            print("Inspecting Client Player Scene...")
            command = {
                "type": "get_scene_structure",
                "commandId": "inspect_client_player",
                "params": {"path": "res://source/client/local_player/player_3d.tscn"}
            }
            await websocket.send(json.dumps(command))
            resp = await websocket.recv()
            print("CLIENT SCENE:", resp[:500] + "..." if len(resp) > 500 else resp)

            # Inspect Player Server Scene
            print("\nInspecting Server Player Scene...")
            command = {
                "type": "get_scene_structure",
                "commandId": "inspect_server_player",
                "params": {"path": "res://source/server/player/player_3d_server.tscn"}
            }
            await websocket.send(json.dumps(command))
            resp = await websocket.recv()
            print("SERVER SCENE:", resp[:500] + "..." if len(resp) > 500 else resp)

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(inspect_scenes())
