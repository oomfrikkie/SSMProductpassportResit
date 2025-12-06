import json
from datetime import datetime
import paho.mqtt.client as mqtt
import mysql.connector

BROKER = "localhost"
PORT = 1883
TOPIC = "factory/#"   # <<< UNS pattern

def open_maria():
    return mysql.connector.connect(
        host="localhost",
        port=3307,                   # ← FIXED
        user="admin",
        password="adminpassword",
        database="mariadb_testdb"
    )


def on_connect(client, userdata, flags, rc, properties=None):
    print("Connected" if rc == 0 else f"Failed: {rc}")
    client.subscribe(TOPIC)

def on_message(client, userdata, msg, properties=None):
    topic = msg.topic
    payload = msg.payload.decode()
    print(f"📥 Topic: {topic} → Payload: {payload}")

    data = json.loads(payload)
    store_event(topic, data)

def store_event(topic, data):
    scanner = data.get("scanner_id")
    product = data.get("product_id")
    material = data.get("material_id")
    event_type = data.get("event_type", "added")
    timestamp = data.get("timestamp").replace("T", " ").replace("Z", "")

    sql = """
        INSERT INTO material_event
        (scanner_id, product_id, material_id, event_type, scanned_at)
        VALUES (%s, %s, %s, %s, %s)
    """

    conn = open_maria()
    cur = conn.cursor()
    cur.execute(sql, (scanner, product, material, event_type, timestamp))
    conn.commit()
    cur.close()
    conn.close()

    print(f"✔ Inserted → {scanner}, {product}, {material}")

client = mqtt.Client(protocol=mqtt.MQTTv5)
client.on_connect = on_connect
client.on_message = on_message

client.connect(BROKER, PORT, 60)

print("UNS Bridge running…")
client.loop_forever()
