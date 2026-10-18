"""Training augmentations and the train/eval image transforms.

Most augmentations here exist to remove a shortcut an earlier run learned (greyscale,
orientation, printed text); each class docstring names the shortcut.
"""
import random
from io import BytesIO

import cv2
import numpy as np
import torch
from PIL import Image, ImageDraw, ImageFont
from torchvision import transforms

from bone_analyzer.config import PRINTED_MARKS_P

IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]


class RecolourGreyscale:
    """Give a greyscale photo plausible colour, so greyscale stops identifying the class.

    The owl-pellet crops are all greyscale and make up most of the femur and os coxa
    classes, so without this "grey photo" meant "femur or pelvis". Works in LAB: each
    pixel keeps its original lightness exactly (no lost contrast) and only colour is
    invented. Dark and mid tones get a random ground colour (soil, moss, stone, cloth),
    light tones a pale bone colour, and a smooth random colour field varies it across the
    frame the way uneven light and staining do, so the result doesn't carry the flat,
    brightness-locked colour a simple tint would (which a network could learn instead).
    Letterbox bars stay black and colour photos pass through untouched. Training only:
    validation and test keep the original pixels, so the shortcut stays measurable.
    """

    # (a, b) chroma in LAB. Ground: soil, dark earth, moss, leaf litter, stone, blue-grey
    # cloth, sand, wood. Bone: ivory, cream, tan, yellowed, grey-white.
    GROUND = [(8, 14), (5, 10), (-12, 14), (10, 22), (0, 3), (-2, -10), (4, 18), (12, 20), (-8, 8), (2, -4)]
    BONE = [(1, 12), (2, 18), (3, 24), (0, 8), (4, 28), (-1, 5), (2, 15)]

    # Defaults tuned so recoloured photos match real ones on saturation (median 66 vs 65)
    def __init__(self, saturation_threshold=12, ground_scale=(0.5, 1.5), field_amplitude=(4, 14), shadow_chroma=0.2):
        self.saturation_threshold = saturation_threshold
        self.ground_scale = ground_scale
        self.field_amplitude = field_amplitude
        self.shadow_chroma = shadow_chroma      # share of colour kept in the darkest shadows

    @staticmethod
    def _smooth_field(h, w, amplitude):
        grid = np.random.uniform(-1, 1, (random.randint(2, 6), random.randint(2, 6), 2)).astype(np.float32)
        return cv2.resize(grid, (w, h), interpolation=cv2.INTER_CUBIC) * amplitude

    def __call__(self, img):
        image = np.asarray(img)
        content = image.sum(axis=2) > 0                      # everything except letterbox bars
        if not content.any():
            return img
        saturation = cv2.cvtColor(image, cv2.COLOR_RGB2HSV)[:, :, 1]
        if saturation[content].mean() >= self.saturation_threshold:
            return img                                       # already a colour photo
        h, w = image.shape[:2]
        lab = cv2.cvtColor(image.astype(np.float32) / 255.0, cv2.COLOR_RGB2LAB)
        lightness = lab[..., 0]
        ground = np.array(random.choice(self.GROUND), np.float32) * random.uniform(*self.ground_scale)
        bone = np.array(random.choice(self.BONE), np.float32) * random.uniform(0.6, 1.4)
        split = random.uniform(55, 75)                        # lightness where bone colour takes over
        weight = np.clip((lightness - split) / 20 + 0.5, 0, 1)[..., None]
        chroma = ground * (1 - weight) + bone * weight
        # smooth colour variation, stronger in the background than on the bone
        chroma += self._smooth_field(h, w, random.uniform(*self.field_amplitude)) * (1 - 0.6 * weight)
        chroma += np.random.normal(0, 1.5, chroma.shape).astype(np.float32)
        # shadows hold little colour in a real photo
        chroma *= (self.shadow_chroma + (1 - self.shadow_chroma) * np.clip(lightness / 60, 0, 1))[..., None]
        lab[..., 1:] = chroma
        out = cv2.cvtColor(lab, cv2.COLOR_LAB2RGB)
        out = np.clip(out * 255, 0, 255).astype(np.uint8)
        out[~content] = 0
        return out


class RandomRightAngle:
    """Turn the photo a random quarter-turn (or not) and mirror it half the time.

    A bone is the same bone whichever way it lies, but the training photos aren't evenly
    oriented: human bones are mostly shot upright, animal finds lie any which way. A model
    trained without this learned "upright = human" (106 val/test human photos: 73% called human
    as taken, 53% turned 90 degrees). Every orientation equally likely for every label removes
    the cue.
    """

    def __init__(self, turns=None):
        self.turns = turns      # fixed number of quarter-turns, for the robustness check

    def __call__(self, img):
        image = np.asarray(img)
        image = np.rot90(image, random.randrange(4) if self.turns is None else self.turns)
        if self.turns is None and random.random() < 0.5:
            image = image[:, ::-1]
        return np.ascontiguousarray(image)


class PrintedMarks:
    """Print labels, scale bars, rulers or a watermark onto some photos of every kind.

    Museum photos (most of them birds) carry catalogue numbers, "1 cm" labels and scale
    bars; human photos rarely do. A model trained without this learned "printed text = bird":
    a watermark alone turned a human femur into a 96% bird. Adding the same kinds of marks to a share of
    every class, no-bone photos included, leaves text no way to predict an answer.
    Marks keep mostly to the edges, where real labels and rulers sit, so they rarely cover
    the bone's surface (where they could pass for cut marks).
    """

    WORDS = ['ANATOMY', 'SAMPLE', 'SPECIMEN', 'PREVIEW', 'Fig. 3', 'Plate 12', 'Left', 'Right', 'Collection',
             'Museum', 'Field no.', 'Cat. no.', 'STOCK PHOTO', 'Site', 'Unit 4', 'Layer B', 'Lot', 'ID', '©']
    MUSEUMS = ['USNM', 'MVZ', 'UMMZ', 'KU', 'FMNH', 'YPM', 'AMNH', 'CAS', 'LACM', 'ROM', 'NHMUK', 'MCZ']

    def __init__(self, p=0.35):
        self.p = p

    @classmethod
    def _text(cls):
        kind = random.random()
        if kind < 0.25:
            return f'{random.choice(cls.MUSEUMS)} {random.randint(100, 999999)}'
        if kind < 0.45:
            return f'{random.choice([1, 2, 5, 10])} {random.choice(["cm", "mm"])}'
        if kind < 0.6:
            return (f'{random.choice("ABCDEFGHJKLMNPRSTUVW")}{random.choice("ABCDEFGHJKLMNPRSTUVW")}'
                    f'{random.randint(1, 9)}-{random.randint(1, 400)}')
        if kind < 0.7:
            return f'{random.randint(1, 28)}/{random.randint(1, 12)}/{random.randint(70, 99)}'
        if kind < 0.9:
            return random.choice(cls.WORDS)
        letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
        return ''.join(random.choice(letters) for _ in range(random.randint(3, 12)))

    @staticmethod
    def _font(size):
        try:
            return ImageFont.load_default(size=size)
        except TypeError:       # Pillow older than 10.1: fixed-size bitmap font
            return ImageFont.load_default()

    @staticmethod
    def _ink(image, box):
        """Dark ink on a light patch, light ink on a dark one, now and then a colour."""
        x0, y0, x1, y1 = (max(0, int(v)) for v in box)
        patch = image[y0:max(y0 + 1, y1), x0:max(x0 + 1, x1)]
        if random.random() < 0.15:
            return random.choice([(200, 30, 30), (30, 60, 180), (20, 120, 40)])
        return (random.randint(0, 50),) * 3 if patch.size and patch.mean() > 110 else (random.randint(205, 255),) * 3

    @staticmethod
    def _edge_spot(w, h, iw, ih):
        """Top-left corner for a w x h mark, usually in the outer band of the frame."""
        if random.random() < 0.2:
            return random.randint(0, max(0, iw - w)), random.randint(0, max(0, ih - h))
        band_x, band_y = int(iw * 0.18), int(ih * 0.18)
        side = random.choice(['top', 'bottom', 'left', 'right'])
        if side in ('top', 'bottom'):
            y = random.randint(0, max(0, band_y - h)) if side == 'top' else random.randint(min(ih - h, ih - band_y), max(0, ih - h))
            return random.randint(0, max(0, iw - w)), max(0, y)
        x = random.randint(0, max(0, band_x - w)) if side == 'left' else random.randint(min(iw - w, iw - band_x), max(0, iw - w))
        return max(0, x), random.randint(0, max(0, ih - h))

    def _label(self, draw, image):
        ih, iw = image.shape[:2]
        font = self._font(random.randint(int(ih * 0.03), int(ih * 0.07)))
        text = self._text()
        l, t, r, b = draw.textbbox((0, 0), text, font=font)
        x, y = self._edge_spot(r - l, b - t, iw, ih)
        draw.text((x - l, y - t), text, fill=self._ink(image, (x, y, x + r - l, y + b - t)), font=font)

    def _scale_bar(self, draw, image):
        ih, iw = image.shape[:2]
        length, thick = int(iw * random.uniform(0.08, 0.3)), random.randint(2, 7)
        font = self._font(random.randint(int(ih * 0.025), int(ih * 0.05)))
        label = f'{random.choice([1, 2, 5, 10])} {random.choice(["cm", "mm"])}'
        tw = draw.textbbox((0, 0), label, font=font)[2]
        x, y = self._edge_spot(max(length, tw), thick + 4 + font.size, iw, ih)
        ink = self._ink(image, (x, y, x + length, y + thick + font.size))
        if random.random() < 0.5:
            draw.rectangle((x, y, x + length, y + thick), fill=ink)
        else:   # alternating segments
            seg = max(1, length // random.randint(2, 5))
            for i, sx in enumerate(range(x, x + length, seg)):
                draw.rectangle((sx, y, min(sx + seg, x + length), y + thick), fill=ink if i % 2 == 0 else tuple(255 - c for c in ink),
                               outline=ink)
        draw.text((x, y + thick + 3), label, fill=ink, font=font)

    def _ruler(self, draw, image):
        ih, iw = image.shape[:2]
        horizontal = random.random() < 0.7
        span = int((iw if horizontal else ih) * random.uniform(0.5, 0.95))
        depth = random.randint(int(ih * 0.04), int(ih * 0.09))
        w, h = (span, depth) if horizontal else (depth, span)
        x, y = self._edge_spot(w, h, iw, ih)
        body = random.choice([(240, 200, 40), (245, 245, 235), (205, 170, 120), (250, 250, 250), (40, 40, 40)])
        ink = (20, 20, 20) if sum(body) > 300 else (235, 235, 235)
        draw.rectangle((x, y, x + w, y + h), fill=body)
        step = random.randint(4, 9)
        font = self._font(max(8, depth // 3))
        for i, pos in enumerate(range(0, span, step)):
            tick = depth * (0.6 if i % 10 == 0 else 0.4 if i % 5 == 0 else 0.25)
            if horizontal:
                draw.line((x + pos, y, x + pos, y + tick), fill=ink, width=1)
                if i % 10 == 0 and i:
                    draw.text((x + pos + 1, y + depth * 0.6), str(i // 10), fill=ink, font=font)
            else:
                draw.line((x, y + pos, x + tick, y + pos), fill=ink, width=1)
                if i % 10 == 0 and i:
                    draw.text((x + depth * 0.6, y + pos + 1), str(i // 10), fill=ink, font=font)

    def _watermark(self, base):
        """Large see-through text across the picture, sometimes on a slant."""
        iw, ih = base.size
        layer = Image.new('RGBA', base.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)
        font = self._font(random.randint(int(ih * 0.06), int(ih * 0.14)))
        text = random.choice(self.WORDS + [self._text()]).upper()
        l, t, r, b = draw.textbbox((0, 0), text, font=font)
        shade = random.choice([255, 0, 128])
        alpha = random.randint(70, 200)
        x = (iw - (r - l)) // 2 if random.random() < 0.6 else random.randint(0, max(0, iw - (r - l)))
        y = random.choice([(ih - (b - t)) // 2, int(ih * 0.85) - (b - t), int(ih * 0.05)])
        draw.text((x - l, y - t), text, fill=(shade, shade, shade, alpha), font=font)
        if random.random() < 0.35:
            layer = layer.rotate(random.uniform(-40, 40), resample=Image.BILINEAR)
        return Image.alpha_composite(base.convert('RGBA'), layer).convert('RGB')

    def __call__(self, img):
        if random.random() >= self.p:
            return img
        image = np.asarray(img)
        pil = Image.fromarray(image)
        for _ in range(random.choices([1, 2, 3], weights=[0.6, 0.3, 0.1])[0]):
            kind = random.random()
            if kind < 0.18:
                pil = self._watermark(pil)
                continue
            draw = ImageDraw.Draw(pil)
            current = np.asarray(pil)
            if kind < 0.6:
                self._label(draw, current)
            elif kind < 0.85:
                self._scale_bar(draw, current)
            else:
                self._ruler(draw, current)
        return np.asarray(pil)


class RandomJPEG:
    """Re-encode as JPEG at a random quality, the way a phone or messaging app does."""

    def __init__(self, quality=(50, 95)):
        self.quality = quality

    def __call__(self, img):
        buffer = BytesIO()
        img.save(buffer, format='JPEG', quality=random.randint(*self.quality))
        buffer.seek(0)
        return Image.open(buffer).convert('RGB')


class RandomHue:
    """Turn the hue by up to `shift` of the colour wheel, as ColorJitter's hue does, through
    OpenCV: torchvision's version took ~21 ms per 384 px photo, a third of the CPU time each
    training photo costs, and Colab has two CPU cores to keep the GPU fed. This takes ~5 ms
    (the results differ by 0.3/255 per pixel on average)."""

    def __init__(self, shift=0.05):
        self.shift = shift

    def __call__(self, img):
        hsv = cv2.cvtColor(np.asarray(img), cv2.COLOR_RGB2HSV)
        turn = round(random.uniform(-self.shift, self.shift) * 180)     # OpenCV hue runs 0-179
        hsv[..., 0] = (hsv[..., 0].astype(np.int16) + turn) % 180
        return Image.fromarray(cv2.cvtColor(hsv, cv2.COLOR_HSV2RGB))


class GaussianNoise:
    """Sensor noise on a [0, 1] image tensor."""

    def __init__(self, sigma=(0.005, 0.03)):
        self.sigma = sigma

    def __call__(self, tensor):
        return (tensor + torch.randn_like(tensor) * random.uniform(*self.sigma)).clamp(0, 1)


def get_train_transform():
    return transforms.Compose([
        # Greyscale must not be a cue for any label: every greyscale photo is recoloured first,
        # then every image is greyed at the same random rate, so a grey input is equally likely
        # whatever the bone type.
        RecolourGreyscale(),
        # Any orientation, mirrored or not, for every label; then printed marks on a share of
        # every kind of photo. Marks go on after turning so labels stay upright, as they are on
        # real photos.
        RandomRightAngle(),
        PrintedMarks(PRINTED_MARKS_P),
        transforms.ToPILImage(),
        transforms.RandomRotation(degrees=15, fill=0),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.1),
        RandomHue(0.05),
        transforms.RandomAffine(degrees=0, translate=(0.1, 0.1), scale=(0.9, 1.1), fill=0),
        transforms.RandomGrayscale(p=0.25),
        # Phone photos vary in focus, compression and sensor noise, and the model was flipping
        # answers on changes a person can't see. Each corruption hits only some images so clean
        # ones still dominate. Blur is kept mild and rare: strong blur erases cut marks while the
        # label still says they are there.
        transforms.RandomApply([transforms.GaussianBlur(kernel_size=5, sigma=(0.1, 1.2))], p=0.15),
        transforms.RandomApply([RandomJPEG(quality=(50, 95))], p=0.3),
        transforms.ToTensor(),
        transforms.RandomApply([GaussianNoise(sigma=(0.005, 0.03))], p=0.2),
        transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
    ])


def get_val_transform():
    """No augmentation: tensor conversion and ImageNet normalisation only."""
    return transforms.Compose([
        transforms.ToPILImage(),
        transforms.ToTensor(),
        transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
    ])
