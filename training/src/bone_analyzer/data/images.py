"""Image decoding and the letterbox resize shared by preprocessing, the server and the app."""
from io import BytesIO

import cv2
import numpy as np


def decode_image(data):
    """Decode image bytes to a BGR array, or None if unreadable.

    OpenCV handles JPEG, PNG, WebP, BMP and TIFF; Pillow covers what OpenCV builds often
    lack (AVIF, and HEIC/HEIF from iPhones when pillow-heif is installed). Both apply the
    EXIF orientation, so phone photos come out upright.
    """
    image = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)
    if image is not None:
        return image
    try:
        from PIL import Image, ImageOps
        try:
            from pillow_heif import register_heif_opener
            register_heif_opener()
        except ImportError:
            pass
        with Image.open(BytesIO(data)) as im:
            rgb = ImageOps.exif_transpose(im).convert('RGB')
        return cv2.cvtColor(np.asarray(rgb), cv2.COLOR_RGB2BGR)
    except Exception:
        return None


def letterbox_resize(image, target_size):
    """Scale the longer side to target_size and pad the rest with black, centred.
    The app's image_prep.dart reproduces this exactly."""
    h, w = image.shape[:2]
    scale = target_size / max(h, w)
    new_w = int(w * scale)
    new_h = int(h * scale)
    resized = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)
    canvas = np.zeros((target_size, target_size, 3), dtype=np.uint8)
    x_offset = (target_size - new_w) // 2
    y_offset = (target_size - new_h) // 2
    canvas[y_offset:y_offset + new_h, x_offset:x_offset + new_w] = resized
    return canvas
