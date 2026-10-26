"""Firebase boundary tests use synthetic identities; never a real Firebase account."""
import importlib
import time
import os
import tempfile
os.environ.setdefault("KISSAN_DATA_DIR",tempfile.mkdtemp(prefix="kissan-firebase-tests-"))
import pytest
from fastapi.testclient import TestClient
from fastapi import HTTPException
from server import auth
module=importlib.import_module('server.app')

@pytest.fixture
def clients(monkeypatch):
    def verify(token):
        if token not in ('alice','bob'): raise HTTPException(401,'Invalid token')
        return {'sub':token,'email':token+'@example.test','name':token.title(),'exp':time.time()+3600}
    monkeypatch.setattr(auth,'verify_token',verify)
    a=TestClient(module.app);b=TestClient(module.app)
    assert a.post('/api/auth/session',json={'id_token':'alice'}).status_code==200
    assert b.post('/api/auth/session',json={'id_token':'bob'}).status_code==200
    return a,b

def test_session_is_httponly_and_logout_revokes(clients):
    a,b=clients
    assert a.get('/api/auth/me').json()['user']['id']=='alice'
    assert b.get('/api/auth/me').json()['user']['id']=='bob'
    a.post('/api/auth/logout')
    assert a.get('/api/auth/me').status_code==401
    assert b.get('/api/auth/me').status_code==200

def test_invalid_token_rejected(clients):
    a,_=clients
    assert a.post('/api/auth/session',json={'id_token':'fake'}).status_code==401

def test_no_local_password_endpoints(clients):
    a,_=clients
    assert a.post('/api/auth/signup',json={}).status_code==405

def test_private_scan_owner(clients):
    import json
    a,b=clients
    with module.sqlite3.connect(module.DB) as db:
        db.execute("INSERT OR REPLACE INTO scans (id,created_at,result,notes,image,owner_id) VALUES (?,?,?,?,?,?)",
          ('private-test','2026-10-26',json.dumps({'selected_crop':'Potato'}),'private',b'photo','alice'))
    assert any(r['id']=='private-test' for r in a.get('/api/scans').json()['scans'])
    assert all(r['id']!='private-test' for r in b.get('/api/scans').json()['scans'])
    assert b.delete('/api/scans/private-test').status_code==404
    assert b.patch('/api/scans/private-test',json={'notes':'intrusion'}).status_code==404

def test_client_project_explicitly_blocked(monkeypatch):
    monkeypatch.setenv('KISSAN_FIREBASE_PROJECT_ID','seatsandspaces')
    with pytest.raises(HTTPException) as error: auth.verify_token('anything')
    assert error.value.status_code==503

def test_wrong_audience_and_expired_token_rejected(monkeypatch):
    monkeypatch.setenv('KISSAN_FIREBASE_PROJECT_ID','personal-kissan')
    for claims in ({'aud':'other','sub':'alice','exp':time.time()+3600},
                   {'aud':'personal-kissan','iss':'https://securetoken.google.com/personal-kissan','sub':'alice','exp':0}):
        auth._signed_claims.cache_clear()
        monkeypatch.setattr(auth.id_token,'verify_firebase_token',lambda *a,**k: claims)
        with pytest.raises(HTTPException): auth.verify_token('test')


def test_private_chat_context_and_history(clients,monkeypatch):
    a,b=clients
    contexts=[]
    class Assistant:
        async def chat(self,question,crop,previous):
            contexts.append((crop,previous))
            return {'answer':'Check soil moisture.','crop':crop or 'Tomato','sources':[],'suggestions':[]}
    monkeypatch.setattr(module,'ml_client',Assistant())
    a.delete('/api/chat')
    assert a.post('/api/chat',json={'question':'How do I water tomato?'}).status_code==200
    assert a.post('/api/chat',json={'question':'And what soil?'}).status_code==200
    assert contexts[1]==('Tomato','How do I water tomato?')
    assert len(a.get('/api/chat').json()['messages'])==4
    assert b.get('/api/chat').json()['messages']==[]
    b.delete('/api/chat')
    assert len(a.get('/api/chat').json()['messages'])==4
