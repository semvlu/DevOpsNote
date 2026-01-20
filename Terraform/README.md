`main.tf`: terraform block, for backend, cloud, and required_providers setup

`resource.tf`: resource block, for_each

`variables.tf`: Def variable, sensitive. Combine var w/ local val (vide `vpc.locals`), static checking: custom validation rule

`secret.tfvars`: store secret variables, e.g. username, password. (vide variables.db_username / password).
```
terraform apply  -var-file="secret.tfvars"
```
Will not adopt normally, secrets are put in during runtime, e.g.
```
terraform apply -var="db_username=username" -var="db_password=password"
```
`outputs.tf`: output info

`vpc.tf`: module, local (merge variables)

`S3onEC2.tf`: Run S3 on EC2 instance. Lifecycle, depends_on


## Multi Env Mgmt: Dev, Staging, Prod

### Terraform workspace
Pros: 
- easy, use: `terraform workspace` cmd
- min code dup

Cons:
- prone to human error
- state stored w/in same backend
- codebase not showing deploy config unambiguous

### File structure
Pros:
- backend isolation: security, human error decr
- codebase fully represents deploy state

Cons:
- duplicated codes
- require many `terraform apply`
