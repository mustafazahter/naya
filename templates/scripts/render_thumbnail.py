"""Kütüphane kartı için şablon modelinin saydam zeminli render'ı.

    blender -b --python render_thumbnail.py -- product.glb cikti.webp x,y,z

x,y,z kameranın modele bakış yönü (Blender'da Z yukarı). Model geniş
kadrajla render edilir, saydam kenarlar kırpılır ve 900×540 WebP olarak
yazılır (`apps/naya/assets/templates/<şablon>.webp`).
"""
import math
import os
import sys
import tempfile

import bpy
import numpy as np
from mathutils import Vector

WIDTH, HEIGHT = 900, 540


def main():
    glb, out, direction = sys.argv[sys.argv.index('--') + 1:]
    direction = Vector([float(v) for v in direction.split(',')]).normalized()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=glb)
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    points = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo, hi = Vector(map(min, *points)), Vector(map(max, *points))
    center, size = (lo + hi) / 2, (hi - lo).length

    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 96
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x, scene.render.resolution_y = 1800, 1080
    scene.view_settings.view_transform = 'AgX'
    scene.view_settings.look = 'AgX - Medium High Contrast'

    world = bpy.data.worlds.new('dunya')
    world.use_nodes = True
    background = next(n for n in world.node_tree.nodes
                      if n.type == 'BACKGROUND')
    background.inputs['Color'].default_value = (0.8, 0.82, 0.85, 1)
    background.inputs['Strength'].default_value = 0.6
    scene.world = world

    # Önden üstten ana ışık, karşı taraftan yumuşak dolgu.
    for name, angle, energy in (('ana', (0.9, 0.2, -0.6), 4.0),
                                ('dolgu', (1.1, -0.3, 2.4), 1.2)):
        light = bpy.data.lights.new(name, 'SUN')
        light.energy = energy
        light.angle = math.radians(8)
        obj = bpy.data.objects.new(name, light)
        obj.rotation_euler = angle
        scene.collection.objects.link(obj)

    camera_data = bpy.data.cameras.new('kamera')
    camera_data.lens = 70
    camera_data.clip_end = size * 20
    camera = bpy.data.objects.new('kamera', camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.location = center + direction * size * 2.2
    camera.rotation_euler = (center - camera.location).to_track_quat(
        '-Z', 'Y').to_euler()
    render = os.path.join(tempfile.gettempdir(), 'naya_kart.png')
    scene.render.filepath = render
    bpy.ops.render.render(write_still=True)
    fit(render, out)


def fit(source, out):
    """Saydam kenarları kırpar, 5:3 tuvale ortalar, WebP yazar."""
    image = bpy.data.images.load(source)
    w, h = image.size
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rows = np.where(pixels[:, :, 3].max(axis=1) > 0.01)[0]
    cols = np.where(pixels[:, :, 3].max(axis=0) > 0.01)[0]
    crop = pixels[rows[0]:rows[-1] + 1, cols[0]:cols[-1] + 1]
    ch, cw = crop.shape[:2]
    # Kenarda biraz boşluk kalsın.
    tw = max(cw, ch * WIDTH / HEIGHT) * 1.04
    th = tw * HEIGHT / WIDTH
    canvas = np.zeros((int(th), int(tw), 4), dtype=np.float32)
    y0, x0 = (int(th) - ch) // 2, (int(tw) - cw) // 2
    canvas[y0:y0 + ch, x0:x0 + cw] = crop
    result = bpy.data.images.new('kart', canvas.shape[1], canvas.shape[0],
                                 alpha=True)
    result.pixels = canvas.ravel()
    result.scale(WIDTH, HEIGHT)
    result.filepath_raw = out
    result.file_format = 'WEBP'
    result.save()


main()
