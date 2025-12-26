import os
import sys

AUDIT_FILE = "complete_codebase_audit.txt"

def debug_restore(filter_prefix=None):
    if not os.path.exists(AUDIT_FILE):
        print(f"Audit file {AUDIT_FILE} not found.")
        return

    with open(AUDIT_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    separator = "=" * 80
    chunks = content.split(separator)

    count = 0
    for i in range(1, len(chunks), 2):
        filename_block = chunks[i].strip()
        if not filename_block.startswith("FILE: res://"):
            continue

        filepath = filename_block.replace("FILE: res://", "").strip()

        if filter_prefix and not filepath.startswith(filter_prefix):
            continue

        print(f"Would restore: {filepath}")
        count += 1

    print(f"Total matching '{filter_prefix}': {count}")

if __name__ == "__main__":
    filter_arg = sys.argv[1] if len(sys.argv) > 1 else None
    debug_restore(filter_arg)
