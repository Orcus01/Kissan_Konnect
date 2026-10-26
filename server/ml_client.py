"""Versioned HTTP boundary to the independently owned ML repository."""
from __future__ import annotations
import os
from urllib.parse import urlsplit
import httpx
from fastapi import HTTPException
from pydantic import BaseModel, ConfigDict, Field, ValidationError
from typing import Literal


class Candidate(BaseModel):
    model_config = ConfigDict(extra='forbid')
    label: str
    crop: str = Field(min_length=1, max_length=80)
    condition: str
    score: float = Field(ge=0, le=1)


class Prediction(BaseModel):
    model_config = ConfigDict(extra='forbid')
    api_version: Literal[1]
    status: Literal['candidate', 'uncertain', 'crop_mismatch']
    selected_crop: str = Field(min_length=1, max_length=80)
    identification: dict | None = None
    review_reason: str | None = None
    candidates: list[Candidate] = Field(min_length=3, max_length=3)
    elapsed_ms: int = Field(ge=0)
    model_name: str
    model_version: str
    model_source: str
    verified_diagnosis: Literal[False]
    dataset_sample: bool
    request_id: str
    created_at: str


class MLClient:
    def __init__(self, base_url: str | None = None, transport=None):
        self.base_url = (base_url or os.environ.get('KISSAN_ML_URL', 'http://127.0.0.1:8767')).rstrip('/')
        url = urlsplit(self.base_url)
        if url.scheme not in {'http', 'https'} or not url.hostname or url.username or url.password or url.query or url.fragment:
            raise ValueError('KISSAN_ML_URL must be a plain HTTP(S) service URL without credentials or query parameters.')
        if url.scheme == 'http' and url.hostname not in {'127.0.0.1', 'localhost'}:
            raise ValueError('Remote model services require HTTPS.')
        self.transport = transport

    async def _request(self, path: str, *, photo: bytes | None = None, crop: str | None = None, data: dict | None = None):
        try:
            async with httpx.AsyncClient(timeout=75, transport=self.transport) as client:
                if data is not None:
                    response = await client.post(self.base_url + path, json=data)
                elif photo is None:
                    response = await client.get(self.base_url + path)
                else:
                    response = await client.post(self.base_url + path, params={'crop': crop}, content=photo, headers={'Content-Type': 'application/octet-stream'})
            if response.status_code in {413, 422} or (path == '/v1/chat' and response.status_code == 503):
                detail = response.json().get('detail')
                raise HTTPException(response.status_code, detail if isinstance(detail, str) else 'The model could not read this photo.')
            response.raise_for_status()
            payload = response.json()
            if not isinstance(payload, dict) or payload.get('api_version') != 1:
                raise ValueError('Incompatible ML API version.')
            return payload
        except HTTPException:
            raise
        except (httpx.HTTPError, ValueError):
            raise HTTPException(502, 'Model service is unavailable or incompatible. Start the Kissan Konnect ML service and retry.')

    async def metadata(self):
        payload = await self._request('/v1/model')
        if payload.get('ready') is not True or not isinstance(payload.get('classes'), list):
            raise HTTPException(502, 'The model service is not ready. Retry shortly.')
        return payload

    async def predict(self, photo: bytes, crop: str):
        payload = await self._request('/v1/predict', photo=photo, crop=crop)
        try:
            prediction = Prediction.model_validate(payload)
        except ValidationError:
            raise HTTPException(502, 'The model service returned an incompatible result. Check that both repositories use API version 1.')
        if prediction.selected_crop != crop:
            raise HTTPException(502, 'The model returned a result for a different crop. Please retry.')
        return prediction.model_dump()

    async def chat(self, question, context_crop=None, previous_question=None, history=None):
        payload = await self._request('/v1/chat', data={'question':question,'context_crop':context_crop,'previous_question':previous_question,'history':history or []})
        if not isinstance(payload.get('answer'),str) or not isinstance(payload.get('sources'),list):
            raise HTTPException(502,'The plant assistant returned an invalid response. Please retry.')
        return payload
