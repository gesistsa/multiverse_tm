#!/bin/bash

STAGED_FILES=$(git diff --cached --name-only)
NEED_RERENDERING=false

for FILE in $STAGED_FILES
do
    if [[ "$FILE" == "renv.lock" || "$FILE" == "readme.rmd" ]]; then
	$NEED_RERENDERING=true
	break
    fi
done

if $NEED_RERENDERING; then
    if ! make rmd; then
	echo "Error: 'make rmd' failed. Aborting commit."
	exit 1 # Exit with a non-zero status to abort the commit
    fi
    git add readme.md
    exit 0
else
    exit 0
fi
