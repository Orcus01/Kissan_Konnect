"""App gateway tests use an HTTP-boundary mock, never ONNX or real records."""
import io
import json
import os
from pathlib import Path
import tempfile
os.environ['KISSAN_DATA_DIR'] = tempfile.mkdtemp(prefix='kissan-app-test-')
import importlib
import httpx
from PIL import Image
import pytest
from fastapi.testclient import TestClient
from server.ml_client import MLClient

module = importlib.import_module('server.app')
client = TestClient(module.app)
SAMPLE = (Path(__file__).resolve().parents[2] / 'assets/samples/potato_early_blight.jpg').read_bytes()


def result(crop='Potato'):
    return {'api_version': 1, 'status': 'candidate', 'selected_crop': crop,
            'candidates': [{'label': 'Potato___Early_blight', 'crop': 'Potato', 'condition': 'Early blight', 'score': .9},
                           {'label': 'Tomato_healthy', 'crop': 'Tomato', 'condition': 'Healthy', 'score': .06},
                           {'label': 'Pepper__bell___healthy', 'crop': 'Bell pepper', 'condition': 'Healthy', 'score': .02}],
            'elapsed_ms': 25, 'model_name': 'Test model', 'model_version': 'test-model-version',
            'model_source': 'https://example.test/model', 'verified_diagnosis': False,
            'dataset_sample': True, 'request_id': 'ml-request-id', 'created_at': '2026-10-25T12:00:00Z'}


@pytest.fixture(autouse=True)
def mock_ml(monkeypatch):
    def handle(request):
        if request.url.path == '/v1/model':
            return httpx.Response(200, json={'api_version': 1, 'ready': True, 'classes': [], 'name': 'Test model'})
        assert request.url.path == '/v1/predict'
        assert request.method == 'POST'
        assert request.content == SAMPLE
        assert request.url.params['crop'] == 'Potato'
        return httpx.Response(200, json=result())
    monkeypatch.setattr(module, 'ml_client', MLClient(transport=httpx.MockTransport(handle)))


def predict(raw=SAMPLE):
    return client.post('/api/predict?crop=Potato', content=raw)


def test_app_proxies_model_and_retains_provenance():
    response = predict()
    assert response.status_code == 200
    data = response.json()
    assert data['api_version'] == 1
    assert data['request_id'] == 'ml-request-id'
    assert data['verified_diagnosis'] is False
    assert data['id'] != data['request_id']
    assert data['candidates'][0]['label'] == 'Potato___Early_blight'
    assert client.get('/api/model').json()['ready'] is True


def test_upload_limit_before_contacting_model():
    assert predict(raw=b'x' * (8 * 1024 * 1024 + 1)).status_code == 413


def test_prediction_not_saved_automatically():
    before = len(client.get('/api/scans').json()['scans'])
    predict()
    assert len(client.get('/api/scans').json()['scans']) == before


def test_save_edit_reload_image_delete():
    data = predict().json()
    scan_id = data['id']
    payload = {'prediction_id': scan_id, 'notes': ' Plot A — lower leaves '}
    assert client.post('/api/scans', json=payload).status_code == 200
    assert client.post('/api/scans', json=payload).status_code == 200
    saved = next(r for r in client.get('/api/scans').json()['scans'] if r['id'] == scan_id)
    assert saved['notes'] == 'Plot A — lower leaves'
    assert saved['result']['request_id'] == 'ml-request-id'
    image = client.get(saved['image_url'])
    assert image.headers['Content-Type'] == 'image/jpeg'
    assert Image.open(io.BytesIO(image.content)).getexif() == {}
    assert client.patch('/api/scans/' + scan_id, json={'notes': 'Day two'}).status_code == 200
    assert next(r for r in client.get('/api/scans').json()['scans'] if r['id'] == scan_id)['notes'] == 'Day two'
    assert client.delete('/api/scans/' + scan_id).status_code == 200
    assert client.get(saved['image_url']).status_code == 404


def test_reject_invented_result_and_oversized_notes():
    assert client.post('/api/scans', json={'prediction_id': 'invented', 'notes': ''}).status_code == 409
    assert client.post('/api/scans', json={'prediction_id': 'invented', 'notes': 'x' * 2001}).status_code == 400


def test_ml_unavailable_is_recoverable_error(monkeypatch):
    def offline(request):
        raise httpx.ConnectError('offline')
    monkeypatch.setattr(module, 'ml_client', MLClient(transport=httpx.MockTransport(offline)))
    response = predict()
    assert response.status_code == 502
    assert 'Model service' in response.json()['detail']
    assert client.get('/api/model').status_code == 502
    assert client.get('/api/scans').status_code == 200


@pytest.mark.parametrize('change', [{'api_version': 2}, {'candidates': []}, {'selected_crop': 'Tomato'}, {'verified_diagnosis': True}])
def test_incompatible_or_unsafe_ml_response_is_not_accepted(monkeypatch, change):
    def incompatible(request):
        return httpx.Response(200, json=dict(result(), **change))
    monkeypatch.setattr(module, 'ml_client', MLClient(transport=httpx.MockTransport(incompatible)))
    assert predict().status_code == 502


def test_ml_image_validation_error_preserved(monkeypatch):
    monkeypatch.setattr(module, 'ml_client', MLClient(transport=httpx.MockTransport(lambda _: httpx.Response(422, json={'detail': 'Choose a sharper image'}))))
    response = predict()
    assert response.status_code == 422
    assert response.json()['detail'] == 'Choose a sharper image'


def test_local_access_and_source_paths():
    assert client.post('/api/predict?crop=Potato', content=SAMPLE, headers={'Origin': 'https://unrelated.example'}).status_code == 403
    assert client.get('/api/model', headers={'Host': 'unrelated.example'}).status_code == 403
    assert client.get('/api/model').headers['Cache-Control'] == 'no-store'
    assert client.get('/server/data/notebook.sqlite3').status_code == 404
    assert client.get('/lib/firebase_options.dart').status_code == 404


def test_bad_city_and_coordinates():
    assert client.get('/api/weather?city=x').status_code == 400
    assert client.get('/api/forecast?latitude=999&longitude=0').status_code == 400


def test_weather_location_choices_and_forecast(monkeypatch):
    real_client = module.httpx.AsyncClient
    def handle(request):
        if 'geocoding' in request.url.host:
            return httpx.Response(200, json={'results': [
                {'id': 1, 'name': 'Kharar', 'admin1': 'Punjab', 'country': 'India', 'latitude': 30.75, 'longitude': 76.64},
                {'id': 2, 'name': 'Kharar', 'admin1': 'Other region', 'country': 'India', 'latitude': 31.1, 'longitude': 76.1}]})
        assert request.url.params['forecast_days'] == '5'
        return httpx.Response(200, json={'current': {'temperature_2m': 24}})
    transport = httpx.MockTransport(handle)
    monkeypatch.setattr(module.httpx, 'AsyncClient', lambda **kwargs: real_client(transport=transport, **kwargs))
    assert len(client.get('/api/weather?city=Kharar').json()['locations']) == 2
    assert client.get('/api/forecast?latitude=30.75&longitude=76.64').json()['current']['temperature_2m'] == 24


def test_weather_provider_failure(monkeypatch):
    real_client = module.httpx.AsyncClient
    def handle(request):
        raise httpx.ConnectError('offline')
    transport = httpx.MockTransport(handle)
    monkeypatch.setattr(module.httpx, 'AsyncClient', lambda **kwargs: real_client(transport=transport, **kwargs))
    assert client.get('/api/weather?city=Kharar').status_code == 502


def test_remote_model_transport_requires_https():
    with pytest.raises(ValueError):
        MLClient('http://remote.example')
    with pytest.raises(ValueError):
        MLClient('https://user:password@example.test')
