#!/usr/bin/env python3
"""Register the iOS bundle id with App Store Connect when it is missing.

Writes APP_RECORD=yes|no|unknown to GITHUB_ENV. The App Store Connect app
record itself cannot be created through this API.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt


BUNDLE_ID = os.environ.get("BUNDLE_ID", "es.verkvest.cindermote")
APP_NAME = os.environ.get("APP_NAME", "Cindermote")
API = "https://api.appstoreconnect.apple.com"


def _token() -> str:
    now = int(time.time())
    with open(os.environ["APPSTORE_API_KEY_PATH"], encoding="utf-8") as handle:
        private_key = handle.read()
    encoded = jwt.encode(
        {
            "iss": os.environ["APPSTORE_API_ISSUER_ID"],
            "iat": now,
            "exp": now + 19 * 60,
            "aud": "appstoreconnect-v1",
        },
        private_key,
        algorithm="ES256",
        headers={"kid": os.environ["APPSTORE_API_KEY_ID"], "typ": "JWT"},
    )
    if isinstance(encoded, bytes):
        return encoded.decode()
    return encoded


def _request(method: str, url: str, token: str, body=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode() or "{}"
            return resp.status, json.loads(raw)
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode()
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = raw
        return exc.code, parsed


def _write_env(flag: str) -> None:
    path = os.environ.get("GITHUB_ENV")
    if not path:
        print(f"APP_RECORD={flag}")
        return
    with open(path, "a", encoding="utf-8") as handle:
        handle.write(f"APP_RECORD={flag}\n")


def _duplicate(payload) -> bool:
    text = payload if isinstance(payload, str) else json.dumps(payload)
    return "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE" in text or "409" in text


def main() -> int:
    token = _token()
    query = urllib.parse.urlencode({"filter[identifier]": BUNDLE_ID, "limit": "5"})
    status, payload = _request("GET", f"{API}/v1/bundleIds?{query}", token)
    if status != 200:
        print(f"::error::App Store Connect bundle id lookup failed ({status}): {payload}")
        return 1
    if payload.get("data"):
        print(f"Bundle id {BUNDLE_ID} is already registered.")
    else:
        body = {
            "data": {
                "type": "bundleIds",
                "attributes": {
                    "identifier": BUNDLE_ID,
                    "name": APP_NAME,
                    "platform": "IOS",
                },
            }
        }
        status, payload = _request("POST", f"{API}/v1/bundleIds", token, body)
        if status == 201:
            print(f"Registered bundle id {BUNDLE_ID}.")
        elif status == 409 or _duplicate(payload):
            print(f"Bundle id {BUNDLE_ID} is already registered.")
        else:
            print(f"::error::Could not register bundle id {BUNDLE_ID} ({status}): {payload}")
            return 1

    query = urllib.parse.urlencode({"filter[bundleId]": BUNDLE_ID, "limit": "5"})
    status, payload = _request("GET", f"{API}/v1/apps?{query}", token)
    if status != 200:
        print(f"::warning::Could not check the App Store Connect app record ({status}): {payload}")
        _write_env("unknown")
        return 0
    if payload.get("data"):
        print(f"App Store Connect app record exists for {BUNDLE_ID}.")
        _write_env("yes")
    else:
        print(f"No App Store Connect app record for {BUNDLE_ID} yet.")
        _write_env("no")
    return 0


if __name__ == "__main__":
    sys.exit(main())
