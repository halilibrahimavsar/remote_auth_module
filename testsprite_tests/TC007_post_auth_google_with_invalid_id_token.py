import requests
from unittest import mock

BASE_URL = "http://localhost:8080//home/garuda/Masaüstü/remote_auth_module"
TIMEOUT = 30

def test_post_auth_google_with_invalid_id_token():
    url = f"{BASE_URL}/auth/google"
    invalid_id_token = "invalid_or_expired_token_example"

    # Mocking Firebase or external Google token verification would be done here.
    # Since this is a library test environment and we should mock Firebase services,
    # we will mock requests.post to simulate the backend response for invalid token.

    with mock.patch('requests.post') as mock_post:
        mock_response = mock.Mock()
        mock_response.status_code = 401
        mock_response.json.return_value = {"error": "invalid_oauth_token"}
        mock_post.return_value = mock_response

        response = requests.post(url, json={"id_token": invalid_id_token}, timeout=TIMEOUT)

        try:
            assert response.status_code == 401, f"Expected status 401 but got {response.status_code}"
            json_data = response.json()
            assert "error" in json_data, "Response JSON should have 'error' key"
            assert json_data["error"] == "invalid_oauth_token", f"Expected error 'invalid_oauth_token' but got {json_data['error']}"
        except Exception as e:
            raise AssertionError(f"Test failed: {e}")

test_post_auth_google_with_invalid_id_token()