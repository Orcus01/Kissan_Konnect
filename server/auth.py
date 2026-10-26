"""Firebase-only identities. No client project or password database is used."""
from __future__ import annotations
import hashlib
import json
import os
import secrets
import sqlite3
import time
from functools import lru_cache, partial
from fastapi import HTTPException
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token

COOKIE = 'kissan_session'

def initialize(db_path):
    with sqlite3.connect(db_path) as db:
        db.executescript("""
        CREATE TABLE IF NOT EXISTS firebase_profiles (
            id TEXT PRIMARY KEY, email TEXT NOT NULL, name TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS firebase_sessions (
            token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL, expires_at REAL NOT NULL
        );
        """)

def name_value(value):
    if not isinstance(value,str) or not 2 <= len(value.strip()) <= 80:
        raise HTTPException(422,'Enter a name between 2 and 80 characters.')
    return value.strip()

def token_hash(value):
    return hashlib.sha256(value.encode()).hexdigest()

@lru_cache(maxsize=512)
def _signed_claims(token, project):
    return id_token.verify_firebase_token(token,partial(GoogleRequest(),timeout=10),audience=project)

def verify_token(token):
    project=os.environ.get('KISSAN_FIREBASE_PROJECT_ID','')
    if not project:
        raise HTTPException(503,'The personal Kissan Konnect Firebase project has not been configured.')
    if project == 'seatsandspaces':
        raise HTTPException(503,'This client project cannot be used for Kissan Konnect.')
    if not isinstance(token,str) or not 1 <= len(token) <= 8192:
        raise HTTPException(401,'Sign in to continue.')
    try:
        # Unsigned emulator tokens are accepted ONLY in explicitly enabled demo mode.
        if os.environ.get('KISSAN_AUTH_EMULATOR') == '1' and project.startswith('demo-'):
            import base64
            payload=token.split('.')[1]
            claims=json.loads(base64.urlsafe_b64decode(payload+'='*(-len(payload)%4)))
        else:
            claims=_signed_claims(token,project)
        if (claims.get('aud') != project or claims.get('iss') != f'https://securetoken.google.com/{project}'
            or not isinstance(claims.get('sub'),str) or not 1 <= len(claims['sub']) <= 128
            or claims.get('exp',0) <= time.time()):
            raise ValueError('Invalid claims')
        return claims
    except Exception:
        raise HTTPException(401,'Your Firebase session has expired. Please sign in again.')

def sync_profile(db_path,claims):
    user={'id':claims['sub'],'email':claims.get('email',''),
          'name':claims.get('name') or claims.get('email','Grower').split('@')[0], 'provider':'firebase'}
    with sqlite3.connect(db_path) as db:
        db.execute('INSERT INTO firebase_profiles VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET email=excluded.email,name=excluded.name',
                   (user['id'],user['email'],user['name']))
    return user

def current_user(db_path,request):
    authorization=request.headers.get('authorization','')
    if authorization.startswith('Bearer '):
        return sync_profile(db_path,verify_token(authorization[7:]))
    token=request.cookies.get(COOKIE,'')
    with sqlite3.connect(db_path) as db:
        row=db.execute('SELECT p.id,p.email,p.name FROM firebase_profiles p JOIN firebase_sessions s ON s.user_id=p.id WHERE s.token_hash=? AND s.expires_at>?',
                       (token_hash(token),time.time())).fetchone() if token else None
    if not row:
        raise HTTPException(401,'Sign in to continue.')
    return {'id':row[0],'email':row[1],'name':row[2],'provider':'firebase'}

def session(db_path,request,response,data):
    claims=verify_token(data.get('id_token'))
    user=sync_profile(db_path,claims)
    token=secrets.token_urlsafe(32)
    expiry=min(claims['exp'],time.time()+3600)
    with sqlite3.connect(db_path) as db:
        old=request.cookies.get(COOKIE,'')
        if old: db.execute('DELETE FROM firebase_sessions WHERE token_hash=?',(token_hash(old),))
        db.execute('DELETE FROM firebase_sessions WHERE expires_at<?',(time.time(),))
        db.execute('INSERT INTO firebase_sessions VALUES (?,?,?)',(token_hash(token),user['id'],expiry))
    response.set_cookie(COOKIE,token,max_age=max(1,int(expiry-time.time())),httponly=True,
                        secure=request.url.scheme=='https',samesite='strict',path='/api')
    return {'user':user}

def logout(db_path,request,response):
    with sqlite3.connect(db_path) as db:
        db.execute('DELETE FROM firebase_sessions WHERE token_hash=?',(token_hash(request.cookies.get(COOKIE,'')),))
    response.delete_cookie(COOKIE,path='/api',httponly=True,samesite='strict')
    return {'signed_out':True}
