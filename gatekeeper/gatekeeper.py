from flask import Flask, request, jsonify
import os
import requests
from sshtunnel import SSHTunnelForwarder

app = Flask(__name__)

trusted_host_dns = os.environ.get("TRUSTED_HOST_DNS")
if not trusted_host_dns:
    raise ValueError("Trust Host environment variable not set")

server = SSHTunnelForwarder(
    (trusted_host_dns, 22),  # Remote SSH server
    ssh_username="ubuntu",
    ssh_pkey="/etc/gatekeeper/vockey.pem",
    remote_bind_address=(trusted_host_dns, 80),  # Trusted Host server port
    local_bind_address=("127.0.0.1", 80),
)

try:
    server.start()  # Start SSH tunnel
    app.logger.warning("Tunnel connected")
except Exception as e:
    app.logger.error(f"Error establishing SSH Tunnel: {e}")
    raise

@app.route("direct", methods=["POST"])
def direct():
    try:
        trusted_host_dns = f"http://{trusted_host_dns}/direct"
        response = requests.post(trusted_host_dns, json=request.json)
        return response.json()
    except Exception as e:
        app.logger.error(f"Error making direct request: {e}")
        return jsonify({"error": "Internal server error"}), 500

@app.route("random", methods=["POST"])
def random():
    try:
        trusted_host_dns = f"http://{trusted_host_dns}/random"
        response = requests.post(trusted_host_dns, json=request.json)
        return response.json()
    except Exception as e:
        app.logger.error(f"Error making random request: {e}")
        return jsonify({"error": "Internal server error"}), 500
    
@app.route("customized", methods=["POST"])
def customized():
    try:
        trusted_host_dns = f"http://{trusted_host_dns}/customized"
        response = requests.post(trusted_host_dns, json=request.json)
        return response.json()
    except Exception as e:
        app.logger.error(f"Error making customized request: {e}")
        return jsonify({"error": "Internal server error"}), 500
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
