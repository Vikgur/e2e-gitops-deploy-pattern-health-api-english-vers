import pytest
import requests
import allure
from requests.auth import HTTPBasicAuth


@allure.step("GET request to endpoint: {endpoint}")
def get_with_auth(api_base, endpoint):
    return requests.get(f"{api_base}{endpoint}", auth=HTTPBasicAuth("admin", "admin"))


@pytest.mark.parametrize("endpoint", ["/", "/health", "/version"])
def test_basic_endpoints_200(api_base, endpoint):
    allure.dynamic.title(f"Check {endpoint} is reachable")
    allure.dynamic.description("Verifies that endpoint returns 200 and correct Content-Type")

    with allure.step("Sending GET request"):
        res = get_with_auth(api_base, endpoint)

    with allure.step("Asserting status code is 200"):
        assert res.status_code == 200

    with allure.step("Asserting Content-Type is application/json"):
        assert res.headers["Content-Type"].startswith("application/json")


def test_db_test_growth(api_base):
    allure.dynamic.title("Check that /db-test increases entry count")
    allure.dynamic.description("Makes two calls and checks that the second has same or more entries")

    with allure.step("First request to /db-test"):
        res1 = get_with_auth(api_base, "/db-test")
        assert res1.status_code == 200
        count1 = len(res1.json())

    with allure.step("Second request to /db-test"):
        res2 = get_with_auth(api_base, "/db-test")
        assert res2.status_code == 200
        count2 = len(res2.json())

    with allure.step("Verifying entry count increased or stayed same"):
        assert count2 >= count1


def test_db_test_last_5(api_base):
    allure.dynamic.title("Check /db-test returns max 5 recent records")
    allure.dynamic.description("Ensures returned list has up to 5 items with correct fields")

    with allure.step("Sending GET request to /db-test"):
        res = get_with_auth(api_base, "/db-test")
        assert res.status_code == 200
        data = res.json()

    with allure.step("Validating response is a list with ≤5 items"):
        assert isinstance(data, list)
        assert len(data) <= 5

    with allure.step("Validating each record has required fields"):
        for entry in data:
            assert "id" in entry
            assert "message" in entry
            assert "timestamp" in entry


def test_db_test_fail(api_base):
    allure.dynamic.title("Check /db-test fails with wrong hostname")
    allure.dynamic.description("Replaces localhost with invalid hostname and expects failure")

    wrong_url = api_base.replace("localhost", "unknown-host")

    with allure.step("Attempting request to broken address"):
        try:
            res = requests.get(f"{wrong_url}/db-test", timeout=3, auth=HTTPBasicAuth("admin", "admin"))
        except requests.exceptions.RequestException:
            with allure.step("Expected exception was raised"):
                assert True
        else:
            with allure.step("Response received unexpectedly — check status code"):
                assert res.status_code == 500


def test_send_kafka(api_base):
    allure.dynamic.title("Check /send-kafka endpoint works")
    allure.dynamic.description("Sends a request to Kafka endpoint and checks response structure")

    with allure.step("Sending request to /send-kafka"):
        res = get_with_auth(api_base, "/send-kafka")
        assert res.status_code == 200
        data = res.json()

    with allure.step("Validating response fields"):
        assert "status" in data
        assert "message" in data
        assert "service" in data["message"]
        assert "timestamp" in data["message"]
