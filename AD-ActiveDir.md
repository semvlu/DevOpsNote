# AD (Active Directory)

- Domain: logical group of net obj that share the same AD
- DN (Distinguished Name): Full name to identify something, consists of CN, OU, DC
  - CN (Common Name)
  - OU (Org Unit): containers w/in a domain, organise obj, apply Group Policy (GPO)   
  - DC (Domain Controller): server which holds AD, auth mgmt, usually match website domain, e.g. DC=example,DC=com
- GPO (Group Policy): apply config & sec settings w/in the domain
- Trusts: inter-domain relation to acc
- Forest: 1+ AD domains, share common schema and global catalog. Top-level container in AD, boundary for sec policy and schema extension. 
- Forest Root Domain: 1e domain in a forest, other domains are linked by trust relations. 
- Schema: def types of obj, e.g. users, groups, printers, etc. that exist in AD
Global Catalog: distributed data store, contains partial replica of all obj in AD Forest
- Replication: proc, info in AD DB is copied b/w DC, sync DCs
- ADFS: Federation/SSO serv. win env

# Rancher AD Config

Create new AD user qua service account for Rancher. 

- Perm: LDAP search, read attr of Users and Groups under AD domain.

Self-signed Cert for AD: `.pem`

Rancher UI: User & Auth -> Auth Provider -> Active Directory

Service Account DN & User Search Base

- Check Remote Desktop: AD Users and Computers -> User -> Attribute editor -> distinguishedName

`ldapsearch`

```
cd "C:\OpenLDAP\ClientTools"

ldapsearch -x -H ldap://<ip>:<port> \
-D "bind@testdomain.local" \
-w "password" \
-b "dc=testdomain,dc=local" 
"sAMAccountName=bind"
```

```
-D: BindDN: username
-b: BaseDN: search base
-s sub: # Subtree: recursive search under BaseDN
"sAMAccountName=bind": Search Query
```

LDAP Filtre: 
`|`: OR, `&`: AND

```
(|
(memberOf=CN=developers,OU=test,DC=exampe,DC=com)
(memberOf=CN=sales,OU=biz,DC=example,DC=com)
)
```