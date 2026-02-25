import requests
from unittest import mock

BASE_URL = "http://localhost:8080"

def test_post_auth_google_web_without_configuration():
    """
    Test the POST /auth/google endpoint on web platform without proper client configuration (missing serverClientId).
    Expected: 400 status with error 'google_signin_not_configured'.
    """

    # Construct the request payload without serverClientId config implicitly by platform: "web"
    payload = {
        "id_token": "any_dummy_token_for_test",
        "platform": "web"
    }

    headers = {
        "Content-Type": "application/json"
    }

    url = f"{BASE_URL}/auth/google"

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
    except requests.RequestException as e:
        assert False, f"Request failed: {e}"

    assert response.status_code == 400, f"Expected status code 400, got {response.status_code}"
    try:
        response_json = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    assert "error" in response_json, "Response JSON missing 'error' key"
    assert response_json["error"] == "google_signin_not_configured", \
        f"Expected error 'google_signin_not_configured', got {response_json['error']}"

test_post_auth_google_web_without_configuration()
