#!/usr/bin/env bash

set -eo pipefail

# shellcheck wrapper - to be run locally and in PR workflow:
# extract each bash run step from action.yml and all workflows and run them
# through shellcheck for safety. requires yq and shellcheck in $PATH

FAILS=0
IFS="
"

# Create an array of YAML files (recent bash and zsh supported here)
if [[ -n "$BASH_VERSION" ]]; then
  YAMLFILES=()
  while read -r YAMLFILE; do
      YAMLFILES+=("$YAMLFILE")
  done < <(find action.yml .github/workflows -type f -name \*yml -print -o -name \*yaml -print)
else
  if [[ -n "$ZSH_VERSION" ]]; then
    YAMLFILES=("${(@f)$(find action.yml .github/workflows -type f -name \*yml -print -o -name \*yaml -print)}")
  else
    echo "This script requires a recent bash or zsh shell"
    exit 1
  fi
fi


for YAMLFILE in "${YAMLFILES[@]}"; do

  echo "Checking $YAMLFILE"

  # find bash run steps in workflow jobs.*.steps[] and action runs.steps[] 
  for n in $(yq '.. | select(has("steps")) | .steps[] | select(.shell == "bash") | .name' < "$YAMLFILE")
  do
    # do not error out while in this inner loop: we want to find all problems
    set +e

    # prepare a safe location to create a temporary script for evaluation
    tmpscript=$(mktemp)

    # extract the *.steps[].run elements into the temp file 
    yq ".. | select(has(\"steps\")) | .steps[] | select(.name == \"$n\") | .run" < "$YAMLFILE" > "$tmpscript"

    # run the checks
    shellcheck --shell bash -S warning "$tmpscript"
    if [ $? -ne 0 ]; then
      echo ""
      echo "The script in $YAMLFILE step \"$n\" did not pass shellcheck"
      echo ""
      ((FAILS++))
    fi
    rm "$tmpscript"
    set -e
  done
done

if [[ $FAILS -ne 0 ]]; then
  echo "$FAILS error(s) or warning(s) detected, please fix and run bin/shellcheck.sh again"
  exit 1
fi