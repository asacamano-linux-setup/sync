#!/bin/bash

# Set up the dot_include files

other_modules=$( ls -d */ | sed -e 's/\/$//' | grep -v 'public' )

# .bash_alises
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

# .vimrc
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

# .vimrc
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
