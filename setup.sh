#!/bin/bash

# Bash strict mode
set -euo pipefail
IFS=$'\n\t'

#
# Common functions
#

# Check for duplicates
dupcheck() {
  local SRC_DIR=$1
  if [[ "${SRC_DIR}" == "" ]]; then
    echo "Bad call to dupcheck() - missing first arg SRC_DIR."
    exit 1
  fi
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
}

# Symlink to files in a module
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
  dupcheck "${SRC_DIR}"
  for module in public ${other_modules}; do
    if ls ~/Sync/${module}/${SRC_DIR}/* > /dev/null 2>&1 ; then
      for file in ~/Sync/${module}/${SRC_DIR}/* ; do
        if [[ ! "${file}" =~ (\.old|\.tmp|\.swp|\.bak|\*)$ ]]; then
          local base=$(basename "${file}");
          local dest="${DEST_PATH}${base}"
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

# Copy cronfiles
copycron() {
  local SRC_DIR=$1
  if [[ "${SRC_DIR}" == "" ]]; then
    echo "Bad call to cropcron() - missing first arg SRC_DIR."
    exit 1
  fi
  local DEST_PATH="/etc/cron.d/"
  local reload=no
  dupcheck "${SRC_DIR}"
  for module in public ${other_modules}; do
    if ls ~/Sync/${module}/${SRC_DIR}/* > /dev/null 2>&1 ; then
      for file in ~/Sync/${module}/${SRC_DIR}/* ; do
        if [[ ! "${file}" =~ (\.old|\.tmp|\.swp|\.bak|\*)$ ]]; then
          local base=$(basename "${file}");
          local dest="${DEST_PATH}${base}"
          local updated=no
          if [[ -f "${dest}" ]]; then
            local file_sum=$( sha256sum "${file}" | awk '{print $1}' )
            local dest_sum=$( sha256sum "${dest}" | awk '{print $1}' )
            if [[ "${file_sum}" == "${dest_sum}" ]]; then
              echo "  ${dest} exists and is up to date"
            else
              echo "  sudo cp ${file} ${dest}"
              sudo cp "${file}" "${dest}"
              updated=yes
            fi
          else
            echo "  sudo cp ${file} ${dest}"
            sudo cp "${file}" "${dest}"
            updated=yes
          fi

          if [[ "${updated}" == "yes" ]]; then
            echo "Updating attributes and reloading cron."
            sudo chown root:root ${dest}
            sudo chmod 644 ${dest}
            reload=yes
          fi
        fi
      done
    fi
  done
  if [[ "${reload}" == "yes" ]]; then
    sudo service cron reload
  fi
}


#
# Main code
#

echo A
other_modules=$( ls -d */ | sed -e 's/\/$//' | ( grep -v 'public' || echo "" ) )
echo B

# Set up all dot files (which are not supported as mergable dot_include)
echo "Checking dot files symlinks"
symlink "dots" "${HOME}/."

# Set up all bin files
echo "Checking bin file symlink"
mkdir -p ~/bin
symlink "bin" "${HOME}/bin/"

# Set up all cron files
echo "Checking cron files copied and cron updated"
copycron "cron"

#
# Set up the dot_include files, build building files that include elements
# from all modules.
#

# Build .bash_alises
outfile=~/.bash_aliases
if [[ -f "${outfile}" ]]; then
  mv "${outfile}" "${outfile}.bak"
fi
for module in public ${other_modules}; do
  file="${module}/dot_includes/bash_aliases"
  if [[ -f "${file}" ]]; then
    file=$( realpath "${file}" )
    echo ". ${file} >> $outfile"
    echo ". ${file}" >> $outfile
  fi
done
echo "" >> ${outfile}
# Source the new aliases
. ~/.bash_aliases

# Build .vimrc
outfile=~/.vimrc
if [[ -f "${outfile}" ]]; then
  mv "${outfile}" "${outfile}.bak"
fi
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
if [[ -f "${outfile}" ]]; then
  mv "${outfile}" "${outfile}.bak"
fi
for module in public ${other_modules}; do
  file="${module}/dot_includes/tmux.conf"
  if [[ -f "${file}" ]]; then
    file=$( realpath "${file}" )
    echo "source ${file} >> $outfile"
    echo "source ${file}" >> $outfile
  fi
done

# Build .config/i3/config file
outfile=~/.config/i3/config
mkdir -p ~/.config/i3
rm -f ${outfile}
for module in public ${other_modules}; do
  file="${module}/dot_includes/i3"
  if [[ -f "${file}" ]]; then
    file=$( realpath "${file}" )
    echo "cat ${file} >> $outfile"
    cat "${file}" >> $outfile
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
