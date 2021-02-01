# Sync dir

This directory contains things I'd like to keep in sync across my workstations.

It uses [Ansible](http://ansible.com) running locally. This was chosen because
Ansible does not run a peristent agent on the machine.

## Choosing or adding modues

It does basic setup, but can be extended by adding "modules" to the modules
directory. Each module must contain a tasks file with the same name
as the modue, e.g.

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

