import time
import json
import random
import paho.mqtt.client as mqtt

BROKER = "localhost"
PORT = 1883
TOPIC = "factory/material_event"
CLIENT_ID = "material_publisher"

client = mqtt.Client(client_id=CLIENT_ID, protocol=mqtt.MQTTv5)

def on_connect(client, userdata, flags, rc):
    print("Connected" if rc == 0 else f"Failed: {rc}")

client.on_connect = on_connect
client.connect(BROKER, PORT, 60)

SCANNERS = ["SCN001", "SCN002", "SCN003"]
PRODUCTS = ["P001", "P002", "P003", "P004"]

PRODUCT_MATERIALS = {
    "P001": ["MAT001", "MAT002"],
    "P002": ["MAT003", "MAT004"],
    "P003": ["MAT005", "MAT002"],
    "P004": ["MAT006", "MAT005", "MAT004"],
}

while True:
    product = random.choice(PRODUCTS)
    material = random.choice(PRODUCT_MATERIALS[product])
    scanner = random.choice(SCANNERS)

    payload = {
        "scanner_id": scanner,
        "product_id": product,
        "material_id": material,
        "event_type": "added",
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()) # ← FIXED
    }

    message = json.dumps(payload)
    client.publish(TOPIC, message)
    print("Sent:", message)

    time.sleep(2)
