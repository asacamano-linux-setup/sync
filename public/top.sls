base:
  '*':
    - git
    - silver-searcher
    - tmux
    - bin
{% if grains['modules'] is iterable %}{% for module in grains['modules']|sort %}    - {{ module }}
{% endfor %}{% endif %}
