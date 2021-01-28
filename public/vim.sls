vim:
  pkg:
    - installed

# Set up the config file
vimrc_general:
  file.managed:
    - name: "{{ grains['target_home'] }}/.vimrc"
    - source: "salt://vimrc"
    - group:  {{ grains['target_user'] }}
    - mode: 644
    - template: jinja

# How to include other files
public_vimrc:
  file.accumulated:
    - name: vimrc_includes
    - filename: "{{ grains['target_home'] }}/.vimrc"
    - text: '" Placeholder for other modules vim content'
    - require_in:
      - file: vimrc_general

