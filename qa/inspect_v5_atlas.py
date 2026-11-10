"""Measure original PNGs; does not edit image pixels."""
from pathlib import Path
from collections import deque
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets/runner/v5'

def measure(name, columns, rows):
    image = Image.open(ROOT / name).convert('RGBA')
    alpha = np.array(image)[:, :, 3]
    width, height = image.size
    cells = []
    for index in range(columns * rows):
        x0, x1 = round(index % columns * width / columns), round((index % columns + 1) * width / columns)
        y0, y1 = round(index // columns * height / rows), round((index // columns + 1) * height / rows)
        mask = alpha[y0:y1, x0:x1] > 150
        seen = np.zeros_like(mask)
        best = []
        for y, x in zip(*np.where(mask)):
            if seen[y, x]:
                continue
            pending = [(int(x), int(y))]
            seen[y, x] = True
            component = []
            while pending:
                px, py = pending.pop()
                component.append((px, py))
                for nx, ny in ((px-1, py), (px+1, py), (px, py-1), (px, py+1)):
                    if 0 <= nx < mask.shape[1] and 0 <= ny < mask.shape[0] and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        pending.append((nx, ny))
            if len(component) > len(best):
                best = component
        xs, ys = zip(*best)
        bounds = [min(xs), min(ys), max(xs)+1, max(ys)+1]
        cells.append({'region': [x0, y0, x1-x0, y1-y0], 'bounds': bounds, 'pivot': [(x1-x0)*.5, max(ys)+1]})
    return cells

data = {'hero': measure('hero-atlas.png', 4, 4)}
data['hero_scale'] = 124 / float(np.median([c['bounds'][3] - c['bounds'][1] for c in data['hero'][:8]]))
if (ROOT / 'horses-atlas.png').exists():
    data['horse'] = measure('horses-atlas.png', 4, 2)
    data['horse_scale'] = 91 / float(np.median([c['bounds'][3] - c['bounds'][1] for c in data['horse'][:4]]))
(ROOT / 'atlas-data.json').write_text(json.dumps(data, indent=2), encoding='utf-8')
(ROOT / 'atlas_data.gd').write_text('extends RefCounted\nconst DATA = ' + json.dumps(data, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: v if not isinstance(v, list) else [c['bounds'] for c in v] for k, v in data.items()}))
