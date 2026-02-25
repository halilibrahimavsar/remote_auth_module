import requests
import uuid

BASE_URL = "http://localhost:8080"

def test_post_auth_register_with_existing_email():
    # Generate a unique email to register first
    unique_email = f"testuser_{uuid.uuid4().hex}@example.com"
    password = "ValidPass123!"

    register_url = f"{BASE_URL}/auth/register"
    headers = {
        "Content-Type": "application/json"
    }
    payload = {
        "email": unique_email,
        "password": password
    }

    try:
        # First, register the user
        resp_register_first = requests.post(register_url, json=payload, headers=headers, timeout=30)
        assert resp_register_first.status_code == 201, f"Expected 201 on first register, got {resp_register_first.status_code}"
        resp_json_first = resp_register_first.json()
        assert "userId" in resp_json_first and "emailVerified" in resp_json_first, "Missing keys in first register response"
        assert resp_json_first["emailVerified"] is False

        # Now try to register with the same email again, expecting 409 error
        resp_register_second = requests.post(register_url, json=payload, headers=headers, timeout=30)

        assert resp_register_second.status_code == 409, f"Expected 409 on duplicate register, got {resp_register_second.status_code}"
        resp_json_second = resp_register_second.json()
        assert "error" in resp_json_second, "Missing error key on duplicate register response"
        assert resp_json_second["error"] == "email_already_exists", f"Expected error 'email_already_exists', got {resp_json_second['error']}"

    finally:
        # Cleanup: No deletion endpoint given, if it existed delete the created user here.
        pass

test_post_auth_register_with_existing_email()