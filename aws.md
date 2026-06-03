# Init & Setup
Config files: `~/.aws/config`

Login
```
aws sso login --sso-session <session>
aws sts get-caller-identity --profile <profile>
export AWS_PROFILE="<profile>"
aws sso logout
```

Setup
```
aws configure sso
    us-west-2
```

## VPC
- CIDR
- AZs
- Private subnets
- Public subnets
- NAT GW

$$
\begin{laligned}
X: subnet \ set, x \in X \\
Y: AZ \ set, y\in Y \\
F: X \rightarrow Y \\
y = f(x)
\end{laligned}
$$

### Security Group
`from_port` & `to_port`: def. range of ports
Protocol: `-1` for all 
