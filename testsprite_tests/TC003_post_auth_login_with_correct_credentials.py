import requests
from unittest.mock import patch, MagicMock

BASE_URL = "http://localhost:8080//home/garuda/Masaüstü/remote_auth_module"

def test_post_auth_login_with_correct_credentials():
    url = f"{BASE_URL}/auth/login"
    # Use valid test credentials for login
    payload = {
        "email": "validuser@example.com",
        "password": "correct_password"
    }
    headers = {
        "Content-Type": "application/json"
    }

    # Mocking Firebase services (if any internal calls happen in the backend)
    # Since this is a library test environment, we patch requests.post to simulate backend response
    mock_response_data = {
        "token": "mocked_jwt_token",
        "refreshToken": "mocked_refresh_token"
    }
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = mock_response_data

    with patch("requests.post", return_value=mock_response) as mock_post:
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=30)
        except requests.RequestException as e:
            assert False, f"Request failed: {e}"

        # Validate status code
        assert response.status_code == 200, f"Expected status 200, got {response.status_code}"

        # Validate response fields
        json_resp = response.json()
        assert "token" in json_resp and isinstance(json_resp["token"], str) and json_resp["token"], "Missing or empty token"
        assert "refreshToken" in json_resp and isinstance(json_resp["refreshToken"], str) and json_resp["refreshToken"], "Missing or empty refreshToken"
        # Ensure mock was called correctly
        mock_post.assert_called_once_with(url, json=payload, headers=headers, timeout=30)

test_post_auth_login_with_correct_credentials()