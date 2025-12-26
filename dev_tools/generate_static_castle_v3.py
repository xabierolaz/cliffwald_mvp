import uuid

# Configuración v3.1 (Refined Proportions)
WALL_HEIGHT = 6.0 # Aumentado para que techos altos se sientan épicos
DOOR_WIDTH = 3.0
DOOR_HEIGHT = 4.0
WINDOW_WIDTH = 2.0
WINDOW_HEIGHT = 3.0
WINDOW_SILL = 1.5 # Altura del alféizar desde el suelo

tscn_content = """[gd_scene load_steps=7 format=3 uid="uid://castle_greybox_v3"]

[sub_resource type="StandardMaterial3D" id="Mat_Floor"]
albedo_color = Color(0.15, 0.15, 0.15, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Wall"]
albedo_color = Color(0.6, 0.6, 0.6, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Bed"]
albedo_color = Color(0.8, 0.2, 0.2, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Table"]
albedo_color = Color(0.4, 0.2, 0.1, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Crafting"]
albedo_color = Color(0.2, 0.8, 0.2, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Glass"]
transparency = 1
albedo_color = Color(0.4, 0.7, 1.0, 0.3)

[sub_resource type="NavigationMesh" id="NavigationMesh_v1"]
geometry_parsed_geometry_type = 1
geometry_source_geometry_mode = 0
agent_height = 1.8
agent_radius = 0.4

[node name="CastleGreybox" type="NavigationRegion3D"]
navigation_mesh = SubResource("NavigationMesh_v1")

[node name="CastleCSG" type="CSGCombiner3D" parent="."]
use_collision = true
"""

def add_box(name, pos, size, material_id, operation="UNION"):
    global tscn_content
    op_str = ""
    if operation == "SUBTRACTION":
        op_str = 'operation = 2'
    
    unique_name = f"{name}_{str(uuid.uuid4())[:4]}"
    
    tscn_content += f"""
[node name="{unique_name}" type="CSGBox3D" parent="CastleCSG"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})
{op_str}
size = Vector3({size[0]}, {size[1]}, {size[2]})
material = SubResource("{material_id}")
"""

def build_room(center, size, mat, open_ceiling=False):
    # Floor
    # Floor thickness 1m. Top surface at center[1]. So center Y is center[1] - 0.5.
    floor_y = center[1]
    add_box("Floor", (center[0], floor_y - 0.5, center[2]), (size[0], 1, size[2]), "Mat_Floor")
    
    thickness = 1.0
    h = size[1]
    # Walls sit ON the floor. Floor top is at floor_y.
    # Wall center Y = floor_y + h/2.
    h_y = floor_y + h / 2.0
    
    add_box("Wall_N", (center[0], h_y, center[2] - size[2]/2), (size[0], h, thickness), mat)
    add_box("Wall_S", (center[0], h_y, center[2] + size[2]/2), (size[0], h, thickness), mat)
    add_box("Wall_E", (center[0] + size[0]/2, h_y, center[2]), (thickness, h, size[2]), mat)
    add_box("Wall_W", (center[0] - size[0]/2, h_y, center[2]), (thickness, h, size[2]), mat)
    
    if not open_ceiling:
        add_box("Ceiling", (center[0], floor_y + h + 0.5, center[2]), (size[0], 1, size[2]), mat)

def cut_door(p_from, p_to):
    # Logic: Connect two points with a subtractive box.
    # Assumes both points are at Floor Level (Y).
    
    mid = [(p_from[0] + p_to[0])/2, (p_from[1] + p_to[1])/2, (p_from[2] + p_to[2])/2]
    dist = ((p_from[0]-p_to[0])**2 + (p_from[2]-p_to[2])**2)**0.5
    
    # Box Center Y.
    # Door sits on floor. Height 4. Center = FloorY + 2.
    floor_y = mid[1]
    center_y = floor_y + DOOR_HEIGHT / 2.0
    
    # Dimensions
    # We make it slightly longer than dist to ensure it punches through walls at ends
    long_dim = dist + 4.0 
    
    size = [DOOR_WIDTH, DOOR_HEIGHT, long_dim]
    if abs(p_from[0] - p_to[0]) > abs(p_from[2] - p_to[2]):
        # Horizontal cut (X axis dominant)
        size = [long_dim, DOOR_HEIGHT, DOOR_WIDTH]
        
    add_box("DoorCut", (mid[0], center_y, mid[2]), size, "Mat_Wall", "SUBTRACTION")

def cut_window(wall_center, facing_axis="Z"):
    # Cuts a window into a wall at 'wall_center'
    # wall_center is assumed to be on the wall plane at FLOOR level (we adjust Y up)
    
    floor_y = wall_center[1]
    center_y = floor_y + WINDOW_SILL + WINDOW_HEIGHT / 2.0
    
    thickness_cut = 4.0 # Deep cut to ensure penetration
    
    size = [WINDOW_WIDTH, WINDOW_HEIGHT, thickness_cut]
    if facing_axis == "X": # Wall runs along Z, Normal is X
        size = [thickness_cut, WINDOW_HEIGHT, WINDOW_WIDTH]
        
    add_box("WindowCut", (wall_center[0], center_y, wall_center[2]), size, "Mat_Glass", "SUBTRACTION")

def fill_beds_semantic(house_name, center):
    bed_size = (1.0, 0.5, 2.0)
    current_year = 1
    student_idx = 1
    start_x = center[0] - 8
    start_z = center[2] - 8
    floor_y = center[1]
    
    for x in range(0, 5): 
        for z in range(0, 6): 
            if current_year > 4: break
            bed_name = f"Bed_{house_name}_Y{current_year}_{student_idx:02d}"
            pos = (start_x + (x * 4.0), floor_y + 0.25, start_z + (z * 4.0))
            add_box(bed_name, pos, bed_size, "Mat_Bed")
            student_idx += 1
            if student_idx > 7:
                student_idx = 1
                current_year += 1

def create_dining_table(house_name, center):
    add_box(f"Table_{house_name}", (center[0], center[1] + 0.5, center[2]), (1.5, 1, 30), "Mat_Table")

def create_crafting_station(pos):
    add_box("CraftingStation", (pos[0], pos[1] + 0.6, pos[2]), (2.0, 1.2, 1.0), "Mat_Crafting")

# --- GENERATION v3.1 ---

# 1. HUB: GREAT HALL (30x50, High Ceiling)
gh_center = (0, 5, 0)
build_room(gh_center, (30, 12, 50), "Mat_Wall", open_ceiling=False)

# Dining
create_dining_table("Ignis", (8, 5, 0))
create_dining_table("Axiom", (3, 5, 0))
create_dining_table("Vesper", (-3, 5, 0))
create_dining_table("Staff", (-8, 5, 0))

# Windows in Great Hall (East and West walls)
# Wall E is at x=15. Wall W is at x=-15.
for z in range(-20, 21, 10): # 5 windows per side
    cut_window((15, 5, z), "X")
    cut_window((-15, 5, z), "X")

# 2. WINGS

# IGNIS (Basement)
ignis_center = (40, -5, 10)
build_room(ignis_center, (25, 6, 30), "Mat_Wall")
fill_beds_semantic("Ignis", ignis_center)
# Windows? It's a basement, maybe high slit windows?
for z in range(0, 21, 10):
    cut_window((52.5, -5, z), "X") # High windows on outer wall

# AXIOM (Tower)
axiom_center = (-40, 15, 10)
build_room(axiom_center, (20, 8, 20), "Mat_Wall")
fill_beds_semantic("Axiom", axiom_center)
# Tower Windows (All sides)
cut_window((-40, 15, 20), "Z")
cut_window((-40, 15, 0), "Z")
cut_window((-30, 15, 10), "X")
cut_window((-50, 15, 10), "X")

# VESPER (Garden Wing)
vesper_center = (0, 5, -40)
build_room(vesper_center, (30, 6, 30), "Mat_Wall", open_ceiling=True) # Open roof!
fill_beds_semantic("Vesper", vesper_center)
# No windows needed if roof is open, but let's add some facing garden
cut_window((0, 5, -55), "Z")

# 3. CONNECTIONS
# Hall -> Vesper
cut_door((0, 5, -25), (0, 5, -30))
# Hall -> Ignis (Ramp area)
cut_door((15, 5, 5), (25, 5, 5))
# Ignis Ramp (Manual box for floor)
add_box("Ramp_Ignis", (20, 0, 5), (10, 1, 15), "Mat_Floor") 
# Need to cut the wall between ramp and ignis room
cut_door((27, -5, 5), (28, -5, 5))

# 4. CLASSROOMS
# Potions
potions_pos = (50, -5, -20)
build_room(potions_pos, (15, 6, 15), "Mat_Wall")
cut_door(ignis_center, potions_pos) 

# Library
library_pos = (-50, 15, -20)
build_room(library_pos, (15, 6, 15), "Mat_Wall")
cut_window((-50, 15, -27.5), "Z") # View to outside

# 5. SECRET TUNNEL
add_box("SecretTunnel_Floor", (25, 0, -35), (40, 1, 4), "Mat_Floor")
# Tunnel needs to be "hollow". We build a big solid then subtract center?
# Or just build walls. Walls are cheaper for navmesh usually.
# Let's rely on the fact players can walk on the floor and just add side rails.
add_box("TunnelWall_1", (25, 2, -33), (40, 4, 1), "Mat_Wall")
add_box("TunnelWall_2", (25, 2, -37), (40, 4, 1), "Mat_Wall")


with open(r"D:\AI\Cliffwald\source\common\gameplay\maps\castle_greybox.tscn", "w") as f:
    f.write(tscn_content)

print("Castle v3.1 (Windows & Correct Doors) Generated")
