import httpx
import sys

BASE_URL = "http://localhost:8000"

def run_tests():
    print("[*] Starting Backend Integration Test Suite...")
    
    # 1. Test registration
    print("\n1. Testing User Registration...")
    reg_payload = {
        "email": "architect@DevForge.ai",
        "password": "supersecurepassword123",
        "full_name": "Senior Software Architect"
    }
    try:
        response = httpx.post(f"{BASE_URL}/api/auth/register", json=reg_payload)
        if response.status_code == 400 and "already registered" in response.json().get("detail", ""):
            print("[info] User already registered, continuing to login.")
        else:
            assert response.status_code == 200, f"Registration failed: {response.text}"
            print("[ok] User registration succeeded!")
    except Exception as e:
        print(f"[error] Registration request failed: {str(e)}")
        sys.exit(1)

    # 2. Test login
    print("\n2. Testing User Login...")
    login_payload = {
        "email": "architect@DevForge.ai",
        "password": "supersecurepassword123"
    }
    response = httpx.post(f"{BASE_URL}/api/auth/login", json=login_payload)
    assert response.status_code == 200, f"Login failed: {response.text}"
    token_data = response.json()
    token = token_data["access_token"]
    user_name = token_data["user"]["full_name"]
    print(f"[ok] Login succeeded! Welcome, {user_name}.")
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # 3. Test current user profile fetch
    print("\n3. Testing Profile Retrieval...")
    response = httpx.get(f"{BASE_URL}/api/auth/me", headers=headers)
    assert response.status_code == 200, f"Me query failed: {response.text}"
    print(f"[ok] Profile verified: {response.json()['email']}")

    # 4. Test project creation
    print("\n4. Testing Project Creation...")
    project_payload = {
        "name": "DevForge AI SaaS Platform",
        "description": "An automated project planning toolkit for developers using multi-agent networks.",
        "target_users": "Fullstack developers and managers",
        "budget": "$10,000",
        "timeline": "3 months"
    }
    response = httpx.post(f"{BASE_URL}/api/projects", json=project_payload, headers=headers)
    assert response.status_code == 200, f"Project creation failed: {response.text}"
    project = response.json()
    project_id = project["id"]
    print(f"[ok] Project created successfully! ID: {project_id}, Title: {project['name']}")

    # 5. Test AI agent generation (Requirements Analyzer)
    print("\n5. Testing Requirements Agent Generation (Simulation)...")
    response = httpx.post(f"{BASE_URL}/api/projects/{project_id}/generate/requirements", json={}, headers=headers)
    assert response.status_code == 200, f"AI generation failed: {response.text}"
    report = response.json()
    print("[ok] AI Requirements report generated successfully!")
    print(f"[info] Functional Specs Count: {len(report['content']['functional'])}")

    # 6. Test AI agent generation (Task Planner Kanban)
    print("\n6. Testing Task Planner Agent Generation...")
    response = httpx.post(f"{BASE_URL}/api/projects/{project_id}/generate/tasks", json={}, headers=headers)
    assert response.status_code == 200, f"AI tasks generation failed: {response.text}"
    tasks_report = response.json()
    print("[ok] AI Task/Sprint report generated successfully!")
    print(f"[info] Todo Tasks Count: {len(tasks_report['content']['kanban']['todo'])}")

    # 7. List project reports
    print("\n7. Verifying SQLite Log Persistence...")
    response = httpx.get(f"{BASE_URL}/api/projects/{project_id}/reports", headers=headers)
    assert response.status_code == 200, f"Failed to list reports: {response.text}"
    reports_list = response.json()
    print(f"[ok] SQLite reports saved: {len(reports_list)} agents recorded.")

    # 8. Test project duplication
    print("\n8. Testing Project Duplication...")
    response = httpx.post(f"{BASE_URL}/api/projects/{project_id}/duplicate", json={}, headers=headers)
    assert response.status_code == 200, f"Duplication failed: {response.text}"
    dup_project = response.json()
    dup_id = dup_project["id"]
    print(f"[ok] Project duplicated successfully! New ID: {dup_id}, Title: {dup_project['name']}")

    # 9. List projects history
    print("\n9. Querying Projects list...")
    response = httpx.get(f"{BASE_URL}/api/projects", headers=headers)
    assert response.status_code == 200, f"Querying projects failed: {response.text}"
    all_projects = response.json()
    print(f"[ok] Found {len(all_projects)} projects in database history.")

    # 10. Clean up duplicated project
    print("\n10. Cleaning up (Deleting duplicate)...")
    response = httpx.delete(f"{BASE_URL}/api/projects/{dup_id}", headers=headers)
    assert response.status_code == 200, f"Deletions failed: {response.text}"
    print("[ok] Duplicate project clean-up successful!")

    print("\n[SUCCESS] ALL BACKEND TESTS COMPLETED SUCCESSFULLY! 100% OPERATIONAL.")


if __name__ == "__main__":
    run_tests()
