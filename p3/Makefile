all: install deploy

install:
	sudo ./scripts/init.sh

deploy:
	sudo ./scripts/deploy.sh

clean:
	sudo k3d cluster delete mfouadiCI

re: clean all

.PHONY: all install deploy clean re
