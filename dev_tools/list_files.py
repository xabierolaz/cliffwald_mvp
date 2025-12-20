import asyncio
import websockets
import json

async def list_files():
    uri = "ws://127.0.0.1:9080"
    try:
        async with websockets.connect(uri) as websocket:
            await websocket.recv()
            
            command = {
                "type": "list_project_files",
                "commandId": "list_all",
                "params": {"extensions": [".tscn", ".gd"]}
            }
            await websocket.send(json.dumps(command))
            files_resp = json.loads(await websocket.recv())
            files = files_resp["result"]["files"]
            
            print("--- PLAYER FILES ---")
            for f in files:
                if "player" in f.lower(): print(f)
                
            print("\n--- COMBAT FILES ---")
            for f in files:
                if "combat" in f.lower(): print(f)

            print("\n--- NPC FILES ---")
            for f in files:
                if "npc" in f.lower(): print(f)

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(list_files())

