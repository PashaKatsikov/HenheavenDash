import os
from PIL import Image

SRC = r'D:\flutter_proj\Henhaven_Dash\asstets'
FILES = [
    'Horizontal_Loading_Screen.webp',
    'bg1_asset.webp', 'bg3_asset.webp', 'bg5_asset.webp', 'bg6_asset.webp',
    'chicken_asset.webp', 'foods_asset.webp', 'Icon.png',
]

def dominant_colors(path, n=6):
    im = Image.open(path).convert('RGB')
    im = im.resize((150, 150))
    q = im.quantize(colors=n, method=Image.MAXCOVERAGE)
    pal = q.getpalette()[:n*3]
    counts = sorted(q.getcolors(), reverse=True)
    colors = []
    for count, idx in counts:
        r, g, b = pal[idx*3:idx*3+3]
        colors.append((f'#{r:02X}{g:02X}{b:02X}', count))
    return colors

for f in FILES:
    print(f)
    for hexc, cnt in dominant_colors(os.path.join(SRC, f)):
        print(f'   {hexc}  weight={cnt}')
