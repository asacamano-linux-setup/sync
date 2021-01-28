base:
  '*':
    - vim
    - tmux
    - silver-searcher
    - bin
    # Just in case
    - git
{% if grains['modules'] is iterable %}{% for module in grains['modules']|sort %}    - {{ module }}
{% endfor %}{% endif %}
