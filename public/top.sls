base:
  '*':
    - git
    - silver-searcher
    - tmux
{% if grains['modules'] is iterable %}{% for module in grains['modules']|sort %}    - {{ module }}
{% endfor %}{% endif %}
