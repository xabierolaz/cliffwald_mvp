import os
import re

AUDIT_FILE = "complete_codebase_audit.txt"
OUTPUT_DIR = "."

def restore_files():
    if not os.path.exists(AUDIT_FILE):
        print(f"Audit file {AUDIT_FILE} not found.")
        return

    print(f"Reading {AUDIT_FILE}...")
    with open(AUDIT_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # Regex to find file blocks
    # Format:
    # ================================================================================
    # FILE: res://path/to/file.ext
    # ================================================================================
    # file content...

    # We'll split by the separator line, then check for FILE: res://

    separator = "=" * 80
    parts = content.split(separator)

    print(f"Found {len(parts)} parts (rough estimate). Processing...")

    files_restored = 0

    for i in range(len(parts)):
        part = parts[i].strip()
        if part.startswith("FILE: res://"):
            # This part contains the filename
            # The NEXT part contains the content
            # But wait, the split consumes the separator.
            # So the structure is:
            # [Pre-content] [Separator] [Filename Block] [Separator] [File Content] [Separator] ...

            # Let's parse differently. Iterate line by line.
            pass

    # Re-reading line by line is safer.

    with open(AUDIT_FILE, "r", encoding="utf-8") as f:
        lines = f.readlines()

    current_file = None
    current_content = []
    in_file_block = False

    for line in lines:
        stripped = line.strip()
        if stripped == separator:
            if current_file and in_file_block:
                # End of file block, save file
                save_file(current_file, current_content)
                current_file = None
                current_content = []
                in_file_block = False
            elif current_file is None:
                # Could be start of a file definition
                pass
            continue

        if line.startswith("FILE: res://"):
             # Found a file header.
             # If we were already collecting content for a previous file, we should have hit a separator.
             # But let's handle the case where we just see the header.
             path = line.strip().replace("FILE: res://", "")
             current_file = path
             current_content = []
             in_file_block = True
             continue

        if in_file_block:
            current_content.append(line)

    # Save last file if any
    if current_file and current_content:
        save_file(current_file, current_content)

def save_file(path, content_lines):
    # Remove leading/trailing newlines if necessary, but keep the structure
    # Actually, the parsing logic above is a bit flawed because the separator is both before and after the filename.
    # Pattern:
    # SEP
    # FILE: res://...
    # SEP
    # Content...
    # SEP

    # So when we hit SEP, we might be ending a content block or starting a file block.
    # A better way is to identify the "FILE:" line.
    pass

def robust_restore():
    with open(AUDIT_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # Split by the separator
    separator = "=" * 80
    chunks = content.split(separator)

    # chunks[0] is header
    # chunks[1] might be "FILE: res://..."
    # chunks[2] is content
    # chunks[3] is "FILE: res://..."
    # chunks[4] is content

    # So odd indices (starting 1) are filenames, even indices (starting 2) are content.

    for i in range(1, len(chunks), 2):
        filename_block = chunks[i].strip()
        if not filename_block.startswith("FILE: res://"):
            # Maybe not a file block?
            # print(f"Skipping block {i}: {filename_block[:50]}...")
            continue

        filepath = filename_block.replace("FILE: res://", "").strip()

        if i + 1 < len(chunks):
            file_content = chunks[i+1]
            # Content might start/end with newlines due to split
            # usually the first character is a newline because the separator is followed by newline in the file
            if file_content.startswith("\n"):
                file_content = file_content[1:]

            # Write to file
            full_path = os.path.join(OUTPUT_DIR, filepath)
            dirname = os.path.dirname(full_path)

            if not os.path.exists(dirname):
                os.makedirs(dirname)

            print(f"Restoring {filepath}")
            with open(full_path, "w", encoding="utf-8") as out:
                out.write(file_content)

if __name__ == "__main__":
    robust_restore()
