#"{{ grains['sync_dir'] }}/public/salt-formulas":
#  file.directory:
#    - dir_mode: 755
#    - user: {{ grains['target_user'] }}
#    - group: {{ grains['target_user'] }}
#  
#"cd {{ grains['sync_dir'] }}/public/salt-formulas/; git submodule add https://github.com/saltstack-formulas/tmux-formula.git tmux-formula":
#  cmd.run:
#    - creates: {{ grains['sync_dir'] }}/public/salt-formulas/tmux-formula
#    - runas:  {{ grains['target_user'] }}
#    - require:
#      - git
#      - "{{ grains['sync_dir'] }}/public/salt-formulas"
#
