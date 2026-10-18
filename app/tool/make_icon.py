"""Draws the Ossia app icon: the googly-eyed bone mascot on the sunny accent.

Writes the source images that `flutter_launcher_icons` turns into every
Android and iOS size:

    assets/icon/icon.png         full icon (iOS, legacy Android)
    assets/icon/foreground.png   adaptive icon foreground, transparent
    assets/icon/monochrome.png   Android 13 themed icon silhouette

Run from the app folder:  python tool/make_icon.py
Then:                     dart run flutter_launcher_icons
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / 'assets' / 'icon'

SUNNY = (255, 210, 63, 255)
INK = (20, 20, 20, 255)
BONE = (255, 248, 234, 255)
BONE_SHADE = (240, 223, 194, 255)
BLUSH = (255, 158, 199, 210)
WHITE = (255, 255, 255, 255)

SS = 4        # supersampling factor
SIZE = 1024   # final edge length


def bone_parts(cx, cy, w, h):
    """Shaft rectangle and four knob circles of a cartoon bone."""
    k = h * 0.25
    shaft = h * 0.52  # chunkier than in-app so the face fits at icon size
    rect = (cx - w / 2 + k, cy - shaft / 2, cx + w / 2 - k, cy + shaft / 2)
    knobs = [(cx + sx * (w / 2 - k), cy + sy * (h / 2 - k), k)
             for sx in (-1, 1) for sy in (-1, 1)]
    return rect, knobs


def draw_bone(d, cx, cy, w, h, fill, grow=0.0):
    rect, knobs = bone_parts(cx, cy, w, h)
    x0, y0, x1, y1 = rect
    d.rectangle((x0, y0 - grow, x1, y1 + grow), fill=fill)
    for x, y, r in knobs:
        d.ellipse((x - r - grow, y - r - grow, x + r + grow, y + r + grow), fill=fill)


def mascot_layer(edge, bone_frac, tilt_deg, shadow=True, face=True, silhouette=None):
    """Transparent layer with the mascot, rotated, at supersampled size."""
    px = edge * SS
    layer = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    w = px * bone_frac
    h = w * 0.5
    cx = cy = px / 2
    stroke = w * 0.03

    if silhouette is not None:
        draw_bone(d, cx, cy, w, h, silhouette, grow=stroke)
        return layer.rotate(tilt_deg, resample=Image.BICUBIC)

    if shadow:
        off = w * 0.035
        draw_bone(d, cx + off, cy + off * 1.2, w, h, INK, grow=stroke)
    draw_bone(d, cx, cy, w, h, INK, grow=stroke)
    draw_bone(d, cx, cy, w, h, BONE_SHADE)
    # Lighter bone over the shade, nudged up, leaves a shaded lower lip.
    mask = Image.new('L', (px, px), 0)
    draw_bone(ImageDraw.Draw(mask), cx, cy, w, h, 255)
    top = Image.new('L', (px, px), 0)
    draw_bone(ImageDraw.Draw(top), cx, cy - h * 0.09, w, h, 255)
    layer.paste(BONE, (0, 0), Image.composite(top, Image.new('L', (px, px), 0), mask))

    if face:
        s = 1.1  # face a touch larger than in-app so it reads at small sizes
        eye_r = h * 0.1 * s
        eye_dx = w * 0.075 * s
        eye_y = cy - h * 0.05 * s
        line = max(2, int(stroke * 0.6))
        for sx in (-1, 1):
            ex = cx + sx * eye_dx
            d.ellipse((ex - eye_r, eye_y - eye_r, ex + eye_r, eye_y + eye_r),
                      fill=WHITE, outline=INK, width=line)
            pr = eye_r * 0.52
            px_, py_ = ex + eye_r * 0.18, eye_y + eye_r * 0.08
            d.ellipse((px_ - pr, py_ - pr, px_ + pr, py_ + pr), fill=INK)
            hr = pr * 0.3
            d.ellipse((px_ - pr * 0.35 - hr, py_ - pr * 0.35 - hr,
                       px_ - pr * 0.35 + hr, py_ - pr * 0.35 + hr), fill=WHITE)
        for sx in (-1, 1):
            bx, by = cx + sx * w * 0.14 * s, cy + h * 0.08 * s
            bw, bh = h * 0.075 * s, h * 0.042 * s
            d.ellipse((bx - bw, by - bh, bx + bw, by + bh), fill=BLUSH)
        mw = w * 0.055 * s
        my = cy + h * 0.07 * s
        d.chord((cx - mw, my - mw * 0.6, cx + mw, my + mw * 0.6), 0, 180,
                fill=INK)

    return layer.rotate(tilt_deg, resample=Image.BICUBIC)


def finish(img):
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    tilt = 24

    full = Image.new('RGBA', (SIZE * SS, SIZE * SS), SUNNY)
    full.alpha_composite(mascot_layer(SIZE, 0.7, tilt))
    finish(full).convert('RGB').save(OUT / 'icon.png')

    # flutter_launcher_icons insets the adaptive foreground by 16% a side, which
    # already lands it inside the safe zone, so draw it near full size.
    finish(mascot_layer(SIZE, 0.78, tilt)).save(OUT / 'foreground.png')
    finish(mascot_layer(SIZE, 0.78, tilt, silhouette=WHITE)).save(OUT / 'monochrome.png')
    print(f'Wrote icons to {OUT}')


if __name__ == '__main__':
    main()
