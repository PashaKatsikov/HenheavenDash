import os
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = r'D:\flutter_proj\Henhaven_Dash\asstets'
OUT = r'D:\flutter_proj\Henhaven_Dash\_analysis\sliced'
os.makedirs(OUT, exist_ok=True)

SHEETS = [
    'chicken_asset.webp',
    'clients_asset.webp',
    'cooking_ingredients_asset.webp',
    'decorative_elements_asset.webp',
    'effects_asset.webp',
    'foods_asset.webp',
    'rewards_collection_asset.webp',
    'rustic_farm_kitchen_asset.webp',
]

def process(fname):
    path = os.path.join(SRC, fname)
    im = Image.open(path).convert('RGBA')
    arr = np.array(im)
    alpha = arr[:, :, 3]
    mask = alpha > 10

    # Morphological closing: fills tiny internal AA gaps without bridging
    # separate icons the way plain dilation does.
    structure = np.ones((3, 3), dtype=bool)
    closed = ndimage.binary_closing(mask, structure=structure, iterations=2)

    labeled, num = ndimage.label(closed, structure=np.ones((3, 3)))
    objs = ndimage.find_objects(labeled)

    boxes = []
    for sl in objs:
        y0, y1 = sl[0].start, sl[0].stop
        x0, x1 = sl[1].start, sl[1].stop
        area = (y1 - y0) * (x1 - x0)
        if area < 400:  # filter tiny noise specks
            continue
        boxes.append((x0, y0, x1, y1))

    # sort into reading order: row by row (using y0 clustered), then x0
    boxes.sort(key=lambda b: (round(b[1] / 40), b[0]))

    name = os.path.splitext(fname)[0]
    sheet_out = os.path.join(OUT, name)
    os.makedirs(sheet_out, exist_ok=True)

    print(f"\n=== {fname} ({im.width}x{im.height}) -> {len(boxes)} sprites ===")
    for i, (x0, y0, x1, y1) in enumerate(boxes):
        pad = 4
        cx0 = max(0, x0 - pad)
        cy0 = max(0, y0 - pad)
        cx1 = min(im.width, x1 + pad)
        cy1 = min(im.height, y1 + pad)
        crop = im.crop((cx0, cy0, cx1, cy1))
        crop.save(os.path.join(sheet_out, f'{i:02d}.png'))
        print(f"  {i:02d}: box=({cx0},{cy0},{cx1},{cy1}) size=({cx1-cx0}x{cy1-cy0})")

for f in SHEETS:
    process(f)
