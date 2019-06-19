#!/bin/bash


other_modules=$( ls -d */ | sed -e 's/\/$//' | grep -v 'public' )

#
# Set up all dot files (which are not supported as mergable)
#

# Check for duplicates
FILES="";
  for file in public ${other_modules}; do
  FILES=${FILES}" "$(ls -1 $file/dots)
done
duplicates=$( echo $FILES | sed -e 's/ /\n/g' | sort | uniq -c | grep -v '^\s\s*1\s\s*' | wc | awk '{print $1}' )
if [[ "${duplicates}" != "0" ]]; then
  echo "There are duplicate dot files in the modules:"
  for file in $( echo $FILES | sed -e 's/ /\n/g' | sort | uniq -c | grep -v '^\s\s*1\s\s*' | awk '{print "  "$2}' | sort -u ); do
    ls -l */dots/${file}
  done
  echo "Fix the duplicate dot files (move them to dot_includes) and rerun setup.sh"
  exit 1
fi

echo "Checking dot file symlink"
for module in public ${other_modules}; do
  if ls ~/Sync/${module}/dots/* > /dev/null 2>&1 ; then
    for file in ~/Sync/${module}/dots/* ; do
      if [[ ! "${file}" =~ (\.old|\.tmp|\.swp|\.bak)$ ]]; then
        base=$(basename "${file}");
        if [[ -L ~/".${base}" ]]; then
          echo "  .${base} is linked correctly"
        elif [[ -f  ~/".${base}" ]]; then
          echo "  WARNING: .${base} is not linked"
        else
          echo "  Making symlink ln -s $file ~/.${base}"
          ln -s "$file" ~/."${base}"
        fi
      fi
    done
  fi
done

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

