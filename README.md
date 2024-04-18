# Sync dir

This directory contains things I'd like to keep in sync across my workstations.

It uses [Ansible](http://ansible.com) running locally. This was chosen because
Ansible does not run a peristent agent on the machine.

## Running it on a new box

### Short term - not making changes

```
cd ~
git clone https://github.com/asacamano-linux-setup/sync.git ;
cs sync
git submodule add -f https://github.com/asacamano-linux-setup/gui.git modules/gui
sudo sync.sh
```

### Long term

First, make a [new SSH
key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
and add it to your SSH agent and your GitHub account following the instructions
on that GitHib page.

Then

```
cd ~
git clone git@github.com:asacamano-linux-setup/sync.git ;
cs sync
git submodule add -f git@github.com:asacamano-linux-setup/gui.git modules/gui
sudo sync.sh
```

## Choosing or adding modues

By itself this code does basic setup, but can be extended by adding "modules"
to the modules directory.

Use the `git submodule` command to add them, e.g.

```
git submodule add -f https://github.com/asacamano-linux-setup/gui.git modules/gui
```

Each module must contain a tasks file with the same name as the modue, e.g.

```
modules/gui/gui.yml
```

## Running the setup script

Once the modules are installed, run

```
sudo ./setup.sh
```

## Overview

All modules playbooks are executed first, so that they can populate variables
used in the public playboks. Modules are executed in alphabetical sort order.
