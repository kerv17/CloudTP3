import sys
import pymysql
from sshtunnel import SSHTunnelForwarder
import random
from pythonping import ping

# Set master server address as first argument
MASTER_SERVER = sys.argv[3]
# Set Slave servers as the rest of the arguments
SLAVE_SERVERS = sys.argv[4:]


def make_request(query, server):
    with SSHTunnelForwarder(
        (server, 22),
        ssh_username="ubuntu",
        ssh_pkey="vockey.ppk",
        remote_bind_address=(MASTER_SERVER, 3306)) as tunnel:
        conn = pymysql.connect(host=tunnel.local_bind_host,
                               port=tunnel.local_bind_port,
                               user='root',
                               passwd='root',
                               db='sakila')
        cur = conn.cursor()
        cur.execute(query)
        result = cur.fetchall()
        cur.close()
        conn.close()
        return results


def direct_hit(query):
    print("Request sent to master: " + MASTER_SERVER)
    return make_request(query, MASTER_SERVER)


def get_random_slave():
    return random.choice(SLAVE_SERVERS)
def random_hit(query):
    slave = get_random_slave()
    print("Request sent to slave: " + slave)
    return make_request(query, slave)

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
def fastest_hit(query):
    # Send the query to the fastest slave server
    # Return the response
    slave = get_fastest_slave()
    print("Request sent to slave: " + slave)
    return make_request(query, slave)



if __name__ == "__main__":
    implementation = sys.argv[1]
    query = sys.argv[2]

    if implementation == "direct":
        direct_hit(query)
    elif implementation == "random":
        random_hit(query)
    elif implementation == "customized":
        fastest_hit(query)
    else:
        print("Invalid implementation")