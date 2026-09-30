#!/bin/sh
set -eu

usage() {
    echo "usage: scripts/validate.sh <git-url>" >&2
    echo "Checks that the repository is a Burn project and prints name=, kind= and description= lines." >&2
    exit 2
}

[ $# -eq 1 ] || usage
url="$1"

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

field() {
    sed -n "s/^$1 *= *\"\\(.*\\)\" *\$/\\1/p" "$2" | head -n 1
}

case "$url" in
    https://*) ;;
    *) fail "the git URL must start with https://, for example https://github.com/you/colors" ;;
esac
case "$url" in
    *[!A-Za-z0-9._~:/@+-]*) fail "the git URL has characters that do not belong in a URL" ;;
esac

path="${url#https://}"
path="${path%/}"
path="${path%.git}"
domain="$(printf '%s' "${path%%/*}" | tr '[:upper:]' '[:lower:]')"
rest="${path#*/}"
name="$domain/$rest"

if ! printf '%s' "$name" | grep -Eq '^[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]+/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'; then
    fail "packages are named <domain>/<owner>/<project>, so the URL must look like https://github.com/you/colors (got $url)"
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
if ! GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 "https://$name" "$work/repo" 2>/dev/null; then
    fail "https://$name cannot be cloned; the repository must be public"
fi
toml="$work/repo/burn.toml"
[ -f "$toml" ] || fail "https://$name has no burn.toml at the top, so it is not a Burn project (create one with burn init)"

real_name="$(field name "$toml")"
kind="$(field kind "$toml")"
[ -n "$kind" ] || kind=app
description="$(field description "$toml")"
main="$(field main "$toml")"
if [ -z "$main" ]; then
    if [ "$kind" = lib ]; then main=src/lib.bn; else main=src/main.bn; fi
fi

lower_real="$(printf '%s' "$real_name" | tr '[:upper:]' '[:lower:]')"
lower_name="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
[ -n "$real_name" ] || fail "burn.toml has no name in [package]"
[ "$lower_real" = "$lower_name" ] || fail "burn.toml names the package \"$real_name\", but it is hosted at $name; they must match so that ash install $name works"
case "$kind" in
    app | lib) ;;
    *) fail "burn.toml says kind = \"$kind\"; it must be \"app\" or \"lib\"" ;;
esac
[ -f "$work/repo/$main" ] || fail "the main file $main from burn.toml does not exist"

printf 'name=%s\n' "$real_name"
printf 'kind=%s\n' "$kind"
printf 'description=%s\n' "$description"
