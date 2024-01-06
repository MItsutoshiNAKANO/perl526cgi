## @license AGPL-3.0-or-later
# SPDX-License-Identifier: AGPL-3.0-or-later

# You must repeat `vagrant reload --provision`
$script = <<-SCRIPT
  ## @see https://www.if-not-true-then-false.com/2010/install-virtualbox-guest-additions-on-fedora-centos-red-hat-rhel/#14-install-following-packages
  dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  dnf -y upgrade
  dnf -y install gcc kernel-devel kernel-headers dkms make bzip2 perl

  dnf -y install cpan httpd mod_perl perl-CGI perl-HTML-Template-Expr

  ## @see https://www.postgresql.org/download/linux/redhat/
  dnf -y install postgresql postgresql-server-devel postgresql-contrib postgresql-upgrade-devel perl-DBD-Pg perl-pgsql_perl5
  
  echo yes | cpan 'CGI::Application::Plugin::Authentication'
  cpan 'CGI::Application::Plugin::Session'
  cpan 'Mojo::Log'
  install -b -m 644 -o root -g root /vagrant/root/etc/selinux/config /etc/selinux/
  setenforce Permissive
  rm -rf /var/www
  ln -s /vagrant /var/www

  sudo -u postgres initdb -D /var/lib/pgsql/data
  systemctl enable postgresql.service
  systemctl start postgresql.service
  /vagrant/scripts/0010-create_database.sh
  sudo -u vagrant /vagrant/scripts/0020-create_tables.sh
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "almalinux/8"
  # @see https://developer.hashicorp.com/vagrant/docs/providers/virtualbox/configuration#vboxmanage-customizations
  config.vm.provider "virtualbox" do |v|
    v.memory = 6144
    v.cpus = 2
  end
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = true
  end
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.provision "shell", inline: $script
  config.trigger.after :up, :reload do |trigger|
    trigger.info = "Start httpd"
    trigger.run_remote = {inline: "systemctl start httpd.service"}
  end
end
