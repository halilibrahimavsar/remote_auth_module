import requests

BASE_URL = "http://localhost:8080//home/garuda/Masa\xFCst\xFC/remote_auth_module"

def test_post_auth_phone_verify_with_invalid_phone_number():
    url = f"{BASE_URL}/auth/phone/verify"
    headers = {"Content-Type": "application/json"}
    payload = {"phoneNumber": "123-invalid-phone"}

    response = requests.post(url, json=payload, headers=headers, timeout=30)

    # Validate the response status code and error message
    assert response.status_code == 400, f"Expected 400 but got {response.status_code}"
    json_resp = response.json()
    assert "error" in json_resp, "Response JSON should contain 'error'"
    assert json_resp["error"] == "invalid_phone_number", f"Expected error 'invalid_phone_number' but got {json_resp['error']}"

test_post_auth_phone_verify_with_invalid_phone_number()