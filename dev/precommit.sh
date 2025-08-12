#!/bin/bash

STAGED_FILES=$(git diff --cached --name-only --diff-filter=AM)
QUARTO_AVAILBLE=$(command -v quarto)
AIR_AVAILABLE=$(command -v air)
NEED_RERENDERING=false

CHANGED_R_FILES=$(echo "$STAGED_FILES" | grep -E '\.R$')

if [ -n "$CHANGED_R_FILES" ]; then
    if [ -n $AIR_AVAILABLE ]; then
	air format $CHANGED_R_FILES
	git add $CHANGED_R_FILES
    fi
fi

for FILE in $STAGED_FILES
do
    if [[ "$FILE" == "renv.lock" || "$FILE" == "readme.rmd" ]]; then
	NEED_RERENDERING=true
	break
    fi
done

if $NEED_RERENDERING; then
    if [ -n $QUARTO_AVAILABLE ]; then
	if ! make rmd; then
	    echo "Error: 'make rmd' failed. Aborting commit."
	    exit 1
	fi
	git add readme.md
    else
	echo "Quarto not available."
    fi
    exit 0
else
    exit 0
fi
