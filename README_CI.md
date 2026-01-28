# CI build (Flutter skeleton generation)

This repo is kept as a "source pack" (lib/, assets/, pubspec.yaml).
GitHub Actions generates a fresh Flutter project at build time to avoid Gradle/Android template drift.

If you want to run locally:
1) `flutter create -t app tibia_tools_flutter`
2) Copy this repo's `lib/`, `assets/`, `pubspec.yaml` into the created folder
3) Run `flutter pub get` and `flutter run`
