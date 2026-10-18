"""Serve a trained checkpoint to the Ossia app over the local network.

Usage:
    python scripts/serve.py bone_analyzer.pt
    python scripts/serve.py checkpoints/bone_analyzer.pt --port 8000

The model name is looked up as given, then in the project folder and checkpoints/.
See bone_analyzer/server.py for the endpoints.
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))

from bone_analyzer.server import resolve_model_path, run


def main():
    try:
        sys.stdout.reconfigure(errors='replace')
    except (AttributeError, ValueError):
        pass

    parser = argparse.ArgumentParser(description='Serve a trained bone analyzer model to the Ossia app.')
    parser.add_argument('model', help='checkpoint file name or path, e.g. bone_analyzer.pt')
    parser.add_argument('--port', type=int, default=8000, help='port to listen on (default 8000)')
    parser.add_argument('--host', default='0.0.0.0',
                        help='interface to bind (default 0.0.0.0 = reachable from your network)')
    parser.add_argument('--no-warmup', action='store_true', help='skip the warm-up pass at startup')
    args = parser.parse_args()

    run(resolve_model_path(args.model), args.host, args.port, warmup=not args.no_warmup)


if __name__ == '__main__':
    main()
