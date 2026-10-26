"""Supervise both independent services and stop the pair on either failure."""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def wait_ready(url, process, expected_version):
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f'Service exited before it was ready: {url}')
        try:
            with urllib.request.urlopen(url, timeout=2) as response:
                data = json.load(response)
            if data.get('ready') is True and data.get('api_version') == expected_version:
                return
        except (OSError, ValueError, urllib.error.URLError):
            pass
        time.sleep(.2)
    raise RuntimeError(f'Service did not report API {expected_version} readiness: {url}')


def require_free_port(port):
    with socket.socket() as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(('127.0.0.1', port))
        except OSError as exc:
            raise RuntimeError(f'Port {port} is already in use. Stop that service or choose different KISSAN_PORT / KISSAN_ML_PORT values.') from exc


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ml-dir', type=Path, required=True)
    parser.add_argument('--ml-python', type=Path, required=True)
    parser.add_argument('--port', type=int, default=8765)
    parser.add_argument('--ml-port', type=int, default=8767)
    parser.add_argument('--llm-python', type=Path)
    parser.add_argument('--llm-port', type=int, default=8768)
    args = parser.parse_args()
    if args.port == args.ml_port:
        parser.error('The app and ML service need different ports.')
    require_free_port(args.port)
    require_free_port(args.ml_port)
    if args.llm_python:
        if args.llm_port in {args.port,args.ml_port}: parser.error('Language model needs its own port.')
        require_free_port(args.llm_port)
    expected = json.loads((ROOT / 'ml-service.lock.json').read_text())['api_version']
    processes = []
    def stop_signal(_number, _frame):
        raise KeyboardInterrupt()
    signal.signal(signal.SIGTERM, stop_signal)
    try:
        environment = dict(os.environ, KISSAN_LLM_URL=f'http://127.0.0.1:{args.llm_port}')
        if args.llm_python:
            llm = subprocess.Popen([str(args.llm_python.expanduser().absolute()),
                str(args.ml_dir.resolve() / 'language_model/server.py'),
                '--model',str(args.ml_dir.resolve() / 'language_model/weights'),
                '--port',str(args.llm_port)],cwd=args.ml_dir.resolve())
            processes.append(llm)
            wait_ready(f'http://127.0.0.1:{args.llm_port}/health',llm,expected)
        ml = subprocess.Popen([str(args.ml_python.expanduser().absolute()), '-m', 'model_service.app', '--port', str(args.ml_port)], cwd=args.ml_dir.resolve(), env=environment)
        processes.append(ml)
        wait_ready(f'http://127.0.0.1:{args.ml_port}/health', ml, expected)
        environment = dict(environment, KISSAN_ML_URL=f'http://127.0.0.1:{args.ml_port}')
        app = subprocess.Popen([sys.executable, '-m', 'server.app', '--port', str(args.port)], cwd=ROOT, env=environment)
        processes.append(app)
        wait_ready(f'http://127.0.0.1:{args.port}/api/model', app, expected)
        print(f'Both repositories connected. Open http://127.0.0.1:{args.port}', flush=True)
        while True:
            for process in processes:
                if process.poll() is not None:
                    raise RuntimeError(f'A service stopped (exit {process.returncode}); stopping the other service.')
            time.sleep(.5)
    except KeyboardInterrupt:
        print('Stopping app, classifier and language-model services.', flush=True)
    finally:
        for process in reversed(processes):
            if process.poll() is None:
                process.terminate()
        for process in processes:
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


if __name__ == '__main__':
    try:
        main()
    except RuntimeError as exc:
        raise SystemExit(str(exc))
