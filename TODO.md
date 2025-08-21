
# p2
- add checks 
    - k3s installed
    - KUBECONFIG already in .zshrc


- Persistent Environment Variables within the Guest (Shell or File Provisioner):
To make environment variables available consistently within the guest machine, even after provisioning, they need to be written to a file that is sourced upon login or system startup.
a. Using a Shell Provisioner to write to /etc/profile.d/:
Code

``` ruby
Vagrant.configure("2") do |config|
  config.vm.provision :shell, inline: <<-SHELL
    echo 'export MY_PERSISTENT_VAR="my_persistent_value"' | sudo tee /etc/profile.d/myvars.sh
    echo 'export ANOTHER_PERSISTENT_VAR="another_persistent_value"' | sudo tee -a /etc/profile.d/myvars.sh
  SHELL
end
```
This creates a file in /etc/profile.d/ which is automatically sourced by many Linux distributions for interactive shells.