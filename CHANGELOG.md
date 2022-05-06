## Release 1.4.0

* 9eeaa7d update: use version 13 in tests where possible

## Release 1.3.2

* 62e1a8c bugfix: switch to hspaans/ansible-galaxy-action
* a6f54b5 bugfix: install postgresql from official repo on Fedora

## Release 1.3.1

* 2cf70ac bugfix: default to ansible_distribution_version
* 9f85e11 update: support Devuan 4
* 445e451 bugfix: fix risky-file-permissions, quote octal values

## Release 1.3.0

* 70a1a0e bugfix: QA
* acf4754 ci: update kitchen workflow
* 2e2f88c feat: support Fedora
* d66c7eb ci: build in parallel with matrix
* e374b7e feat: support OpenBSD 7.0
* edde2f1 ci: add test-kitchen to CI

## Release 1.2.0

* c3e566e update: bump default version to 13 on FreeBSD
* 338eeb8 bugfix: use python on CentOS, instead of python3
* 98a505d bugfix: test if psycopg2 is usable

## Release 1.1.2

* fd56a9e bugfix: QA
* 4e15a61 bugfix: support Devuan

## Release 1.1.1

* 2693a03 bugfix: remove postgresql_initdb_command
* 6c93d97 bugfix: install postgresql_extra_packages after postgresql_package
* cbd96be bugfix: update gems
* a71bb41 bugfix: implement postgresql_debug

## Release 1.1.0

* 25aa589 ci: add GitHub Actions
* 37c60c8 imp: support initial admin password, update boxes, versions


## Release 1.0.0

* Initial release
