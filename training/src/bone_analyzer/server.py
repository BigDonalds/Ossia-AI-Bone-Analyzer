"""HTTP server the Ossia app sends photos to when it analyses online.

Started by scripts/serve.py. It prints the address to type into the app (Settings ->
Analyze on: Online -> Online address); the phone and this computer need to be on the
same Wi-Fi, or reachable through a tunnel.

Endpoints:
    GET  /            health check: model name, device, uptime
    POST /analyze     multipart/form-data with an `image` file (repeat the field
                      for several angles of the same bone) and optional fields:
                      `length_cm`; the widths `end_width_cm` (across an end),
                      `shaft_width_cm` (across the shaft at its narrowest) and
                      `head_diameter_cm` (the ball of the femur or humerus, or
                      the hip socket); and `shape` (long, skull, flat or
                      vertebra; empty = not sure). A raw image body also works,
                      with the same names in the query string.

Standard library only on top of what the analyzer needs. The response shape is what the
app parses; tests in the app pin it, so change both together.
"""
from __future__ import annotations

import json
import math
import os
import socket
import tempfile
import threading
import time
import traceback
from datetime import datetime
from email.parser import BytesParser
from email.policy import default as email_policy
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from bone_analyzer.config import CHECKPOINT_DIR, DEVICE, PROJECT_DIR
from bone_analyzer.data.images import decode_image
from bone_analyzer.inference.analyzer import BoneAnalyzer, calibration_note
from bone_analyzer.inference.shape_hint import SHAPES
from bone_analyzer.model import load_bone_cnn

MAX_UPLOAD_BYTES = 25 * 1024 * 1024
MAX_IMAGES_PER_REQUEST = 8
MAX_LENGTH_CM = 500.0
WIDTH_FIELDS = ('end_width_cm', 'shaft_width_cm', 'head_diameter_cm')
MAX_WIDTH_CM = 100.0


def resolve_model_path(name: str) -> Path:
    """Find the checkpoint the user named: as given, then in the project and checkpoint folders."""
    given = Path(name).expanduser()
    names = [given] if given.suffix else [given, given.with_suffix('.pt')]

    candidates: list[Path] = []
    for n in names:
        if n.is_absolute():
            candidates.append(n)
        else:
            candidates += [
                Path.cwd() / n,
                PROJECT_DIR / n,
                CHECKPOINT_DIR / n,
            ]

    for c in candidates:
        if c.is_file():
            return c.resolve()

    looked = '\n  '.join(str(c) for c in dict.fromkeys(candidates))
    raise SystemExit(f"Model file '{name}' not found. Looked in:\n  {looked}")


class ModelService:
    """Owns the analyzer and serialises access to it."""

    def __init__(self, model_path: Path):
        self.model_path = model_path
        self.device = DEVICE
        self.started = time.time()
        self._lock = threading.Lock()

        self.analyzer = BoneAnalyzer()
        self._load_checkpoint(model_path)

    def _load_checkpoint(self, model_path: Path) -> None:
        """Build the CNN and load weights into it.

        Unlike `BoneAnalyzer.load_trained_model`, a bad checkpoint stops the
        server instead of silently disabling phases 2-8.
        """
        try:
            model, _ = load_bone_cnn(model_path, self.analyzer.device)
        except Exception as e:
            raise SystemExit(
                f"Could not load '{model_path.name}': {e}\n"
                'The checkpoint may be from a model version whose label lists '
                'differ from bone_analyzer/config.py.')

        self.analyzer.model = model
        self.analyzer.has_classifier = True
        print(f'Loaded trained model from {model_path} ({calibration_note(model)})', flush=True)

    def warm_up(self) -> None:
        """Run one throwaway analysis so the first real request is not slow."""
        import cv2
        import numpy as np

        blank = np.full((320, 320, 3), 200, dtype=np.uint8)
        fd, path = tempfile.mkstemp(suffix='.jpg')
        os.close(fd)
        try:
            cv2.imwrite(path, blank)
            with self._lock:
                self.analyzer.analyze_image(path)
        except Exception:
            pass
        finally:
            _unlink(path)

    def analyze(self, image_paths: list[str], length_cm: float | None,
                widths: dict[str, float] | None = None, shape: str | None = None) -> dict:
        with self._lock:
            if len(image_paths) == 1:
                raw = self.analyzer.analyze_image(image_paths[0], user_length=length_cm,
                                                  widths=widths, shape=shape)
            else:
                raw = self.analyzer.analyze_multiple_images(
                    image_paths, user_length=length_cm, widths=widths, shape=shape)

        if raw.get('error'):
            raise AnalysisError(raw.get('message', 'Analysis failed'))

        report = to_json_safe(raw)
        p1 = report.get('phase1_bone_detection', {})
        p1.pop('image_path', None)
        present = bool(p1.get('final_verdict', p1.get('bone_present', False)))

        # Reference length range for the identified bone; the app reads min_cm /
        # max_cm / user_length_cm, and gets nothing when there is no bone or no range.
        length = report.pop('bone_length', None) or {}
        if present and length.get('available'):
            report['bone_length'] = {
                'min_cm': round(length['min_cm'], 1),
                'max_cm': round(length['max_cm'], 1),
                'user_length_cm': length_cm,
                'range_source': length.get('range_source'),
                'reference_for': length.get('reference_for'),
            }

        report.setdefault('num_images_analyzed', len(image_paths))
        phase9 = report.setdefault('phase9_multi_image', {})
        phase9.setdefault('num_angles', len(image_paths))
        phase9['user_length_cm'] = length_cm
        return report


class AnalysisError(Exception):
    pass


class BadRequest(Exception):
    pass


def to_json_safe(value):
    """Convert numpy / torch scalars and arrays into plain JSON types."""
    if isinstance(value, dict):
        return {str(k): to_json_safe(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [to_json_safe(v) for v in value]
    if isinstance(value, float):
        return value if math.isfinite(value) else None
    if isinstance(value, (str, int, bool)) or value is None:
        return value
    if isinstance(value, Path):
        return str(value)
    if hasattr(value, 'tolist'):  # numpy arrays / scalars, torch tensors
        return to_json_safe(value.tolist())
    if hasattr(value, 'item'):
        return to_json_safe(value.item())
    return str(value)


def parse_length(raw: str | None, name: str = 'length_cm', most: float = MAX_LENGTH_CM) -> float | None:
    if raw is None or not raw.strip():
        return None
    try:
        v = float(raw.replace(',', '.'))
    except ValueError:
        raise BadRequest(f"{name} must be a number, got '{raw}'")
    if not math.isfinite(v) or v <= 0 or v > most:
        raise BadRequest(f'{name} must be between 0 and {most:g}')
    return round(v, 2)


def parse_shape(raw: str | None) -> str | None:
    if raw is None or raw.strip().lower() in ('', 'unsure', 'not_sure', 'none'):
        return None
    shape = raw.strip().lower()
    if shape not in SHAPES:
        raise BadRequest(f"shape must be one of {', '.join(SHAPES)} (or empty), got '{raw}'")
    return shape


def parse_multipart(content_type: str, body: bytes) -> tuple[list[bytes], dict[str, str]]:
    """Split a multipart/form-data body into image payloads and text fields."""
    head = f'Content-Type: {content_type}\r\nMIME-Version: 1.0\r\n\r\n'.encode()
    message = BytesParser(policy=email_policy).parsebytes(head + body)
    if not message.is_multipart():
        raise BadRequest('Expected multipart/form-data with an "image" field')

    images: list[bytes] = []
    fields: dict[str, str] = {}
    for part in message.iter_parts():
        name = part.get_param('name', header='content-disposition')
        payload = part.get_payload(decode=True) or b''
        is_file = part.get_filename() is not None or part.get_content_maintype() == 'image'
        if is_file:
            if name in (None, 'image', 'images', 'file', 'photo') and payload:
                images.append(payload)
        elif name:
            fields[name] = payload.decode('utf-8', 'replace').strip()
    return images, fields


def check_image(data: bytes) -> str:
    """Make sure the analyzer can decode the bytes; return a file suffix for them."""
    if decode_image(data) is None:
        raise BadRequest("Couldn't read that image. Send a JPEG, PNG, WebP, AVIF or HEIC photo.")
    if data[:3] == b'\xff\xd8\xff':
        return '.jpg'
    if data[:8] == b'\x89PNG\r\n\x1a\n':
        return '.png'
    if data[:4] == b'RIFF' and data[8:12] == b'WEBP':
        return '.webp'
    return '.img'


def _unlink(path: str) -> None:
    try:
        os.remove(path)
    except OSError:
        pass


def make_handler(service: ModelService):
    class Handler(BaseHTTPRequestHandler):
        server_version = 'OssiaServer/1.0'

        # Keep the console readable: one line per analysis, errors in full.
        def log_message(self, format, *args):  # noqa: A002 - signature fixed by base class
            pass

        def _send_json(self, status: int, payload: dict) -> None:
            body = json.dumps(payload).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(body)

        def _error(self, status: int, message: str) -> None:
            self._send_json(status, {'error': True, 'message': message})

        def do_OPTIONS(self):  # noqa: N802
            self.send_response(HTTPStatus.NO_CONTENT)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type')
            self.end_headers()

        def do_GET(self):  # noqa: N802
            path = '/' + urlparse(self.path).path.strip('/')
            if path in ('/', '/health', '/analyze'):
                self._send_json(HTTPStatus.OK, {
                    'status': 'ok',
                    'service': 'ossia-analysis',
                    'model': service.model_path.name,
                    'device': service.device,
                    'uptime_s': round(time.time() - service.started),
                    'analyze': 'POST /analyze (multipart "image", optional "length_cm", '
                               '"end_width_cm", "shaft_width_cm", "head_diameter_cm", "shape")',
                })
            else:
                self._error(HTTPStatus.NOT_FOUND, f'No route {path}')

        def do_POST(self):  # noqa: N802
            url = urlparse(self.path)
            # Tolerate doubled or trailing slashes from a hand-typed address.
            if '/' + '/'.join(p for p in url.path.split('/') if p) != '/analyze':
                self._error(HTTPStatus.NOT_FOUND, f'No route {url.path}')
                return

            started = time.time()
            temp_paths: list[str] = []
            try:
                size = int(self.headers.get('Content-Length') or 0)
                if size <= 0:
                    raise BadRequest('Empty request: attach an image')
                if size > MAX_UPLOAD_BYTES:
                    self._error(HTTPStatus.REQUEST_ENTITY_TOO_LARGE,
                                f'Upload is over {MAX_UPLOAD_BYTES // (1024 * 1024)} MB')
                    return
                body = self.rfile.read(size)

                content_type = self.headers.get('Content-Type', '')
                query = parse_qs(url.query)
                if content_type.startswith('multipart/form-data'):
                    images, fields = parse_multipart(content_type, body)
                else:
                    images = [body]
                    fields = {k: v[0] for k, v in query.items() if v}
                length_cm = parse_length(fields.get('length_cm'))
                widths = {k: parse_length(fields.get(k), k, MAX_WIDTH_CM) for k in WIDTH_FIELDS}
                widths = {k: v for k, v in widths.items() if v is not None}
                shape = parse_shape(fields.get('shape'))

                if not images:
                    raise BadRequest('No image found. Send it in a field called "image".')
                if len(images) > MAX_IMAGES_PER_REQUEST:
                    raise BadRequest(f'At most {MAX_IMAGES_PER_REQUEST} images per request')

                for data in images:
                    suffix = check_image(data)
                    fd, path = tempfile.mkstemp(prefix='ossia_', suffix=suffix)
                    with os.fdopen(fd, 'wb') as f:
                        f.write(data)
                    temp_paths.append(path)

                report = service.analyze(temp_paths, length_cm, widths, shape)
                elapsed = time.time() - started
                report['server'] = {
                    'model': service.model_path.name,
                    'device': service.device,
                    'elapsed_ms': round(elapsed * 1000),
                }
                self._send_json(HTTPStatus.OK, report)
                log_request(self.client_address[0], report, length_cm, elapsed, widths, shape)

            except BadRequest as e:
                log_line(self.client_address[0], f'rejected: {e}')
                self._error(HTTPStatus.BAD_REQUEST, str(e))
            except AnalysisError as e:
                log_line(self.client_address[0], f'analysis failed: {e}')
                self._error(HTTPStatus.UNPROCESSABLE_ENTITY, str(e))
            except (BrokenPipeError, ConnectionResetError):
                log_line(self.client_address[0], 'client disconnected')
            except Exception as e:  # keep serving whatever one request does
                traceback.print_exc()
                try:
                    self._error(HTTPStatus.INTERNAL_SERVER_ERROR, f'Server error: {e}')
                except OSError:
                    pass
            finally:
                for p in temp_paths:
                    _unlink(p)

    return Handler


def log_line(client: str, text: str) -> None:
    print(f"[{datetime.now():%H:%M:%S}] {client:<15} {text}", flush=True)


def log_request(client: str, report: dict, length_cm: float | None, elapsed: float,
                widths: dict[str, float] | None = None, shape: str | None = None) -> None:
    p1 = report.get('phase1_bone_detection', {})
    if not p1.get('final_verdict', p1.get('bone_present')):
        summary = 'no bone detected'
    else:
        species = report.get('phase2_species', {}).get('species', '?').replace('_', '-')
        preds = report.get('phase3_bone_type', {}).get('predictions') or []
        bone = preds[0]['bone_type'].replace('_', ' ') if preds else 'unidentified'
        conf = preds[0]['confidence'] if preds else 0
        summary = f'{species} {bone} ({conf:.0%})'
    extra = f', user length {length_cm:g} cm' if length_cm else ''
    extra += ''.join(f", {k.removesuffix('_cm').replace('_', ' ')} {v:g} cm" for k, v in (widths or {}).items())
    extra += f', shape {shape}' if shape else ''
    if report.get('shape_hint', {}).get('changed'):
        extra += ' (shape changed the bone type)'
    if report.get('length_check', {}).get('changed'):
        check = report['length_check']
        before = check.get('image_only') or next(
            (c['image_only'] for c in check.get('per_image', []) if c.get('changed')), {})
        extra += f" (measurements changed it from {before.get('taxon', '?')} {before.get('bone_type', '?').replace('_', ' ')})"
    log_line(client, f'analyzed -> {summary}{extra} in {elapsed:.1f}s')


def lan_addresses() -> list[str]:
    """IPv4 addresses a phone on the same network could reach, best first."""
    found: list[str] = []
    try:
        # Connecting a UDP socket sends nothing; it just asks the OS which
        # interface it would route through, which is the Wi-Fi/Ethernet one.
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(('10.255.255.255', 1))
            found.append(s.getsockname()[0])
    except OSError:
        pass
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            found.append(info[4][0])
    except OSError:
        pass

    usable = [ip for ip in dict.fromkeys(found)
              if not ip.startswith(('127.', '169.254.', '0.'))]
    return usable or ['127.0.0.1']


def print_banner(service: ModelService, host: str, port: int) -> None:
    bar = '=' * 62
    print()
    print(bar)
    print('  OSSIA SERVER IS RUNNING')
    print(bar)
    print(f'  Model   : {service.model_path.name}  ({service.device})')
    print()
    print('  In the app: Settings -> Analyze on: Online')
    print('              -> Online address -> type one of:')
    print()

    loopback = host in ('127.0.0.1', 'localhost', '::1')
    if loopback:
        # Bound to this computer only: a phone on the Wi-Fi cannot connect,
        # and "localhost" typed on the phone means the phone itself.
        print('  Same Wi-Fi : NOT AVAILABLE. This server only accepts')
        print(f'               connections from this computer (--host {host}).')
        print('               Start it without --host to allow your phone.')
    else:
        addresses = lan_addresses() if host in ('0.0.0.0', '') else [host]
        print(f'  Same Wi-Fi : http://{addresses[0]}:{port}')
        for a in addresses[1:]:
            print(f'               http://{a}:{port}   (if the first one fails)')
        print('               Phone and computer must be on the same Wi-Fi.')
        print('               If Windows asks about the firewall, allow Private networks.')
    print()
    print('  Anywhere   : in another window run')
    print(f'                 cloudflared tunnel --url http://localhost:{port}')
    print('               and type the https://....trycloudflare.com link it prints.')
    print()
    print('  Never type localhost or 127.0.0.1 in the app: on the phone that')
    print('  means the phone itself.')
    print()
    print('  Press Ctrl+C to stop.')
    print(bar, flush=True)


def run(model_path: Path, host: str = '0.0.0.0', port: int = 8000, warmup: bool = True) -> None:
    """Load the model and serve until Ctrl+C."""
    print(f'Loading {model_path} ...', flush=True)
    service = ModelService(model_path)
    if warmup:
        print('Warming up ...', flush=True)
        service.warm_up()

    try:
        httpd = ThreadingHTTPServer((host, port), make_handler(service))
    except OSError as e:
        raise SystemExit(
            f'Could not listen on {host}:{port} ({e}). '
            f'Is something else using that port? Try --port {port + 1}')

    httpd.daemon_threads = True
    print_banner(service, host, port)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\nStopping server.')
    finally:
        httpd.server_close()
