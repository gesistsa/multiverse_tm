#!/bin/sh

STAGED_FILES=$(git diff --cached --name-only)

if echo "$STAGED_FILES" | grep -q "renv.lock"; then
  if ! make rmd; then
    echo "Error: 'make rmd' failed. Aborting commit."
    exit 1 # Exit with a non-zero status to abort the commit
  fi
fi

git add readme.md
exit 0
