#!/usr/bin/env bash
# One-time setup of the GitHub Actions secrets used by
# .github/workflows/release-please.yml. Reads credentials from 1Password,
# creates a dedicated read-only deploy key on the match repo, and pushes
# everything into this repository's secrets. Safe to re-run: secrets are
# overwritten and a deploy key with the same title is replaced.
#
# Requires: op (signed in), gh (authenticated), jq, ssh-keygen, openssl.
set -euo pipefail

REPO="${REPO:-cedricziel/trueapp}"
MATCH_REPO="${MATCH_REPO:-cedricziel/certificates}"
MATCH_GIT_URL="git@github.com:${MATCH_REPO}.git"
DEPLOY_KEY_TITLE="trueapp-fastlane-match-ci"

# 1Password locations (see fastlane/.env.default).
OP_ASC_ITEM="${OP_ASC_ITEM:-AppStore Connect: fastlane-ci}"
OP_ASC_KEY_ID_FIELD="${OP_ASC_KEY_ID_FIELD:-Benutzername}"
OP_ASC_ISSUER_FIELD="${OP_ASC_ISSUER_FIELD:-Issue ID}"
OP_ASC_P8_FILE="${OP_ASC_P8_FILE:-}"   # file attachment name; auto-detected if empty
OP_MATCH_ITEM="${OP_MATCH_ITEM:-fastlane-ci: match}"

for tool in op gh jq ssh-keygen openssl; do
  command -v "$tool" >/dev/null || { echo "missing required tool: $tool" >&2; exit 1; }
done

set_secret() { # name value
  printf '%s' "$2" | gh secret set "$1" --repo "$REPO"
  echo "  set $1"
}

echo "Reading App Store Connect key from 1Password item '$OP_ASC_ITEM'..."
asc_item="$(op item get "$OP_ASC_ITEM" --format json --reveal)"
field() { jq -r --arg l "$1" '.fields[] | select(.label == $l) | .value' <<<"$asc_item"; }
ASC_KEY_ID="$(field "$OP_ASC_KEY_ID_FIELD")"
ASC_ISSUER_ID="$(field "$OP_ASC_ISSUER_FIELD")"
[[ -n "$OP_ASC_P8_FILE" ]] || OP_ASC_P8_FILE="$(jq -r '.files[0].name' <<<"$asc_item")"
# Secret references must use ids: item titles may contain characters (':')
# that op://vault/item/file rejects.
ASC_KEY_CONTENT="$(op read "op://$(jq -r '.vault.id' <<<"$asc_item")/$(jq -r '.id' <<<"$asc_item")/$OP_ASC_P8_FILE")"
[[ "$ASC_KEY_CONTENT" == *"BEGIN PRIVATE KEY"* ]] || { echo "downloaded .p8 does not look like a private key" >&2; exit 1; }

echo "Reading match password from 1Password item '$OP_MATCH_ITEM'..."
MATCH_PASSWORD="$(op item get "$OP_MATCH_ITEM" --fields password --reveal)"

echo "Creating deploy key '$DEPLOY_KEY_TITLE' on $MATCH_REPO..."
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
ssh-keygen -q -t ed25519 -N "" -C "$DEPLOY_KEY_TITLE" -f "$tmp/key"
# Replace a previous key with the same title so re-runs stay idempotent.
gh api "repos/$MATCH_REPO/keys" --jq ".[] | select(.title == \"$DEPLOY_KEY_TITLE\") | .id" \
  | while read -r id; do gh api -X DELETE "repos/$MATCH_REPO/keys/$id"; done
gh api "repos/$MATCH_REPO/keys" -f title="$DEPLOY_KEY_TITLE" -f key="$(cat "$tmp/key.pub")" -F read_only=true >/dev/null

echo "Setting secrets on $REPO..."
set_secret ASC_KEY_ID "$ASC_KEY_ID"
set_secret ASC_ISSUER_ID "$ASC_ISSUER_ID"
set_secret ASC_KEY_CONTENT "$ASC_KEY_CONTENT"
set_secret MATCH_GIT_URL "$MATCH_GIT_URL"
set_secret MATCH_PASSWORD "$MATCH_PASSWORD"
set_secret MATCH_KEYCHAIN_PASSWORD "$(openssl rand -base64 32)"
set_secret MATCH_DEPLOY_KEY "$(cat "$tmp/key")"

cat <<MSG

Done. Two manual steps remain:

1. RELEASE_PLEASE_TOKEN: a fine-grained PAT with Contents + Pull requests
   (read/write) on $REPO, so the release PR triggers CI:
     gh secret set RELEASE_PLEASE_TOKEN --repo $REPO

2. Create the App Store provisioning profile in the match repo (needs the
   App ID $(grep -o 'com\.cedricziel\.[a-z]*' fastlane/Appfile | head -1) to exist with its capabilities enabled):
     cp fastlane/.env.default fastlane/.env   # fill in ASC_* and MATCH_PASSWORD
     bundle exec fastlane bootstrap_signing
MSG
