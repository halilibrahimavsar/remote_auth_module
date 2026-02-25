import requests

def test_post_auth_phone_verify_with_valid_phone_number():
    base_url = "http://localhost:8080//home/garuda/Masaüstü/remote_auth_module"
    endpoint = "/auth/phone/verify"
    url = base_url + endpoint
    headers = {
        "Content-Type": "application/json"
    }
    # Using a valid E.164 phone number format for test, example +15555550123
    payload = {
        "phoneNumber": "+15555550123"
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
    except requests.RequestException as e:
        assert False, f"HTTP request failed: {e}"

    assert response.status_code == 200, f"Expected status code 200 but got {response.status_code}"
    try:
        resp_json = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    assert "verificationId" in resp_json, "Response JSON missing 'verificationId'"
    assert isinstance(resp_json["verificationId"], str) and len(resp_json["verificationId"]) > 0, "'verificationId' should be a non-empty string"
    assert "ttlSeconds" in resp_json, "Response JSON missing 'ttlSeconds'"
    assert isinstance(resp_json["ttlSeconds"], int) and resp_json["ttlSeconds"] > 0, "'ttlSeconds' should be a positive integer"


test_post_auth_phone_verify_with_valid_phone_number()