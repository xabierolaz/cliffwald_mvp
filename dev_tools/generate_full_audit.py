import os

TARGET_DIR = r"D:\AI\Cliffwald"
OUTPUT_FILE = r"D:\AI\Cliffwald\complete_codebase_audit.txt"

# Extensions to include (Text-based source code)
EXTENSIONS = {'.gd', '.tscn', '.tres', '.json', '.txt', '.md', '.cfg', '.ps1', '.sh', '.py'}

# Directories to exclude (Binaries, Cache, Assets)
EXCLUDE_DIRS = {'.git', '.godot', '.mcp', 'godot_bin', '__pycache__', '.continue', 'assets', 'gdd_temp'}

def generate_audit():
    print(f"Starting audit of {TARGET_DIR}...")
    file_count = 0
    
    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as outfile:
            outfile.write(f"=== CLIFFWALD PROJECT AUDIT ===\n")
            outfile.write(f"Root: {TARGET_DIR}\n\n")

            for root, dirs, files in os.walk(TARGET_DIR):
                # Filter directories in place to avoid traversing them
                dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
                
                for file in files:
                    ext = os.path.splitext(file)[1].lower()
                    if ext in EXTENSIONS:
                        full_path = os.path.join(root, file)
                        rel_path = os.path.relpath(full_path, TARGET_DIR)
                        
                        # Skip the output file itself and the huge server audit if it exists
                        if full_path == OUTPUT_FILE or file == "server_audit.txt":
                            continue

                        outfile.write(f"\n{'='*80}\n")
                        outfile.write(f"FILE: res://{rel_path.replace(os.sep, '/')}\n")
                        outfile.write(f"{ '='*80}\n")
                        
                        try:
                            with open(full_path, 'r', encoding='utf-8', errors='replace') as infile:
                                content = infile.read()
                                outfile.write(content)
                                outfile.write("\n")
                            file_count += 1
                        except Exception as e:
                            outfile.write(f"[ERROR READING FILE: {e}]\n")
        
        print(f"Audit completed. Processed {file_count} files.")
        print(f"Output saved to: {OUTPUT_FILE}")
        
    except Exception as e:
        print(f"Critical Error: {e}")

if __name__ == "__main__":
    generate_audit()
