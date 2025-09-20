import pytest
import os


@pytest.fixture(scope="session")
def api_base():
    return os.getenv("API_BASE", "http://localhost")
