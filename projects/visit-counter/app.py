import os
from flask import Flask
import redis

app = Flask(__name__)
r = redis.Redis(host=os.environ.get("REDIS_HOST", "redis"), port=6379)

@app.route("/")
def index():
    count = r.incr("visits")
    return f"Hello from Catto! This page has been visited {count} times.\n"

@app.route("/health")
def health():
    return ("Working fine", 200)

def sec():
    with open("/run/secrets/api_key") as secrets:
        key = secrets.read()
        key = key.strip()
        app.logger.warning("API key loaded (%d chars)", len(key))

if __name__ == "__main__":
    sec()
    app.run(host="0.0.0.0", port=8000)
