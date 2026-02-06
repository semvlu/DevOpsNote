`terraform.tf`: terraform block, for backend, cloud, required_providers setup

`main.tf`: resource block, `for_each`, module calling

`variables.tf`: Def variable, sensitivity. Combine var w/ local val (vide locals in `main.tf`), static checking: custom validation rule

`terraform.tfvars`: Store secret variables, e.g. username, password. (vide variables.db_username / password).
> [!CAUTION]
> Do NOT upload `.tfvars` file to Github or VCS! 

```
terraform apply  -var-file="terraform.tfvars"
```
Will not adopt normally, secrets are put in during runtime, e.g.
```
terraform apply -var="db_username=username" -var="db_password=password"
```
`outputs.tf`: output info


`modules/S3onEC2`: Run S3 on EC2 instance. `lifecycle`, `depends_on`


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
