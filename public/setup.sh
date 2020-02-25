#!/bin/bash

# Bash strict mode
set -euo pipefail
IFS=$'\n\t'

## In generall, all of these should be idempotent

## Gnome terminal setup
if [[ "${DISPLAY}" != "" ]]; then
  dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < gnome-terminal-profile
fi

## Tmux
if ( apt list --installed 2>&1 | grep "^tmux/" > /dev/null ); then
  echo tmux already installed
else
  echo Installing tmux
  sudo apt update && sudo apt install tmux
fi

## Install tmux plugin manager
if [[ -d ~/.tmux/plugins/tpm ]]; then
  echo "Tmux Plugin Manager already installed"
else
  echo "Getting Tmux Plugin Manager"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

  ## Install / updatetmux plugins
  ~/.tmux/plugins/tpm/bin/install_plugins
fi

## Silver Searcher (ag)
if ( apt list --installed 2>&1 | grep "^silversearcher-ag/" > /dev/null ); then
  echo SilverSearcher already installed
else
  echo Installing SilverSearcher
  sudo apt update && sudo apt install silversearcher-ag
fi

## kdiff3
if ( apt list --installed 2>&1 | grep "^kdiff3/" > /dev/null ); then
  echo kdiff3 already installed
else
  echo Installing kdiff3
  sudo apt update && sudo apt install kdiff3
fi

## meld
if ( apt list --installed 2>&1 | grep "^meld/" > /dev/null ); then
  echo meld already installed
else
  echo Installing meld
  sudo apt update && sudo apt install meld
fi

## i3 tiling window manager
if ( apt list --installed 2>&1 | grep "^i3/" > /dev/null ); then
  echo i3 already installed
else
  echo Installing i3
  sudo apt update && sudo apt install i3
fi

## rofi app launcher
if ( apt list --installed 2>&1 | grep "^rofi/" > /dev/null ); then
  echo rofi already installed
else
  echo Installing rofi
  sudo apt update && sudo apt install rofi
fi
