
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

random_ssh_tunnel = None
customized_ssh_tunnel = None
ping_times = None
random_request_counter = 0

def make_request(data, pickMethod:function):
    data = request.json
    sql = data.get("sql")
    if not sql:
        return jsonify({"error": "SQL query not found"}), 400

    server = pickMethod()
    # Print the server address to the console and the name of the picked method
    app.logger.warning(f"Server address is: {server}")
    app.logger.warning(f"Method used is: {pickMethod.__name__}")

    # Create an SSH tunnel to the picked server
    try:
        with SSHTunnelForwarder(
            (server, 22),
            ssh_username="ubuntu",
            ssh_pkey="vockey.ppk",
            remote_bind_address=(MASTER_SERVER, 3306)) as tunnel:
            conn = pymysql.connect(host=tunnel.local_bind_host,
                                port=tunnel.local_bind_port,
                                user='root',
                                db='prod')
            cur = conn.cursor()
            cur.execute(query)
            result = cur.fetchall()
            cur.close()
            conn.close()
            return results
    except Exception as e:
        print(e)
        return jsonify({"error": "Internal server error"}), 500

@app.route("/health_check", methods=["GET"])
def health_check():
    return f"<h1>Proxy@{self_dns} running</h1>"


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



@app.route("direct", methods=["POST"])
def direct_hit():
    return make_request(request,getMaster)

@app.route("random", methods=["POST"])
def random_hit():
    return make_request(request,get_random_slave)

@app.route("customized", methods=["POST"])
def fastest_hit():
    return make_request(request, get_fastest_slave)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)