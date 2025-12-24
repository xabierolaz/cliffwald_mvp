import os

AUDIT_FILE = "complete_codebase_audit.txt"

# Minimal set for security fixes
TARGET_FILES = [
    "source/common/gameplay/characters/player/net_player.gd",
    "source/server/master/components/authentication_manager.gd",
    "source/server/master/components/database.gd"
]

def restore_files():
    if not os.path.exists(AUDIT_FILE):
        print(f"Error: {AUDIT_FILE} not found.")
        return

    with open(AUDIT_FILE, "r", encoding="utf-8") as f:
        lines = f.readlines()

    current_file = None
    file_content = []

    i = 0
    while i < len(lines):
        line = lines[i]

        if line.startswith("FILE: res://"):
            # Save previous file
            if current_file:
                if current_file in TARGET_FILES:
                    write_file(current_file, file_content)
                file_content = []

            path = line.strip().split("FILE: res://")[1]
            current_file = path

            if i + 1 < len(lines) and lines[i+1].startswith("===="):
                i += 1

        elif line.startswith("================================================================================"):
            pass
        else:
            if current_file:
                file_content.append(line)

        i += 1

    if current_file and current_file in TARGET_FILES:
        write_file(current_file, file_content)

def write_file(path, content_lines):
    dir_path = os.path.dirname(path)
    if dir_path:
        os.makedirs(dir_path, exist_ok=True)

    try:
        with open(path, "w", encoding="utf-8") as f:
            f.writelines(content_lines)
        print(f"Restored: {path}")
    except Exception as e:
        print(f"Failed to write {path}: {e}")

if __name__ == "__main__":
    restore_files()
