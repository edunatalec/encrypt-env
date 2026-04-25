#!/bin/bash
set -e

TOTAL_STEPS=9
STEP=0
step() {
  STEP=$((STEP + 1))
  echo
  echo "[$STEP/$TOTAL_STEPS] $1"
}

step "Installing dependencies"
dart pub get

step "Running tests"
dart test

step "Validating package (dry-run)"
dart pub publish --dry-run

step "Running pana (pub.dev score)"
PANA_OUT=$(pana --no-warning . | tee /dev/stderr)
if ! grep -q "Points: 160/160" <<<"$PANA_OUT"; then
  echo
  echo "❌ Aborting release: pana score is below 160/160. Fix the issues above."
  exit 1
fi

step "Generating version"
dart run build_runner build --delete-conflicting-outputs

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')

step "Committing version update"
if ! git diff --quiet lib/src/version.dart 2>/dev/null; then
  git add lib/src/version.dart
  git commit -m "chore: update version to $VERSION"
else
  echo "No changes to lib/src/version.dart, skipping commit"
fi

step "Creating tag v$VERSION"
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Tag v$VERSION already exists, skipping"
else
  git tag "v$VERSION"
fi

step "Pushing"
git push origin master
git push --tags

step "Publishing to pub.dev"
dart pub publish --force

echo
echo "🎉 Done! Published v$VERSION"
