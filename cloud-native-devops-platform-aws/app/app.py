"""Simple Flask web app used to demonstrate the DevOps platform.

Endpoints:
  /         -> welcome message (shows which pod served the request)
  /health   -> health check used by Kubernetes liveness/readiness probes
  /version  -> app version (set by the CI/CD pipeline via env var)
"""
import os
import socket

from flask import Flask, jsonify

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "dev")
APP_ENV = os.getenv("APP_ENV", "local")


@app.route("/")
def home():
    return jsonify(
        message="Hello from the Cloud-Native DevOps Platform on AWS!",
        environment=APP_ENV,
        pod=socket.gethostname(),
    )


@app.route("/health")
def health():
    return jsonify(status="healthy"), 200


@app.route("/version")
def version():
    return jsonify(version=APP_VERSION)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
