import matplotlib.pyplot as plt
import matplotlib.patches as patches

def draw_castle_blueprint_v2(version="2.0"):
    fig, ax = plt.subplots(figsize=(12, 12))
    ax.set_facecolor('#1a1a1a')

    def add_room(x, y, w, h, color, label, alpha=1.0, dashed=False):
        ls = '--' if dashed else '-'
        rect = patches.Rectangle((x, y), w, h, linewidth=2, edgecolor='white', facecolor=color, alpha=alpha, linestyle=ls)
        ax.add_patch(rect)
        if label:
            ax.text(x + w/2, y + h/2, label, ha='center', va='center', color='white', fontsize=8, fontweight='bold')

    def add_connection(x, y, w, h, color='#404040', label=None):
        rect = patches.Rectangle((x, y), w, h, linewidth=0, facecolor=color)
        ax.add_patch(rect)
        if label:
             ax.text(x + w/2, y + h/2, label, ha='center', va='center', color='#aaaaaa', fontsize=7, rotation=90)

    # --- VERSION 2.0 LAYOUT (CIRCULAR FLOW) ---
    
    # 1. HUB (Same core)
    add_room(-15, -40, 30, 25, '#2d3436', "COURTYARD")
    add_room(-10, -15, 20, 15, '#636e72', "STAIRS")
    add_room(-20, 0, 40, 60, '#8e44ad', "GREAT HALL")
    add_room(-10, 60, 20, 10, '#2c3e50', "STAFF")

    # 2. WINGS (Improved)
    # West Conn (Main)
    add_connection(-35, 10, 15, 10) 
    # NEW: West Side Door (Hall -> Greenhouse)
    add_connection(-35, -20, 15, 5, '#d63031', "Side Door") # Red for visibility
    
    add_room(-65, 0, 30, 40, '#27ae60', "VESPER DORM")
    add_room(-65, -30, 30, 30, '#16a085', "GREENHOUSE")

    # East Conn (Main)
    add_connection(20, 10, 15, 10)
    # NEW: East Side Door (Hall -> Library)
    add_connection(20, -20, 15, 5, '#d63031', "Side Door") # Red for visibility

    add_room(35, 0, 30, 40, '#2980b9', "LIBRARY")
    add_room(35, 40, 30, 20, '#3498db', "AXIOM TOWER")

    # 3. THE SECRET LOOP (Back Passage)
    # Connects Vesper Dorm (North) to Axiom Tower (North) behind the Great Hall
    add_connection(-35, 50, 90, 5, '#e17055', "SECRET PASSAGE (The Loop)")

    # 4. DEPTHS
    add_room(15, -15, 20, 15, '#c0392b', "IGNIS", alpha=0.8)
    add_room(35, -40, 30, 25, '#d35400', "POTIONS", alpha=0.7)
    # NEW: Potions Shortcut (Potions -> Library)
    add_connection(35, -15, 5, 15, '#e17055', "Shortcut")

    # Limits & Info
    ax.set_xlim(-80, 80)
    ax.set_ylim(-50, 80)
    ax.axis('off')
    
    plt.text(75, 75, f"ver {version}", color='#00ff00', fontsize=20, fontweight='bold', ha='right')
    plt.title(f"CLIFFWALD CASTLE LAYOUT v{version} (Circular Flow)", color='white', pad=20)
    
    output_path = r"D:\AI\Cliffwald\castle_blueprint_v2.png"
    plt.savefig(output_path, dpi=100, bbox_inches='tight')
    print(f"Blueprint v{version} generated at: {output_path}")

if __name__ == "__main__":
    draw_castle_blueprint_v2("2.0")
