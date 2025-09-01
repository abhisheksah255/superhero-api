# import requests

# BASE_URL = "https://superhero-api-b6u9.onrender.com"

# def test_home():
#     r = requests.get(f"{BASE_URL}/")
#     assert r.status_code == 200
#     assert "Welcome" in r.text

# def test_get_all():
#     r = requests.get(f"{BASE_URL}/superheros")
#     assert r.status_code == 200
#     assert isinstance(r.json(), list)

# def test_add_hero():
#     hero = {"name": "Batman", "realName": "Bruce Wayne", "franchise": "DC"}
#     r = requests.post(f"{BASE_URL}/superheros/add_hero", json=hero)
#     assert r.status_code in (200, 204)

# if __name__ == "__main__":
#     test_home()
#     test_get_all()
#     test_add_hero()
#     print("✅ Python tests passed")

import sys, json, requests

collection_file = sys.argv[1]
out_file = sys.argv[2]

with open(collection_file) as f:
    collection = json.load(f)

results = []


def parse_url(url_obj):
    """
    Convert Postman url object into string (handles raw or joined parts)
    """
    if isinstance(url_obj, str):
        return url_obj
    if "raw" in url_obj:
        return url_obj["raw"]
    if "host" in url_obj and "path" in url_obj:
        scheme = url_obj.get("protocol", "https")
        host = ".".join(url_obj["host"]) if isinstance(url_obj["host"], list) else url_obj["host"]
        path = "/".join(url_obj["path"]) if isinstance(url_obj["path"], list) else url_obj["path"]
        return f"{scheme}://{host}/{path}"
    return ""


for item in collection.get("item", []):
    try:
        req = item.get("request", {})
        name = item.get("name", "Unnamed Test")
        method = req.get("method", "GET")
        url = parse_url(req.get("url", ""))

        headers = {h["key"]: h["value"] for h in req.get("header", [])}

        body = None
        if "body" in req and req["body"].get("mode") == "raw":
            body = req["body"]["raw"]

        resp = None
        if method == "GET":
            resp = requests.get(url, headers=headers)
        elif method == "POST":
            resp = requests.post(url, data=body, headers=headers)
        elif method == "PUT":
            resp = requests.put(url, data=body, headers=headers)
        elif method == "DELETE":
            resp = requests.delete(url, headers=headers)
        else:
            results.append({"name": name, "url": url, "method": method, "error": "Unsupported method"})
            continue

        results.append({
            "name": name,
            "url": url,
            "method": method,
            "status": resp.status_code,
            "ok": resp.ok
        })

    except Exception as e:
        results.append({
            "name": item.get("name", "Unnamed Test"),
            "url": "",
            "method": "",
            "error": str(e)
        })

# Write detailed JSON output
with open(out_file, "w") as f:
    json.dump(results, f, indent=2)

# Write a human-readable report
with open("python-report.txt", "w") as f:
    total = len(results)
    passed = sum(1 for r in results if r.get("ok"))
    failed = total - passed
    f.write("Python API Test Report\n")
    f.write("========================\n")
    f.write(f"Total requests: {total}\n")
    f.write(f"Passed: {passed}\n")
    f.write(f"Failed: {failed}\n\n")

    for r in results:
        if "error" in r:
            f.write(f"❌ {r['name']} [{r['method']}] -> ERROR: {r['error']}\n")
        else:
            status_icon = "✅" if r["ok"] else "⚠️"
            f.write(f"{status_icon} {r['name']} [{r['method']}] {r['url']} -> {r['status']}\n")


print(f"✅ Finished running {len(results)} requests.")
print(f"📂 JSON results saved to {out_file}")
print(f"📂 Summary report saved to python-report.txt")
