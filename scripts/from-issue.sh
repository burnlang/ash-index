#!/bin/sh
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
body="${ISSUE_BODY:-}"
author="${ISSUE_AUTHOR:-}"
association="${ISSUE_ASSOCIATION:-}"
out="${1:?usage: scripts/from-issue.sh <result-file>}"
: >"$out"

section() {
    printf '%s\n' "$body" | tr -d '\r' | awk -v h="### $1" '
        $0 == h { on = 1; next }
        on && /^### / { exit }
        on && NF { print; exit }
    '
}

reject() {
    printf 'ok=false\n' >>"$out"
    {
        printf 'errors<<ASH_EOF\n'
        printf '%s\n' "$*"
        printf 'ASH_EOF\n'
    } >>"$out"
    exit 0
}

clean() {
    printf '%s' "$1" | tr -d '\n' | sed 's/_No response_//; s/\\/\\\\/g; s/"/\\"/g; s/^ *//; s/ *$//' | cut -c1-200
}

url="$(section "Git URL")"
[ -n "$url" ] || reject "The issue has no git URL. Fill in the \"Git URL\" field of the form."

if ! result="$(sh "$root/scripts/validate.sh" "$url" 2>&1)"; then
    reject "$(printf '%s' "$result" | sed 's/^error: //')"
fi
name="$(printf '%s\n' "$result" | sed -n 's/^name=//p')"
kind="$(printf '%s\n' "$result" | sed -n 's/^kind=//p')"
description="$(clean "$(section "Description")")"
[ -n "$description" ] || description="$(clean "$(printf '%s\n' "$result" | sed -n 's/^description=//p')")"
[ -n "$description" ] || reject "There is no description. Add one to the form, or set description = \"...\" in the [package] section of burn.toml."

keywords=""
raw="$(section "Keywords" | sed 's/_No response_//')"
old_ifs="$IFS"
IFS=','
for k in $raw; do
    k="$(printf '%s' "$k" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9 -' | sed 's/^ *//; s/ *$//')"
    [ -n "$k" ] || continue
    if [ -n "$keywords" ]; then keywords="$keywords, "; fi
    keywords="$keywords\"$k\""
done
IFS="$old_ifs"

file="packages/$name.toml"
action=add
if [ -f "$root/$file" ]; then
    owner="$(printf '%s' "$name" | cut -d/ -f2)"
    domain="$(printf '%s' "$name" | cut -d/ -f1)"
    case "$association" in
        OWNER | MEMBER | COLLABORATOR) ;;
        *)
            if [ "$domain" != github.com ] || [ "$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$author" | tr '[:upper:]' '[:lower:]')" ]; then
                reject "$name is already listed. Only its owner ($owner) or a maintainer of the index can change the entry."
            fi
            ;;
    esac
    action=update
fi

mkdir -p "$(dirname "$root/$file")"
{
    printf 'name = "%s"\n' "$name"
    printf 'description = "%s"\n' "$description"
    printf 'kind = "%s"\n' "$kind"
    printf 'keywords = [%s]\n' "$keywords"
} >"$root/$file"

{
    printf 'ok=true\n'
    printf 'name=%s\n' "$name"
    printf 'kind=%s\n' "$kind"
    printf 'file=%s\n' "$file"
    printf 'action=%s\n' "$action"
    printf 'branch=add/%s\n' "$(printf '%s' "$name" | tr '/.' '--' | tr '[:upper:]' '[:lower:]')"
} >>"$out"
