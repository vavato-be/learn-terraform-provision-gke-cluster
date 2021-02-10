#!/usr/bin/env python

import datetime
import json
import sys

from authlib.jose import JsonWebKey


def jwks_format(public_key):
    key = JsonWebKey.import_key(public_key, {'kty': 'RSA'})
    key['kid'] = str(datetime.datetime.utcnow())

    return {
        "keys": [key]
    }


if __name__ == "__main__":
    public_key = open(sys.argv[1]).read()
    jwks = jwks_format(public_key)
    print(json.dumps(jwks, indent=4))
