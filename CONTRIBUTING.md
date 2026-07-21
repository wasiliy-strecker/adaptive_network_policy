# Contributing

Issues and focused pull requests are welcome. Please discuss broad API or
platform-semantic changes in an issue before implementation.

## Setup

Install a Flutter SDK compatible with the constraints in `pubspec.yaml`, then:

```sh
flutter pub get
(cd example && flutter pub get)
```

## Generated channels

Edit `pigeons/network_conditions_api.dart`, never generated channel files, then:

```sh
dart run pigeon --input pigeons/network_conditions_api.dart
dart format lib/src/platform/generated/network_conditions_api.g.dart
dart run tool/normalize_generated.dart
```

Commit the schema input and all Dart, Kotlin, and Swift outputs together.

## Required checks

```sh
dart format --output=none --set-exit-if-changed lib test tool pigeons example/lib example/test example/integration_test
flutter analyze
flutter test
(cd example && flutter test)
(cd example && flutter build web)
```

Native changes should additionally build the affected example target and add a
focused native mapper test or a documented integration verification.

## Pull requests

Keep changes scoped, explain platform differences explicitly, and include:

- the behavior and motivation;
- tests or a manual verification command;
- screenshots for visible example changes;
- changelog updates for user-facing behavior.

Do not include credentials, private network details, generated caches, or build
artifacts.
