# Sync dir

This directory contains things I'd like to keep in sync across my workstations.

Each directory is a "module" to allow public stuff to live in my github repo in
a public module, and private stuff to live in private repos (like stuff for
specifics jobs).

Within each module, there are several files:

* setup.sh contains idempotent scripts to setup a new machine
* dots/ contains files that can be linked from home dir .foo files, such as
  .bash\_aliases, .vimrc, etc...
* dot\_includes confains files that should be included in specific home dir
  files, specifially:
  * .bash\_aliases
  * .tmux.conf
  * .vimrc
* bin/ contains executable scripts for each module
