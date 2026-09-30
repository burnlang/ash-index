#!/bin/sh
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failed=0

field() {
    sed -n "s/^$1 *= *\"\\(.*\\)\" *\$/\\1/p" "$2" | head -n 1
}

problem() {
    printf '%s: %s\n' "$1" "$2" >&2
    failed=1
}

files="$*"
if [ -z "$files" ]; then
    files="$(cd "$root" && find packages -name '*.toml' | sort)"
fi

for file in $files; do
    path="$root/$file"
    [ -f "$path" ] || continue
    expected="${file#packages/}"
    expected="${expected%.toml}"
    name="$(field name "$path")"
    kind="$(field kind "$path")"
    description="$(field description "$path")"
    if [ "$name" != "$expected" ]; then
        problem "$file" "name is \"$name\", but the file says $expected"
        continue
    fi
    case "$kind" in
        app | lib) ;;
        *) problem "$file" "kind must be \"app\" or \"lib\"" ;;
    esac
    [ -n "$description" ] || problem "$file" "description is missing"
    dir="$work/$(printf '%s' "$name" | tr '/' '_')"
    if ! GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 "https://$name" "$dir" 2>/dev/null; then
        problem "$file" "https://$name cannot be cloned"
        continue
    fi
    if [ ! -f "$dir/burn.toml" ]; then
        problem "$file" "https://$name has no burn.toml, so it is not a Burn project"
        continue
    fi
    real_name="$(field name "$dir/burn.toml")"
    real_kind="$(field kind "$dir/burn.toml")"
    [ -n "$real_kind" ] || real_kind=app
    [ "$real_name" = "$name" ] || problem "$file" "its burn.toml is named \"$real_name\""
    [ "$real_kind" = "$kind" ] || problem "$file" "its burn.toml says kind = \"$real_kind\""
    if [ "$failed" -eq 0 ]; then
        printf 'ok  %s\n' "$name"
    fi
done

exit "$failed"
