deactivate && rm -rf venv/ __pycache__/ && virtualenv venv && source venv/bin/activate.fish && pip install -r requirements.txt && ./jwks.py ../keys/jwt-key.pub
