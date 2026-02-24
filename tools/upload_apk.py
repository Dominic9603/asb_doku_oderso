import urllib.request
import json

import os
TOKEN = os.environ.get("GITHUB_TOKEN", "")
RELEASE_ID = 289595964
APK_PATH = r"C:\Users\Administrator\rescue_doc\build\app\outputs\flutter-apk\app-release.apk"

# Existing assets löschen
req = urllib.request.Request(
    f"https://api.github.com/repos/Dominic9603/asb_doku_oderso/releases/{RELEASE_ID}/assets",
    headers={"Authorization": f"Bearer {TOKEN}", "Accept": "application/vnd.github+json"}
)
with urllib.request.urlopen(req) as resp:
    assets = json.loads(resp.read())

for asset in assets:
    print(f"Lösche Asset: {asset['name']} (id={asset['id']})")
    del_req = urllib.request.Request(
        f"https://api.github.com/repos/Dominic9603/asb_doku_oderso/releases/assets/{asset['id']}",
        method="DELETE",
        headers={"Authorization": f"Bearer {TOKEN}", "Accept": "application/vnd.github+json"}
    )
    try:
        urllib.request.urlopen(del_req)
        print("  gelöscht")
    except Exception as e:
        print(f"  Fehler: {e}")

# APK hochladen
print("Lade APK hoch...")
with open(APK_PATH, "rb") as f:
    apk_data = f.read()

print(f"APK-Größe: {len(apk_data)/1024/1024:.1f} MB")

upload_url = f"https://uploads.github.com/repos/Dominic9603/asb_doku_oderso/releases/{RELEASE_ID}/assets?name=rescue_doc.apk"
upload_req = urllib.request.Request(
    upload_url,
    data=apk_data,
    method="POST",
    headers={
        "Authorization": f"Bearer {TOKEN}",
        "Accept": "application/vnd.github+json",
        "Content-Type": "application/octet-stream",
        "X-GitHub-Api-Version": "2022-11-28",
    }
)
with urllib.request.urlopen(upload_req) as resp:
    result = json.loads(resp.read())
    print(f"Upload fertig: {result['browser_download_url']}")
