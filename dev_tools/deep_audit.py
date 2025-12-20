import os
import re

PROJECT_ROOT = r"D:\AI\Cliffwald"

def check_file_exists(path, origin_file):
    # Resolve res://
    if path.startswith("res://"):
        rel_path = path.replace("res://", "")
        full_path = os.path.join(PROJECT_ROOT, rel_path.replace("/", os.sep))
        if not os.path.exists(full_path):
            print(f"[MISSING REF] In {os.path.basename(origin_file)}: {path} does not exist.")
            return False
    return True

def audit_project():
    print(f"--- AUDITING CLIFFWALD: {PROJECT_ROOT} ---")
    
    # 1. Scan all .gd and .tscn files
    for root, dirs, files in os.walk(PROJECT_ROOT):
        if ".godot" in root or ".git" in root or "dev_tools" in root: continue
        
        for file in files:
            if file.endswith(".gd") or file.endswith(".tscn"):
                full_path = os.path.join(root, file)
                with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # Check Preloads/Resources
                    # Pattern: preload("res://...") or ExtResource("res://...") or path="res://..."
                    matches = re.findall(r'(?:preload|ExtResource|path)\s*\(\s*"res://([^"]+)"', content)
                    for m in matches:
                        check_file_exists(f"res://{m}", file)
                        
                    # Check simple path strings
                    matches_str = re.findall(r'"res://([^"]+)"', content)
                    for m in matches_str:
                        # Filter out common noise if needed
                        if m.endswith(".gd") or m.endswith(".tscn") or m.endswith(".tres"):
                            check_file_exists(f"res://{m}", file)

    # 2. Specific Logic Checks
    print("\n--- LOGIC CHECKS ---")
    
    # Check Cliffwald World for Spawner
    world_path = os.path.join(PROJECT_ROOT, "source", "common", "gameplay", "maps", "cliffwald_world.tscn")
    if os.path.exists(world_path):
        with open(world_path, 'r') as f:
            content = f.read()
            if "MultiplayerSpawner" in content:
                print("[OK] MultiplayerSpawner found in World.")
            else:
                print("[FAIL] MultiplayerSpawner MISSING in World.")
            
            if "SimpleSpawner" in content:
                print("[OK] SimpleSpawner found in World.")
            else:
                print("[FAIL] SimpleSpawner MISSING in World.")
                
            if "castle_greybox.tscn" in content:
                print("[OK] Castle Greybox loaded in World.")
            else:
                print("[FAIL] Castle Greybox MISSING in World.")

    # Check NPC Scene script
    npc_scene_path = os.path.join(PROJECT_ROOT, "source", "common", "gameplay", "characters", "npc", "npc_v2.tscn")
    if os.path.exists(npc_scene_path):
        with open(npc_scene_path, 'r') as f:
            content = f.read()
            if "echo_ai.gd" in content:
                print("[OK] NPC_v2 uses EchoAI script.")
            elif "npc.gd" in content:
                print("[FAIL] NPC_v2 still uses DELETED npc.gd!")
            else:
                print("[WARN] NPC_v2 uses unknown script.")
    else:
        print("[FAIL] npc_v2.tscn not found (Did we rename it to npc.tscn? Checking...)")
        # Fallback check
        npc_path = os.path.join(PROJECT_ROOT, "source", "common", "gameplay", "characters", "npc", "npc.tscn")
        if os.path.exists(npc_path):
             print("[INFO] npc.tscn exists instead.")

if __name__ == "__main__":
    audit_project()
