#!/bin/bash

# Bash strict mode
set -euo pipefail
IFS=$'\n\t'

#
# Common function to symlink files
#

symlink() {
  local SRC_DIR=$1
  if [[ "${SRC_DIR}" == "" ]]; then
    echo "Bad call to simlink() - missing first arg SRC_DIR."
    exit 1
  fi
  local DEST_PATH=$2
  if [[ "${DEST_PATH}" == "" ]]; then
    echo "Bad call to simlink() - missing second arg DEST_PATH."
    exit 1
  fi
  # Check for duplicates
  local FILES="";
  for module in public ${other_modules}; do
    if ls ~/Sync/${module}/${SRC_DIR}/* > /dev/null 2>&1 ; then
      FILES=${FILES}" "$(ls -1 $module/${SRC_DIR})
    fi
  done
  local duplicates=$( echo $FILES | sed -e 's/ /\n/g' | sort | uniq -c | grep -v '^\s\s*1\s\s*' | wc | awk '{print $1}' )
  if [[ "${duplicates}" != "0" ]]; then
    echo "There are duplicate files in the modules' ${SRC_DIR} directories:"
    for file in $( echo $FILES | sed -e 's/ /\n/g' | sort | uniq -c | grep -v '^\s\s*1\s\s*' | awk '{print "  "$2}' | sort -u ); do
      ls -l */${SRC_DIR}/${file}
    done
    echo "Fix the duplicate ${SRC_DIR} files and rerun setup.sh"
    echo "Note that duplicate dot files can sometimes be handed as dot_includes files."
    exit 1
  fi

  for module in public ${other_modules}; do
    if ls ~/Sync/${module}/${SRC_DIR}/* > /dev/null 2>&1 ; then
      for file in ~/Sync/${module}/${SRC_DIR}/* ; do
        if [[ ! "${file}" =~ (\.old|\.tmp|\.swp|\.bak|\*)$ ]]; then
          base=$(basename "${file}");
          dest="${DEST_PATH}${base}"
          if [[ -L "${dest}" ]]; then
            echo "  ${dest} is linked correctly"
          elif [[ -f  "${dest}" ]]; then
            echo "  WARNING: ${dest} is not linked"
          else
            echo "  Making symlink ln -s $file ${dest}"
            sudo ln -s "$file" "${dest}"
          fi
        fi
      done
    fi
  done
}


#
# Main code
#

other_modules=$( ls -d */ | sed -e 's/\/$//' | grep -v 'public' )

# Set up all dot files (which are not supported as mergable dot_include)
echo "Checking dot files symlinks"
symlink "dots" "${HOME}/."

# Set up all bin files
echo "Checking bin file symlink"
mkdir -p ~/bin
symlink "bin" "${HOME}/bin/"

# Set up all cron files
echo "Checking cron file symlink"
symlink "cron" "/etc/cron.d/"

#
# Set up the dot_include files, build building files that include elements
# from all modules.
#

# Build .bash_alises
outfile=~/.bash_aliases
rm -f ${outfile}
for module in public ${other_modules}; do
  file="${module}/dot_includes/bash_aliases"
  if [[ -f "${file}" ]]; then
    file=$( realpath "${file}" )
    echo ". ${file} >> $outfile"
    echo ". ${file}" >> $outfile
  fi
done
# Source the new aliases
. ~/.bash_aliases

# Build .vimrc
outfile=~/.vimrc
rm -f ${outfile}
for module in public ${other_modules}; do
  file="${module}/dot_includes/vimrc"
  if [[ -f "${file}" ]]; then
    file=$( realpath "${file}" )
    echo "source ${file} >> $outfile"
    echo "source ${file}" >> $outfile
  fi
done

# Build .conf
outfile=~/.tmux.conf
rm -f ${outfile}
for module in public ${other_modules}; do
  file="${module}/dot_includes/tmux.conf"
  if [[ -f "${file}" ]]; then
    file=$( realpath "${file}" )
    echo "source ${file} >> $outfile"
    echo "source ${file}" >> $outfile
  fi
done

#
# Now that all the .rc files are setup, run the setup.sh files
#

# Run all setup.sh files
for module in public ${other_modules}; do
  file="${module}/setup.sh"
  if [[ -f "${file}" ]]; then
    echo "==============================================================="
    echo "Running ${file}"
    pushd "${module}"
    ./setup.sh
    popd
  fi
done
