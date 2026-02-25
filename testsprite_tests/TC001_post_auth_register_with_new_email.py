import requests
import uuid

BASE_URL = "http://localhost:8080"
REGISTER_ENDPOINT = "/auth/register"
TIMEOUT = 30

def test_post_auth_register_with_new_email():
    # Generate a unique email to ensure new registration
    unique_email = f"test_{uuid.uuid4().hex}@example.com"
    password = "TestPassword123!"

    url = BASE_URL + REGISTER_ENDPOINT
    payload = {
        "email": unique_email,
        "password": password
    }
    headers = {
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=TIMEOUT)
        # Assert status code 201 Created
        assert response.status_code == 201, f"Expected status 201, got {response.status_code}"

        data = response.json()
        # Assert that userId is present and is a non-empty string
        assert "userId" in data and isinstance(data["userId"], str) and data["userId"], "userId missing or invalid in response"
        # Assert emailVerified is present and False
        assert "emailVerified" in data and data["emailVerified"] is False, "emailVerified is not False"

    except requests.RequestException as e:
        assert False, f"Request failed: {e}"

test_post_auth_register_with_new_email()
