
from sshtunnel import SSHTunnelForwarder
import random
from pythonping import ping
from flask import Flask, request, jsonify
import threading
import os
import pymysql

app = Flask(__name__)



# Retrieve and validate the list of worker DNS addresses from environment variables
slave_1 = os.environ.get("SLAVE_1_DNS", "")
slave_2 = os.environ.get("SLAVE_2_DNS", "")
slave_3 = os.environ.get("SLAVE_3_DNS", "")
MASTER_SERVER = os.environ.get("MASTER_DNS", "")
self_dns = os.environ.get("SELF_DNS")
SLAVE_SERVERS = [slave_1, slave_2, slave_3]


db_config = {
    "host": MASTER_SERVER,
    "user": "root",  # MySQL username
    "password": "",  # MySQL password
    "database": "prod",  # Database name
}

ssh_tunnel = None
def create_ssh_tunnel(target_dns):
    global ssh_tunnel
    try:
        ssh_tunnel = SSHTunnelForwarder(
            (db_config["host"], 22),
            ssh_username="ubuntu",
            ssh_pkey="/etc/proxy/vockey.pem",
            remote_bind_address=(target_dns, 3306),
            local_bind_address=("127.0.0.1", 8080),
        )
        ssh_tunnel.start()
        app.logger.warning("Successfully established SSH tunnel.")
    except Exception as e:
        app.logger.error(f"Failed to establish SSH tunnel: {e}")
        return None
    
def ping_slave(slave):
    try:
        rtt = ping(slave, verbose=True, count=1)
        return rtt.rtt_avg_ms
    except Exception as e:
        return float("inf")

def get_tunnel(method):
    random_slave = method()
    random_ssh_tunnel = create_ssh_tunnel(random_slave)
    return random_ssh_tunnel

def make_request(request, method):
    global ssh_tunnel
    get_tunnel(method)
    data = request.get_json()
    sql = data["sql"]
    if not ssh_tunnel:
        return jsonify({"error": "Failed to establish SSH tunnel"}), 500
    try:
        # Connect to the database using an SSH tunnel and the db_config
        with pymysql.connect(host=db_config["host"],
                             port=3306,
                             user=db_config["user"],
                             password=db_config["password"],
                             database=db_config["database"]) as conn:
            with conn.cursor() as cursor:
                cursor.execute(sql)
                result = cursor.fetchall()
        ssh_tunnel.stop()
        return jsonify(result)
    except Exception as err:
        return jsonify({"error": str(err)}), 500



def getMaster():
    return MASTER_SERVER


def get_random_slave():
    return random.choice(SLAVE_SERVERS)


def get_fastest_slave():
    # Get the fastest slave server
    # Return the address of the fastest slave server
    fastest = None
    min = 1000000000000
    for slave in SLAVE_SERVERS:
        rtt = ping(slave, verbose=True, count=1)
        if rtt.rtt_avg_ms < min:
            min = rtt.rtt_avg_ms
            fastest = slave
    return fastest

@app.route("/health_check", methods=["GET"])
def health_check():
    return f"<h1>Proxy@{self_dns} running</h1>"

@app.route("/direct", methods=["POST"])
def direct_hit():
    print("direct request:", request.json)
    return make_request(request,getMaster)

@app.route("/random", methods=["POST"])
def random_hit():
    return make_request(request,get_random_slave)

@app.route("/customized", methods=["POST"])
def fastest_hit():
    return make_request(request, get_fastest_slave)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)