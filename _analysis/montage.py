import os
from PIL import Image, ImageDraw, ImageFont

BASE = r'D:\flutter_proj\Henhaven_Dash\_analysis\sliced'
OUT = r'D:\flutter_proj\Henhaven_Dash\_analysis\montages'
os.makedirs(OUT, exist_ok=True)

CELL = 160

def montage(sheet_name, cols=7):
    folder = os.path.join(BASE, sheet_name)
    files = sorted(os.listdir(folder), key=lambda f: int(f.split('.')[0]))
    n = len(files)
    rows = (n + cols - 1) // cols
    canvas = Image.new('RGBA', (cols * CELL, rows * CELL), (255, 255, 255, 255))
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype('arial.ttf', 20)
    except Exception:
        font = ImageFont.load_default()
    for i, fname in enumerate(files):
        im = Image.open(os.path.join(folder, fname)).convert('RGBA')
        im.thumbnail((CELL - 10, CELL - 30))
        r, c = divmod(i, cols)
        x = c * CELL + (CELL - im.width) // 2
        y = r * CELL + 5
        canvas.paste(im, (x, y), im)
        draw.rectangle([c * CELL, r * CELL, c * CELL + CELL - 1, r * CELL + CELL - 1], outline=(200, 200, 200, 255))
        draw.text((c * CELL + 4, r * CELL + CELL - 22), fname.split('.')[0], fill=(0, 0, 0, 255), font=font)
    canvas.save(os.path.join(OUT, f'{sheet_name}.png'))
    print(f'{sheet_name}: {n} icons -> montage saved')

for sheet in os.listdir(BASE):
    montage(sheet)
