#!/bin/bash


other_modules=$( ls -d */ | sed -e 's/\/$//' | grep -v 'public' )

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
    $file
  fi
done

