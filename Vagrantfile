Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'

  config.vm.provider 'virtualbox' do |vb|
    # Customize the amount of memory on the VM:
    # vb.memory = '1024'
    vb.name = 'Robert-VM'
  end
  config.vm.network 'private_network', type: 'dhcp'

  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provision 'file', source: '.', destination: '.env/rc'
  config.vm.synced_folder "#{ENV['HOME']}/Dev", '/home/ubuntu/Dev'

  config.vm.provision 'shell', privileged: false, inline: <<-SHELL
    sudo apt-get install -y build-essential git vim
    yes | $HOME/.env/rc/setup.sh
    source $HOME/.profile
    rvm install ruby
    gem install bundler
  SHELL
end
