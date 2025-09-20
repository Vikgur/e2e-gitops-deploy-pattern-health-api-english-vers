import os
from unittest.mock import MagicMock, patch

import pytest

from app.app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        yield client


def test_root_ok(client):
    os.environ["SERVICE_NAME"] = "health-api"
    response = client.get("/")
    assert response.status_code == 200
    assert response.json["status"] == "health-api is alive!"


def test_health_ok(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json["status"] == "ok"


def test_version_ok(client):
    os.environ["VERSION"] = "1.2.3"
    response = client.get("/version")
    assert response.status_code == 200
    assert response.json["version"] == "1.2.3"


@patch("app.app.psycopg2.connect")
def test_db_test_ok(mock_connect, client):
    mock_conn = MagicMock()
    mock_cursor = mock_conn.cursor.return_value.__enter__.return_value
    mock_cursor.fetchone.return_value = [0]
    mock_cursor.fetchall.return_value = [
        (1, "Test msg", MagicMock(isoformat=lambda: "2024-01-01T12:00:00"))
    ]
    mock_connect.return_value = mock_conn

    response = client.get("/db-test")
    assert response.status_code == 200
    assert isinstance(response.json, list)
    assert response.json[0]["message"] == "Test msg"


@patch("app.app.KafkaProducer")
def test_send_kafka_ok(mock_kafka_producer, client):
    mock_producer = MagicMock()
    mock_kafka_producer.return_value = mock_producer

    os.environ["KAFKA_TOPIC"] = "test-topic"
    os.environ["SERVICE_NAME"] = "health-api"

    response = client.get("/send-kafka")
    assert response.status_code == 200
    assert "Message sent to Kafka" in response.json["status"]


@patch("app.app.psycopg2.connect", side_effect=Exception("DB down"))
def test_db_test_fail(mock_connect, client):
    response = client.get("/db-test")
    assert response.status_code == 500
    assert "error" in response.json


@patch("app.app.KafkaProducer", side_effect=Exception("Kafka error"))
def test_send_kafka_fail(mock_kafka, client):
    response = client.get("/send-kafka")
    assert response.status_code == 500
    assert "error" in response.json
