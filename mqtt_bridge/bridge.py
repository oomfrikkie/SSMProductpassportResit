import os
import json
from datetime import datetime
import paho.mqtt.client as mqtt
import mysql.connector
import psycopg2

# ================================
# CONFIG
# ================================
BROKER = "localhost"
PORT = 1883
TOPIC = "factory/material_event"

# MARIA DB (time-series)
maria = mysql.connector.connect(
    host="localhost",
    user="admin",
    password="adminpassword",
    database="mariadb_testdb"
)
maria_cur = maria.cursor()

# POSTGRES (reference data)
postgres = psycopg2.connect(
    host="localhost",
    user="admin",
    password="adminpassword",
    database="testdb"
)
pg_cur = postgres.cursor()


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
# STORE EVENT IN MARIA DB
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

    maria_cur.execute(sql, (scanner, product, material, event_type, timestamp))
    maria.commit()

    print(f"Inserted event → {product} + {material} @ {scanner}")



# ================================
# START MQTT CLIENT
# ================================
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

print("Connecting to MQTT...")
client.connect(BROKER, PORT, 60)
client.loop_forever()
