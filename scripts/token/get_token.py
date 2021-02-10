#!/usr/bin/env python3.8

import datetime

import jwt

private_key = open('../keys/jwt-key').read()

payload = {
    'iss': 'vavato',
    'sub': 'vavato',
    'aud': 'https://echo.api.vavato.com',
    'iat': datetime.datetime.utcnow(),
    'exp': datetime.datetime.utcnow() + datetime.timedelta(days=30)
}

token = jwt.encode(payload, private_key, algorithm='RS256')
print(token)
