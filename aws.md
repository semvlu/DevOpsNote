# Init & Setup

Config files: `~/.aws/config`

## Login

```sh
aws sso login --sso-session <session>
aws sts get-caller-identity --profile <profile>
export AWS_PROFILE="<profile>"
aws sso logout
```

profile: sem-dev

## Setup

```sh
aws configure sso
    us-west-2
```

## Session Timeout

```
Error: Retrieving AWS account details:... StatusCode: 403... ExpiredToken: The security token included in the request is expired
```

`aws configure`: Prompt for: access key ID, secret access key, session token



```sh
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value, InstanceId:InstanceId, PublicIP:PublicIpAddress, PrivateDNS:PrivateDnsName}" \
  --output table
```

