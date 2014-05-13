{% from "mysql/map.jinja" import mysql with context %}


{% if grains['os'] in ['Ubuntu', 'Debian'] %}
mysql-debconf:
  debconf.set:
    - name: mysql-server
    - data:
        'mysql-server/root_password': {'type': 'password', 'value': '{{ salt['pillar.get']('mysql:server:root_password', 'somepass') }}'}
        'mysql-server/root_password_again': {'type': 'password', 'value': '{{ salt['pillar.get']('mysql:server:root_password', 'somepass') }}'}
        'mysql-server/start_on_boot': {'type': 'boolean', 'value': 'true'}
{% endif %}

mysqld:
  pkg:
    - installed
    - name: {{ mysql.server }}
{% if grains['os'] in ['Ubuntu', 'Debian'] %}
    - require:
      - debconf: mysql-debconf
{% endif %}
  service:
    - running
    - name: {{ mysql.service }}
    - enable: True
    - watch:
      - pkg: mysqld

mysql-python:
  pkg:
    - installed
    - name: {{ mysql.python }}

{% if grains['os'] in ['Ubuntu', 'Debian', 'Gentoo'] %}
my.cnf:
  file.managed:
    - name: {{ mysql.config }}
    - source: salt://mysql/files/{{ grains['os'] }}-my.cnf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: mysqld
{% endif %}

# Set SELinux to permissive mode while installing mysqld otherwise the
# mysql user will not be created; restore enforcing when done.
{% if (grains['os_family'] == 'RedHat'
    and salt['cmd.run']("sestatus | awk '/Current mode/ { print $3 }'") == 'enforcing') %}
selinux_permissive:
  cmd.run:
    - name: setenforce permissive
    - prereq:
      - pkg: mysqld

selinux_enforcing:
  cmd.wait:
    - name: setenforce enforcing
    - watch_in:
      - pkg: mysqld
{% endif %}

{% if grains['os'] in 'FreeBSD' %}
my.cnf:
  file.managed:
    - name: {{ mysql.config }}
    - source: salt://mysql/files/my-{{ mysql.mysql_size }}.cnf
    - template: jinja
    - watch_in:
      - service: mysqld
{% endif %}
