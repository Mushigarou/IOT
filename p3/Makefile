all:
	@if ! vagrant plugin list | grep -q vbguest; then vagrant plugin install vagrant-vbguest; fi
	vagrant up --no-provision
	sleep 10
	vagrant ssh -c "mkdir -p /home/vagrant/confs /home/vagrant/scripts"
	vagrant upload confs /home/vagrant/confs/
	vagrant upload scripts /home/vagrant/scripts/
	vagrant provision
	vagrant ssh -c "kubectl port-forward svc/will42 -n dev 9999:8085 &"

re: all
	echo "destroying Machine"
	vagrant destroy -f

.phony: all re