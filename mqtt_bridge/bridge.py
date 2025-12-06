import json
from datetime import datetime
import paho.mqtt.client as mqtt
import mysql.connector
import psycopg


# ================================
# CONFIG
# ================================
BROKER = "localhost"
PORT = 1883
TOPIC = "factory/material_event"

# ================================
# CREATE FRESH MARIA + POSTGRES CONN EACH TIME
# ================================
def open_maria():
    return mysql.connector.connect(
        host="localhost",
        user="admin",
        password="adminpassword",
        database="mariadb_testdb"
    )

def open_postgres():
    return psycopg.connect(
        host="localhost",
        user="admin",
        password="adminpassword",
        dbname="testdb"
    )



# ================================
# MQTT CALLBACKS
# ================================
def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print("🔌 MQTT Connected")
        client.subscribe(TOPIC)
        print(f"📡 Subscribed to: {TOPIC}")
    else:
        print("❌ MQTT Connection failed:", rc)


def on_message(client, userdata, msg, properties=None):
    payload = msg.payload.decode()
    print("📥 Received:", payload)

    try:
        data = json.loads(payload)
        store_event(data)
    except Exception as e:
        print("❌ Invalid JSON:", e)


# ================================
# STORE EVENT IN MARIA DB (SAFE)
# ================================
def store_event(data):
    scanner = data.get("scanner_id")
    product = data.get("product_id")
    material = data.get("material_id")
    event_type = data.get("event_type", "added")

    raw_ts = data.get("timestamp")
    timestamp = raw_ts.replace("T", " ").replace("Z", "")

    sql = """
        INSERT INTO material_event
        (scanner_id, product_id, material_id, event_type, scanned_at)
        VALUES (%s, %s, %s, %s, %s)
    """

    try:
        conn = open_maria()          # <--- FRESH CONNECTION
        cur = conn.cursor()
        cur.execute(sql, (scanner, product, material, event_type, timestamp))
        conn.commit()
        cur.close()
        conn.close()

        print(f"✔ Inserted event → product={product}, material={material}, scanner={scanner}")

    except Exception as e:
        print("❌ Failed to insert event into MariaDB:", e)


# ================================
# START MQTT CLIENT
# ================================
client = mqtt.Client(protocol=mqtt.MQTTv5)
client.on_connect = on_connect
client.on_message = on_message

print("Connecting to MQTT broker...")
client.connect(BROKER, PORT, 60)

print("Bridge running 🔄 Listening for events...")
client.loop_forever()
