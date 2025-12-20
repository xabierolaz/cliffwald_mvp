import matplotlib.pyplot as plt
import matplotlib.patches as patches

def draw_castle_blueprint():
    fig, ax = plt.subplots(figsize=(12, 12))
    ax.set_facecolor('#1a1a1a') # Background dark

    # --- UTILS ---
    def add_room(x, y, w, h, color, label, alpha=1.0):
        rect = patches.Rectangle((x, y), w, h, linewidth=2, edgecolor='white', facecolor=color, alpha=alpha)
        ax.add_patch(rect)
        ax.text(x + w/2, y + h/2, label, ha='center', va='center', color='white', fontsize=9, fontweight='bold')

    def add_connection(x, y, w, h):
        rect = patches.Rectangle((x, y), w, h, linewidth=0, facecolor='#404040')
        ax.add_patch(rect)

    # --- LAYOUT ---
    
    # 1. CENTRAL AXIS (HUB)
    # Courtyard (Entry)
    add_room(-15, -40, 30, 25, '#2d3436', "COURTYARD\n(Spawn / Social)")
    
    # Grand Staircase (The Connector)
    add_room(-10, -15, 20, 15, '#636e72', "GRAND STAIRCASE\n(Up/Down Access)")
    
    # Great Hall (Dining)
    add_room(-20, 0, 40, 60, '#8e44ad', "GREAT HALL\n(Dining & Events)")
    
    # Headmaster / Staff Podium
    add_room(-10, 60, 20, 10, '#2c3e50', "Staff Podium")

    # 2. WEST WING (Nature & Magic)
    # Corridor West
    add_connection(-35, 10, 15, 10)
    # Vesper Dorms (Green)
    add_room(-65, 0, 30, 40, '#27ae60', "VESPER DORM\n(Nature / Ground)", alpha=0.8)
    # Greenhouse / Garden
    add_room(-65, -30, 30, 30, '#16a085', "GREENHOUSE\n(Ingredients)", alpha=0.6)

    # 3. EAST WING (Logic & Library)
    # Corridor East
    add_connection(20, 10, 15, 10)
    # Library (Blue/Silver vibe)
    add_room(35, 0, 30, 40, '#2980b9', "LIBRARY\n(Class Area)")
    # Axiom Dorm Entrance (Tower Base)
    add_room(35, 40, 30, 20, '#3498db', "AXIOM TOWER\n(Logic / Upper Floor Access)", alpha=0.8)

    # 4. UNDERGROUND / DEPTHS (Indicated by dashed lines or dark colors)
    # Ignis Entrance (Near Staircase)
    add_room(15, -15, 20, 15, '#c0392b', "IGNIS DEPTHS\n(Basement Entry)", alpha=0.8)
    # Potions Class (Basement Concept)
    add_room(35, -40, 30, 25, '#d35400', "POTIONS DUNGEON\n(Class Area)", alpha=0.7)

    # 5. LIMITS
    ax.set_xlim(-80, 80)
    ax.set_ylim(-50, 80)
    ax.axis('off') # Hide axes
    
    plt.title("CLIFFWALD CASTLE - GAMEPLAY FLOW LAYOUT v1", color='white', pad=20)
    plt.tight_layout()
    
    # Save
    output_path = r"D:\AI\Cliffwald\castle_blueprint_layout.png"
    plt.savefig(output_path, dpi=100, bbox_inches='tight')
    print(f"Blueprint generated at: {output_path}")

if __name__ == "__main__":
    draw_castle_blueprint()
