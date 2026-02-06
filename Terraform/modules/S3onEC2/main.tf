# Run S3 on EC2 instances
# Concepts: lifecycle, depends_on

resource "aws_iam_role_policy" "S3OnEC2" {
  name   = "example"
  role   = aws_iam_role.example.name
  policy = jsonencode({
    "Statement" = [{
      # The policy allows software running on EC2 instance to
      # acc S3 API.
      "Action" = "s3:*",
      "Effect" = "Allow",
    }],
  })

  lifecycle {
    create_before_destroy = true # 0 downtime deploy
    ignore_changes = [] # prevent metadata being revert elsewhere
    prevent_destroy =  false # reject any plan to destroy this resource
  }
}

resource "aws_instance" "EC2w/S3" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"

  # TF can infer from this: instance profile must
  # be created before the EC2 instance.
  iam_instance_profile = "example"
  
  # However, if software running in this EC2 instance needs acc
  # to S3 API in order to boot properly, il y a also a "hidden"
  # depend. on the aws_iam_role_policy that Terraform cannot
  # automatically infer. Must decl. explicitly:
  depends_on = [
    aws_iam_role_policy.S3OnEC2
  ]
}