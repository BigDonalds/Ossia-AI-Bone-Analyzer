"""Draws the whole skeleton that the atlas pages light a bone on.

Writes lib/data/skeleton_geometry.dart: every bone as SVG-style paths, for
the front view and the back view, plus which parts each atlas page lights.

Run from the app folder:  python tool/make_skeleton.py

One figure in a 200 x 480 box, drawn in front-view coordinates (the figure's
right side on the viewer's left). The back view is the same outline mirrored
left to right and painted in reverse depth order, with a few parts swapped
for their back-face versions (skull, feet, scapular spine and so on).

Every path uses only absolute M, L, C, Q and Z so the app can read them with
a tiny interpreter.

Each draw item: bone id, depth z (bigger = nearer the front of the body),
face ('both', 'front' or 'back'), shapes (closed outlines, the first one is
the silhouette), holes (always ink) and lines (detail strokes).
"""
import math
import os

W, H = 200, 480
CX = 100.0


def f(v):
    s = f'{v:.1f}'
    return s[:-2] if s.endswith('.0') else s


def pt(p):
    return f'{f(p[0])} {f(p[1])}'


# ---------------------------------------------------------------- primitives

def smooth_closed(pts, k=1.0):
    """Closed Catmull-Rom spline through pts, as cubic Beziers."""
    n = len(pts)
    d = [f'M {pt(pts[0])}']
    for i in range(n):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6 * k, p1[1] + (p2[1] - p0[1]) / 6 * k)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6 * k, p2[1] - (p3[1] - p1[1]) / 6 * k)
        d.append(f'C {pt(c1)} {pt(c2)} {pt(p2)}')
    d.append('Z')
    return ' '.join(d)


def smooth_open(pts, k=1.0):
    n = len(pts)
    d = [f'M {pt(pts[0])}']
    for i in range(n - 1):
        p0 = pts[i - 1] if i > 0 else pts[i]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[i + 2] if i + 2 < n else pts[i + 1]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6 * k, p1[1] + (p2[1] - p0[1]) / 6 * k)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6 * k, p2[1] - (p3[1] - p1[1]) / 6 * k)
        d.append(f'C {pt(c1)} {pt(c2)} {pt(p2)}')
    return ' '.join(d)


def poly(pts):
    return 'M ' + ' L '.join(pt(p) for p in pts) + ' Z'


def line(pts):
    return 'M ' + ' L '.join(pt(p) for p in pts)


def ellipse(cx, cy, rx, ry, rot=0.0):
    k = 0.5523
    a = math.radians(rot)
    ca, sa = math.cos(a), math.sin(a)

    def P(x, y):
        return (cx + x * ca - y * sa, cy + x * sa + y * ca)
    p = [P(rx, 0), P(0, ry), P(-rx, 0), P(0, -ry)]
    c = [(P(rx, k * ry), P(k * rx, ry)), (P(-k * rx, ry), P(-rx, k * ry)),
         (P(-rx, -k * ry), P(-k * rx, -ry)), (P(k * rx, -ry), P(rx, -k * ry))]
    d = [f'M {pt(p[0])}']
    for i in range(4):
        d.append(f'C {pt(c[i][0])} {pt(c[i][1])} {pt(p[(i + 1) % 4])}')
    return ' '.join(d) + ' Z'


def spline_pts(ctrl, steps=10):
    """Sample an open Catmull-Rom spline."""
    out = []
    n = len(ctrl)
    for i in range(n - 1):
        p0 = ctrl[i - 1] if i > 0 else ctrl[i]
        p1, p2 = ctrl[i], ctrl[i + 1]
        p3 = ctrl[i + 2] if i + 2 < n else ctrl[i + 1]
        for s in range(steps):
            t = s / steps
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2
                       + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2
                       + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(ctrl[-1])
    return out


def band(ctrl, w0, w1=None, wmid=None, n_out=9):
    """A rounded strip of varying width along a spline (ribs, clavicles)."""
    if w1 is None:
        w1 = w0
    if wmid is None:
        wmid = (w0 + w1) / 2
    s = spline_pts(ctrl, 12)
    # cumulative length for the width profile
    L = [0.0]
    for i in range(1, len(s)):
        L.append(L[-1] + math.dist(s[i], s[i - 1]))
    tot = L[-1]
    left, right = [], []
    idx = [round(i * (len(s) - 1) / (n_out - 1)) for i in range(n_out)]
    for i in idx:
        a = s[max(i - 1, 0)]
        b = s[min(i + 1, len(s) - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        m = math.hypot(dx, dy) or 1
        nx, ny = -dy / m, dx / m
        u = L[i] / tot
        w = (w0 * (1 - u) * (1 - 2 * u) + w1 * u * (2 * u - 1) + wmid * 4 * u * (1 - u)) / 2
        left.append((s[i][0] + nx * w, s[i][1] + ny * w))
        right.append((s[i][0] - nx * w, s[i][1] - ny * w))
    # rounded ends: one extra point beyond each end
    def cap(p, q, w):
        dx, dy = p[0] - q[0], p[1] - q[1]
        m = math.hypot(dx, dy) or 1
        return (p[0] + dx / m * w * 0.55, p[1] + dy / m * w * 0.55)
    e0 = cap(s[0], s[2], w0 / 2)
    e1 = cap(s[-1], s[-3], w1 / 2)
    ring = left + [e1] + right[::-1] + [e0]
    return smooth_closed(ring, 0.9)


def mx(p):
    return (2 * CX - p[0], p[1])


def mirror_d(d):
    """Mirror an M/L/C/Q/Z path left to right."""
    toks = d.split()
    out = []
    i = 0
    expect_x = True
    while i < len(toks):
        t = toks[i]
        if t in 'MLCQZ':
            out.append(t)
            expect_x = True
        else:
            v = float(t)
            if expect_x:
                out.append(f(2 * CX - v))
            else:
                out.append(f(v))
            expect_x = not expect_x
        i += 1
    return ' '.join(out)


# ---------------------------------------------------------------- the figure

ITEMS = []


def add(bone, z, shapes, holes=(), lines=(), face='both', side=None):
    ITEMS.append(dict(bone=bone, z=z, face=face, shapes=list(shapes),
                      holes=list(holes), lines=list(lines), side=side))


def pair(bone, z, shapes, holes=(), lines=(), face='both'):
    """Viewer-left geometry is the figure's right; mirror it for the left."""
    add(f'{bone}_r', z, shapes, holes, lines, face, 'r')
    add(f'{bone}_l', z, [mirror_d(d) for d in shapes], [mirror_d(d) for d in holes],
        [mirror_d(d) for d in lines], face, 'l')


def sym(half):
    """Points for the viewer-left half from top centre to bottom centre;
    returns the whole closed ring."""
    right = [mx(p) for p in reversed(half[1:-1])]
    return half + right


# --- skull -----------------------------------------------------------------

cranium_front = smooth_closed(sym([
    (100, 10), (89.5, 11.8), (82.2, 18), (79, 28), (79.4, 38), (80.6, 45),
    (78.6, 49.5), (79.6, 54), (83.6, 56.6), (87.6, 58.2), (88.8, 62),
    (93, 64.4), (100, 64.8),
]), 0.9)
orbit_r = smooth_closed([(84.2, 40.4), (86.6, 36.4), (91.6, 35.6), (95.6, 37.4),
                         (96.2, 42), (93.4, 45.4), (88, 45.6), (85, 43.6)])
nasal = smooth_closed([(100, 47.2), (102.6, 51), (103.4, 55.4), (101.8, 57.6),
                       (100, 57), (98.2, 57.6), (96.6, 55.4), (97.4, 51)])
teeth_up = [line([(x, 60.6), (x, 64.4)]) for x in (91.6, 94.6, 97.4, 102.6, 105.4, 108.4)]
cranium_lines = [
    smooth_open([(82.5, 53.4), (86.8, 51.2), (91, 52.6)]),            # cheekbone
    smooth_open([(117.5, 53.4), (113.2, 51.2), (109, 52.6)]),
    smooth_open([(89.5, 60.4), (100, 61.2), (110.5, 60.4)]),          # upper tooth row
] + teeth_up
add('cranium', 30, [cranium_front], [orbit_r, mirror_d(orbit_r), nasal],
    cranium_lines, face='front')

# from behind: the vault and the occiput, the face is hidden
cranium_back = smooth_closed(sym([
    (100, 10), (89.5, 11.8), (82.2, 18), (79, 28), (79.2, 38), (80, 46),
    (79.2, 51), (81.6, 55.6), (85.4, 58.6), (89.4, 57.8), (94, 59.6),
    (100, 60.4),
]), 0.9)
cranium_back_lines = [
    smooth_open([(84, 30), (92, 22.6), (100, 20.2), (108, 22.6), (116, 30)]),  # lambdoid
    line([(100, 10.6), (100, 20.2)]),                                         # sagittal
    smooth_open([(91, 49), (100, 46.6), (109, 49)]),                          # nuchal line
]
add('cranium', 30, [cranium_back], [], cranium_back_lines, face='back')

mandible = smooth_closed([
    (85.2, 55.6), (84.8, 61.4), (86.4, 67.6), (90, 71.2), (95, 73), (100, 73.6),
    (105, 73), (110, 71.2), (113.6, 67.6), (115.2, 61.4), (114.8, 55.6),
    (111.8, 56.4), (111.2, 61.6), (107.2, 64.6), (100, 65.2),
    (92.8, 64.6), (88.8, 61.6), (88.2, 56.4),
])
teeth_low = [line([(x, 64.8), (x, 68)]) for x in (92.8, 95.6, 98.2, 101.8, 104.4, 107.2)]
add('mandible', 31, [mandible], [],
    [smooth_open([(90.6, 67.4), (100, 68.4), (109.4, 67.4)])] + teeth_low)

# --- spine -------------------------------------------------------------------

def level_bounds(start, end, n):
    step = (end - start) / n
    return [(start + i * step, start + (i + 1) * step) for i in range(n)]


CERV = level_bounds(56.8, 91.4, 7)
THOR = level_bounds(91.4, 166.0, 12)
LUMB = level_bounds(166.0, 209.4, 5)


def vert_front(y0, y1, body_hw, tp_hw, tp_y=0.45, tp_h=0.34, gap=0.9):
    """A vertebra seen from the front: body with the transverse processes."""
    a, b = y0 + gap / 2, y1 - gap / 2
    h = b - a
    ty = a + h * tp_y
    th = h * tp_h
    half = [
        (100, a), (100 - body_hw * 0.92, a + 0.1), (100 - body_hw, a + h * 0.22),
        (100 - body_hw * 1.02, ty - th * 0.2), (100 - tp_hw, ty - th * 0.45),
        (100 - tp_hw - 0.6, ty + th * 0.2), (100 - tp_hw, ty + th * 0.75),
        (100 - body_hw * 1.02, ty + th * 0.85), (100 - body_hw * 1.06, b - h * 0.12),
        (100 - body_hw * 0.94, b), (100, b),
    ]
    return smooth_closed(sym(half), 0.85)


def vert_back(y0, y1, lam_hw, tp_hw, sp_drop, sp_w=1.4, gap=0.9):
    """A vertebra seen from behind: lamina, transverse and spinous processes."""
    a, b = y0 + gap / 2, y1 - gap / 2
    h = b - a
    half = [
        (100, a - 0.2), (100 - sp_w * 1.3, a + 0.1), (100 - lam_hw, a + h * 0.05),
        (100 - tp_hw, a + h * 0.2), (100 - tp_hw - 0.5, a + h * 0.45),
        (100 - tp_hw + 0.4, a + h * 0.66), (100 - lam_hw, a + h * 0.72),
        (100 - lam_hw * 0.8, b), (100 - sp_w, b + sp_drop * 0.4),
        (100 - sp_w * 0.6, b + sp_drop), (100, b + sp_drop + 0.6),
    ]
    return smooth_closed(sym(half), 0.85)


def spine():
    for i, (y0, y1) in enumerate(CERV):
        n = i + 1
        bhw = 2.6 + 0.12 * i
        thw = 6.6 + 0.25 * i if n > 1 else 7.8
        add(f'c{n}', 20, [vert_front(y0, y1, bhw, thw)], face='front')
        drop = 0.8 if n < 7 else 2.4
        add(f'c{n}', 14, [vert_back(y0, y1, 4.6 + 0.12 * i, thw, drop,
                                    sp_w=1.2 if n < 7 else 1.6)], face='back')
    for i, (y0, y1) in enumerate(THOR):
        n = i + 1
        bhw = 3.4 + 0.16 * i
        thw = 8.6 - 0.18 * i
        add(f't{n}', 20, [vert_front(y0, y1, bhw, thw, tp_y=0.35, tp_h=0.38)], face='front')
        add(f't{n}', 14, [vert_back(y0, y1, 4.4 + 0.08 * i, thw, 2.2, sp_w=1.5)], face='back')
    for i, (y0, y1) in enumerate(LUMB):
        n = i + 1
        bhw = 5.4 + 0.25 * i
        thw = 8.8 + 0.4 * i if n != 3 else 10.4
        add(f'l{n}', 20, [vert_front(y0, y1, bhw, thw, tp_y=0.42, tp_h=0.3, gap=1.2)], face='front')
        add(f'l{n}', 14, [vert_back(y0, y1, 5.6 + 0.2 * i, thw, 1.0, sp_w=2.4, gap=1.2)], face='back')


spine()

# sacrum and coccyx (never highlighted, but the hip pages need them clear)
sacrum = smooth_closed(sym([
    (100, 209.6), (92, 209.4), (86.6, 211.4), (87.4, 216.4), (89.8, 222.4),
    (93, 229), (96.2, 234.6), (98.2, 237.4), (100, 237.8),
]), 0.9)
sacral_holes = [ellipse(100 + dx, y, 1.1, 0.9) for y, dx in ((215, 6.2), (221, 5.4), (226.8, 4.4), (232, 3.2)) for dx in (dx, -dx)]
add('sacrum', 18, [sacrum], sacral_holes, [], face='front')
add('sacrum', 18, [sacrum], sacral_holes,
    [line([(100, 212), (100, 232)])], face='back')
coccyx = smooth_closed([(97.6, 238.4), (102.4, 238.4), (101.6, 242.6), (100, 245), (98.4, 242.6)])
add('coccyx', 18, [coccyx])

# --- ribs, sternum, clavicles -------------------------------------------------

# lateral half width, and where the front part of each rib meets its cartilage
RIB_HW = [21.5, 29.5, 34, 37, 39, 40.2, 40.8, 40.6, 39.8, 38.2, 35.4, 31]
RIB_ANT = [(88.6, 100.2), (84.6, 110), (80.6, 120.4), (77.8, 129.6), (76, 138),
           (75, 145.6), (75.2, 152), (73.2, 157.8), (70.4, 162.6), (67.8, 167.2),
           (65, 175), (72, 178.4)]
STERNUM_JOIN = [(93.2, 101.6), (94.6, 110.6), (95, 118.2), (95.2, 124.4), (95.4, 130.2),
                (95.6, 135.4), (96.4, 141)]


def rib_ctrl(n):
    i = n - 1
    y0, y1 = THOR[i]
    yp = (y0 + y1) / 2 - 0.6
    hw = RIB_HW[i]
    xa, ya = RIB_ANT[i]
    drop = 4.2 + 0.75 * n
    xl, yl = 100 - hw, yp + drop
    w = 3.4 if n == 1 else (3.0 if n == 2 else (2.7 if n < 11 else 2.4))
    if n <= 10:
        back = [(96.4, yp), (100 - hw * 0.42, yp - 1.3), (100 - hw * 0.8, yp + drop * 0.25),
                (xl + 0.3, yl - 0.4)]
        front = [(xl + 0.3, yl - 0.4), (xl + 1.0, yl + (ya - yl) * 0.4),
                 (xl + (xa - xl) * 0.5, ya - 1.2), (xa, ya)]
    else:
        # floating ribs end free, out at the side
        back = [(96.4, yp), (100 - hw * 0.45, yp + 0.4), (100 - hw * 0.85, yp + drop * 0.55),
                (xa, ya)]
        front = None
    return back, front, w


# each half is drawn full width in the view that faces it and thinner in the
# other, so the near side of the cage reads first
for n in range(1, 13):
    back, front, w = rib_ctrl(n)
    end_w = w * (0.6 if n >= 11 else 1.0)
    pair(f'rib{n}', 16, [band(back, w * 0.9, end_w, n_out=7)], face='back')
    pair(f'rib{n}', 16, [band(back, w * 0.62, end_w * 0.7, n_out=7)], face='front')
    if front:
        pair(f'rib{n}', 26, [band(front, w, w * 1.05, n_out=7)], face='front')
        pair(f'rib{n}', 26, [band(front, w * 0.7, w * 0.72, n_out=7)], face='back')

# costal cartilage (not bone, never lit)
cart = []
for n in range(1, 7):
    a = RIB_ANT[n - 1]
    j = STERNUM_JOIN[n - 1]
    mid = ((a[0] + j[0]) / 2, (a[1] + j[1]) / 2 + (0.5 if n < 5 else 1.4))
    cart.append(band([a, mid, j], 2.2, 2.0, n_out=5))
# the seventh runs up to the bottom of the sternum and the next three join it,
# which draws the costal margin
cart.append(band([RIB_ANT[6], (84, 148.8), STERNUM_JOIN[6]], 2.3, 2.0, n_out=7))
for n, tgt in ((8, (81, 151.2)), (9, (76.6, 156.8)), (10, (73.4, 161.8))):
    a = RIB_ANT[n - 1]
    cart.append(band([a, ((a[0] + tgt[0]) / 2 - 0.2, (a[1] + tgt[1]) / 2 + 0.6), tgt], 2.0, 1.7, n_out=5))
pair('cartilage', 27, cart)

sternum = smooth_closed(sym([
    (100, 97.6), (97.4, 98.2), (93.4, 98.6), (92.6, 101.6), (94.4, 106.8),
    (95.4, 110.4), (94.8, 112.6), (94.8, 124), (94.6, 134), (95.4, 140),
    (97.6, 142.2), (98.2, 146.6), (100, 148.6),
]), 0.9)
add('sternum', 28, [sternum], [], [line([(95.2, 111.2), (104.8, 111.2)])])

clav = band([(93.6, 97.6), (85, 98.4), (71, 95.6), (60.6, 94.6), (52.6, 93.6)], 4.0, 3.6, wmid=3.0, n_out=9)
pair('clavicle', 29, [clav])

# --- shoulder girdle and arms ---------------------------------------------------

scap = smooth_closed([
    (79.4, 104.6), (82.2, 110), (83.4, 122), (84.6, 136.6), (82, 141.6),
    (76.6, 139.2), (68.4, 129), (60.6, 117.4), (57.4, 110.6), (57.6, 104.6),
    (61.8, 101.2), (70.2, 101.4),
], 0.95)
scap_parts = [
    scap,
    band([(56.6, 95.2), (51.2, 95.4), (49.4, 98.2), (52.6, 100.2)], 4.2, 3.2, n_out=6),  # acromion
    ellipse(57.8, 106.2, 2.6, 4.6, -10),                                             # glenoid rim
]
add('scapula_r', 12, scap_parts,
    lines=[smooth_open([(63.4, 104.2), (60, 106.2)])], face='front', side='r')
add('scapula_l', 12, [mirror_d(d) for d in scap_parts],
    lines=[mirror_d(smooth_open([(63.4, 104.2), (60, 106.2)]))], face='front', side='l')
# from behind the spine of the scapula and the acromion stand out
spine_s = band([(81.4, 112.6), (73, 108.4), (63.8, 103.6), (56.4, 98.8), (51.6, 97.2)], 1.8, 4.4, wmid=3.4, n_out=9)
scap_back = [scap, band([(56.6, 95.2), (51.2, 95.4), (49.4, 98.2), (52.6, 100.2)], 4.2, 3.2, n_out=6),
             spine_s]
add('scapula_r', 12, scap_back,
    lines=[smooth_open([(80.4, 116), (72, 112.4), (62, 108.6)])], face='back', side='r')
add('scapula_l', 12, [mirror_d(d) for d in scap_back],
    lines=[mirror_d(smooth_open([(80.4, 116), (72, 112.4), (62, 108.6)]))], face='back', side='l')

# humerus: head at the shoulder, shaft, flared lower end
hum_shaft = smooth_closed([
    (52.6, 104.4), (57.8, 106.2), (58.4, 112), (57.4, 124), (56.6, 146), (57.2, 164),
    (59, 174.6), (60.6, 179.6), (57.6, 182.8), (53.2, 181.6), (48.6, 183.4),
    (45, 182.4), (44.6, 178.6), (47.4, 172), (48.6, 160), (49.4, 140), (49.6, 122),
    (48.4, 110.6), (49.4, 106),
], 0.95)
hum_head = ellipse(54.6, 103.4, 5.4, 5.8, 0)
pair('humerus', 34, [hum_shaft, hum_head], lines=[smooth_open([(48.4, 178.8), (52.4, 180.2), (57.6, 179)])])

# forearm, palms forward: radius on the thumb side (outer), ulna on the inner side
radius = smooth_closed([
    (47.4, 183.6), (51.2, 183.4), (51.6, 186.6), (50.4, 189), (49.6, 200), (47.6, 216),
    (45.4, 232), (45, 242), (45.4, 246.6), (41.4, 248.6), (37, 247.6), (37, 243),
    (39.6, 234), (43.6, 216), (45.6, 199), (46.6, 189), (45.6, 186.2),
], 0.95)
ulna = smooth_closed([
    (53, 182.8), (58.6, 181.8), (59.6, 185.6), (57.4, 191), (55.2, 200), (53, 214),
    (50.2, 232), (48.6, 242), (49.4, 246.4), (46.6, 248.2), (44.4, 246.4), (45.2, 240),
    (46.8, 230), (49.6, 212), (51.8, 198), (53.4, 190), (52.4, 186),
], 0.95)
pair('ulna', 35, [ulna])
pair('radius', 36, [radius])
olecranon = smooth_closed([(52, 181.6), (55.8, 178.8), (59.6, 180.6), (60, 185.4), (56.8, 188.6), (53, 186.6)])
add('ulna_r', 10, [olecranon], face='back', side='r')
add('ulna_l', 10, [mirror_d(olecranon)], face='back', side='l')


def hand():
    """A palm-forward hand hanging down, thumb out to the side."""
    parts = []
    parts.append(smooth_closed([(38.8, 248.6), (47.8, 248.2), (49.6, 253.6), (47.6, 258.2),
                                (39.6, 258.8), (36.6, 254)], 0.9))  # carpals
    # metacarpals and fingers: base x, angle; thumb first
    digits = [((38.6, 255.6), (31.4, 266.6), (29.2, 274.2), 2.6),          # thumb
              ((40.4, 258.4), (38.2, 272.4), (36.6, 288.2), 2.2),
              ((43, 258.8), (42.4, 273.8), (42, 291.6), 2.2),
              ((45.4, 258.6), (46.2, 273), (46.8, 289), 2.1),
              ((47.6, 257.4), (49.8, 270.4), (51.2, 283.4), 1.9)]
    lines = []
    for base, knuckle, tip, w in digits:
        parts.append(band([base, knuckle], w * 1.1, w * 1.15, n_out=5))
        mid = ((knuckle[0] + tip[0]) / 2, (knuckle[1] + tip[1]) / 2)
        parts.append(band([knuckle, mid, tip], w, w * 0.75, n_out=5))
    return parts, lines


hp, hl = hand()
pair('hand', 38, hp)

# --- pelvis ------------------------------------------------------------------

os_coxa = smooth_closed([
    (90.4, 207.6), (86.2, 199.6), (79.6, 193.2), (71.4, 191.6), (64.6, 194.8),
    (62.2, 201.8), (64.4, 209.6), (68.8, 216.2), (71.6, 222.4), (72.8, 229.6),
    (76.4, 236.4), (81.2, 241.4), (85.4, 244.6), (90.2, 243.2), (93.2, 240.2),
    (97.8, 238.4), (98.6, 233.6), (95.4, 231.6), (90.6, 229.2), (88.4, 224.6),
    (88.6, 218.2), (89.4, 212.6),
], 0.95)
obturator = smooth_closed([(83.2, 230.4), (88.4, 232.6), (91.8, 236), (89.6, 239.6),
                           (84.4, 239.6), (81.4, 235.2)])
acetab_front = ellipse(77.8, 226.2, 5.6, 5.8)
pair('os_coxa', 22, [os_coxa], [obturator],
     [smooth_open([(68.6, 200.6), (74.6, 197.6), (81.6, 199.4), (86.4, 205)]),   # iliac fossa rim
      smooth_open([(73.2, 222.8), (77.8, 220.4), (82.2, 222.8)])])

# --- legs ---------------------------------------------------------------------

fem_shaft = smooth_closed([
    (69.2, 224.6), (75.2, 222.4), (78.6, 226.4), (78.4, 234), (80, 248),
    (83.2, 290), (85.8, 318), (88.6, 330), (90.6, 336.6), (88.8, 340.6),
    (83.8, 339.6), (80.8, 341.4), (76.6, 340.6), (75.6, 335.6), (77, 326),
    (76.6, 300), (72.6, 262), (69.8, 240), (67.6, 232.6), (66.8, 227.6),
], 0.95)
fem_neck = band([(72.4, 230), (79.6, 226.6), (84.2, 225.4)], 6.4, 5.4, n_out=5)
fem_head = ellipse(84, 225.6, 4.8, 4.8)
pair('femur', 24, [fem_shaft, fem_neck, fem_head],
     lines=[smooth_open([(78.2, 336.4), (83.6, 334), (88.6, 336)])])

patella = smooth_closed([(83.4, 325.6), (87.6, 324.4), (90.2, 327.8), (89.4, 333.2),
                         (86.2, 336.2), (83, 333.4), (82.2, 329)])
pair('patella', 32, [patella], face='front')

tibia = smooth_closed([
    (79.8, 343.4), (85.2, 342.2), (90.8, 343), (91.6, 347), (89.6, 352),
    (88.8, 372), (88.4, 400), (88.6, 428), (90.4, 440), (90.6, 447.6),
    (87.6, 449.4), (85.4, 446.6), (82.6, 445.8), (82.4, 440), (83.4, 426),
    (83.6, 398), (82.6, 370), (80.8, 353.6), (79, 349.6),
], 0.95)
fibula = smooth_closed([
    (77.2, 347.4), (80.4, 346.8), (81.2, 350.4), (80, 356), (80.4, 390),
    (81, 420), (81.6, 440), (82.8, 448.8), (80.2, 451.4), (77.8, 449.2),
    (78, 440), (77.6, 420), (77, 390), (77, 356), (76.4, 351),
], 0.95)
pair('fibula', 23, [fibula])
pair('tibia', 25, [tibia])


def foot_front():
    parts = [smooth_closed([(80.4, 448.8), (91.8, 448.6), (93.6, 455.4), (90.4, 460.4),
                            (80.6, 460.6), (78, 454.6)], 0.9)]
    toes = [((90.6, 458.8), (95.6, 468.6), 3.0), ((87.8, 459.6), (90.2, 470.4), 2.4),
            ((85.4, 460), (85.8, 470.6), 2.3), ((83, 459.8), (81.8, 470.2), 2.2),
            ((80.8, 459.4), (77.6, 468.8), 2.1)]
    for a, b, w in toes:
        parts.append(band([a, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), b], w, w * 0.9, n_out=5))
    return parts


def foot_back():
    return [smooth_closed([(80.6, 448), (91, 448), (92.6, 455), (90.6, 463.4), (86, 466.6),
                           (81.4, 463.4), (79.2, 455)], 0.9)]


pair('foot', 30, foot_front(), face='front')
pair('foot', 30, foot_back(), face='back')

# --------------------------------------------------------------- highlight map

def side_pair(b):
    return [f'{b}_r', f'{b}_l']


HIGHLIGHT = {
    'skull': ['cranium', 'mandible'],
    'cranium': ['cranium'],
    'mandible': ['mandible'],
    'femur': side_pair('femur'),
    'tibia': side_pair('tibia'),
    'humerus': side_pair('humerus'),
    'radius': side_pair('radius'),
    'ulna': side_pair('ulna'),
    'scapula': side_pair('scapula'),
    'os_coxa': side_pair('os_coxa'),
    'rib_1_2': side_pair('rib1') + side_pair('rib2'),
    'typical_rib': sum((side_pair(f'rib{n}') for n in range(3, 10)), []),
    'rib_11_12': side_pair('rib11') + side_pair('rib12'),
    'cervical_vertebrae': [f'c{n}' for n in range(1, 8)],
    'thoracic_vertebrae': [f't{n}' for n in range(1, 13)],
    'lumbar_vertebrae': [f'l{n}' for n in range(1, 6)],
}

# parts that sit mostly behind other bones in one view get a dashed outline on top
GHOST = {
    'front': set(side_pair('scapula') + [f't{n}' for n in range(1, 13)] + ['c1', 'c2', 'c3']
                 + side_pair('rib11') + side_pair('rib12')),
    'back': set(),
}


def view(name):
    """Items for one view, in paint order, with back-view geometry mirrored."""
    out = []
    for it in ITEMS:
        if it['face'] not in ('both', name):
            continue
        if name == 'back':
            it = dict(it, shapes=[mirror_d(d) for d in it['shapes']],
                      holes=[mirror_d(d) for d in it['holes']],
                      lines=[mirror_d(d) for d in it['lines']])
        out.append(it)
    # stable sort keeps declaration order inside a depth
    out.sort(key=lambda i: i['z'] if name == 'front' else -i['z'])
    return out


# ------------------------------------------------------------------ dart file

def bounds(paths):
    """Left, top, right, bottom of the points in the paths (control points
    included, which is close enough for placing a ring)."""
    xs, ys = [], []
    for d in paths:
        toks = d.split()
        i = 0
        while i < len(toks):
            if toks[i] in 'MLCQZ':
                i += 1
                continue
            xs.append(float(toks[i]))
            ys.append(float(toks[i + 1]))
            i += 2
    return [min(xs), min(ys), max(xs), max(ys)]


def dart_list(items, kind):
    return f'<{kind}>[' + ', '.join(items) + ']'


def dart_str(s):
    return f"'{s}'"


def dart_part(it):
    args = [dart_str(it['bone']),
            dart_list((f(v) for v in bounds(it['shapes'])), 'double'),
            '\n      ' + dart_list((dart_str(d) for d in it['shapes']), 'String')]
    if it['holes'] or it['lines']:
        args.append('\n      ' + dart_list((dart_str(d) for d in it['holes']), 'String'))
    if it['lines']:
        args.append('\n      ' + dart_list((dart_str(d) for d in it['lines']), 'String'))
    return '    SkeletonPart(' + ', '.join(args).replace(', \n', ',\n') + '),'


def dart_view(name):
    parts = view(name)
    hidden = sorted(GHOST[name])
    out = [f'const SkeletonView skeleton{name.title()} = SkeletonView(',
           '  <SkeletonPart>[']
    out += [dart_part(it) for it in parts]
    out += ['  ],',
            '  <String>{' + ', '.join(dart_str(b) for b in hidden) + '},',
            ');']
    return out


HEADER = '''\
// Drawn by tool/make_skeleton.py; change the drawing there and run it again:
//
//   python tool/make_skeleton.py
//
// dart format off

/// One drawn part of the atlas skeleton in one view. Paths use only absolute
/// M, L, C, Q and Z commands, in figure units.
class SkeletonPart {
  const SkeletonPart(this.bone, this.box, this.shapes,
      [this.holes = const <String>[], this.lines = const <String>[]]);

  /// Bone id, e.g. `femur_r` (the figure's right side), `t4` or `cranium`.
  final String bone;

  /// Left, top, right and bottom of the part.
  final List<double> box;

  /// Closed outlines; the first is the silhouette.
  final List<String> shapes;

  /// Openings drawn solid, like the eye sockets.
  final List<String> holes;

  /// Detail strokes, like teeth and sutures.
  final List<String> lines;
}

/// The whole skeleton seen from one side, in paint order (farthest first).
class SkeletonView {
  const SkeletonView(this.parts, this.hidden);

  final List<SkeletonPart> parts;

  /// Bones that sit mostly behind others from this side; when lit they get a
  /// dashed outline on top so they can still be found.
  final Set<String> hidden;
}
'''


def main():
    allb = [bounds(it['shapes']) for v in ('front', 'back') for it in view(v)]
    box = [min(b[0] for b in allb) - 3, min(b[1] for b in allb) - 3,
           max(b[2] for b in allb) + 4, max(b[3] for b in allb) + 4]
    out = [HEADER]
    out.append('/// The area both views are drawn in: left, top, width and height.')
    out.append('const List<double> skeletonViewBox = <double>['
               + ', '.join(f(v) for v in (box[0], box[1], box[2] - box[0], box[3] - box[1])) + '];')
    out.append('')
    out.append('/// The bones each atlas page lights, by atlas key.')
    out.append('const Map<String, List<String>> skeletonHighlight = <String, List<String>>{')
    for k, v in HIGHLIGHT.items():
        out.append(f"  '{k}': " + dart_list((dart_str(b) for b in v), 'String') + ',')
    out.append('};')
    out.append('')
    out += dart_view('front')
    out.append('')
    out += dart_view('back')
    out.append('')
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'data',
                        'skeleton_geometry.dart')
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(out))
    print('wrote', os.path.normpath(path), os.path.getsize(path), 'bytes')


if __name__ == '__main__':
    main()
