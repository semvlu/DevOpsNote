terraform init

# preview changes 
terraform plan

# exec the plan
terraform apply

terraform apply -var "instance_name=appServer1"
# Or
-var-file="secret.tfvars"

terraform output

# get cur state & update
# update state w/o making changes to infra 
terraform refresh 
# a.k.a. terraform apply -refresh-only -auto-approve

terraform destroy
