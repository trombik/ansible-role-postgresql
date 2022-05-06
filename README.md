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

## Debian

```text
---
__postgresql_major_version: 12
__postgresql_user: postgres
__postgresql_group: postgres
__postgresql_db_dir: "/var/lib/postgresql/{{ postgresql_major_version }}/main"
__postgresql_service: postgresql
__postgresql_package: postgresql-{{ postgresql_major_version }}
__postgresql_home_dir: "/var/lib/postgresql"
__postgresql_default_auth_method: md5
__postgresql_default_login_db: postgres
```

## Fedora

```text
---
__postgresql_major_version: 12
__postgresql_user: postgres
__postgresql_group: postgres
__postgresql_db_dir: "/var/lib/pgsql/data"
__postgresql_service: postgresql
__postgresql_package: "@postgresql:{{ postgresql_major_version }}/server"
__postgresql_home_dir: "/var/lib/pgsql"
__postgresql_default_auth_method: scram-sha-256
__postgresql_default_login_db: postgres
```

## FreeBSD

```text
---
__postgresql_major_version: 13
__postgresql_user: postgres
__postgresql_group: postgres
__postgresql_db_dir: "/var/db/postgres/data{{ postgresql_major_version }}"
__postgresql_service: postgresql
__postgresql_package: databases/postgresql{{ postgresql_major_version }}-server
__postgresql_home_dir: "/var/db/postgres"
__postgresql_default_auth_method: scram-sha-256
__postgresql_default_login_db: postgres
```

## OpenBSD

```text
---
__postgresql_major_version: 13
__postgresql_user: _postgresql
__postgresql_group: _postgresql
__postgresql_db_dir: "/var/postgresql/data"
__postgresql_service: postgresql
__postgresql_package: postgresql-server
__postgresql_home_dir: "/var/postgresql"
__postgresql_default_auth_method: scram-sha-256
__postgresql_default_login_db: template1
```

## RedHat

```text
---
__postgresql_major_version: 12
__postgresql_user: postgres
__postgresql_group: postgres
__postgresql_db_dir: "/var/lib/pgsql/{{ postgresql_major_version }}/data"
__postgresql_service: postgresql-{{ postgresql_major_version }}
__postgresql_package: postgresql{{ postgresql_major_version }}-server
__postgresql_home_dir: "/var/lib/pgsql"
__postgresql_default_auth_method: scram-sha-256
__postgresql_default_login_db: postgres
```

## Devuan-3

```text
---
__postgresql_major_version: 11
__postgresql_user: postgres
__postgresql_group: postgres
__postgresql_db_dir: "/var/lib/postgresql/{{ postgresql_major_version }}/main"
__postgresql_service: postgresql
__postgresql_package: postgresql-{{ postgresql_major_version }}
__postgresql_home_dir: "/var/lib/postgresql"
__postgresql_default_auth_method: md5
__postgresql_default_login_db: postgres
```

## Devuan-4

```text
---
__postgresql_major_version: 13
__postgresql_user: postgres
__postgresql_group: postgres
__postgresql_db_dir: "/var/lib/postgresql/{{ postgresql_major_version }}/main"
__postgresql_service: postgresql
__postgresql_package: postgresql-{{ postgresql_major_version }}
__postgresql_home_dir: "/var/lib/postgresql"
__postgresql_default_auth_method: md5
__postgresql_default_login_db: postgres
```

## Ubuntu-20

```text
---
__postgresql_major_version: 12
__postgresql_user: postgres
__postgresql_group: postgres
__postgresql_db_dir: "/var/lib/postgresql/{{ postgresql_major_version }}/main"
__postgresql_service: postgresql
__postgresql_package: postgresql-{{ postgresql_major_version }}
__postgresql_home_dir: "/var/lib/postgresql"
__postgresql_default_auth_method: md5
__postgresql_default_login_db: postgres
```

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
    postgresql_initial_password: password
    postgresql_debug: yes
    os_postgresql_major_version:
      Devuan: "{% if ansible_distribution_version | int >= 4 %}13{% else %}11{% endif %}"
      Ubuntu: 12
    # XXX use version 13 where possible because trusted extension, which is
    # introduced in 13, is a critical feature in automation.
    #
    # see "An Overview of Trusted Extensions in PostgreSQL 13" at
    # https://severalnines.com/database-blog/overview-trusted-extensions-postgresql-13
    postgresql_major_version: "{{ os_postgresql_major_version[ansible_distribution] | default(13) }}"
    os_sysctl:
      FreeBSD: {}
      OpenBSD:
        kern.seminfo.semmni: 60
        kern.seminfo.semmns: 1024
      Debian: {}
      RedHat: {}
    sysctl: "{{ os_sysctl[ansible_os_family] }}"

    os_postgresql_extra_packages:
      FreeBSD:
        - "databases/postgresql{{ postgresql_major_version }}-contrib"
      OpenBSD:
        - postgresql-contrib
      Devuan:
        - postgresql-contrib
      Ubuntu:
        - postgresql-contrib
      Debian:
        - postgresql-contrib
      RedHat:
        - "postgresql{{ postgresql_major_version }}-contrib"
      CentOS:
        - "postgresql{{ postgresql_major_version }}-contrib"
      Fedora:
        - postgresql-contrib

    postgresql_extra_packages: "{{ os_postgresql_extra_packages[ansible_distribution] }}"
    postgresql_pg_hba_config: |
      host    all             all             127.0.0.1/32            {{ postgresql_default_auth_method }}
      host    all             all             ::1/128                 {{ postgresql_default_auth_method }}
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
      lc_messages = 'C'
      lc_monetary = 'C'
      lc_numeric = 'C'
      lc_time = 'C'
      default_text_search_config = 'pg_catalog.english'
      include_dir = 'conf.d'
      password_encryption = {{ postgresql_default_auth_method }}
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
      password_encryption = {{ postgresql_default_auth_method }}
      {% endif %}
    postgresql_users:
      - name: foo
        password: PassWord
      - name: root
        password: AdminPassWord
        role_attr_flags: SUPERUSER

    postgresql_databases:
      - name: bar
        owner: foo
        state: present

    project_postgresql_initdb_flags: --encoding=utf-8 --lc-collate=C --locale=en_US.UTF-8
    project_postgresql_initdb_flags_pwfile: "--pwfile={{ postgresql_initial_password_file }}"
    project_postgresql_initdb_flags_auth: "--auth-host={{ postgresql_default_auth_method }} --auth-local={{ postgresql_default_auth_method }}"
    os_postgresql_initdb_flags:
      FreeBSD: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      OpenBSD: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      RedHat: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      # XXX you cannot use --auth-host or --auth-local here because
      # pg_createcluster, which is executed during the installation, overrides
      # them, forcing md5
      Debian: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }}"

    postgresql_initdb_flags: "{{ os_postgresql_initdb_flags[ansible_os_family] }}"
    os_postgresql_flags:
      FreeBSD: |
        postgresql_flags="-w -s -m fast"
      OpenBSD: ""
      Debian: ""
      RedHat: ""
    postgresql_flags: "{{ os_postgresql_flags[ansible_os_family] }}"
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
