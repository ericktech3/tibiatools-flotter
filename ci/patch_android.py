#!/usr/bin/env python3
import sys
import re
from pathlib import Path

DESUGAR_LIB = "com.android.tools:desugar_jdk_libs:2.0.4"

def ensure_permission(manifest: str, perm: str) -> str:
    line = f'    <uses-permission android:name="{perm}" />'
    if perm in manifest:
        return manifest
    idx = manifest.find('>')  # end of first tag line
    if idx == -1:
        return manifest
    insert_at = idx + 1
    return manifest[:insert_at] + "\n" + line + manifest[insert_at:]

def insert_service(manifest: str, service_block: str) -> str:
    if 'com.pravera.flutter_foreground_task.service.ForegroundService' in manifest:
        return manifest
    close_tag = '</application>'
    pos = manifest.rfind(close_tag)
    if pos == -1:
        return manifest
    return manifest[:pos] + service_block + "\n  " + manifest[pos:]

def patch_manifest(app_dir: Path) -> None:
    manifest_path = app_dir / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest_path.exists():
        print(f"AndroidManifest.xml not found at {manifest_path}", file=sys.stderr)
        return
    manifest = manifest_path.read_text(encoding="utf-8")

    if 'xmlns:android="http://schemas.android.com/apk/res/android"' not in manifest:
        manifest = manifest.replace(
            "<manifest",
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android"',
            1,
        )

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

def _patch_groovy_build_gradle(text: str) -> str:
    # Ensure compileOptions has coreLibraryDesugaringEnabled true
    if "coreLibraryDesugaringEnabled" not in text:
        # Try to insert into existing compileOptions { ... }
        m = re.search(r"compileOptions\s*\{", text)
        if m:
            insert_at = m.end()
            text = text[:insert_at] + "\n        coreLibraryDesugaringEnabled true" + text[insert_at:]
        else:
            # Insert a compileOptions block inside android { ... } near the top
            m2 = re.search(r"android\s*\{", text)
            if m2:
                insert_at = m2.end()
                block = """\n    compileOptions {\n        coreLibraryDesugaringEnabled true\n        sourceCompatibility JavaVersion.VERSION_1_8\n        targetCompatibility JavaVersion.VERSION_1_8\n    }\n"""
                text = text[:insert_at] + block + text[insert_at:]

    # Ensure dependency exists
    dep_line = f'coreLibraryDesugaring \'{DESUGAR_LIB}\''
    if dep_line not in text:
        m = re.search(r"dependencies\s*\{", text)
        if m:
            insert_at = m.end()
            text = text[:insert_at] + f"\n    {dep_line}" + text[insert_at:]
    return text

def _patch_kts_build_gradle(text: str) -> str:
    if "isCoreLibraryDesugaringEnabled" not in text:
        m = re.search(r"compileOptions\s*\{", text)
        if m:
            insert_at = m.end()
            text = text[:insert_at] + "\n        isCoreLibraryDesugaringEnabled = true" + text[insert_at:]
        else:
            m2 = re.search(r"android\s*\{", text)
            if m2:
                insert_at = m2.end()
                block = """\n    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n        sourceCompatibility = JavaVersion.VERSION_1_8\n        targetCompatibility = JavaVersion.VERSION_1_8\n    }\n"""
                text = text[:insert_at] + block + text[insert_at:]

    dep_line = f'coreLibraryDesugaring("{DESUGAR_LIB}")'
    if dep_line not in text:
        m = re.search(r"dependencies\s*\{", text)
        if m:
            insert_at = m.end()
            text = text[:insert_at] + f"\n    {dep_line}" + text[insert_at:]
    return text

def patch_gradle(app_dir: Path) -> None:
    # Flutter templates vary: build.gradle or build.gradle.kts
    groovy = app_dir / "android" / "app" / "build.gradle"
    kts = app_dir / "android" / "app" / "build.gradle.kts"
    target = None
    is_kts = False
    if groovy.exists():
        target = groovy
    elif kts.exists():
        target = kts
        is_kts = True
    else:
        print("No android/app/build.gradle(.kts) found; skipping Gradle patch.")
        return

    text = target.read_text(encoding="utf-8")
    new_text = _patch_kts_build_gradle(text) if is_kts else _patch_groovy_build_gradle(text)

    if new_text != text:
        target.write_text(new_text, encoding="utf-8")
        print(f"Patched {target.name} (core library desugaring)")
    else:
        print(f"{target.name} already OK")

def main():
    if len(sys.argv) != 2:
        print("Usage: patch_android.py <flutter_app_dir>", file=sys.stderr)
        sys.exit(2)
    app_dir = Path(sys.argv[1])
    patch_manifest(app_dir)
    patch_gradle(app_dir)

if __name__ == "__main__":
    main()
