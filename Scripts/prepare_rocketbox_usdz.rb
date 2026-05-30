#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "open3"
require "shellwords"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
SOURCE_DIR = File.join(ROOT, "Build", "RocketboxSource")
WORK_DIR = File.join(ROOT, "Build", "RocketboxUSD")
MODEL_ROOT = File.join(ROOT, "PoseReferenceApp", "Resources", "Models")
ROCKETBOX_REPO = "https://github.com/microsoft/Microsoft-Rocketbox.git"

ASSETS = [
  { tier: "Free", usdz: "Male_Adult_03", source: "Assets/Avatars/Adults/Male_Adult_03" },
  { tier: "Free", usdz: "Sports_Male_01", source: "Assets/Avatars/Professions/Sports_Male_01" },
  { tier: "Free", usdz: "Female_Adult_03", source: "Assets/Avatars/Adults/Female_Adult_03" },
  { tier: "Free", usdz: "Sports_Female_01", source: "Assets/Avatars/Professions/Sports_Female_01" },
  { tier: "Pro", usdz: "Business_Male_01", source: "Assets/Avatars/Professions/Business_Male_01" },
  { tier: "Pro", usdz: "Business_Female_01", source: "Assets/Avatars/Professions/Business_Female_01" },
  { tier: "Pro", usdz: "Military_Male_01", source: "Assets/Avatars/Professions/Military_Male_01" },
  { tier: "Pro", usdz: "Female_Party_01", source: "Assets/Avatars/Adults/Female_Party_01" }
].freeze

def run!(*cmd, chdir: nil)
  puts "$ #{cmd.shelljoin}"
  options = chdir ? { chdir: chdir } : {}
  stdout, stderr, status = Open3.capture3(*cmd, **options)
  puts stdout unless stdout.empty?
  warn stderr unless stderr.empty?
  raise "Command failed: #{cmd.shelljoin}" unless status.success?
end

def find_blender
  candidates = [
    ENV["BLENDER_PATH"],
    "/Applications/Blender.app/Contents/MacOS/Blender",
    "/opt/homebrew/bin/blender",
    "/usr/local/bin/blender"
  ].compact
  candidates.find { |path| File.executable?(path) } ||
    raise("Blender not found. Install it with: brew install --cask blender")
end

def ensure_rocketbox_source!
  sparse_paths = ASSETS.map { |asset| asset.fetch(:source) }
  if File.directory?(File.join(SOURCE_DIR, ".git"))
    run!("git", "fetch", "--depth", "1", "origin", chdir: SOURCE_DIR)
  else
    FileUtils.rm_rf(SOURCE_DIR)
    run!("git", "clone", "--depth", "1", "--filter=blob:none", "--sparse", ROCKETBOX_REPO, SOURCE_DIR)
  end

  run!("git", "sparse-checkout", "set", *sparse_paths, chdir: SOURCE_DIR)
end

def blender_script
  <<~PY
    import bpy
    import math
    import os
    import sys

    fbx_path = sys.argv[sys.argv.index("--") + 1]
    usdz_path = sys.argv[sys.argv.index("--") + 2]

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.ops.import_scene.fbx(filepath=fbx_path, use_anim=False)

    def make_material(name, color):
        material = bpy.data.materials.new(name)
        material.diffuse_color = color
        material.use_nodes = True
        bsdf = material.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = color
            bsdf.inputs["Roughness"].default_value = 0.72
            bsdf.inputs["Metallic"].default_value = 0.0
        return material

    skin = make_material("skin_reference", (0.72, 0.53, 0.42, 1.0))
    cloth = make_material("cloth_reference", (0.24, 0.30, 0.34, 1.0))
    dark = make_material("hair_and_shoes_reference", (0.06, 0.055, 0.05, 1.0))
    accent = make_material("accent_reference", (0.13, 0.45, 0.52, 1.0))

    for obj in bpy.context.scene.objects:
        obj.select_set(True)
        if obj.type == "MESH":
            obj.rotation_euler[0] = 0
            if len(obj.material_slots) == 0:
                obj.data.materials.append(cloth)
            for material_slot in obj.material_slots:
                material_name = (material_slot.material.name if material_slot.material else "").lower()
                object_name = obj.name.lower()
                if "head" in material_name or "skin" in material_name or "body" in material_name and "cloth" not in object_name:
                    material_slot.material = skin
                elif "hair" in material_name or "shoe" in material_name:
                    material_slot.material = dark
                elif "equipment" in material_name or "helmet" in material_name:
                    material_slot.material = accent
                else:
                    material_slot.material = cloth

    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    bpy.ops.wm.usd_export(
        filepath=usdz_path,
        selected_objects_only=False,
        export_materials=True,
        export_textures_mode="NEW",
        export_animation=False,
        export_uvmaps=True,
        export_armatures=True,
        only_deform_bones=False,
        triangulate_meshes=True,
        evaluation_mode="RENDER",
        root_prim_path="/Root"
    )
  PY
end

def convert_asset!(asset, blender_path, script_path)
  name = asset.fetch(:usdz)
  source = File.join(SOURCE_DIR, asset.fetch(:source))
  fbx = File.join(source, "Export", "#{name}.fbx")
  raise "Missing Rocketbox FBX: #{fbx}" unless File.file?(fbx)

  tier_dir = File.join(MODEL_ROOT, asset.fetch(:tier))
  FileUtils.mkdir_p(tier_dir)
  FileUtils.mkdir_p(WORK_DIR)

  usdz = File.join(tier_dir, "#{name}.usdz")
  FileUtils.rm_f(usdz)

  run!(blender_path, "--background", "--factory-startup", "--python", script_path, "--", fbx, usdz)
  run!("usdchecker", "--arkit", usdz)
end

FileUtils.mkdir_p(WORK_DIR)
ensure_rocketbox_source!

blender_path = find_blender
script_path = File.join(Dir.tmpdir, "poseframe_rocketbox_export.py")
File.write(script_path, blender_script)

ASSETS.each do |asset|
  convert_asset!(asset, blender_path, script_path)
end

puts "Generated #{ASSETS.size} Rocketbox USDZ files under #{MODEL_ROOT}"
