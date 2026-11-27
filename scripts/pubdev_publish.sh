#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/pubdev_publish.sh dry-run
  scripts/pubdev_publish.sh publish

Modes:
  dry-run  Run release validations and `flutter pub publish --dry-run`.
  publish  Run validations, require release-safe git state, then publish.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

mode="${1:-dry-run}"
if [[ "$mode" != "dry-run" && "$mode" != "publish" ]]; then
  usage
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

for command_name in git flutter dart awk; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "ERROR: missing required command: $command_name"
    exit 1
  fi
done

if [[ ! -f pubspec.yaml ]]; then
  echo "ERROR: pubspec.yaml not found in $repo_root"
  exit 1
fi

version="$(awk '/^version:/{print $2; exit}' pubspec.yaml)"
if [[ -z "$version" ]]; then
  echo "ERROR: unable to read version from pubspec.yaml"
  exit 1
fi

require_clean_tree() {
  local status
  # Explicit, because status.showUntrackedFiles=no hides untracked files.
  status="$(git status --porcelain --untracked-files=normal)"
  if [[ -n "$status" ]]; then
    echo "ERROR: working tree must be clean before publish."
    echo "$status"
    exit 1
  fi
}

require_release_state() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$branch" != "main" ]]; then
    echo "ERROR: publish mode requires main branch (current: $branch)."
    exit 1
  fi

  local tag
  tag="v$version"
  if ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    echo "ERROR: expected tag $tag for version $version."
    exit 1
  fi

  local head_commit
  local tag_commit
  head_commit="$(git rev-parse HEAD)"
  tag_commit="$(git rev-list -n 1 "$tag")"
  if [[ "$head_commit" != "$tag_commit" ]]; then
    echo "ERROR: tag $tag does not point to HEAD."
    echo "HEAD: $head_commit"
    echo "$tag: $tag_commit"
    exit 1
  fi

  local remote_commit
  # FETCH_HEAD and the full ref name: the fetch updates origin/main only when
  # the fetch refspec of the clone covers main, and "main" also matches a tag.
  if ! git fetch --quiet origin refs/heads/main; then
    echo "ERROR: unable to fetch origin/main."
    exit 1
  fi
  remote_commit="$(git rev-parse FETCH_HEAD)"
  if [[ "$head_commit" != "$remote_commit" ]]; then
    echo "ERROR: HEAD does not match origin/main."
    echo "HEAD: $head_commit"
    echo "origin/main: $remote_commit"
    exit 1
  fi
}

run_validations() {
  echo "==> flutter pub get"
  flutter pub get

  echo "==> dart format --set-exit-if-changed ."
  dart format --set-exit-if-changed .

  echo "==> flutter analyze"
  flutter analyze

  echo "==> flutter test"
  flutter test

  echo "==> flutter pub publish --dry-run"
  flutter pub publish --dry-run
}

if [[ "$mode" == "publish" ]]; then
  require_clean_tree
  require_release_state
fi

run_validations

if [[ "$mode" == "dry-run" ]]; then
  echo "Dry-run validation completed for bloc_plus $version."
  exit 0
fi

credentials_file="${PUB_CACHE:-$HOME/.pub-cache}/credentials.json"
if [[ ! -f "$credentials_file" ]]; then
  echo "WARNING: pub credentials not found at $credentials_file."
  echo "Publish may fail if your account is not authenticated."
fi

read -r -p "Publish bloc_plus $version to pub.dev now? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Publish aborted."
  exit 0
fi

echo "==> flutter pub publish --force"
flutter pub publish --force

echo "Publish command completed for bloc_plus $version."
