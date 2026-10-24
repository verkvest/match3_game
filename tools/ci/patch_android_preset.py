#!/usr/bin/env python3
"""Fill Android versionCode and, when present, the release keystore.

Godot's export preset has one password field. It is used as both the keystore
password and the key password, so those two secrets must match.
"""

import os
import pathlib
import sys


def _cfg_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def main() -> int:
    path = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "export_presets.cfg")
    text = path.read_text(encoding="utf-8")
    build = os.environ.get("ANDROID_VERSION_CODE", "").strip()
    if build:
        text = text.replace("version/code=1", f"version/code={int(build)}")
    keystore = os.environ.get("ANDROID_KEYSTORE_PATH", "").strip()
    alias = os.environ.get("ANDROID_KEY_ALIAS", "").strip()
    password = os.environ.get("ANDROID_KEYSTORE_PASSWORD", "")
    key_password = os.environ.get("ANDROID_KEY_PASSWORD", "")
    if keystore:
        if key_password and key_password != password:
            print(
                "::error::ANDROID_KEY_PASSWORD differs from ANDROID_KEYSTORE_PASSWORD. "
                "Godot signs with a single password, so set them to the same value.",
                file=sys.stderr,
            )
            return 1
        text = text.replace('keystore/release=""', f'keystore/release="{_cfg_escape(keystore)}"')
        text = text.replace('keystore/release_user=""', f'keystore/release_user="{_cfg_escape(alias)}"')
        text = text.replace(
            'keystore/release_password=""',
            f'keystore/release_password="{_cfg_escape(password)}"',
        )
    path.write_text(text, encoding="utf-8")
    print(f"patched {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
