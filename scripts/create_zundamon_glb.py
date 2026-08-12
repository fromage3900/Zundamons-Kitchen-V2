#!/usr/bin/env python3
import os
import math
import numpy as np
import trimesh

def build_zundamon_glb():
    meshes = []
    
    # 1. Zundamon Head (Sphere)
    head = trimesh.creation.icosphere(subdivisions=4, radius=1.0)
    head.apply_translation([0, 0, 0])
    meshes.append(head)
    
    # 2. Body (Smaller sphere)
    body = trimesh.creation.icosphere(subdivisions=3, radius=0.75)
    body.apply_translation([0, -1.3, 0])
    meshes.append(body)
    
    # 3. Left Pea Ear (Capsule / Cylinder)
    left_ear = trimesh.creation.capsule(height=1.2, radius=0.25)
    # Rotate ear slightly outward
    rot_matrix_l = trimesh.transformations.rotation_matrix(math.radians(-30), [0, 0, 1])
    left_ear.apply_transform(rot_matrix_l)
    left_ear.apply_translation([-0.75, 1.1, 0])
    meshes.append(left_ear)
    
    # 4. Right Pea Ear
    right_ear = trimesh.creation.capsule(height=1.2, radius=0.25)
    rot_matrix_r = trimesh.transformations.rotation_matrix(math.radians(30), [0, 0, 1])
    right_ear.apply_transform(rot_matrix_r)
    right_ear.apply_translation([0.75, 1.1, 0])
    meshes.append(right_ear)
    
    # 5. Top Stem / Leaf Node
    stem = trimesh.creation.cone(radius=0.15, height=0.5)
    stem.apply_translation([0, 1.25, 0])
    meshes.append(stem)

    # 6. Left Eye
    left_eye = trimesh.creation.icosphere(subdivisions=2, radius=0.12)
    left_eye.apply_translation([-0.35, 0.2, 0.9])
    meshes.append(left_eye)

    # 7. Right Eye
    right_eye = trimesh.creation.icosphere(subdivisions=2, radius=0.12)
    right_eye.apply_translation([0.35, 0.2, 0.9])
    meshes.append(right_eye)

    # Combine into Scene
    scene = trimesh.Scene(meshes)
    
    out_dir = os.path.join(os.path.dirname(__file__), "..", "site", "assets")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "zundamon.glb")
    
    scene.export(out_path)
    print(f"Exported 3D Zundamon GLB model to: {out_path} ({os.path.getsize(out_path)} bytes)")

if __name__ == "__main__":
    build_zundamon_glb()
