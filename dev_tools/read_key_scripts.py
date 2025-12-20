import asyncio
import websockets
import json

async def read_scripts():
    uri = "ws://127.0.0.1:9080"
    scripts_to_read = [
        "res://source/client/local_player/gesture_manager.gd",
        "res://source/client/local_player/player_3d.gd",
        "res://source/common/gameplay/characters/npc/npc.gd"
    ]
    
    try:
        async with websockets.connect(uri) as websocket:
            await websocket.recv() # Consume the initial greeting message
            
            for script in scripts_to_read:
                print(f"Reading {script}...")
                command = {
                    "type": "get_script",
                    "commandId": f"read_{script}",
                    "params": {"script_path": script}
                }
                await websocket.send(json.dumps(command))
                resp = json.loads(await websocket.recv())
                
                if resp["status"] == "success":
                    print(f"--- START {script} ---")
                    print(resp["result"]["content"])
                    print(f"--- END {script} ---\
")
                else:
                    print(f"Failed to read {script}: {resp.get('message')}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(read_scripts())
