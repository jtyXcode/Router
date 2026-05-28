#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  POD_SOURCE_GIT_URL=https://github.com/your-org/IndustrialRouter.git \
  POD_HOMEPAGE_URL=https://github.com/your-org/IndustrialRouter \
  Scripts/publish_cocoapods.sh --lint

  POD_SOURCE_GIT_URL=https://github.com/your-org/IndustrialRouter.git \
  POD_HOMEPAGE_URL=https://github.com/your-org/IndustrialRouter \
  Scripts/publish_cocoapods.sh --push

Required environment:
  POD_SOURCE_GIT_URL  Public git repository URL used by s.source
  POD_HOMEPAGE_URL    Public homepage URL used by s.homepage

Modes:
  --lint              Validate the generated podspec only
  --push              Validate and push to CocoaPods trunk

Before --push:
  1. Commit the library source.
  2. Create and push a git tag matching s.version in IndustrialRouter.podspec.
  3. Login to CocoaPods trunk with: pod trunk register <email> <name>
USAGE
}

mode="${1:-}"
case "$mode" in
  --lint|--push)
    ;;
  -h|--help|"")
    usage
    exit 0
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    usage
    exit 1
    ;;
esac

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods is not installed. Install it before publishing." >&2
  exit 1
fi

source_git_url="${POD_SOURCE_GIT_URL:-}"
homepage_url="${POD_HOMEPAGE_URL:-}"

if [[ -z "$source_git_url" || -z "$homepage_url" ]]; then
  echo "POD_SOURCE_GIT_URL and POD_HOMEPAGE_URL are required." >&2
  usage
  exit 1
fi

if [[ "$source_git_url" == *"example.com"* || "$homepage_url" == *"example.com"* ]]; then
  echo "Refusing to publish placeholder URLs." >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
spec_path="$repo_root/IndustrialRouter.podspec"
generated_spec="$repo_root/IndustrialRouter.generated.podspec"

cleanup() {
  rm -f "$generated_spec"
}
trap cleanup EXIT

ruby - "$spec_path" "$generated_spec" "$source_git_url" "$homepage_url" <<'RUBY'
spec_path, generated_spec, source_git_url, homepage_url = ARGV
content = File.read(spec_path)
content = content.gsub(%r{s\.homepage\s*=\s*'[^']+'}, "s.homepage = '#{homepage_url}'")
content = content.gsub(%r{s\.source\s*=\s*\{\s*:git\s*=>\s*'[^']+',\s*:tag\s*=>\s*s\.version\.to_s\s*\}}, "s.source = { :git => '#{source_git_url}', :tag => s.version.to_s }")
File.write(generated_spec, content)
RUBY

echo "Generated $generated_spec"
pod spec lint "$generated_spec" --allow-warnings --skip-import-validation

if [[ "$mode" == "--push" ]]; then
  pod trunk push "$generated_spec" --allow-warnings --skip-import-validation
fi
