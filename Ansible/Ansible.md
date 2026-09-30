# Ansible

- Collections in EX294: builtin, redhat.rhel_system_roles, ansible.posix

# CLI

```sh
ansible-playbook --syntax-check playbook.yml
ansible-playbook -C playbook.yml # dry-run (--check)
```

# Coding Style

- `command` over `shell`, `shell` only for I/O redir
- `ansible-galaxy init`: install roles

# Config Files

`/etc/ansible/ansible.cfg`

```conf
[defaults]
inventory = ./inventory
remote_user = automationuser
roles_path = ./roles
collections_path = ./collections
host_key_checking = false

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false

```

`/etc/ansible/hosts`
`/etc/ansible/roles`

# Host Management



## Host Files

`/etc/ansible/hosts`
`ansible-inventory -i <hosts, inventory.ini> [--graph, --list]`

```ini
localhost ansible_connection=local # exec on control node / Ansible server itself

[databases]
db-[99:101]-node.example.com # 99-101, inclusive
server ansible_host=10.0.0.100 # Alias

[databases:vars]
ansible_user=admin
ansible_pasword=password
http_port=8080
```

```yml
- name: Pattern matching for host groups
  hosts: a,b,&c,!d,!e 
  # (a OR B) AND C AND (!d OR !e)
  # `,` and `:`: concat, `&`: intersection, `!`: exclusion
```



# Playbook

- Exec playbook w/ abs path
- No need to mod file perm



# Service

```yml
- name: service module
  hosts: all
  tasks:
  - name: install/uninstall apache
    package:
     name: httpd
     state: present | absent

  - name: start httpd
    service:
     name: httpd
     state: started | restarted | stopped | reloaded
     enabled: true
```



# File Op

```yml
- name: File op
  hosts: localhost
  tasks:
  - name: create file
    file:
      path: /tmp/file.txt
      state: touch
  - name: append text
    blockinfile: 
      path: /tmp/file.txt
      block: |
        add this line to the file
        add this for a new line

  - name: Create directory
    file: 
      path: /tmp/dir1
      owner: admin
      group: admin
      mode: 777
      state: directory

  - name: file stat
    stat:
      path: /tmp/file.txt
    register: stat
  - debug:
      msg: "{{ stat }}"

  - name: Copy file 
    become: true
    copy:
     src: /tmp/file.txt
     dest: /opt
     owner: admin
     group: admin
     mode: 0644
     remote_src: true | false # true: on managed host, false (default): on control node
     
  - name: Symlink
    file:
      src: /file/to/link/to
      dest: /path/to/symlink
      state: link
  - name: 2 hard links
    file:
      src: '/tmp/{{ item.src }}'
      dest: '{{ item.dest }}'
      state: hard
    loop:
      - { src: file1, dest: link1 }
      - { src: file2, dest: link2 }
```



## `lookup`

- Plugin to retrieve data from external sources
- Exec & evaluated on Control Node
- args: `plugin name`, `source`, `wantlist=false`
- `wantlist=True` = `query('<plugin>', '<source>')`: return a list

```yml
vars: 
  secret: "{{ lookup('file', '/path/to/secret.txt') }}"
  envvar: "{{ lookup('env', 'HOME') }}"
  date: "{{ lookup('pipe', 'date +%Y-&m-%d') }}"
  content: "{{ lookup('url', 'https://example.com/') }}"

```



# Firewall

`ansible-galaxy collection install ansible.posix`

```yml
- name: install & start httpd, open firewall port
  hosts: all
  tasks:
  - name: install httpd
    dnf:
      name: httpd
      state: present
  - name: start httpd
    dnf:
      name: httpd
      state: started
  - name: open firewall port 80
    firewalld:
      service: http
      permanent: true
      state: enabled
  - name: reload firewalld
    service: 
      name: firewalld
      state: reloaded
  - name: Redirect port 443 -> 8443 with Rich Rule
    firewalld:
      rich_rule: rule family=ipv4 forward-port port=443 protocol=tcp to-port=8443
      zone: public
      permanent: true
      immediate: true
      state: enabled
```



# Download from URL

```yml
- name: Download Tomcat using get_url
  get_url:
    url: https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.78/bin/apache-tomcat-8.5.78.tar.gz
    dest: /opt/tomcat
    mode: 0755
    group: iafzal
    owner: iafzal

```



# Cronjob

```yml
- name: cronjob
  cron:
    name: This job is scheduled by Ansible
    minute: 0
    hour: 10
    day: "*"
    month: "*"
    weekday: 4
    user: root
    job: "path/to/script.sh"
```



# Mount Storage

`ansible-galaxy collection install ansible.posix community.general`

```yml
- name: Create partition & FS
  parted: 
    name: files
    label: gpt
    device: /dev/sdb
    number: 1
    state: present
    part_started: 1MiB # default: 0%
    part_end: 1GiB # default: 100%
    fs_type: xfs

- name: Create mount dir
  file:
    path: /mnt/data
    state: directory

- name: Mount FS on dir
  mount: 
    src: /dev/sdb1
    path: /mnt/data
    fstype: xfs
    opts: rw,sync # /etc/fstab <options>
    state: mounted
    
```



# User Mgmt



## Create user

```yml
- name: Create user
  user:
    name: george
    # Groups config
    groups: admins,developers # Secondary group
    append: yes
    password_expire_warn: 30
    password_expire_account_disable: 15

```



## Update password

- `vault.yml`: enc w/ ansible-vault

```sh
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --extra-vars newpassword=password1234
```

```yml
- name: Change user password
  vars_files:
  - vault.yml
  tasks: 
  - name: Change password
    user: 
      name: george
      password: "{{ newpassword | password_hash('sha512') }}"
```



# Kill Process

```yml
- name: Get running proc from remote host
  ignore_errors: yes
  shell: "ps aux | grep top | awk '{print $2}'" # or ps -ef
  register: running_proc

- name: Kill running proc
  ignore_errors: yes
  shell: "kill {{ item }}"
  with_items: "{{ running_proc.stdout_lines }}"
```



# Task Control

```sh
ansible-playbook playbook.yml --start-at-task '<task-name>'
```



## Ad-Hoc Commands

- Scenario: test connectivity, create/delete a file, install packages

`ansible [target] -m [module] -a "[module options]"`

```sh
# Test Connectivity
ansible all -m ping
ansible all -a "uptime" # w/o -m, default to `command` module

# Gather facts
ansible all -m setup

# Delete a file
ansible all -m file -a "path=/data/file.txt state=absent"

# Install pkg
ansible all -m package -a "name=httpd state=present"


ansible all -m user -a "name=george state=absent"
ansible server1 -a "/sbin/reboot"
```



# Handler

- Special form of a Task, exec only when notified by a prev task which resulted in a "changed" status, and all tasks w/in a play are finished.
- `notify` & `name` of the handler must be the same.

```yml
tasks:
- name: Open firewall port 80
  firewalld:
    service: http
    permanent: true
    state: enabled
  notify:
  - Reload firewalld
 
- name: Ensure firewalld is running
  service:
    name: firewalld
    state: started

handlers:
- name: Reload firewalld
  service:
    name: firewalld
    state: reloaded

```



# Conditions

```yml
- name: trigger task when cond met
  debug:
    msg: "this is triggered when cond met"
  when: ansible_facts['os_family'] == 'RedHat'




```



# Loop

- `loop: "{{ <list_var> }}", "{{ <dict_var> | dict2items}}"`
- l

```yml
- name: Loop examples
  hosts: localhost
  vars:
    # list
    pkg: [httpd, nfs-utils, ftp] 

    # list of dict
    users:
    - { name: 'alice', group: 'admin' }
    - { name: 'bob', group: 'developers' }

    # dict
    user_dict:
      alice: admin
      bob: developers

  tasks:
  - name: install pkg
    package:
      name: "{{ pkg }}"
      state: present

  - name: install pkg w/ item
    package:
      name: "{{ item }}"
      state: present
    loop: "{{ pkg }}"
    
  - name: create users and assign their groups w/ list of dict
    user:
      name: "{{ item.name }}"
      group: "{{ item.group }}"
    with_items: "{{ users }}"
  
  - name: create users and assign their groups w/ dict
    user:
      name: "{{ item.key }}"
      group: "{{ item.value }}"
    loop: "{{ users_dict | dict2items }}"

```



# Tag

- Ref / alias for a task
- Spec in command:

```sh
ansible-playbook playbook.yml --list-tags
--tags tag1,tag2
--tags all
--tags [tagged | untagged]

--skip-tags tag3,tag4
```



# Ansible Vault

```sh
ansible-vault [crate | edit | view | encrypt | decrypt | rekey] playbook.yml
ansible-playbook playbook.yml --ask-vault-pass
```



## Encrypt String

```sh
ansible-vault encrypt_string <plaintext>

# If multi encrypted strings with different passwords
# Create password files 
touch .vault_pass1 .vault_pass2
ansible-playbook playbook.yml --vault-password-file .vault_pass1 --vault-password-file .vault_pass2
```

```yml
- name:
  hosts: localhost
  vars:
    plaintext: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          30373466323730323434343731653031396233333462613261313034646139643866353962356338
          3936666661303435643066646635633665663134373331610a373865353137663661646361396335
          34343662306135376164373161393832633039633731623966393234343334363030326564343131
          6239353336336333360a623531626561613335626439383466313162396663643735376339313835
          3339
  tasks:
  - name: print encrypted string
    debug:
      var: plaintext
```



# `ansible-config`

```sh
ansible-config list
ansible-config view <ansible.cfg>
```



# `ansible-doc`

```sh
ansible-doc -l <collection (opt)> # ansible.builtin, ansible.posix, etc.
ansible-doc <module> # file
ansible-doc -s <module> # snippet
```



# `[ansible-galaxy](https://galaxy.ansible.com)`

- Install Roles & Collections

```sh
ansible-galaxy role

ansible-galaxy collection [install | list]
ansible-galaxy collection install -r requirements.yml -p /path/to/collections
```

`requirements.yml`

```yml
roles:
- src: git+https://bitbucket.org/willthames/git-ansible-galaxy
  version: v1.4

collections:
- name: ansible.posix
  version: 2.2.2

- src: https://github.com/bennojoy/nginx

```

`ansible.cfg`

```conf
# `/etc/ansible/roles` @ head of entry 
[defaults]
roles_path = /etc/ansible/roles:<other_paths>

[galaxy]
server_list = automation_hub

[galaxy_server.automation_hub]
url = https://internal-exam-server.example.com/api/galaxy/
```



# `ansible-navigator`

```sh
ansible-navigator doc <module>	# Container-aware equiv. of ansible-doc
ansible-navigator run <file> -m stdout	# Run playbook w/o TUI
```



# `ansible-pull`

- Managed host pull playbooks from VCS repo, runs locally against `localhost`
- Inversion of Ansible default "push" arch

1. Create repo & upload playbooks

```yml
- name: client self-config
  hosts: localhost
  tasks: ...
```

1. Managed node: install git, ansible
2. Test: `ansible-pull --url https://github.com/<user>/<repo>/playbook.yml`
3. Config cronjob:

```sh
crontab -e
0 0 * * * /usr/bin/ansible-pull --url https://github.com/<user>/<repo>/playbook.yml >> /var/log/ansible-pull.log 2>&1
```

