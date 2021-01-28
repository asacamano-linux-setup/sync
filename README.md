# Sync dir

This directory contains things I'd like to keep in sync across my workstations.

It uses [Salt](http://saltstack.com) in a masterless mode.

## Choosing or adding modues

It does basic setup, but can be extended by adding "modules" to the modules
directory. Each module must contain a Salt actions file with the same name
as the modue, e.g.

```
modules/gui/gui.sls
```

## Running the setup script

Once the modules are installed, run 

```
sudo ./setup.sh
```
