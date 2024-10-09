ansible -i inventory.ini -u root -m ping <group> 
# <group> e.g. all, webservers, databases
# -u root: login to root

# Ad-hoc cmd: one-off cmd on CLI, not in playbook
ansible -i inventory.ini -u root <module> -a  "name=john state=present" -a
# -a: module args

# Run a playbook
ansible-playbook playbook.yml -i inventory.ini -u root

# Run tasks with spec tags
ansible-playbook playbook.yml -i inventory.ini -u root --tags=<tagname>
--tags=<tagname>
--skip-tags=<tagname>
