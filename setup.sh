#!/bin/bash

# Set up Ansible and then my standard Linux set up on a new server

# ----------------------------------------------------------------------------
# Bash strict mode
#
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------------------------------
# Utility functions

backup_and_empty() {
  FILE=${1}
  if [[ -f ${FILE} ]]; then
    MAX=$( ( ls -1 "${FILE}.bak."* 2>/dev/null || echo "" ) | sed -e "s:${FILE}.bak.::" | grep -v '[^0-9]' | sort -n | tail -1)
    if [[ -z "${MAX}" ]]; then
      MAX=0
    else
      MAX=$(($MAX + 1))
    fi
    echo "Backing up ${FILE} to ${FILE}.bak.${MAX}"
    mv "${FILE}" "${FILE}.bak.${MAX}"
  fi
  echo "Making new ${FILE}"
  mkdir -p $(dirname "${FILE}")
  touch "${FILE}"
}

other_modules() {
  ( cd ${SYNC_DIR}/modules; ls -d * ) 2>/dev/null || echo ""
}

# ----------------------------------------------------------------------------
# Main

# Run as root rather than random prompt for password
if [ "$EUID" -ne 0 ]
  then echo "Please run as root. Trust me, it's OK."
  exit
fi

# Handle options
FORCE_DOWNLOAD=""
FORCE_NEW_CONFIG=""
DEBUG=""
while getopts "dcx" OPT; do
  case "${OPT}" in
    d)
      FORCE_DOWNLOAD="Y"
      ;;
    c)
      FORCE_NEW_CONFIG="Y"
      ;;
    x)
      DEBUG="-vvv"
      ;;
    *)
      echo "Use -d to force new downloads, or -c to force new config, or -x to debug."
      exit 1
      ;;
   esac
done

# Use configuration from this directory
SYNC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Install salt if requested
ANSIBLE_CMD=$( which ansible || echo "")
if [[ -z "${ANSIBLE_CMD}" || -n "${FORCE_DOWNLOAD}" ]]; then
  apt-get install ansible
fi

if [[ -f ${SYNC_DIR}/.secrets ]]; then
  echo Reading secrets from ${SYNC_DIR}/.secrets
else
  echo "GIT_NAME=" >> ${SYNC_DIR}/.secrets
  echo "GIT_EMAIL=" >> ${SYNC_DIR}/.secrets
  echo "Adding secrets to ${SYNC_DIR}/.secrets. Press enter to edit."
  read
  vi "${SYNC_DIR}/.secrets"
fi
. ${SYNC_DIR}/.secrets

# Make config
CONFIG_FILE="${SYNC_DIR}/.config.yml"
if [[ ! -f "${CONFIG_FILE}" || -n "${FORCE_NEW_CONFIG}" ]]; then
  backup_and_empty "${CONFIG_FILE}"
  REQUIRED="MISSING"
  echo "---" >> "${CONFIG_FILE}"
  echo "sync_dir: \"${SYNC_DIR}\"" >> "${CONFIG_FILE}"
  echo "target_user: \"${SUDO_USER}\"" >> "${CONFIG_FILE}"
  TARGET_GROUP=$( id -g -n ${SUDO_USER} )
  echo "target_group: \"${TARGET_GROUP}\"" >> "${CONFIG_FILE}"
  TARGET_HOME=$( eval echo "~${SUDO_USER}" )
  echo "target_home: \"${TARGET_HOME}\"" >> "${CONFIG_FILE}"
  echo "target_git_name: \"${GIT_NAME:-$REQUIRED}\"" >> "${CONFIG_FILE}"
  echo "target_git_email: \"${GIT_EMAIL:-$REQUIRED}\"" >> "${CONFIG_FILE}"
  echo "modules:" >> "${CONFIG_FILE}"
  for module in $( other_modules ); do
    echo "  - ${module}" >> "${CONFIG_FILE}"
  done
  while grep "${REQUIRED}" "${CONFIG_FILE}" > /dev/null 2>&1; do
    echo "Confile file still has missing values - please replace all ${REQUIRED}:"
    echo ""
    grep "${REQUIRED}" "${CONFIG_FILE}"
    echo ""
    echo "Press enter to edit"
    read
    vi "${CONFIG_FILE}"
  done
fi

# Some Ansible options
export ANSIBLE_RETRY_FILES_ENABLED=0

# Run the setup
OTHER_PLAYBOOKS=$( other_modules | awk '{printf "modules/%s/%s.yml ",$0,$0}' | sort)
echo "ansible-playbook -c local -i localhost, --extra-vars @${CONFIG_FILE} ${DEBUG} ${OTHER_PLAYBOOKS} public/site.yml"
IFS=" "
ansible-playbook -c local -i localhost, --extra-vars @"${CONFIG_FILE}" ${DEBUG} ${OTHER_PLAYBOOKS} public/site.yml
