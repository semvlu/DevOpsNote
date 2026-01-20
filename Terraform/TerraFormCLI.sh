terraform init

# check config syntax & internal consistency
terraform validate

# preview changes 
terraform plan

# exec the plan
terraform apply

terraform apply -var="instance_name=appServer1" -var="short_var=foo"
# Or
-var-file="secret.tfvars"

terraform output

# get cur state & update
# update state w/o making changes to infra 
terraform refresh 
# a.k.a. terraform apply -refresh-only -auto-approve

terraform destroy

terraform state list # list deployment
terraform show # detail
# moves resources from one state file to another
terraform state mv -state-out=<statefile>.tfstate <resource-type>.<resource-label>


:'
Multi ENV MGNT: Dev, Staging, Prod

Terraform workspace:
+
    easy
    use: terraform workspace cmd
    min code dup
-
    prone to human error
    state stored w/in same backend
    codebase not showing deploy config unambiguous

File structure:
+
    backend isolation
        security
        human error decr
    codebase fully represents deploy state
-
    duplicated codes
    require many terraform apply 
'
# Terraform workspace (cf. File Structure method)
terraform init
terraform workspace list 
terraform workspace new <workspaceName>
terraform workspace select <workspaceName>



# Static checking
terraform fmt # check format & apply changes
terraform fmt -check # check format only





