import matplotlib.pyplot as plt
import matplotlib.patches as patches

def draw_castle_blueprint(version="1.0"):
    fig, ax = plt.subplots(figsize=(12, 12))
    ax.set_facecolor('#1a1a1a')

    def add_room(x, y, w, h, color, label, alpha=1.0):
        rect = patches.Rectangle((x, y), w, h, linewidth=2, edgecolor='white', facecolor=color, alpha=alpha)
        ax.add_patch(rect)
        ax.text(x + w/2, y + h/2, label, ha='center', va='center', color='white', fontsize=9, fontweight='bold')

    def add_connection(x, y, w, h, color='#404040'):
        rect = patches.Rectangle((x, y), w, h, linewidth=0, facecolor=color)
        ax.add_patch(rect)

    # --- VERSION 1.0 LAYOUT (LINEAR HUB & SPOKE) ---
    
    # HUB
    add_room(-15, -40, 30, 25, '#2d3436', "COURTYARD")
    add_room(-10, -15, 20, 15, '#636e72', "STAIRCASE")
    add_room(-20, 0, 40, 60, '#8e44ad', "GREAT HALL")
    add_room(-10, 60, 20, 10, '#2c3e50', "STAFF")

    # WINGS
    add_connection(-35, 10, 15, 10) # West Conn
    add_room(-65, 0, 30, 40, '#27ae60', "VESPER DORM")
    add_room(-65, -30, 30, 30, '#16a085', "GREENHOUSE")

    add_connection(20, 10, 15, 10) # East Conn
    add_room(35, 0, 30, 40, '#2980b9', "LIBRARY")
    add_room(35, 40, 30, 20, '#3498db', "AXIOM TOWER")

    # DEPTHS (Overlay)
    add_room(15, -15, 20, 15, '#c0392b', "IGNIS ENTRY", alpha=0.8)
    add_room(35, -40, 30, 25, '#d35400', "POTIONS", alpha=0.7)

    # Limits & Info
    ax.set_xlim(-80, 80)
    ax.set_ylim(-50, 80)
    ax.axis('off')
    
    # Version Label
    plt.text(75, 75, f"ver {version}", color='yellow', fontsize=20, fontweight='bold', ha='right')
    plt.title(f"CLIFFWALD CASTLE LAYOUT v{version}", color='white', pad=20)
    
    output_path = r"D:\AI\Cliffwald\castle_blueprint_v1.png"
    plt.savefig(output_path, dpi=100, bbox_inches='tight')
    print(f"Blueprint v{version} generated at: {output_path}")

if __name__ == "__main__":
    draw_castle_blueprint("1.0")
