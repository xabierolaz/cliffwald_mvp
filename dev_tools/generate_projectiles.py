import os

base_path = r"D:\AI\Cliffwald\source\common\gameplay\combat\projectiles"
os.makedirs(base_path, exist_ok=True)

def create_projectile_tscn(name, color_vec, shape_type="Sphere", speed=20.0, damage=10.0):
    mesh_str = ""
    mesh_def = ""
    
    if shape_type == "Sphere":
        mesh_str = 'mesh = SubResource("SphereMesh_v1")'
        mesh_def = '[sub_resource type="SphereMesh" id="SphereMesh_v1"]\nradius = 0.3\nheight = 0.6\nmaterial = SubResource("Mat_Proj")'
    elif shape_type == "Box":
        mesh_str = 'mesh = SubResource("BoxMesh_v1")'
        mesh_def = '[sub_resource type="BoxMesh" id="BoxMesh_v1"]\nsize = Vector3(0.5, 0.5, 0.5)\nmaterial = SubResource("Mat_Proj")'
    elif shape_type == "Prism":
        mesh_str = 'mesh = SubResource("PrismMesh_v1")'
        mesh_def = '[sub_resource type="PrismMesh" id="PrismMesh_v1"]\nsize = Vector3(0.5, 0.5, 0.5)\nmaterial = SubResource("Mat_Proj")'

    content = f"""[gd_scene load_steps=6 format=3 uid=\"uid://proj_{name.lower()}\"]

[ext_resource type=\"Script\" path=\"res://source/common/gameplay/combat/projectiles/base_projectile.gd\" id=\"1_script\"]

[sub_resource type=\"StandardMaterial3D\" id=\"Mat_Proj\"]
albedo_color = Color({color_vec[0]}, {color_vec[1]}, {color_vec[2]}, 1)
emission_enabled = true
emission = Color({color_vec[0]}, {color_vec[1]}, {color_vec[2]}, 1)
emission_energy_multiplier = 2.0

{mesh_def}

[sub_resource type=\"SphereShape3D\" id=\"Shape_Col\"]
radius = 0.3

[sub_resource type=\"SceneReplicationConfig\" id=\"Rep_Config\"]
properties/0/path = NodePath(\".:position\")
properties/0/spawn = true
properties/0/replication_mode = 1
properties/1/path = NodePath(\".:direction\")
properties/1/spawn = true
properties/1/replication_mode = 1

[node name=\"{name}\" type=\"Area3D\"]
collision_layer = 4
collision_mask = 3
script = ExtResource(\"1_script\")
speed = {speed}
damage = {damage}

[node name=\"MeshInstance3D\" type=\"MeshInstance3D\" parent=\".\"]
{mesh_str}

[node name=\"CollisionShape3D\" type=\"CollisionShape3D\" parent=\".\"]
shape = SubResource(\"Shape_Col\")

[node name=\"MultiplayerSynchronizer\" type=\"MultiplayerSynchronizer\" parent=\".\"]
replication_config = SubResource(\"Rep_Config\")
"""
    with open(os.path.join(base_path, f"projectile_{name.lower()}.tscn"), "w") as f:
        f.write(content)

create_projectile_tscn("Kinetic", (1, 1, 1), "Sphere", 25.0, 10.0)
create_projectile_tscn("Aegis", (0, 0.5, 1), "Sphere", 0.0, 0.0)
create_projectile_tscn("Pyroclasm", (1, 0.2, 0), "Prism", 15.0, 30.0)
create_projectile_tscn("Stasis", (1, 1, 0), "Box", 30.0, 5.0)

print("Projectiles Generated")