from flask import Flask, request, jsonify
import os
import requests
from sshtunnel import SSHTunnelForwarder

app = Flask(__name__)

target_dns = os.environ.get("TARGET_DNS")
task_name = os.environ.get("INSTANCE_TASK_NAME")
self_dns = os.environ.get("SELF_DNS")
if not target_dns:
    raise ValueError("Trust Host environment variable not set")
print(f"Target DNS is: {target_dns}")


@app.route("/health_check", methods=["GET"])
def health_check():
    #Make health check request to target
    try:
        dns = f"http://{target_dns}/health_check"
        response = requests.get(dns)
    except Exception as e:
        response = "Error making health check request: {e}"
    return f"<h1>Gatekeeper@{self_dns} running</h1>\n<p>Target response: {response}</p>"

@app.route("/direct", methods=["POST"])
def direct():
    app.logger.warning("Received direct request")
    try:
        target_url = f"http://{target_dns}/direct"
        response = requests.post(target_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /direct: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/random", methods=["POST"])
def random():
    app.logger.warning("Received random request")
    try:
        target_url = f"http://{target_dns}/random"
        response = requests.post(target_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /random: {e}")
        return jsonify({"error": str(e)}), 500
    
@app.route("/customized", methods=["POST"])
def customized():
    app.logger.warning("Received customized request")
    try:
        target_url = f"http://{target_dns}/customized"
        response = requests.post(target_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /customized: {e}")
        return jsonify({"error": str(e)}), 500
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
