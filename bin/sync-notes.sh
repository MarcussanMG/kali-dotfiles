#!/usr/bin/env bash
# Refreshes the PentestingNotes clone from origin on every i3 (re)start so the
# notes are fresh without waiting on `notes` to fetch. If the clone has local
# changes (uncommitted or untracked), the refresh is skipped so nothing is lost.
set -uo pipefail

NOTES_DIR="$HOME/.notes-repo"
NOTES_REPO="https://github.com/MarcussanMG/PentestingNotes.git"

if [[ ! -d "$NOTES_DIR/.git" ]]; then
    git clone --quiet "$NOTES_REPO" "$NOTES_DIR" 2>/dev/null || exit 0
fi

(
    cd "$NOTES_DIR" || exit 1
    # Never clobber local work: if the clone has uncommitted or untracked
    # changes, skip the refresh entirely and leave everything as-is.
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        echo "sync-notes: local changes in $NOTES_DIR -- skipping refresh" >&2
        exit 0
    fi
    git fetch origin >/dev/null 2>&1
    BRANCH="$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')"
    git reset --hard "origin/${BRANCH:-main}" >/dev/null 2>&1
    git clean -fd >/dev/null 2>&1
)
