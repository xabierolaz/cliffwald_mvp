import uuid

# Configuración
WALL_HEIGHT = 4.0
DOOR_WIDTH = 2.5
DOOR_HEIGHT = 3.0

tscn_content = """[gd_scene load_steps=4 format=3 uid="uid://castle_greybox_v1"]

[sub_resource type="StandardMaterial3D" id="Mat_Floor"]
albedo_color = Color(0.2, 0.2, 0.2, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Wall"]
albedo_color = Color(0.5, 0.5, 0.5, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Bed"]
albedo_color = Color(0.86, 0.08, 0.24, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Table"]
albedo_color = Color(0.55, 0.27, 0.07, 1)

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
    
    # Ensure unique name collision avoidance for generic parts
    unique_name = name
    if "Wall" in name or "Door" in name or "Floor" in name:
        unique_name = f"{name}_{str(uuid.uuid4())[:4]}"
    
    tscn_content += f"""
[node name="{unique_name}" type="CSGBox3D" parent="CastleCSG"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})
{op_str}
size = Vector3({size[0]}, {size[1]}, {size[2]})
material = SubResource("{material_id}")
"""

def build_room_walls(center, size, mat):
    thickness = 1.0
    h = size[1]
    h_y = center[1] + h / 2.0
    
    add_box("Wall_N", (center[0], h_y, center[2] - size[2]/2), (size[0], h, thickness), mat)
    add_box("Wall_S", (center[0], h_y, center[2] + size[2]/2), (size[0], h, thickness), mat)
    add_box("Wall_E", (center[0] + size[0]/2, h_y, center[2]), (thickness, h, size[2]), mat)
    add_box("Wall_W", (center[0] - size[0]/2, h_y, center[2]), (thickness, h, size[2]), mat)

def cut_door(p_from, p_to):
    mid = [(p_from[0] + p_to[0])/2, (p_from[1] + p_to[1])/2, (p_from[2] + p_to[2])/2]
    dist = ((p_from[0]-p_to[0])**2 + (p_from[2]-p_to[2])**2)**0.5
    size = [DOOR_WIDTH, DOOR_HEIGHT, dist + 4.0]
    if abs(p_from[0] - p_to[0]) > abs(p_from[2] - p_to[2]):
        size = [dist + 4.0, DOOR_HEIGHT, DOOR_WIDTH]
    add_box("DoorCut", (mid[0], mid[1] + DOOR_HEIGHT/2, mid[2]), size, "Mat_Wall", "SUBTRACTION")

def fill_beds_semantic(house_name, center):
    bed_size = (1.5, 0.5, 2.5)
    start_x = center[0] - 10
    start_z = center[2] - 10
    
    current_year = 1
    student_idx = 1
    
    for x in range(5): 
        for z in range(6): 
            if current_year > 4: break
            bed_name = f"Bed_{house_name}_Y{current_year}_{student_idx:02d}"
            pos = (start_x + (x * 4.0), center[1] + 0.25, start_z + (z * 4.0))
            add_box(bed_name, pos, bed_size, "Mat_Bed")
            student_idx += 1
            if student_idx > 7:
                student_idx = 1
                current_year += 1

def create_desk_rows(class_name, center, rows, cols):
    desk_size = (1.2, 1.0, 0.6)
    chair_size = (0.5, 0.5, 0.5)
    spacing_x = 3.0
    spacing_z = 2.5
    start_x = center[0] - ((cols - 1) * spacing_x) / 2
    start_z = center[2] - ((rows - 1) * spacing_z) / 2
    
    idx = 1
    for r in range(rows):
        for c in range(cols):
            pos = (start_x + (c * spacing_x), center[1] + 0.5, start_z + (r * spacing_z))
            add_box("Desk_Generic", pos, desk_size, "Mat_Table")
            
            # Add Chair/Seat Point
            seat_pos = (pos[0], center[1] + 0.25, pos[2] + 1.0)
            seat_name = f"Seat_{class_name}_{idx:02d}"
            add_box(seat_name, seat_pos, chair_size, "Mat_Bed") # Red chairs
            idx += 1

def create_dining_table(house_name, center, length, seats_per_side):
    add_box(f"Table_{house_name}", center, (2, 1, length), "Mat_Table")
    
    chair_size = (0.5, 0.5, 0.5)
    start_z = center[2] - (length / 2) + 1.0
    step = (length - 2.0) / (seats_per_side - 1)
    
    for i in range(seats_per_side):
        z = start_z + (i * step)
        # Right side
        add_box(f"DiningSeat_{house_name}_{i+1:02d}_A", (center[0] + 1.5, center[1] - 0.25, z), chair_size, "Mat_Bed")
        # Left side
        add_box(f"DiningSeat_{house_name}_{i+1:02d}_B", (center[0] - 1.5, center[1] - 0.25, z), chair_size, "Mat_Bed")

# --- GENERATION ---

# 1. Floor
add_box("MainFloor", (0, -0.5, 0), (150, 1, 150), "Mat_Floor")

# 2. Perimeter walls
p_height = 10.0
wall_thick = 2.0
add_box("Perimeter_N", (0, p_height/2, -75), (150, p_height, wall_thick), "Mat_Wall")
add_box("Perimeter_S", (0, p_height/2, 75), (150, p_height, wall_thick), "Mat_Wall")
add_box("Perimeter_E", (75, p_height/2, 0), (wall_thick, p_height, 150), "Mat_Wall")
add_box("Perimeter_W", (-75, p_height/2, 0), (wall_thick, p_height, 150), "Mat_Wall")

# 3. Great Hall
build_room_walls((0, 0, 0), (40, WALL_HEIGHT, 60), "Mat_Wall")
# Dining Tables with Seats (Need 28 seats per house)
# 40m long table. 14 seats per side = 28 total.
create_dining_table("Ignis", (10, 0.5, 0), 30, 14)
create_dining_table("Axiom", (3, 0.5, 0), 30, 14)
create_dining_table("Vesper", (-3, 0.5, 0), 30, 14)
create_dining_table("Staff", (-10, 0.5, 0), 30, 14)

# 4. Dorms
ignis_pos = (55, 0, 0)
build_room_walls(ignis_pos, (30, WALL_HEIGHT, 40), "Mat_Wall")
cut_door((20, 0, 0), (40, 0, 0))
fill_beds_semantic("Ignis", ignis_pos)

axiom_pos = (-55, 0, 0)
build_room_walls(axiom_pos, (30, WALL_HEIGHT, 40), "Mat_Wall")
cut_door((-20, 0, 0), (-40, 0, 0))
fill_beds_semantic("Axiom", axiom_pos)

vesper_pos = (0, 0, 60)
build_room_walls(vesper_pos, (40, WALL_HEIGHT, 30), "Mat_Wall")
cut_door((0, 0, 30), (0, 0, 45))
fill_beds_semantic("Vesper", vesper_pos)

# 5. Classrooms
potions_pos = (30, 0, -50)
build_room_walls(potions_pos, (20, WALL_HEIGHT, 20), "Mat_Wall")
cut_door((20, 0, -30), potions_pos)
create_desk_rows("Potions", potions_pos, 4, 4) # 16 seats

library_pos = (-30, 0, -50)
build_room_walls(library_pos, (20, WALL_HEIGHT, 20), "Mat_Wall")
cut_door((-20, 0, -30), library_pos)
create_desk_rows("Library", library_pos, 4, 4)

with open(r"D:\AI\Cliffwald\source\common\gameplay\maps\castle_greybox.tscn", "w") as f:
    f.write(tscn_content)

print("Castle Tscn Generated with Semantic Seats")
