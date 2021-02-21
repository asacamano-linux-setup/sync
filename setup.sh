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

usage() {
  echo "Usage: setup.sh"
  echo "Optons:"
  echo "  -d : force new download"
  echo "  -c : generate new config"
  echo "  -p <playbook> : run a specific playbook or task list"
  echo "  -x : debug"
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
PLAYBOOKS=""
while getopts "dcxp:" OPT; do
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
    p)
      PLAYBOOKS="${OPTARG}"
      ;;
    *)
      usage
      exit 1
      ;;
   esac
done

shift $((OPTIND - 1)) 
if [[ -n "${1:-}" ]]; then
  usage
  exit 1
fi

# Use configuration from this directory
SYNC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# What user is running this
TARGET_USER="${SUDO_USER}"
TARGET_GROUP=$( id -g -n ${TARGET_USER} )

# Install ansible if requested
ANSIBLE_CMD=$( which ansible || echo "")
if [[ -z "${ANSIBLE_CMD}" || -n "${FORCE_DOWNLOAD}" ]]; then
  apt-get install ansible
fi

# There are secrets and config values.
# Secrets are provied by the user once and never change unless the user does so.
# Config values can be recomputed at will, and may depend on secrets.
SECRETS_FILE="${SYNC_DIR}/.secrets"
if [[ ! -f "${SECRETS_FILE}" ]]; then
  touch "${SECRETS_FILE}"
fi
chmod 0600 ${SECRETS_FILE}
chown "${TARGET_USER}:${TARGET_GROUP}" "${SECRETS_FILE}"

SECRET_KEYS=""
for module in $( other_modules ); do
  MODULE_CONFIG=modules/${module}/secrets.keys
  if [[ -f "${MODULE_CONFIG}" ]]; then
    SECRET_KEYS="${SECRET_KEYS} "$( cat "${MODULE_CONFIG}" | sed -e 's/#.*$//' )
  fi
done
SECRET_KEYS="${SECRET_KEYS} "$( cat public/secrets.keys | sed -e 's/#.*$//' )
SECRET_KEYS=$( echo ${SECRET_KEYS} | sed -e 's/ /\n/g' -e 's/^\s*//' -e 's/\s*$//' | grep -v '^$' )
HAS_EMPTY_VALUE=Y
while [[ -n "${HAS_EMPTY_VALUE}" ]]; do
  HAS_EMPTY_VALUE=""
  for key in ${SECRET_KEYS}; do
    # if the key does not have a value
    if [[ 0 == $( grep -c "^export ${key}=\"..*\"$" "${SECRETS_FILE}" ) ]]; then
      # if the key is not present at all
      if [[ 0 == $( grep -c "^export {key}=" "${SECRETS_FILE}" ) ]]; then
        echo "export ${key}=\"\"" >> "${SECRETS_FILE}"
        HAS_EMPTY_VALUE="Y"
      else
        # The key has an empty value
        HAS_EMPTY_VALUE="Y"
      fi
    fi
  done
  if [[ -n "${HAS_EMPTY_VALUE}" ]]; then
    echo "Missing values in .secrets file.  Press enter to edit."
    read
    vi "${SYNC_DIR}/.secrets"
  fi
done
echo "Reading secrets from ${SECRETS_FILE}"
. "${SECRETS_FILE}"

# Make config
CONFIG_FILE="${SYNC_DIR}/.config.yml"
if [[ ! -f "${CONFIG_FILE}" || -n "${FORCE_NEW_CONFIG}" ]]; then
  backup_and_empty "${CONFIG_FILE}"
  echo "---" >> "${CONFIG_FILE}"
  echo "sync_dir: \"${SYNC_DIR}\"" >> "${CONFIG_FILE}"
  echo "target_user: \"${TARGET_USER}\"" >> "${CONFIG_FILE}"
  echo "target_group: \"${TARGET_GROUP}\"" >> "${CONFIG_FILE}"
  TARGET_HOME=$( eval echo "~${TARGET_USER}" )
  echo "target_home: \"${TARGET_HOME}\"" >> "${CONFIG_FILE}"
  echo "modules:" >> "${CONFIG_FILE}"
  for module in $( other_modules ); do
    echo "  - ${module}" >> "${CONFIG_FILE}"
  done
  cat public/config.template.yml | envsubst >> "${CONFIG_FILE}"
  for module in $( other_modules ); do
    MODULE_CONFIG=modules/${module}/config.template.yml
    if [[ -f "${MODULE_CONFIG}" ]]; then
      cat "${MODULE_CONFIG}" | envsubst >> "${CONFIG_FILE}"
    fi
  done
fi

# Some Ansible options
export ANSIBLE_RETRY_FILES_ENABLED=0

# Run the setup
if [[ -z "${PLAYBOOKS}" ]]; then
  OTHER_PLAYBOOKS=$( other_modules | awk '{printf "modules/%s/%s.yml ",$0,$0}' | sort)
  PLAYBOOKS=$(echo "${OTHER_PLAYBOOKS} public/site.yml" | sed -e 's/  */ /g' -e 's/^ *//' -e 's/ *$//')
fi
echo "ansible-playbook -c local -i localhost, --extra-vars @${CONFIG_FILE} ${DEBUG} ${PLAYBOOKS}"
IFS=$' '
ansible-playbook -c local -i localhost, --extra-vars @"${CONFIG_FILE}" ${DEBUG} ${PLAYBOOKS}
