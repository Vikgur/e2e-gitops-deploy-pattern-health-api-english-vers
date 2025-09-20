import json
import os
from datetime import datetime, timedelta

import psycopg2
from flask import Flask, jsonify, request
from kafka import KafkaProducer
from collections import defaultdict
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_flask_exporter import PrometheusMetrics


app = Flask(__name__)

# Setting up tracers (not in tests)
if os.getenv("FLASK_ENV") != "testing" and not app.config.get("TESTING"):
    trace.set_tracer_provider(
        TracerProvider(
            resource=Resource.create(
                {SERVICE_NAME: os.getenv("SERVICE_NAME", "unknown_service")}
            )
        )
    )
    otlp_exporter = OTLPSpanExporter(
        endpoint=os.getenv(
            "OTEL_EXPORTER_OTLP_ENDPOINT", "http://jaeger:4318/v1/traces"
        ),
    )
    trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(otlp_exporter))
    FlaskInstrumentor().instrument_app(app)


metrics = PrometheusMetrics(app)

kafka_request_log = defaultdict(list)


@app.route("/")
def root():
    return {"status": f"{os.getenv('SERVICE_NAME', 'unknown')} is alive!"}


@app.route("/health")
def health():
    return {"status": "ok"}


@app.route("/version")
def version():
    return {"version": os.getenv("VERSION", "unknown")}


@app.route("/db-test")
def db_test():
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("POSTGRES_DB", "health"),
            user=os.getenv("POSTGRES_USER", "postgres"),
            password=os.getenv("POSTGRES_PASSWORD", "postgres"),
            host=os.getenv("POSTGRES_HOST", "pgbouncer"),
            port=int(os.getenv("POSTGRES_PORT", 6432)),
        )
        with conn.cursor() as cur:
            # Create the table on the first request
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS health (
                    id SERIAL PRIMARY KEY,
                    msg TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """
            )
            # Count how many records already exist
            cur.execute("SELECT COUNT(*) FROM health")
            count = cur.fetchone()[0]
            if count < 10:
                cur.execute(
                    "INSERT INTO health (msg) VALUES (%s)",
                    (
                        f"Ping from Vik at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
                    ),
                )
                conn.commit()
            # Always return the last 5 records
            cur.execute(
                "SELECT id, msg, created_at FROM health ORDER BY id DESC LIMIT 5"
            )
            rows = cur.fetchall()
        conn.close()
        return jsonify(
            [
                {"id": row[0], "message": row[1], "timestamp": row[2].isoformat()}
                for row in rows
            ]
        )
    except Exception as e:
        return {"error": str(e)}, 500


@app.route("/send-kafka")
def send_kafka():
    if os.getenv("FLASK_ENV") == "production":
        return {"error": "Kafka access is disabled in production"}, 403
    try:
        client_ip = request.remote_addr
        now = datetime.now()
        log = kafka_request_log[client_ip]

        # Чистим старые записи
        kafka_request_log[client_ip] = [
            ts for ts in log if now - ts < timedelta(minutes=1)
        ]

        if len(kafka_request_log[client_ip]) >= 20:
            return {
                "error": "Rate limit exceeded: max 20 Kafka messages per minute"
            }, 429

        kafka_request_log[client_ip].append(now)

        producer = KafkaProducer(
            bootstrap_servers=os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        )

        msg = {
            "service": os.getenv("SERVICE_NAME", "unknown"),
            "message": "Vik just pinged Kafka",
            "timestamp": now.isoformat(),
        }

        topic = os.getenv("KAFKA_TOPIC", "health-checks")
        producer.send(topic, msg)
        producer.flush()

        return {"status": f"Message sent to Kafka topic '{topic}'", "message": msg}
    except Exception as e:
        return {"error": str(e)}, 500


if __name__ == "__main__":
    # Fallback mode is enabled — for debugging/development only
    app.run(host="0.0.0.0", port=8080)
