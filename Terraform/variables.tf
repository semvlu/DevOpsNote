variable "instance_name" {
  description = "EC2 instance name tag"
  type = string
  default = "ExampleAppServerInstance"
}

# Credentials: sensitive = true
variable "db_username" {
  description = "DB admin username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "DB admin password"
  type        = string
  sensitive   = true
}


# Combine var w/ local val
# Vide main.locals
variable "resource_tags" {
  description = "Tags to set for all resources"
  type = map(string)
  default = {}
}

variable "project_name" {
  type = string
  default = "proj1"
}

variable "environment" {
  type = string
  default = "dev"
}