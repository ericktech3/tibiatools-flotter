#!/usr/bin/env python3
import sys
from pathlib import Path

def ensure_permission(manifest: str, perm: str) -> str:
    line = f'    <uses-permission android:name="{perm}" />'
    if perm in manifest:
        return manifest
    # Insert after opening <manifest ...> line
    idx = manifest.find('>')  # end of first tag line
    if idx == -1:
        return manifest
    insert_at = idx + 1
    return manifest[:insert_at] + "\n" + line + manifest[insert_at:]

def insert_service(manifest: str, service_block: str) -> str:
    if 'com.pravera.flutter_foreground_task.service.ForegroundService' in manifest:
        return manifest
    # Insert before </application>
    close_tag = '</application>'
    pos = manifest.rfind(close_tag)
    if pos == -1:
        return manifest
    return manifest[:pos] + service_block + "\n  " + manifest[pos:]

def main():
    if len(sys.argv) != 2:
        print("Usage: patch_android.py <flutter_app_dir>", file=sys.stderr)
        sys.exit(2)
    app_dir = Path(sys.argv[1])
    manifest_path = app_dir / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest_path.exists():
        print(f"AndroidManifest.xml not found at {manifest_path}", file=sys.stderr)
        sys.exit(1)

    manifest = manifest_path.read_text(encoding="utf-8")

    # Ensure namespace for android is present (template should have it)
    if 'xmlns:android="http://schemas.android.com/apk/res/android"' not in manifest:
        # crude insert into <manifest ...>
        manifest = manifest.replace("<manifest", '<manifest xmlns:android="http://schemas.android.com/apk/res/android"', 1)

    perms = [
        "android.permission.INTERNET",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_DATA_SYNC",
        "android.permission.WAKE_LOCK",
    ]
    for p in perms:
        manifest = ensure_permission(manifest, p)

    service_block = '''
    <service
        android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
        android:exported="false"
        android:foregroundServiceType="dataSync" />'''
    manifest = insert_service(manifest, service_block)

    manifest_path.write_text(manifest, encoding="utf-8")
    print("Patched AndroidManifest.xml")

if __name__ == "__main__":
    main()
