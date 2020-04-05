# ansible-role-postgresql

Manage PostgreSQL.

## Notes for CentOS users

The role uses `yum` repository from the PostgreSQL project.

## Notes for FreeBSD users

`databases/py-psycopg2`, which is required by `ansible` modules, must be built
with the target PostgreSQL version. The ports system does not yet support
`postgresql` `FLAVOR`. Current default version of `postgresql`,
`PGSQL_DEFAULT` is defined in `/usr/ports/Mk/bsd.default-versions.mk`. If you
want to install different version, the package must be built with
custom `DEFAULT_VERSIONS`, and you must use that package site. See
https://wiki.freebsd.org/Ports/DEFAULT_VERSIONS

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `postgresql_user` | user name of `postgresql` | `{{ __postgresql_user }}` |
| `postgresql_group` | group name of `postgresql` | `{{ __postgresql_group }}` |
| `postgresql_db_dir` | path to `PGDATA` | `{{ __postgresql_db_dir }}` |
| `postgresql_service` | service name of `postgresql` | `{{ __postgresql_service }}` |
| `postgresql_package` | package name of `postgresql` | `{{ __postgresql_package }}` |
| `postgresql_extra_packages` | list of extra packages to install | `[]` |
| `postgresql_conf_dir` | path to configuration directory | `{% if ansible_os_family == 'Debian' %}/etc/postgresql/{{ postgresql_major_version }}/main{% else %}{{ postgresql_db_dir }}{% endif %}` |
| `postgresql_conf_file` | path to `postgresql.conf` | `{{ postgresql_conf_dir }}/postgresql.conf` |
| `postgresql_config` | content of `postgresql.conf` | `""` |
| `postgresql_pg_hba_conf_file` path to `pg_hba.conf` | | `{{ postgresql_conf_dir }}/pg_hba.conf` |
| `postgresql_pg_hba_config` | content of `pg_hba.conf` | `""` |
| `postgresql_flags` | TBW | `""` |
| `postgresql_major_version` | major version of `postgresql` package | `{{ __postgresql_major_version }}` |
| `postgresql_initdb_flags` | TBW | `""` |
| `postgresql_users` | list of `postgresql` users | `[]` |
| `postgresql_debug` | if true, disable `no_log` | `no` |

# Dependencies

None

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - role: trombik.sysctl
    - ansible-role-postgresql
  vars:
    postgresql_debug: yes
    os_sysctl:
      FreeBSD: {}
      OpenBSD:
        kern.seminfo.semmni: 60
        kern.seminfo.semmns: 1024
      Debian: {}
      RedHat: {}
    sysctl: "{{ os_sysctl[ansible_os_family] }}"

    os_postgresql_initdb_flags:
      FreeBSD: --encoding=utf-8 --lc-collate=C
      OpenBSD: "-D {{ postgresql_db_dir }} -U {{ postgresql_user }} --encoding=utf-8 --lc-collate=C --locale=en_US.UTF-8"
      Debian: ""
      RedHat: ""
    postgresql_initdb_flags: "{{ os_postgresql_initdb_flags[ansible_os_family] }}"

    os_postgresql_extra_packages:
      FreeBSD:
        - "databases/postgresql{{ postgresql_major_version }}-contrib"
      OpenBSD:
        - postgresql-contrib
      Debian:
        - postgresql-contrib
      RedHat:
        - "postgresql{{ postgresql_major_version }}-contrib"

    os_postgresql_flags:
      FreeBSD: |
        postgresql_flags="-w -s -m fast"
        postgresql_initdb_flags="--encoding=utf-8 --lc-collate=C"
      OpenBSD: ""
      Debian: ""
      RedHat: ""
    postgresql_flags: "{{ os_postgresql_flags[ansible_os_family] }}"

    postgresql_extra_packages: "{{ os_postgresql_extra_packages[ansible_os_family] }}"
    postgresql_pg_hba_config: |
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             ::1/128                 trust
      local   replication     all                                     trust
      host    replication     all             127.0.0.1/32            trust
      host    replication     all             ::1/128                 trust
    postgresql_config: |
      {% if ansible_os_family == 'Debian' %}
      data_directory = '{{ postgresql_db_dir }}'
      hba_file = '{{ postgresql_conf_dir }}/pg_hba.conf'
      ident_file = '{{ postgresql_conf_dir }}/pg_ident.conf'
      external_pid_file = '/var/run/postgresql/{{ postgresql_major_version }}-main.pid'
      port = 5432
      max_connections = 100
      unix_socket_directories = '/var/run/postgresql'
      ssl = on
      ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
      ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
      shared_buffers = 128MB
      dynamic_shared_memory_type = posix
      log_line_prefix = '%m [%p] %q%u@%d '
      log_timezone = 'UTC'
      cluster_name = '{{ postgresql_major_version }}/main'
      stats_temp_directory = '/var/run/postgresql/{{ postgresql_major_version }}-main.pg_stat_tmp'
      datestyle = 'iso, mdy'
      timezone = 'UTC'
      lc_messages = 'en_US'
      lc_monetary = 'en_US'
      lc_numeric = 'en_US'
      lc_time = 'en_US'
      default_text_search_config = 'pg_catalog.english'
      include_dir = 'conf.d'
      {% else %}
      max_connections = 100
      shared_buffers = 128MB
      dynamic_shared_memory_type = posix
      max_wal_size = 1GB
      min_wal_size = 80MB
      log_destination = 'syslog'
      log_timezone = 'UTC'
      update_process_title = off
      datestyle = 'iso, mdy'
      timezone = 'UTC'
      lc_messages = 'C'
      lc_monetary = 'C'
      lc_numeric = 'C'
      lc_time = 'C'
      default_text_search_config = 'pg_catalog.english'
      {% endif %}
    postgresql_users:
      - name: foo
        # PassWord
        # echo md5`echo -n 'PassWordfoo' | md5`
        password: md5019145e613f681f6ec91b2157b6922a7
        # XXX login_user and db are required on OpenBSD
        login_user: "{{ postgresql_user }}"
        db: template1
      - name: root
        # AdminPassWord
        # echo md5`echo -n 'AdminPassWordroot' | md5`
        password: md55a93c2c23f842b93516fc8e9133d8840
        role_attr_flags: SUPERUSER
        login_user: "{{ postgresql_user }}"
        db: template1
```

# License

```
Copyright (c) 2020 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
