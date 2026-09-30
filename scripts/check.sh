#!/bin/sh
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
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
    [ -n "$description" ] || problem "$file" "description is missing"
    if ! out="$(sh "$root/scripts/validate.sh" "https://$name" 2>&1)"; then
        problem "$file" "$(printf '%s' "$out" | sed 's/^error: //')"
        continue
    fi
    real_kind="$(printf '%s\n' "$out" | sed -n 's/^kind=//p')"
    if [ "$real_kind" != "$kind" ]; then
        problem "$file" "kind is \"$kind\", but its burn.toml says \"$real_kind\""
        continue
    fi
    printf 'ok  %s\n' "$name"
done

exit "$failed"
