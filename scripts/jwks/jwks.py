#!/usr/bin/env python

import datetime
import json
import sys

from authlib.jose import JsonWebKey


def jwks_format(public_key):
    key_type = 'RSA'
    key = JsonWebKey.import_key(public_key, {'kty': key_type})
    key['kid'] = str(datetime.datetime.utcnow())
    key['kty'] = key_type

    return {
        "keys": [key]
    }


if __name__ == "__main__":
    public_key = open(sys.argv[1]).read()
    jwks = jwks_format(public_key)
    print(json.dumps(jwks, indent=4))
