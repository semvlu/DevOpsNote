sudo adduser <username> 
sudo usermod -aG sudo <username>

# set user as sudo
# 1. Enter root
sudo su - # or: sudo su - root
# 2. Enter password

# 3. Edit sudoers file
nano /etc/sudoers
<usernmae> ALL=(ALL)  ALL

# save and exit
Ctrl+X

# read kernel buffer failed operation not permitted
sudo sysctl kernel.dmesg_restrict=0
kernel.dmesg_restrict = 0

# dmesg
dmesg | grep -i error