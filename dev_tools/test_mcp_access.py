import asyncio
import websockets
import json
import subprocess
import time
import os
import signal

GODOT_PATH = r"D:\AI\Cliffwald\Godot_v4.5.1-stable_win64_console.exe"
PROJECT_PATH = r"D:\AI\Cliffwald"

async def test_connection():
    print(f"Launching Godot from {GODOT_PATH}...")
    # Launch Godot in editor mode, headless
    process = subprocess.Popen(
        [GODOT_PATH, "--path", PROJECT_PATH, "--editor", "--headless"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    print("Godot launched. Waiting for MCP server to start (10s)...")
    await asyncio.sleep(10)

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
    finally:
        print("Closing Godot process...")
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
        print("Test finished.")

if __name__ == "__main__":
    asyncio.run(test_connection())
