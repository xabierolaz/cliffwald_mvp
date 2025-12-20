import asyncio
import websockets
import json

async def inspect_project():
    uri = "ws://127.0.0.1:9080"
    try:
        async with websockets.connect(uri) as websocket:
            # Wait for welcome message
            await websocket.recv()
            
            # 1. List Player files
            command = {
                "type": "list_project_files",
                "commandId": "find_player",
                "params": {"extensions": [".tscn", ".gd"]}
            }
            await websocket.send(json.dumps(command))
            files_resp = json.loads(await websocket.recv())
            
            all_files = files_resp["result"]["files"]
            player_files = [f for f in all_files if "player" in f.lower()]
            combat_files = [f for f in all_files if "combat" in f.lower()]
            npc_files = [f for f in all_files if "npc" in f.lower()]
            
            print(f"Found {len(player_files)} player files.")
            print(f"Found {len(combat_files)} combat files.")
            print(f"Found {len(npc_files)} npc files.")
            
            # 2. Inspect Player Scene if found
            player_scene = next((f for f in player_files if f.endswith(".tscn") and "player.tscn" in f), None)
            if player_scene:
                print(f"Inspecting Player Scene: {player_scene}")
                command = {
                    "type": "get_scene_structure",
                    "commandId": "inspect_player",
                    "params": {"path": player_scene}
                }
                await websocket.send(json.dumps(command))
                print(await websocket.recv())

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(inspect_project())
