"""Read-only sprite measurement. Source PNG pixels are never changed.

Writes Godot-compatible frame/pivot metadata so painted cells align to the same
cart chassis, rather than jumping around their full transparent canvas.
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/runner/v2'

def frames(name, cols, rows, hero=False):
    image = Image.open(ASSETS / name).convert('RGBA')
    result = []
    for index in range(cols * rows):
        x = round((index % cols) * image.width / cols)
        x2 = round((index % cols + 1) * image.width / cols)
        y = round((index // cols) * image.height / rows)
        y2 = round((index // cols + 1) * image.height / rows)
        cell = image.crop((x, y, x2, y2))
        alpha = cell.getchannel('A').point(lambda v: 255 if v > 150 else 0)
        bounds = alpha.getbbox()
        if not bounds:
            raise ValueError(f'Empty atlas frame {name}:{index}')
        points = []
        if hero:
            for py in range(cell.height // 2, cell.height):
                for px in range(cell.width):
                    r, g, b, a = cell.getpixel((px, py))
                    if a > 230 and r > 140 and g > 80 and b < g * 0.8 and r > g * 1.15:
                        points.append((px, py))
            if not points:
                raise ValueError('No chassis color detected')
            left = min(p[0] for p in points)
            right = max(p[0] for p in points)
            bottom = max(p[1] for p in points)
            pivot = [(left + right) / 2, bottom + 12]
            scale = 98.0 / (right - left)
        else:
            left, top, right, bottom = bounds
            pivot = [(left + right) / 2, bottom]
            scale = 62.0 / (right - left)
        result.append({'region': [x, y, x2-x, y2-y], 'bounds': list(bounds),
                       'pivot': pivot, 'scale': round(scale, 6)})
    return result

data = {'hero': frames('hero-atlas.png', 4, 2, True),
        'enemies': frames('enemies-atlas.png', 4, 2)}
if (ASSETS / 'props-atlas.png').exists():
    data['props'] = frames('props-atlas.png', 3, 2)
(ASSETS / 'atlas-data.json').write_text(json.dumps(data, indent=2), encoding='utf8')
(ASSETS / 'atlas_data.gd').write_text('extends RefCounted\nconst DATA = ' + json.dumps(data, indent=2) + '\n', encoding='utf8')
print(json.dumps(data, indent=2))
