VAGRANT := vagrant

HOST_CONFS_PATH := ./confs
HOST_SCRIPTS_PATH := ./scripts

GUEST_CONFS_PATH := /home/vagrant/confs
GUEST_SCRIPTS_PATH := /home/vagrant/scripts


define uploadFilesToVM
	$(eval FROM := $(1))
	$(eval TO := $(2))
	@echo Copying from ${FROM} to ${TO}
	
	if [ -d ${FROM} ]; \
		then ${VAGRANT} upload ${FROM} ${TO}; \
		else echo "No $(FROM) path, skipping"; \
	fi
endef


all: up createDir sync provision

up:
	$(VAGRANT) up --no-provision
	sleep 10

createDir:
	$(VAGRANT) ssh -c "mkdir -p $(GUEST_CONFS_PATH) $(GUEST_SCRIPTS_PATH)"

sync:
	@$(call uploadFilesToVM, ${HOST_CONFS_PATH}, ${GUEST_CONFS_PATH})
	@$(call uploadFilesToVM, ${HOST_SCRIPTS_PATH}, ${GUEST_SCRIPTS_PATH})

provision:
	$(VAGRANT) provision

clean:
	@echo "destroying Machine"
	$(VAGRANT) destroy

fclean:
	@echo "destroying Machine"
	$(VAGRANT) destroy -f

re: clean all

.PHONY: all up createDir sync provision clean fclean re