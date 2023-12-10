# SPDX-License-Identifier: AGPL-3.0-or-later

$script = <<-SCRIPT
  # @see https://www.if-not-true-then-false.com/2010/install-virtualbox-guest-additions-on-fedora-centos-red-hat-rhel/#14-install-following-packages
  sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  sudo dnf -y upgrade
  sudo dnf -y install gcc kernel-devel kernel-headers dkms make bzip2 perl

  sudo dnf -y install cpan httpd mod_perl perl-CGI perl-HTML-Template-Expr

  # @see https://www.postgresql.org/download/linux/redhat/
  sudo dnf -y install postgresql postgresql-server-devel postgresql-contrib postgresql-upgrade-devel perl-DBD-Pg perl-pgsql_perl5
  
  echo yes | sudo cpan 'CGI::Application::Plugin::Session'
  sudo rm -rf /var/www
  sudo ln -s /vagrant /var/www
  sudo install -b -m 644 -o root -g root /vagrant/root/etc/selinux/config /etc/selinux
  sudo setenforce Permissive
  sudo systemctl enable httpd.service
  sudo systemctl start httpd.service
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
end
