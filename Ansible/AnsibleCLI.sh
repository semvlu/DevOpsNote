# Ad-hoc cmd: one-off cmd on CLI, not in playbook
ansible <target> -m ping # return "pong"
# <target> e.g. all, webservers, databases

ansible <target> -i inventory.ini -u root -m ping 
# -u root: login to root

ansible -i inventory.ini -u root <module> -a  "name=john state=present"
# -a: module args

# Run a playbook
ansible-playbook playbook.yml -i inventory.ini -u root

# Run tasks with spec tags
ansible-playbook playbook.yml -i inventory.ini -u root --tags="<tagname>"
--tags="<tagname>"
--skip-tags="<tagname>"

# `sshpass` for VM as commander
sudo apt install sshpass
