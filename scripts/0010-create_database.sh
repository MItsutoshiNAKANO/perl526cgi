#! /bin/sh -eux

sudo sudo -u postgres psql --file='/vagrant/ddl/0010-create_role_vagrant.sql'
