#!/usr/bin/env bash
# Hard-resets the CherryTreePentestingNotes clone to origin. Run on every
# i3 (re)start so the notes are always fresh without waiting on `notes` to
# fetch first.
set -uo pipefail

NOTES_DIR="$HOME/.notes-repo"
NOTES_REPO="https://github.com/MarcussanMG/CherryTreePentestingNotes.git"

if [[ ! -d "$NOTES_DIR/.git" ]]; then
    git clone --quiet "$NOTES_REPO" "$NOTES_DIR" 2>/dev/null || exit 0
fi

(
    cd "$NOTES_DIR" || exit 1
    git fetch origin >/dev/null 2>&1
    BRANCH="$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')"
    git reset --hard "origin/${BRANCH:-main}" >/dev/null 2>&1
    git clean -fd >/dev/null 2>&1
)
