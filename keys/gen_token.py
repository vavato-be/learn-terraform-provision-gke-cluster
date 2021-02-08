import jwt

private_key = open('jwt-key').read()
public_key = open('jwt-key.pub').read()

payload = {'user_id': 123}
token = jwt.encode(payload, private_key, algorithm='RS256')
print(token)

#decoded = jwt.decode(token, public_key, algorithms='RS256')
#print(decoded)
