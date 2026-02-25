import requests

def test_post_auth_login_incorrect_password():
    base_url = "http://localhost:8080"
    endpoint = "/auth/login"
    url = base_url + endpoint

    # Using a valid registered email but an incorrect password
    payload = {
        "email": "validuser@example.com",
        "password": "wrongpassword123"
    }
    headers = {
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
    except requests.RequestException as e:
        assert False, f"HTTP request failed: {e}"

    assert response.status_code == 401, f"Expected status 401, got {response.status_code}"
    
    try:
        resp_json = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"
    
    assert "error" in resp_json, "Response JSON missing 'error' field"
    assert resp_json["error"] == "invalid_credentials", f"Expected error 'invalid_credentials', got '{resp_json['error']}'"

test_post_auth_login_incorrect_password()
