# Ansible

- Collections in EX294: builtin, redhat.rhel-system-roles, ansible.posix
- `dnf install rhel-system-roles ansible-core`
- `command` over `shell`, `shell` only for I/O redir (`>`, `>>`, `2>`, `|`)


# Config File: `ansible.cfg`
 `ansible-config`
```sh
ansible-config init > ansible.cfg
ansible-config view path/to/ansible.cfg
```


default: `/etc/ansible/ansible.cfg`

`ansible.cfg` search order:
1. `ANSIBLE_CONFIG` env var
2. `./ansible.cfg` 
3. `~/.ansible.cfg` 
4. `/etc/ansible/ansible.cfg`

```conf
[defaults]

inventory = ./inventory.ini # default: ['/etc/ansible/hosts']
collections_path = ~/collections:/usr/share/ansible/collections
# `/etc/ansible/roles` @ head of entry 
roles_path = ~/roles:/usr/share/ansible/roles:/etc/ansible/roles
remote_user = ansible-user
private_key_file = ~/.ssh/ansible-mgmt
host_key_checking = false

[galaxy]
server = https://galaxy.ansible.com

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false

```

# Host Management


## Host Files

- default: `/etc/ansible/hosts`
- `ansible-inventory -i <hosts, inventory.ini> [--graph, --list]`

```ini
localhost ansible_connection=local # exec on control node / Ansible server itself

[databases]
db-[99:101]-node.example.com # 99-101, inclusive
server ansible_host=10.0.0.100 # Alias

[databases:vars]
ansible_user=admin
ansible_pasword=password
http_port=8080

[prod:children] # Nested group
databases
```

```yml
- name: Pattern matching for host groups
  hosts: a,b,&c,!d,!e 
```
- (a OR B) AND C AND (!d OR !e)
- `,` and `:`: concat, `&`: intersection, `!`: exclusion



# Playbook

- Exec playbook w/ abs path
- No need to mod file perm

## Code Check
```sh
ansible-playbook --syntax-check playbook.yml
ansible-playbook -C playbook.yml # dry-run (--check)
```


# Service

```yml
- name: install RPM Development Tools
  dnf:
    name: "@Development Tools" # @: pkg group
    state: present

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
`ansible.builtin.file` module
- state: "touch", "file", "directory", "absent", "hard", "link"
```yml
- name: File op
  hosts: all
  tasks:
  - name: Create file
    file:
      path: /tmp/file.txt
      state: touch
  - name: Append text
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

## `lineinfile`
- Check string, replace or delete
- Cf. `ansible.builtin.replace`: replace all matches

```yml
- name: Update GPCC TLS Cert config
  lineinfile:
    path: "{{ gpcc_conf }}"
    regexp: '^HTTPSCertFile'
    line: 'HTTPSCertFile       = {{ new_cert_file }}'
    state: present
  tags:
    - TLS

- name: Ensure group wheel not in sudoers
  lineinfile:
    path: /etc/sudoers
    state: absent
    regexp: '^%wheel'
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
  - name: start & enable httpd
    service:
      name: httpd
      state: started
      enabled: true

  - name: Open firewall port 80
    firewalld:
      service: http
      permanent: true
      immediate: true
      state: enabled

  - name: Redirect port 443 -> 8443 with Rich Rule
    firewalld:
      rich_rule: rule family=ipv4 forward-port port=443 protocol=tcp to-port=8443
      zone: public
      permanent: true
      immediate: true
      state: enabled

  - name: reload firewalld
    service: 
      name: firewalld
      state: reloaded
```



# Download from URL

```yml
- name: Download Tomcat using get_url
  get_url:
    url: https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.78/bin/apache-tomcat-8.5.78.tar.gz
    dest: /opt/tomcat
    mode: 0755
    group: root
    owner: root

```



# Cronjob

```yml
- name: Cronjob
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
  community.general.parted: 
    name: files
    label: gpt
    device: /dev/sdb
    number: 1
    state: present
    part_started: 1MiB # default: 0%
    part_end: 1GiB     # default: 100%
    fs_type: xfs

- name: Create mount dir
  file:
    path: /mnt/data
    state: directory

- name: Mount FS on dir
  ansible.posix.mount: 
    src: /dev/sdb1
    path: /mnt/data
    fstype: xfs
    opts: rw,sync # /etc/fstab <options>
    state: mounted
    
```



# User Mgmt

```yml
- name: Create user
  user:
    name: george
    # Groups config
    groups: admins,developers # Secondary group
    append: true
    password_expire_warn: 30
    password_expire_account_disable: 15

```



## Update password

- `vault.yml`: enc w/ `ansible-vault`

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
  ignore_errors: true
  shell: "ps -ef | grep top | awk '{print $2}'"
  register: running_proc

- name: Kill running proc
  ignore_errors: true
  shell: "kill {{ item }}"
  with_items: "{{ running_proc.stdout_lines }}"
```

# Repo Mgmt
```yml
- name: Add repo in /etc/yum.repos.d
  yum_repository:
    name: epel
    description: EPEL yum repo
    file: custom-repo
    baseurl: https://download.fedoraproject.org/pub/epel/$releasever/$basearch/
    gpgcheck: no
    enabled: true
```

# ACL
```yml
- name: Set default ACL on file for user alice
  ansible.posix.acl:
  path: path/to/file
  entity: alice
  etype: user
  permissions: rw
  state: present
  default: true
- name: Get ACL info
  acl:
    path: path/to/file
  register: file_acl_info

```

# Template
`index.html.j2`
```yml
FQDN: {{ ansible_facts['fqdn'] }}
IP: {{ ansible_facts['default_ipv4']['address'] }}
```

```yml
- name: template file for httpd
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
    mode: '0644'
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
ansible all -a "uptime" # w/o -m, `command` module (default)

# Gather facts
ansible all -m setup

# Delete a file
ansible all -m file -a "path=/data/file.txt state=absent"

# Install pkg
ansible all -m package -a "name=httpd state=present"


ansible all -m user -a "name=george state=absent"
ansible server1 -a "/sbin/reboot"
```

## Handler

- Special form of a Task, exec only when (AND)
  1. Notified by prev task which resulted in a "changed" status, 
  2. All tasks in a play are finished.
- `notify` & `name` of the handler be identical.

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



## Conditions
- Operator: `and`, `or`, `not`, `==`, `!=`, etc.
- Type conversion: filter `|`
```yml
- name: trigger task when cond meet
  debug:
    msg: "this is triggered when cond meet"
  when: ansible_facts['os_family'] == 'RedHat' and ansible_facts['cpu_temperature'] | float > 80
```



## Loop

- `loop: "{{ <list_var> }}", "{{ <dict_var> | dict2items}}"`
- `with_items: "{{ <list_var> }}"`

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
  - name: install pkg, since pkg allow multi args at once
    package:
      name: "{{ pkg }}"
      state: present

  - name: install pkg w/ item
    package:
      name: "{{ item }}"
      state: present
    loop: "{{ pkg }}"
    
  - name: create users & assign groups w/ list of dict
    user:
      name: "{{ item.name }}"
      group: "{{ item.group }}"
    with_items: "{{ users }}"
  
  - name: create users and assign groups w/ dict
    user:
      name: "{{ item.key }}"
      group: "{{ item.value }}"
    loop: "{{ users_dict | dict2items }}"

```



## Tag

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
ansible-playbook playbook.yml --vault-password-file <password-file>
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



# Ansible Facts
## Core System
- `['distribution']`: "Ubuntu", "CentOS", "RedHat"
- `['distribution_version']`
- `['os_family']`: "Debian", "RedHat", "Windows"
- `['kernel']`: kernel ver
- `['hostname']`
- `['fqdn']`
- `['architecture']`

## Network
- `['default_ipv4']['address']`:	Primary IPv4
- `['default_ipv4']['gateway']`
- `['default_ipv4']['interface']`
- `['all_ipv4_addresses']`
- `['interfaces']`

## HW
- `['memtotal_mb']`
- `['memfree_mb']`
- `['processor_vcpus']`
- `['processor_cores']`
- `['mounts']`
- `['devices']`: disks

## User & Env
- `['user_id']`: Remote user exec Ansible
- `['real_user_id]`: ibid, but uid
- `['env']['HOME']`	Home dir of remote user
- `['env']['PATH']`


# Magic Variables
- `hostvars`: list of facts for hosts, after gathered/cached facts (`gather_facts: true`) @ play lvl.
- `groups`: groups in inventory
- `group_names`: groups the current host belongs to.
- `inventory_hostname`, `inventory_hostname_short`: FQDN, short hostname conf-ed in inventory, alt to `ansible_hostname` when fact-gathering disabled.

```yml
{% for h in groups['all'] %}
  {{ hostvars[h]['ansible_facts']['default_ipv4']['address'] }}
{% endfor %}


- copy: 
    dest: /etc/issue
    # `>`: folded block scalar: \n into 1 space, multi-line -> single-line
    # `-`: strip chomping: strip all new lines @ end of the string
    content: >- 
    {% if 'dev' in group_names %}Development
    {% elif 'test' in group_names %}Test
    {% elif 'prod' in group_names %}Production
    {% endif %}
  when: "'dev' in group_names or 'test' in group_names or 'prod' in group_names"
  # Equiv: 
  when: inventory_hostname in groups['dev'] or inventory_hostname in groups['test'] or inventory_hostname in groups['prod']
```


# Error Handling
- `block`, `rescue`, `always`: try/catch/anyways
- `force_handlers`: exec `handlers` even on error
- `any_errors_fatal`: abort on error, @ play / block lvl. 

> [!WARNING] 
> Priority: `rescue` & `always` > `abort_errors_fatal` > `force_handlers`

```yml
tasks:
- name: Handle the error

  block:
  - name: Print a message
    debug:
      msg: 'Normal exec'
  - name: Force a failure
    command: /bin/false
  - name: Never exec
    debug:
      msg: 'Never exec due to error'
  
  rescue:
  - name: Print when errors
    debug:
      msg: 'Catch error'
    
  always:
  - name: Always do
    debug:
      msg: 'I do it anyways, no matter what'

```

## Def Failure
- `failed_when`
- `changed_when`: `command` or `shell` reports task status as "changed" no matter what, which breaks idempotency. This def what a real "change" is.
- `ignore_errors`: skip error, not trig `rescue` block


```yml
- name: Combine multi cond to override 'changed' result
  command: /bin/fake_command
  register: result
  ignore_errors: True
  changed_when: '"ERROR" in result.stderr' and result.rc == 2 # rc: return code
```




# `ansible-doc`

```sh
ansible-doc -l <collection (opt)> # ansible.builtin, ansible.posix, etc.
ansible-doc <module> # file
ansible-doc -s <module> # snippet
```



# [`ansible-galaxy`](https://galaxy.ansible.com)

- Install Roles & Collections

```sh
ansible-galaxy role
ansible-galaxy init <role> --init-path /path/to/roles # init a role

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


# `ansible-navigator`
```sh
ansible-navigator run playbook.yml -m stdout	# Run playbook w/o TUI
ansible-navigator doc <module>	# Container-aware equiv. of ansible-doc
ansible-navigator collections
```

`project/ansible-navigator.yml`
```yml
ansible-navigator:
  execution-environment:
    image: registry.example.com/ee-supported-rhel9:latest # Image provided in exam prompt
    pull:
      policy: missing # Crucial: Exam env are offline/firewalled

  mode: stdout # -m stdout
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
2. Managed node: install git, ansible
3. Test: `ansible-pull --url https://github.com/<user>/<repo>/playbook.yml`
4. Config cronjob:
  ```sh
  crontab -e
  0 0 * * * /usr/bin/ansible-pull --url https://github.com/<user>/<repo>/playbook.yml >> /var/log/ansible-pull.log 2>&1
  ```


# `rhel-system-roles`
- Ref: `/usr/share/ansible/roles/rhel-system-roles.<role>/README.md`

```yml
- name: 
  hosts: all
  roles: 
  - role: rhel-system-roles.timesync
    vars:
      timesync_ntp_servers:
      - server: 172.25.254.250
        iburst: true
        pool: false
```


# Create & Distribute SSH Key to Managed Hosts
```sh
ssh-keygen
ssh-copy-id ansible-user@managed-host
```