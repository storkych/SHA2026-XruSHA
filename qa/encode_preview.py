"""Encode Godot-rendered animation frames as a looping GIF, with one stable palette."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
directory = root / 'qa/captures/polish'
paths = sorted((directory / 'frames').glob('frame-*.png'))
assert len(paths) == 240, f'Expected 240 rendered frames, got {len(paths)}'
first = Image.open(paths[0]).convert('RGB')
palette = first.quantize(colors=224, method=Image.Quantize.MEDIANCUT)
frames = [Image.open(path).convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE) for path in paths]
output = directory / 'KhryuSHA2026-character-v2.gif'
frames[0].save(output, save_all=True, append_images=frames[1:], duration=[33, 33, 34] * 80, loop=0, optimize=False, disposal=1)
check = Image.open(output)
assert check.n_frames == 240
print(f'GIF: {output} ({output.stat().st_size:,} bytes, {check.n_frames} frames)')
