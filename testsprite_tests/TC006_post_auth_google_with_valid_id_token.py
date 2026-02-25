import requests
from unittest import mock

BASE_URL = "http://localhost:8080//home/garuda/Masaüstü/remote_auth_module"
TIMEOUT = 30

def test_post_auth_google_valid_id_token():
    # Mocked valid id_token since actual Google token retrieval requires Firebase/Google SDK
    valid_id_token = "mocked_valid_google_id_token_for_testing_purposes"

    url = f"{BASE_URL}/auth/google"
    headers = {
        "Content-Type": "application/json"
    }
    payload = {
        "id_token": valid_id_token
    }

    # Mock requests.post to simulate Firebase behavior for testing environment
    with mock.patch('requests.post') as mock_post:
        # Mock successful response data
        mock_response = mock.Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "token": "mocked_app_token",
            "provider": "google",
            "userId": "mocked_user_id_123"
        }
        mock_post.return_value = mock_response

        response = requests.post(url, json=payload, headers=headers, timeout=TIMEOUT)

        # Assertions
        assert response.status_code == 200, f"Expected status 200 but got {response.status_code}"
        data = response.json()
        assert "token" in data and isinstance(data["token"], str) and data["token"], "Missing or invalid token"
        assert data.get("provider") == "google", "Provider is not 'google'"
        assert "userId" in data and isinstance(data["userId"], str) and data["userId"], "Missing or invalid userId"

test_post_auth_google_valid_id_token()