"""Local-only model, notebook and Flutter preview server. Run from repository root."""
from __future__ import annotations
import argparse
import io
from collections import OrderedDict
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import sqlite3
import threading
import time
import uuid

from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.staticfiles import StaticFiles
from starlette.concurrency import run_in_threadpool
import httpx
from PIL import Image, ImageOps
from .ml_client import MLClient

ROOT = Path(__file__).resolve().parent.parent
DATA = Path(os.environ.get('KISSAN_DATA_DIR', str(ROOT / 'server/data')))
DATA.mkdir(parents=True, exist_ok=True)
DB = DATA / 'notebook.sqlite3'
MAX_UPLOAD = 8 * 1024 * 1024
ml_client = MLClient()
app = FastAPI(title='Kissan Konnect local workspace', docs_url=None, redoc_url=None)
_pending: OrderedDict = OrderedDict()
_lock = threading.Lock()
with sqlite3.connect(DB) as db:
    db.execute('CREATE TABLE IF NOT EXISTS scans (id TEXT PRIMARY KEY, created_at TEXT NOT NULL, result TEXT NOT NULL, notes TEXT NOT NULL, image BLOB NOT NULL)')


@app.middleware('http')
async def local_access(request: Request, call_next):
    # No wildcard CORS or external bind. Block cross-origin writes to this local notebook.
    host = request.url.hostname
    if host not in {'127.0.0.1', 'localhost', 'testserver'}:
        return Response('Local access only', status_code=403)
    origin = request.headers.get('origin')
    if origin and origin != str(request.base_url).rstrip('/'):
        return Response('Cross-origin access is not allowed', status_code=403)
    response = await call_next(request)
    if request.url.path.startswith('/api/'):
        response.headers['Cache-Control'] = 'no-store'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    return response


async def limited_body(request: Request, maximum: int) -> bytes:
    data = bytearray()
    async for chunk in request.stream():
        data.extend(chunk)
        if len(data) > maximum:
            raise HTTPException(413, 'File is too large. Choose a photo under 8 MB.')
    return bytes(data)


async def json_body(request: Request) -> dict:
    try:
        value = json.loads(await limited_body(request, 16_384))
        if not isinstance(value, dict):
            raise ValueError()
        return value
    except (ValueError, UnicodeError):
        raise HTTPException(400, 'Invalid request.')


def clean_notes(value) -> str:
    if not isinstance(value, str) or len(value) > 2000:
        raise HTTPException(400, 'Notes must be under 2,000 characters.')
    return value.strip()


def canonical_preview(raw: bytes) -> bytes:
    with Image.open(io.BytesIO(raw)) as source:
        if source.width * source.height > 16_000_000:
            raise ValueError('Image is too large.')
        image = ImageOps.exif_transpose(source).convert('RGB')
        image.thumbnail((1600, 1600))
        output = io.BytesIO()
        image.save(output, 'JPEG', quality=85)
        return output.getvalue()


@app.get('/api/model')
async def model_info():
    return await ml_client.metadata()


@app.post('/api/predict')
async def predict(request: Request, crop: str):
    raw = await limited_body(request, MAX_UPLOAD)
    result = await ml_client.predict(raw, crop)
    # App-owned persistence uses a canonical preview, independent of model runtime.
    try:
        image = await run_in_threadpool(canonical_preview, raw)
    except (OSError, ValueError):
        raise HTTPException(422, 'This image cannot be saved. Choose a different photo.')
    prediction_id = str(uuid.uuid4())
    result['id'] = prediction_id
    result['created_at'] = datetime.now(timezone.utc).isoformat()
    with _lock:
        now = time.monotonic()
        for key in list(_pending):
            if now - _pending[key][0] > 1800:
                del _pending[key]
        while len(_pending) >= 32:
            _pending.popitem(last=False)
        _pending[prediction_id] = (now, result, image)
    return result


def scan_row(row):
    return {'id': row[0], 'created_at': row[1], 'result': json.loads(row[2]), 'notes': row[3], 'image_url': '/api/scans/' + row[0] + '/image'}


@app.get('/api/scans')
def scans():
    with sqlite3.connect(DB) as db:
        rows = db.execute('SELECT id, created_at, result, notes FROM scans ORDER BY created_at DESC LIMIT 200').fetchall()
    return {'scans': [scan_row(row) for row in rows]}


@app.post('/api/scans')
async def save_scan(request: Request):
    data = await json_body(request)
    notes = clean_notes(data.get('notes', ''))
    scan_id = data.get('prediction_id')
    if not isinstance(scan_id, str):
        raise HTTPException(400, 'Run a scan before saving.')
    with _lock:
        pending = _pending.get(scan_id)
    with sqlite3.connect(DB) as db:
        existing = db.execute('SELECT id, created_at, result, notes FROM scans WHERE id=?', (scan_id,)).fetchone()
        if existing:
            db.execute('UPDATE scans SET notes=? WHERE id=?', (notes, scan_id))
            return scan_row((*existing[:3], notes))
        if not pending or time.monotonic() - pending[0] > 1800:
            raise HTTPException(409, 'Photo review expired. Run the analysis again before saving.')
        _, result, image = pending
        db.execute('INSERT INTO scans VALUES (?, ?, ?, ?, ?)', (scan_id, result['created_at'], json.dumps(result), notes, image))
    return {'id': scan_id, 'saved': True}


@app.patch('/api/scans/{scan_id}')
async def update_scan(scan_id: str, request: Request):
    data = await json_body(request)
    notes = clean_notes(data.get('notes', ''))
    with sqlite3.connect(DB) as db:
        if db.execute('UPDATE scans SET notes=? WHERE id=?', (notes, scan_id)).rowcount == 0:
            raise HTTPException(404, 'Scan not found.')
    return {'updated': True}


@app.delete('/api/scans/{scan_id}')
def delete_scan(scan_id: str):
    with sqlite3.connect(DB) as db:
        if db.execute('DELETE FROM scans WHERE id=?', (scan_id,)).rowcount == 0:
            raise HTTPException(404, 'Scan not found.')
    with _lock:
        _pending.pop(scan_id, None)
    return {'deleted': True}


@app.get('/api/scans/{scan_id}/image')
def scan_image(scan_id: str):
    with sqlite3.connect(DB) as db:
        row = db.execute('SELECT image FROM scans WHERE id=?', (scan_id,)).fetchone()
    if row is None:
        raise HTTPException(404, 'Image not found.')
    return Response(row[0], media_type='image/jpeg')


@app.get('/api/weather')
async def weather(city: str):
    city = city.strip()
    if not 2 <= len(city) <= 100:
        raise HTTPException(400, 'Enter a city name between 2 and 100 characters.')
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            location_response = await client.get('https://geocoding-api.open-meteo.com/v1/search', params={'name': city, 'count': 5, 'language': 'en'})
            location_response.raise_for_status()
            locations = location_response.json().get('results', [])
            if not locations:
                raise HTTPException(404, 'City not found. Try a nearby city or a more specific name.')
            # Return choices first rather than silently selecting the wrong city.
            return {'locations': [{'id': p['id'], 'name': p['name'], 'region': p.get('admin1', ''), 'country': p.get('country', ''), 'latitude': p['latitude'], 'longitude': p['longitude']} for p in locations]}
    except httpx.HTTPError:
        raise HTTPException(502, 'Weather provider could not be reached. Try again shortly.')


@app.get('/api/forecast')
async def forecast(latitude: float, longitude: float):
    if not -90 <= latitude <= 90 or not -180 <= longitude <= 180:
        raise HTTPException(400, 'Invalid city coordinates.')
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.get('https://api.open-meteo.com/v1/forecast', params={
                'latitude': latitude, 'longitude': longitude, 'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
                'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code', 'forecast_days': 5, 'timezone': 'auto'})
            response.raise_for_status()
            return response.json()
    except httpx.HTTPError:
        raise HTTPException(502, 'Forecast could not be loaded. Try again shortly.')


# Only expose compiled public assets, never source, keys, model files, or the database.
WEB = ROOT / 'build/web'
if WEB.is_dir():
    app.mount('/', StaticFiles(directory=WEB, html=True), name='flutter')

if __name__ == '__main__':
    import uvicorn
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args()
    uvicorn.run(app, host='127.0.0.1', port=args.port, access_log=False)
