#!/bin/bash

# Run in bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'
NEWLINE=$'\n'
TAB=$'\t'

# Look for a .dkrtool file in this and partent directories, and populate DKRTOOL_FILES
# in order of furthest to closest

DKRTOOL_FILES=""
HOME_INCLUDED=false
TEST_DIR=${PWD}
while [[ -d ${TEST_DIR} && ${TEST_DIR} != "/" ]]; do
  if [[ -f ${TEST_DIR}/.dkrtool ]]; then
    DKRTOOL_FILES="${TEST_DIR}/.dkrtool${NEWLINE}${DKRTOOL_FILES}"
    if [[ ${TEST_DIR}/.dkrtool -ef ${HOME}/.dkrtool ]]; then
      HOME_INCLUDED=true
    fi
  fi
  TEST_DIR=$( dirname ${TEST_DIR} )
done

if [[ -f ${HOME}/.dkrtool && ${HOME_INCLUDED} == "false" ]]; then
  DKRTOOL_FILES="${HOME}/.dkrtool${NEWLINE}${DKRTOOL_FILES}"
fi

if [[ $DKRTOOL_FILES == "" ]]; then
  echo "Could not find .dkrtool file in $PWD or any parent directories, so can't use Docker Tools."
  exit 1;
fi

for DKRTOOL_FILE in ${DKRTOOL_FILES}; do
  echo "Reading configuration from '${DKRTOOL_FILE}'"
  . ${DKRTOOL_FILE}
done

# Now set up some common stuff

# Is the IMAGE name defined in a .dkrtool file? If not, populate it from the directory name
if [[ -z ${DOCKER_IMAGE_NAME+x} ]]; then
  DKRTOOL_IMAGE_NAME=${PWD##*/}
fi


if [[ ${DKRTOOL_REPO_BASE:-""} == "" ]]; then
  echo "DKRTOOL_REPO_BASE is empty - create a .dkrtool file in this or a parent directory and define it there."
  exit 1
fi

if [[ ${DKRTOOL_IMAGE_NAME:-""} == "" ]]; then
  echo "DKRTOOL_IMAGE_NAME is empty - is it set to be empty in a .dkrtool file?"
  exit 1
fi

echo Using ${DKRTOOL_REPO_BASE}/${DKRTOOL_IMAGE_NAME}
