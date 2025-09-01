import requests

BASE_URL = "https://superhero-api-b6u9.onrender.com"

def test_home():
    r = requests.get(f"{BASE_URL}/")
    assert r.status_code == 200
    assert "Welcome" in r.text

def test_get_all():
    r = requests.get(f"{BASE_URL}/superheros")
    assert r.status_code == 200
    assert isinstance(r.json(), list)

def test_add_hero():
    hero = {"name": "Batman", "realName": "Bruce Wayne", "franchise": "DC"}
    r = requests.post(f"{BASE_URL}/superheros/add_hero", json=hero)
    assert r.status_code in (200, 204)

if __name__ == "__main__":
    test_home()
    test_get_all()
    test_add_hero()
    print("✅ Python tests passed")
