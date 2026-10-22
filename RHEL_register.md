# RHEL new VM dnf setup
- Register & podman login registry.redhat.io -> username/password


```sh
dnf update redhat-release --nogpgcheck
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
dnf clean all
dnf update
```
