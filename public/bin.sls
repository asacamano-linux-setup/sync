path_includes_bin:
  file.line:
    - name: {{ grains['target_home'] }}/.bash_aliases
    - mode: insert
    - content: "export PATH={{ grains['sync_dir'] }}/public/bin:${PATH}"
    - location: end
