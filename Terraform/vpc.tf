locals {
  required_tags = {
    project = var.project_name
    environment = var.environment
  }
  tags = merge(var.resource_tags, local.required_tags)
}

locals {
  name_suffix = "${var.project_name}-${var.environment}"
}
# Module: Multi resource config
module "vpc" {
  count = 5
  source = "terraform-aws-modules/vpc/aws"
  # local: dir loc
  # github: URL
  version = "2.66.0"

  # Input var
  # vide locals
  name = "vpc-${local.name_suffix}" 
  tags = local.tags

}