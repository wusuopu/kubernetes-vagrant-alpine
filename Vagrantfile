# -*- mode: ruby -*-
# vi: set ft=ruby :

$num_instances = 3
$instance_name_prefix = "alpine"
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1
$vb_cpuexecutioncap = 100
ip_prefix = '172.18.8.'

# vagrant up --no-parallel
Vagrant.configure(2) do |config|
  (1..$num_instances).each do |i|
    config.vm.define vm_name = "%s-%02d" % [$instance_name_prefix, i] do |node|
      node.vm.hostname = vm_name

      ip = "#{ip_prefix}#{i+100}"
      # docker network create vagrant_network --subnet=172.18.8.0/24
      node.vm.network 'private_network', ip: ip, subnet: "#{ip_prefix}0/24"
      # vagrant up --provider=docker
      node.vm.provider :docker do |d|

        d.image = "wusuopu/vagrant:k3s-alpine"
        d.has_ssh = true
        d.create_args = ["--privileged"]
        d.env = {
          KUBE_MASTER_HOST_IP: "#{ip_prefix}101",
          KUBE_NODE_NUM: "#{i}"
        }
        d.volumes = [
          "#{Dir.getwd}/etc/docker-daemon.json:/etc/docker/daemon.json",
          "#{Dir.getwd}/tmp/var-docker-#{i}:/var/lib/docker"
        ]
      end

      node.ssh.shell = "sh -l"
      node.vm.provision :shell, path: "run.sh", args: [i, "#{ip_prefix}101"]
    end
  end
end
