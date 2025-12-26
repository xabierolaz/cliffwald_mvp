import os
import sys

AUDIT_FILE = "complete_codebase_audit.txt"
OUTPUT_DIR = "."

def robust_restore(filter_prefix=None):
    if not os.path.exists(AUDIT_FILE):
        print(f"Audit file {AUDIT_FILE} not found.")
        return

    print(f"Reading {AUDIT_FILE}...")
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

        if i + 1 < len(chunks):
            file_content = chunks[i+1]
            if file_content.startswith("\n"):
                file_content = file_content[1:]

            # Additional cleanup: remove trailing newlines that might be part of separator spacing
            # But be careful not to remove essential newlines.
            # The split usually leaves a trailing newline if the file ended with one.

            full_path = os.path.join(OUTPUT_DIR, filepath)
            dirname = os.path.dirname(full_path)

            if not os.path.exists(dirname):
                os.makedirs(dirname)

            print(f"Restoring {filepath}")
            with open(full_path, "w", encoding="utf-8") as out:
                out.write(file_content)
            count += 1

    print(f"Restored {count} files matching '{filter_prefix}'")

if __name__ == "__main__":
    filter_arg = sys.argv[1] if len(sys.argv) > 1 else None
    if not filter_arg:
        print("Usage: python3 restore_codebase_batch.py <directory_prefix>")
        print("Example: python3 restore_codebase_batch.py source/common")
    else:
        robust_restore(filter_arg)
