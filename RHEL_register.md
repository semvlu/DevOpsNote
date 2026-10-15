# RHEL Register & podman login registry.redhat.io -> username/password

# New provisioned VM dnf upgrade
```sh
dnf update redhat-release --nogpgcheck
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
dnf clean all
dnf update
```