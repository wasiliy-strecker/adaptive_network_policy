.PHONY: get generate format format-check analyze test web check

get:
	flutter pub get
	cd example && flutter pub get

generate:
	dart run pigeon --input pigeons/network_conditions_api.dart
	dart format lib/src/platform/generated/network_conditions_api.g.dart
	dart run tool/normalize_generated.dart

format:
	dart format lib test tool pigeons example/lib example/test example/integration_test

format-check:
	dart format --output=none --set-exit-if-changed lib test tool pigeons example/lib example/test example/integration_test

analyze:
	flutter analyze

test:
	flutter test
	cd example && flutter test

web:
	cd example && flutter build web

check: format-check analyze test web
