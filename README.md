# CI/CD

---

## Vagrant

### Key Components

- **Vagrantfile:** Configuration file for the environment.
- **Vagrant Box:** Base image for virtual machines.
- **Provider:** The virtualization backend (e.g., VirtualBox).

### Vagrant File

```ruby
Vagrant.configure("2") do |config|
# Box
    config.vm.box = "box name"
    config.vm.box_version = "box version"

# Provisioning
    # runs a provision using a predefined file
    config.vm.provision "shell", name: "install-dependencies", path: "instal-dependendcies.sh"
    # runs inline shell provision, the provision below will not `run` when running `vagrant up`
    # an be rerun with vagrant provision --provision-with inline-provision
    config.vm.provision "shell", name: "inline-provision", run: "never", inline: <<-SHELL
        docker compose restart
    SHELL

```

### What is Vagrant?

Vagrant is a tool by Hashicorp for isolating development environments, enabling teams to collaborate efficiently.

- **Providers:** Hypervisors such as VirtualBox, VMWare, etc.
- **Vagrantfile:** Essential for defining the environment.
- **Workflow:**
    1. **Scope:** Identify OS, tools, and dependencies needed.
    2. **Author:** Write the `Vagrantfile`.
    3. **Manage:** Use Vagrant commands to control the environment.
    4. **Share:** Distribute the `Vagrantfile` or packaged box for consistent setup.

---

### Common Commands

#### Initialize Environment

```bash
vagrant init [box_name] [box_url]
```
Initializes the environment. You can specify a box name and URL.

#### Start Environment

```bash
vagrant up
```
- Fetches the box from the registry (if not local).
- Configures the provider.
- Applies the configuration from the Vagrantfile.

#### Access Virtual Machine

```bash
vagrant ssh
```
- Sets up a secure SSH connection using an auto-generated key.

```bash
lsb_release -a
```
- Verify you are inside the guest machine.

```bash
logout
```
- Exit the guest machine.

---

### Manage Environment Lifecycle

- `vagrant suspend` — Save and pause the machine state.
- `vagrant resume` — Resume the suspended machine.
- `vagrant halt` — Gracefully power off the machine (clean state on next `up`).
- `vagrant destroy` — Remove the VM (does not delete the box).
- `vagrant box remove <box_name>` — Delete the box from your system.

---

### Provision development environment

> _You can automate software installation and configuration using provisioning scripts in your Vagrantfile (e.g., shell, Ansible, Puppet, etc.)._

#### Run Provisionning Scripts

```bash
vagrant up
```
This command inializes the enviroment and runs all provision scripts
If the machine already exists, the command will not run the provision

```bash
vagrant provision
```
Run provision scripts while the machine is running 

```bash
vagrant up --provision
```
If you want to force provision to be run on machine start up runs

---

### Share resources between host and guest machines

#### Configure port forwarding


```ruby
    Vagrant.configure("2") do |config|
        # some code
        config.vm.network "forwarded_port", guest: "8080", host: "8080"
        # some code
    end
```
Forwards the port from the guest machine to the host machine 

#### Enable Folder Synchronization

```ruby
    Vagrant.configure("2") do |config|
        config.vm.sync_folder "path_to_folder_on_host", "path_to_folder_on_guest", create: true
    end
```
Sync the folder in host machine with the one on the guest machine (somewhat like the logic in docker of volumes)

### Manage multi-machine environments

> _To simplify machine networking `libnss-mdns` and `avahi-daemon` can be installed on each machine

```bash
    # Destroy old machine, if it exists could cause conflicts
    vagrant destory
```

- Destroy the existing machine
- Create a script for installing common things that should exists in all VMs
- 


#### Example

```ruby
# Services Configuration Reference
SERVICES = {
  'backend' => {
    ip: '192.168.56.11',
    ports: { 8080 => 8080 }
  },
  'frontend' => {
    ip: '192.168.56.12',
    ports: { 8081 => 8081 }
  }
}

Vagrant.configure("2") do |config|
    # common configuration
    config.vm.box = "hashicorp-education/ubuntu-24-04"
    config.vm.box_version = "0.1.0"

    # Common provisioning script for all VMs
    config.vm.provision "shell", name: "common", path: "common-dependencies.sh"

    config.vm.define "frontend" do |frontend|
        frontend.vm.hostname = "frontend"
        frontend.vm.network "private_network", ip: SERVICES['frontend'][:ip]
        frontend.vm.network "forwarded_port", guest: 8080, host: 8080
        # frontend.vm.synced_folder ...
        
        frontend.vm.provision "shell", name: "start-frontend", inline: <<-SHELL
            #... some code
            
            # Get frontend IP dynamically (with 1 minute timeout)
            for i in {1..30}; do
                if BACKEND_IP=$(getent hosts backend.local | awk '{print $1}'); then
                break
                fi
                echo "Waiting for backend.local to be resolvable..."
                sleep 2
            done

            #... some code
            
            docker run -d -p 8081:8081 \
                --add-host backend.local:${BACKEND_IP} \
                frontend
        end
    end


end

```

--- 

## Creating an image

- Minimal ubuntu server
- port mapping for ssh
- passwordless sudo access
- apt update/upgrade/reboot
- install additional packages
- install guest additions
- customize files/config
- vagrant public key
- apt clean/autoremove
- truncate log files
- clean history

> **Note:**  
> Before packaging, make sure your VM is powered off and the name matches exactly as shown in VirtualBox.  
> If you get `VM not created. Moving on...`, check the VM name and that it is managed by VirtualBox.
>  
> **Vagrant needs the VM name `.vbox`.
> The VM name is usually the folder name in `~/VirtualBox VMs/` and as listed in VirtualBox Manager.  
> For example, if you see `~/VirtualBox VMs/ubuntu_24_server/ubuntu_24_server.vbox`, your VM name is `ubuntu_24_server`.

vagrant package --base ubuntu_24_server --output ubuntu_24_server.box
ls ~/VirtualBox\ VMs/

```bash
# List files in the VM directory to verify VM name
ls ~/VirtualBox\ VMs/

# Add vagrant user to sudoers with passwordless sudo
echo 'vagrant ALL=(root) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/vagrant

# Update package lists
sudo apt update

# Upgrade installed packages
sudo apt upgrade

# Reboot
sudo reboot

# Install useful packages
sudo apt install -y build-essential dkms linux-headers-$(uname -r) curl wget git vim bash-completion nano tree

# Install VirtualBox Guest Additions (after mounting the CD)
sudo /mnt/VBoxLinuxAdditions.run

# Zeroing disk for better compression 
sudo dd if=/dev/zero of=/empty bs=1M
sudo rm -f /empty

# Clean up apt cache and remove unnecessary packages
sudo apt autoremove -y
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*

# Truncate all log files
sudo find /var/log -type f -exec truncate -s 0 {} \;

# Add vagrant public key for SSH access
curl -L https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -o ~/.ssh/authorized_keys

# Clear bash history
history -c
history -w
```

---

## Global Vagrant Box config

```bash
sudo mkdir -p /opt/vagrant/boxes
sudo mv 'your_gzip_box' /opt/vagrant/boxes
sudo chmod 644  /opt/vagrant/box/'your_gzip_box'
cd /opt/vagrant/box/
vagrant box add 'desired_name_for_box' 'your_gzip_box'
# vagrant unpacks the box in ~/.vagrant.d/boxes
```


## Side Notes

### VirtualBox & Secure Boot (BIOS)

**Environment:**
- Ubuntu
- VirtualBox
- Secure Boot enabled in BIOS

During VirtualBox installation, a Machine Owner Key (MOK) is created. Set a password when prompted. On reboot, enter this password to sign kernel modules, allowing VirtualBox access.

To disable Kernel-based Virtual Machine (KVM) and give VirtualBox exclusive access to hardware virtualization:

```bash
sudo modprobe -r kvm_intel kvm
```
> _Note: KVM may reload after reboot._

---

## Further

- https://developer.hashicorp.com/vagrant/tutorials
- https://developer.hashicorp.com/vagrant/docs/provisioning/ansible
- https://kubernetes.io/docs/concepts/overview/
- https://kubernetes.io/docs/concepts/overview/components/
- https://kubernetes.io/docs/concepts/architecture/