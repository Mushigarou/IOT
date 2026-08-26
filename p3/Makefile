all: up

up:
	vagrant up

provision:
	vagrant provision

ssh:
	vagrant ssh

clean fclean:
	vagrant destroy -f

re: clean all

.PHONY: all up provision ssh clean fclean re
