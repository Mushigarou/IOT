# Bare VM only: part 3 is installed from inside it by p3/run.sh.
VM_NAME = "k3d"
VM_IP   = "192.168.56.115"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"
  config.vm.box_check_update = false

  config.vm.define VM_NAME do |node|
    node.vm.hostname = VM_NAME
    node.vm.network "private_network", ip: VM_IP
    # Argo CD UI and the app.
    node.vm.network "forwarded_port", host: 8080, guest: 8080
    node.vm.network "forwarded_port", host: 10000, guest: 10000

    # Empty drop box, to hand files over during the defense.
    node.vm.synced_folder "~/#{VM_NAME}-shared", "/home/vagrant/shared", create: true

    node.vm.provider "virtualbox" do |v|
      v.name = VM_NAME
      v.memory = 4096
      v.cpus = 4
    end
  end
end
