standard_bash_aliases:
  file.line:
    - name: {{ grains['target_home'] }}/.bash_aliases
    - mode: insert
    - location: end
    - content: "export EDITOR=vi"
