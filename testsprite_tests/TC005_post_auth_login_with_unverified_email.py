import requests
import uuid

base_url = "http://localhost:8080"
timeout = 30

def test_post_auth_login_with_unverified_email():
    register_url = f"{base_url}/auth/register"
    login_url = f"{base_url}/auth/login"

    # Generate unique email for the test
    test_email = f"test_unverified_{uuid.uuid4()}@example.com"
    test_password = "TestPass123!"

    # Register a new user with emailVerified: false assumed by API on register
    register_payload = {
        "email": test_email,
        "password": test_password
    }

    try:
        # Register user
        reg_resp = requests.post(register_url, json=register_payload, timeout=timeout)
        assert reg_resp.status_code == 201, f"Registration failed with status code {reg_resp.status_code}"
        reg_data = reg_resp.json()
        assert "userId" in reg_data
        assert reg_data.get("emailVerified") is False

        # Login with the newly registered unverified email user
        login_payload = {
            "email": test_email,
            "password": test_password
        }
        login_resp = requests.post(login_url, json=login_payload, timeout=timeout)
        assert login_resp.status_code == 200, f"Login failed with status code {login_resp.status_code}"

        login_data = login_resp.json()
        assert "token" in login_data, "Login response missing 'token'"
        assert login_data.get("emailVerificationRequired") is True, "'emailVerificationRequired' flag not True"

    finally:
        # Cleanup: Normally delete user here if API supports it, else skip cleanup
        # No delete endpoint described in PRD, so no cleanup
        pass

test_post_auth_login_with_unverified_email()