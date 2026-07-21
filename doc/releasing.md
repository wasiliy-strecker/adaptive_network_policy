# Release process

The package remains private to pub tooling while `publish_to: none` is present.

## Checklist

1. Choose the semantic version and move the changelog section from Unreleased
   to the release date.
2. Regenerate Pigeon outputs and verify that the working tree stays unchanged.
3. Run formatter, analyzer, Dart tests, example tests, Android unit tests, and
   Android/iOS/macOS example builds.
4. Run `dart pub publish --dry-run` and resolve every package validation issue.
5. Confirm repository topics, issue tracker, license, screenshots, and supported
   platform statements.
6. Remove `publish_to: none` only when publishing to pub.dev is intended.
7. Commit the release, create an annotated `vX.Y.Z` tag, and publish GitHub
   release notes from the changelog.
8. Publish to pub.dev from the immutable tagged revision, then restore normal
   development on the next version if needed.

Never publish from a dirty working tree or include local SDK paths, credentials,
build outputs, or example signing material.
