ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

USERNAME = 'ubuntu'
DEVICE = 'enp3s0'
BRIDGE = 'virbr0'
DISKSIZE = '30G'
DISKPATH = '/media/STORAGE/VM'
IMAGE = 'generic/ubuntu2204'
MACADDR = 'RANDOM'
AUTOCONF = 'off'
SERVERIP = ''
DNS0IP = '192.168.122.1'
DNS1IP = ''
GATEWAYIP = '192.168.122.1'
NETMASK = '255.255.255.0'

nodes = {
  'mycluster-cp1' => [2, 2048, '192.168.122.191'],
  'mycluster-cp2' => [2, 2048, '192.168.122.192'],
  'mycluster-cp3' => [2, 2048, '192.168.122.193'],
  'mycluster-w1' => [1, 2048, '192.168.122.194'],
  'mycluster-w2' => [1, 2048, '192.168.122.195'],
  'mycluster-w3' => [1, 2048, '192.168.122.196'],
#  'mycluster-w4' => [1, 2048, '192.168.122.197'],
}

Vagrant.configure("2") do |config|
  config.vm.box = "#{IMAGE}"
  config.vm.host_name = "#{USERNAME}"

  config.vm.provision 'file', source: '~/.ssh/id_rsa.pub', destination: '/tmp/id_rsa.pub'
  config.vm.provision 'file', source: './hosts', destination: '/tmp/hosts'

  config.vm.provision 'shell', privileged: true, inline: <<-SCRIPT
    sudo swapoff -a
    sudo sed -i '/swap/d' /etc/fstab
    sudo echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
    sudo chmod 440 /etc/sudoers.d/ubuntu
    sudo apt-get update
    useradd -m #{USERNAME} --groups sudo
    su -c "printf 'cd /home/#{USERNAME}\nsudo su #{USERNAME}' >> .bash_profile" -s /bin/sh vagrant
    sudo -u #{USERNAME} mkdir -p /home/#{USERNAME}/.ssh
    sudo -u #{USERNAME} cat /tmp/id_rsa.pub >> /home/#{USERNAME}/.ssh/authorized_keys
    sudo chsh -s /bin/bash #{USERNAME}
    sudo cp /tmp/hosts /etc/hosts
  SCRIPT
  
  nodes.each do | (name, cfg) |
    cpus, memory, ip = cfg
    
    config.vm.define name do |node|
      node.vm.hostname = name
      node.ssh.insert_key = false
      
      node.vm.network :public_network,
        :dev => BRIDGE,
        :mode => 'bridge',
        :type => 'bridge',
        :ip => ip,
        :netmask => NETMASK,
        :dns => DNS0IP,
        :gateway => GATEWAYIP,
        :keep => true

      node.vm.provider :libvirt do |libvirt|
        libvirt.host_device_exclude_prefixes = ['docker', 'macvtap', 'vnet']
        libvirt.management_network_keep = true
        libvirt.driver = 'kvm'
        libvirt.default_prefix = ''
        libvirt.host = ''
        libvirt.cpu_mode = 'host-passthrough'
        libvirt.graphics_type = 'none'
        libvirt.video_type = 'none'
        libvirt.nic_model_type = 'virtio'
        libvirt.cpus = cpus
        libvirt.memory = memory
        libvirt.disk_bus = 'virtio'
        libvirt.disk_driver :cache => 'writeback'
        libvirt.autostart = true
        libvirt.storage_pool_name = "VM"
        libvirt.storage_pool_path = DISKPATH
      end
    end
  end
end
