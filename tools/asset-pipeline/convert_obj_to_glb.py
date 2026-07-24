"""Headless Blender script: import an OBJ, export as GLB.
Usage: blender --background --python convert_obj_to_glb.py -- <in.obj> <out.glb>
"""
import bpy
import sys

argv = sys.argv[sys.argv.index("--") + 1:]
in_path, out_path = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=in_path)
bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB")
print(f"CONVERTED: {in_path} -> {out_path}")
