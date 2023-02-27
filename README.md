## Kubernetes with kubeadm and QEMU/KVM on Ubuntu

If you have a decent multi-core CPU with enough RAM running Ubuntu there's no reason not to use it for your Kubernetes home lab instead of a cloud service.

You should already have [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) and [QEMU/KVM](https://www.tecmint.com/install-qemu-kvm-ubuntu-create-virtual-machines) setup and an ssh key created using `ssh-keygen -t rsa`.

First thing you need to do is make sure you have a virtual bridge. In Ubuntu 22.04 you should already have one called `virbr0`.

```sh
$ ip link show type bridge
$ ip addr show virbr0
5: virbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
    link/ether 52:54:00:c3:12:65 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
        valid_lft forever preferred_lft forever
```

If you don't have a bridge set up you can create one manually (assuming `enp3s0` is your ethernet interface name):

```sh
$ sudo ip link set enp3s0 up
$ sudo ip link add virbr0 type bridge
$ sudo ip link set enp3s0 master virbr0
$ sudo ip address add dev virbr0 192.168.122.1/24
```

You can see our static address range is `192.168.122.1/24`. So let's add some host names to our `/etc/hosts`

```
192.168.122.191 mycluster-cp
192.168.122.191 mycluster-cp1
192.168.122.192 mycluster-cp2
192.168.122.193 mycluster-cp3
192.168.122.194 mycluster-w1
192.168.122.195 mycluster-w2
192.168.122.196 mycluster-w3
192.168.122.197 mycluster-w4
```

## Infrastructure as Code (IaC)

Install [Vagrant](https://developer.hashicorp.com/vagrant/docs/installation) and create a [Vagrantfile](https://developer.hashicorp.com/vagrant/docs/vagrantfile) like below:

```vagrantfile
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
```

Run the following command to provision the VMs' in QEMU/KVM

```sh
$ vagrant up
```

## Bootstrapping the Cluster

It should be as simple as editing `hosts.ini`

```ini
[control_plane]
mycluster-cp1 ansible_host=192.168.122.191
mycluster-cp2 ansible_host=192.168.122.192
mycluster-cp3 ansible_host=192.168.122.193

[workers]
mycluster-w1 ansible_host=192.168.122.194
mycluster-w2 ansible_host=192.168.122.195
mycluster-w3 ansible_host=192.168.122.196
#mycluster-w4 ansible_host=192.168.122.197

[all:vars]
ansible_python_interpreter=/usr/bin/python3
interface=eth1
cp_endpoint_ip=192.168.122.191
cp_endpoint=mycluster-cp
k8s_version=1.26.0
pod_network_cidr=172.16.0.0/16
service_cidr=10.96.0.0/12
#cri_socket=unix:///var/run/crio/crio.sock
cri_socket=unix:///run/containerd/containerd.sock
#cri_socket=unix:///var/run/cri-dockerd.sock
```

Then run the `bootstrap.sh` script:

```sh
$ ./bootstrap.sh
```

By default it will install `containerd` CRI but it also includes scripts for installing `cri-o` and `docker` (just uncommment the appropriate `cri_socket` variable in the `hosts.ini` script).

## Source Code

All the source code to this project is available at https://github.com/benbaker76/k8s-cluster

This concludes the tutorial and thanks for reading!

[![Shop Now](images/shopnow.png)](https://www.teepublic.com/t-shirt/40083218-pixelated-kubernetes)
