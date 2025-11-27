import os
import json
from datetime import datetime
import paho.mqtt.client as mqtt
from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS
import requests


# CONFIGURATION
# -------------------------------------------------------------------
BROKER = os.getenv("BROKER", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
TOPIC = os.getenv("TOPIC", "factory/data/#")

# InfluxDB configuration (from env or defaults)
INFLUX_URL = os.getenv("INFLUX_URL", "http://localhost:8086")
INFLUX_TOKEN = os.getenv("INFLUX_TOKEN", "influx_token")
INFLUX_ORG = os.getenv("INFLUX_ORG", "your_org")
INFLUX_BUCKET = os.getenv("INFLUX_BUCKET", "factory_data")

# Dgraph configuration
DGRAPH_GRAPHQL_URL = os.getenv("DGRAPH_GRAPHQL_URL", "http://localhost:8080/graphql")


# DATABASE CLIENTS
# -------------------------------------------------------------------
# Initialize Influx client lazily to avoid startup errors when not configured
try:
  influx_client = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
  write_api = influx_client.write_api(write_options=SYNCHRONOUS)
except Exception as e:
  influx_client = None
  write_api = None
  print(f"Warning: could not initialize InfluxDB client: {e}")


# MQTT CALLBACKS
# -------------------------------------------------------------------
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker")
        client.subscribe(TOPIC)
    else:
        print(f"Failed to connect, code {rc}")

def on_message(client, userdata, msg):
    payload = msg.payload.decode()
    print(f"Received on {msg.topic}: {payload}")

    try:
        data = json.loads(payload)
        process_message(msg.topic, data)
    except json.JSONDecodeError:
        print("Ignored non-JSON payload")


# MESSAGE HANDLER
# -------------------------------------------------------------------
def process_message(topic, data):
    timestamp = datetime.utcnow()

    # Route data
    store_in_influx(topic, data, timestamp)
    store_in_dgraph(data, timestamp)


# INFLUXDB STORAGE
# -------------------------------------------------------------------
def store_in_influx(topic, data, timestamp):
    try:
        # We are only writing data if the message contains a measurable "value"
    if write_api is None:
      print("Influx write skipped: Influx client not configured")
      return

    if "value" in data:
            point = (
                Point("machine_metrics")
                .tag("factory_id", data.get("factory_id", "unknown"))
                .tag("machine_id", data.get("machine_id", "unknown"))
                .tag("metric", data.get("metric", "unknown"))
                .field("value", float(data["value"]))
                .time(timestamp, WritePrecision.NS)
            )
            write_api.write(bucket=INFLUX_BUCKET, org=INFLUX_ORG, record=point)
            print(f"Stored in InfluxDB: {data.get('metric')}={data.get('value')} for {data.get('machine_id')}")
        else:
            print("Skipped Influx write (no numeric value)")
    except Exception as e:
        print(f"InfluxDB write error: {e}")


# DGRAPH STORAGE (GraphQL MUTATION)
# -------------------------------------------------------------------
def store_in_dgraph(data, timestamp):
    try:
        # Only attempt writes if a GraphQL endpoint is configured
        if not DGRAPH_GRAPHQL_URL:
            print("Dgraph write skipped: DGRAPH_GRAPHQL_URL not configured")
            return

        # If the message contains a product, attempt to add it to Dgraph
        # Map common publisher keys to the GraphQL Product input shape
        if "product_id" in data or "id" in data:
            product_id = data.get("product_id") or data.get("id")
            product_input = {
                "id": product_id,
                "name": data.get("product_name") or data.get("name"),
                "type": data.get("product_type") or data.get("type") or "Food",
                "createdAt": data.get("createdAt") or timestamp.isoformat()
            }

            # optional relations
            if data.get("factory_id"):
                product_input["factory"] = {"id": data.get("factory_id")}
            if data.get("machine_id"):
                product_input["machine"] = {"id": data.get("machine_id")}
            if data.get("materials") and isinstance(data.get("materials"), list):
                # allow list of dicts with id or list of ids
                mats = []
                for m in data.get("materials"):
                    if isinstance(m, dict) and m.get("id"):
                        mats.append({"id": m.get("id")})
                    elif isinstance(m, str):
                        mats.append({"id": m})
                if mats:
                    product_input["materials"] = mats

            mutation = """
            mutation AddProduct($input: [AddProductInput!]!) {
              addProduct(input: $input) {
                product { id }
              }
            }
            """

            variables = {"input": [product_input]}

            response = requests.post(
                DGRAPH_GRAPHQL_URL,
                json={"query": mutation, "variables": variables},
                headers={"Content-Type": "application/json"},
                timeout=10,
            )

            if response.status_code == 200:
                print(f"Stored product in Dgraph: {product_id}")
            else:
                print(f"Dgraph error: {response.status_code} - {response.text}")
        else:
            print("No product info in message; skipped Dgraph write")

    except Exception as e:
        print(f"Dgraph write error: {e}")


# MAIN LOOP
# -------------------------------------------------------------------
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(BROKER, MQTT_PORT, keepalive=60)
client.loop_forever()
