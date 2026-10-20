from asc import api

BUNDLE_ID = "com.tokyonasu.typo"
bundles = api("GET", f"/bundleIds?filter[identifier]={BUNDLE_ID}")["data"]
if not bundles:
    bundle = api("POST", "/bundleIds", {"data": {"type": "bundleIds", "attributes": {
        "identifier": BUNDLE_ID, "name": "TYPO", "platform": "IOS"
    }}})["data"]
else:
    bundle = bundles[0]
print(f"Bundle ready: {bundle['attributes']['identifier']} ({bundle['id']})")
apps = api("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")["data"]
if apps:
    print(f"App ready: {apps[0]['attributes']['name']} ({apps[0]['id']})")
else:
    print("App record needed in App Store Connect: TYPO 文字の建築家 / Japanese / SKU typo-ios")
certificates = api("GET", "/certificates?filter[certificateType]=DISTRIBUTION,IOS_DISTRIBUTION&limit=200")["data"]
for certificate in certificates:
    attributes = certificate["attributes"]
    print(f"Distribution certificate: {certificate['id']} expires {attributes.get('expirationDate')}")
