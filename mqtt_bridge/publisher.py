import time
import json
import random
import paho.mqtt.client as mqtt


# CONFIGURATION
# -------------------------------------------------------------------
BROKER = "localhost"       
PORT = 1883
TOPIC = "factory/data/sensor1"
CLIENT_ID = "factory_publisher"


# MQTT CONNECTION
# -------------------------------------------------------------------
client = mqtt.Client(CLIENT_ID)

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker")
    else:
        print(f"Failed to connect, code {rc}")

client.on_connect = on_connect
client.connect(BROKER, PORT, keepalive=60)


# PUBLISHING LOOP
# -------------------------------------------------------------------
try:
    while True:
        # Example simulated data payload
        payload = {
            "factory_id": "F001",
            "factory_name": "Burger Factory",
            "factory_location": "Berlin",

            "machine_id": "M101",
            "machine_name": "Burger Former",
            "model": "CB-500",
            "status": "Active",

            "metric": "temperature",
            "value": temperature,
            "unit": "°C",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),

            "product_id": "P9001",
            "product_name": "Classic Burger",
            "product_type": "Food",
            "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "materials": [
                {"id": "MAT01", "name": "Beef Patty", "type": "Ingredient"},
                {"id": "MAT02", "name": "Bun", "type": "Ingredient"}
            ]
        }

        message = json.dumps(payload)
        result = client.publish(TOPIC, message)

        # Checking if publishing was successful
        status = result[0]
        if status == 0:
            print(f"Sent `{message}` to topic `{TOPIC}`")
        else:
            print(f"Failed to send message to topic {TOPIC}")

        time.sleep(2)  # Continuously publishing every 2 seconds

except KeyboardInterrupt:
    print("\n Stopping publisher...")
    client.disconnect()
