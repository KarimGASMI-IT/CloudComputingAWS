from flask import Flask
import os

app = Flask(__name__)
VERSION = os.getenv("APP_VERSION", "v1")

@app.get("/")
def home():
    return {
        "message": "TP14 ECS Fargate OK",
        "version": VERSION
    }

@app.get("/health")
def health():
    return {"status": "ok", "version": VERSION}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)