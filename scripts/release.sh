#!/bin/bash
set -e

echo "=== Validating package ==="
dart pub get
dart test
dart pub publish --dry-run

echo ""
echo "=== Building version ==="
dart pub run build_runner build --delete-conflicting-outputs

VERSION=$(grep "version:" pubspec.yaml | head -1 | awk '{print $2}')
echo "Version: $VERSION"

if ! git diff --quiet lib/src/version.dart 2>/dev/null; then
  echo ""
  echo "=== Committing version update ==="
  git add lib/src/version.dart
  git commit -m "chore: update version to $VERSION"
fi

echo ""
echo "=== Creating tag v$VERSION ==="
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Tag v$VERSION already exists, skipping"
else
  git tag "v$VERSION"
fi

echo ""
echo "=== Pushing ==="
git push origin master
git push --tags

echo ""
echo "=== Publishing to pub.dev ==="
dart pub publish --force

echo ""
echo "=== Done! Published v$VERSION ==="
