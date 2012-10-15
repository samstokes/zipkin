# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  # config.vm.network :hostonly, "192.168.33.10"

  # Assign this VM to a bridged network, allowing you to connect directly to a
  # network using the host's network device. This makes the VM appear as another
  # physical device on your network.
  # config.vm.network :bridged

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.

  # Forward Zookeeper ports
  config.vm.forward_port 2181, 2181

  # Forward Cassandra ports
  config.vm.forward_port 7000, 7000
  config.vm.forward_port 9160, 9160

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe 'apt'
    chef.add_recipe 'cassandra::tarball'
    chef.add_recipe 'zookeeper'

    chef.json = {
      :cassandra => {
        :version => '1.1.5',
        :tarball => {
          :url => 'http://apache.cs.utah.edu/cassandra/1.1.5/apache-cassandra-1.1.5-bin.tar.gz',
          :md5 => 'ba4da3782923b8018023e9ae26111e4e',
        },
        :rpc_address => '0.0.0.0',
      },
    }
  end

  # the cassandra recipe apparently fails to start cassandra, so we help it
  config.vm.provision :shell, :inline => <<-SHELL
    sudo /etc/init.d/cassandra start
  SHELL
end
