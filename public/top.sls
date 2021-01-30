base:
  '*':
    - vim
    - tmux
    - bin
    - utils
    # Just in case
    - git
{% if grains['modules'] is iterable %}{% for module in grains['modules']|sort %}    - {{ module }}
{% endfor %}{% endif %}
