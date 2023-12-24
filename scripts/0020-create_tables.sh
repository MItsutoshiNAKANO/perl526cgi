#! /bin/sh -eux

sudo sudo -u vagrant psql --file='/vagrant/ddl/0020-create_table_workers.sql'
