tmux:
  pkg:
    - installed

"{{ grains['target_home'] }}/.tmux/plugins":
  file.directory:
    - user: {{ grains['target_user'] }}
    - group: {{ grains['target_user'] }}
    - dir_mode: 755
    - makedirs: true

# Install tmux plugin manager
"git clone https://github.com/tmux-plugins/tpm {{ grains['target_home'] }}/.tmux/plugins/tpm":
  cmd.run:
    - creates: {{ grains['target_home'] }}/.tmux/plugins/tpm
    - runas: {{ grains['target_user'] }}
    - require:
      - "{{ grains['target_home'] }}/.tmux/plugins"

# Set up the config file
tmux_conf_general:
  file.managed:
    - name: "{{ grains['target_home'] }}/.tmux.conf"
    - source: "salt://tmux.conf"
    - group:  {{ grains['target_user'] }}
    - mode: 644
    - template: jinja

public_tmux_conf:
  file.accumulated:
    - name: tmux_includes
    - filename: "{{ grains['target_home'] }}/.tmux.conf"
    - text: "source {{ grains['sync_dir'] }}/public/salt/tmux.partial.conf"
    - require_in:
      - file: tmux_conf_general

# Install / updatetmux plugins
"{{ grains['target_home'] }}/.tmux/plugins/tpm/bin/install_plugins && touch {{ grains['target_home'] }}/.tmux/tpm.installed":
  cmd.run:
    - runas:  {{ grains['target_user'] }}
    - creates: "{{ grains['target_home'] }}/.tmux/tpm.installed"
    - require:
      - tmux_conf_general
