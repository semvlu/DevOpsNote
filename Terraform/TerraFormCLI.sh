terraform init

# check config syntax & internal consistency
terraform validate

# Static checking
terraform fmt # check format & apply changes
terraform fmt -check # check format only

# preview changes 
terraform plan

# exec the plan
terraform apply
terraform apply -var="instance_name=appServer1" -var="short_var=foo"
# Or
-var-file="secret.tfvars"

# get cur state & update
# update state w/o making changes to infra 
terraform apply -refresh-only

terraform output

terraform destroy

terraform state list # list deployment
terraform show # detail
# moves resources from one state file to another
terraform state mv -state-out=<statefile>.tfstate <resource-type>.<resource-label>

# Terraform workspace (cf. File Structure method)
terraform init
terraform workspace list 
terraform workspace new <workspaceName>
terraform workspace select <workspaceName>
