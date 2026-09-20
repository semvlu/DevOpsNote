# AWS Solution Atchitect - Associate

# IAM

- Root account should not be used or shared.
- Create users & groups.
- A user can be in multi groups.
- Group contains users only.

## Policy

[Policy Generator](https://awspolicygen.s3.amazonaws.com/policygen.html)

- JSON file qua policy imposed on Users or Groups
- Def perm

```json
{
  "Version": "2012-10-17", // Standard policy version, always 2012-10-17
  "Id": "optional-001",
  "Statement": [
      {
          "Sid": "Statement id, optional",
          "Effect": "Allow", // Allow or Deny
          "Principal": {  // account/user/role to which the policy applied to
              "AWS": ["arn:aws:iam::123456789012:root"]
          },
          "Action": [
              "s3:GetObject",
              "s3:PutObject"
          ],
          "Resource": ["arn:aws:s3:::mybucket/*"] // list of resources to which the actions applied to
      }
  ]
}
```



### Condition

```json
{
  "Statement": [
    {
      "Condition": {
        "NotIpAddress": {
          "aws:SourceIp": ["192.168.2.0/24"]
        },
        "StringEquals": {
          // Restrict region
          "aws:RequestedRegion": ["ec-central-1", "eu-west-1"],
          // Tags
          "ec2:ResourceTag/Project": "Analytics",
          "aws:PrincipalTag/Department": "Data",
          // Limit acc to Org
          "aws:PrincipalOrgID": ["o-1234567890"]
        },
        "BoolIfExists": {
          // MFA
          "aws:MultiFactorAuthPresent": false
        }
      }
    }
  ]
}
```



### S3 Bucket & Object Lvl Perm

- Bucket: `"s3:ListBucket"`, `"arn:aws:s3:::test"`
- Obj: `"s3:[Get, Put, Delete]Object"`, `"arn:aws:s3:::test/*"`

## IAM Role vs. Resource-Based Policy

- IAM Role: Role perm over original perm
- Resourced-based policy: principal does not have to give up perm
- EventBridge Rule perm on target
  - Resource-based: S3, Lambda, SQS, SNS, API Gateway
  - IAM Role: Kinesis, EC2 ASG, ECS



## Role

IAM Entity for AWS services to perform actions on your behalf w/ Roles, e.g. EC2 Inst Role, Lambda Function Role

## Organization

- Global service, mng multi AWS accounts
- Account type: Management / Member
- Member can only be in 1 Org
- Consolidated billing across accounts, $ benefit from aggregated usage
- Shared Reserved Inst, Saving Plans



### OU: Organizational Unit

- Root: Management Account
- Hierarchical structure



### [SCP: Service Control Policy](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_evaluation.html#strategy_using_scps)

- IAM policy applied to OU/Accounts: restrict users and roles
- No effect on Management Account
- *Explicit allow* from root, thru each OU, to Account
- SCP at higher lvl has priority over lower
- `FullAWSAccess` (default)
- Top-down tracing
- OU (Root) [FullAWSAccess] > OU (Dev) [FullAWSAccess] > Account D [Allow EC2]: Account D acc: EC2



## Tag Policy

- Attr-BAC
- Standardise tags across resources
- Ensure consistent tags, audit tagged resources, maintain resource categorisation
- Def: key, allowed values
- Prevent non-compliant tagging op on spec services & resources, but no effect on resources w/o tags
- EventBridge monitors non-compliant tags



## IAM Permission Boundary

- Support: User, Role, not Group
- Set Max perm (boundary)
- Actual perm = Org SCP ∩ Identity-based pol (User, Group, Role) ∩ Permission boundary



## [Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic_policy-eval-basics.html)

Deny (explicit Deny) -> Org SCP -> Resource-based -> Identity-based -> IAM Permission boundary -> Session

## IAM Identity Center

- SSO for: AWS accounts in the same AWS Org, Business cloud app (Salesforce, MS365), SAML 2.0-enabled app, EC2 Win inst
- Identity provider: Builtin identity store, AD, Okta
- Multi-Account permission: Permission Set: 1+ IAM policies assigned to users/groups
- Application assignment: assign apps to acc
- Attr-BAC (ABAC): fine-grained perm based on user attr in builtin Identity Store



### Directory Service (AD)

- AWS Managed Microsoft AD: estab *trust* conn w/ on-prem AD to share directories, MFA support 
- AD Connector: directory GW (proxy), redir to on-prem AD, MFA support
- Simple AD: Cannot join on-prem AD
- Integration: IAM Identity Center



## Control Tower

- Setup & Govern multi-account AWS env
- Util AWS Organizations to create accounts
- Preventive Guardrail: util SCP, e.g. restrict regions for all accounts
- Detective Guardrail: util AWS Config, e.g. identify untagged resources



# EC2: Elastic Compute Cloud

- Budget: My Account (Top right) > Billing and Cost Management > Budgets and Planning: Budgets (Sidebar)

Components:

- EC2: VM
- EBS: Drives
- ELB: Distributing loads across VMs
- ASG: Auto-scaling Group



# EC2 (VM)

Config: OS, CPU, RAM, Storage (network-attached, HW), NIC, Firewall (Security Group), Bootstrap script (EC2 User Data)

- EC2 User Data: bootstrap script, run as root.



## Instance Type

- t: general
- c: compute optm
- r: mem optm
- i,d,h: storage optm



## SG: Security Group

- Locked down to a region / VPC combination.
- If app: timeout -> SG issue, connection refused -> app error
- Inbound default: blocked
- Outbound default: authorized
- SG refer to other SGs to control traffic, e.g. if inst A + SG1: inbound ref SG2, SG3; inst B + SG2 can acc inst A



## Attach Roles to EC2 Instance

Select Inst > Actions > Security > Modify IAM Role

## EC2 Hibernate

- Stop EC2 -> RAM state saved to EBS root -> Start EC2 -> RAM loads from EBS root
- Public IP will change when Start from Hibernation, just like from Stop state.

Requirements:

- EBS root size > RAM
- EBS encrypted



## Purchasing Options

### On-demand
- $: per sec, Highest $.

### Reserved Instance (RI, 1-3 yr): Hotel analogy: VIP discount
- Reserve:
  1. Inst attr: Inst type, Region, Tenancy, OS
  2. Scope: regional or zonal (AZ)
- Scenario: steady-state app, e.g. DB
- Buy & sell in RI Marketplace

### Convertible Reserved Instance
- Reserve options changable (inst type, tenancy, OS, scope)


### Savings Plan (1-3 yr)
- Discount for long-term usage
- Commitment to an amount of usage
- Usage over SP -> billed on-demand
- Fixed: inst fam, region
- Flexible: inst size, OS, tenancy
- Hotel analogy: VIP discount, pay lower per hr for 1-3 yr, and stay in any room type.

### Spot Instance
- Can lose at any time, unreliable
- Most cost-efficient
- $: change per hr
- Scenario: batch, data analysis, image proc, dstb workloads

#### Spot Instance Request
- Max spot price: if cur <= max -> provision, if cur > max -> stop | teminate.
- #Inst
- Spec
- Type: one-time | persistent
- Valid from 
- Valid until
- Only cancel requests that are open, active, disabled. Cancel a request does not terminate inst.

### Spot Fleet
- Set: { spot inst, on-demand inst }
- Def multi launch pools: inst type, OS, AZ
- SF chooses b/w launch pools
- Stop launching when hitting capacity or max cost
- Strategy:
  - Lowest price
  - Diversified: dstb across all pools (availability, long workload)
  - Capacity optimized: pool w/ optm capacity for #inst
  - Price capacity optimized (recom): pools w/ highest capacity avail, select the one w/ lowest price.
  
### Dedicated Host
- Book entire phys server (host), control inst placement
- Scenario: compliance, server-bound software licenses (BYOL)
- On-demand | Reserved

### Dedicated Inst
- Host can be diff, but always dedicated to customer.
- ❌ Control over inst placement, i.e. host

### Capacity Reservation
- Reserve capacity in a spec. AZ for any duration.
- No time commitment
- Combine w/ regional RI & Savings Plan to discount-max
- $: On-demand rate whether running inst or not
- Hotel analogy: book a room for a period w/ full price, even not staying



## Placement Group

- Cluster: inst in a lo-latency group in an AZ. Good network, prone to failure.
- Spread: inst across underlying HW, Max 7 inst per AZ per group. 
- Partition: inst across diff partitions (racks) in an AZ, Max 100 EC2, 7 parti per AZ. Scenario: HDFS, Cassandra, Kafka.
- Practice: launch EC2 -> select Placement Group.



## EIP: Elastic IP

- Static public IP
- ⚠️ Avoid EIP: often reflects poor arch decision. Use LB or register DNS name.



## ENI: Elastic Network Interface

- Logical component in a VPC for a virtual net card

Attr:

- Primary private IPv4
- Secondary private IPv4
- 1 EIP per private IPv4 | 1 Public IPv4
- 1+ SG
- MAC adr
- EC2 inst failover: create ENI independently, attach / detach on failure
- ENI ∈ Subnet ∈ VPC: EC2 w/ multi-ENI is in multi subnets inside a VPC.


## AMI: Amazon Machine Image

- Customisation of EC2 inst
- Select inst > Actions > Image and templates > Create image



# EBS: Elastic Block Storage

- Network drive to attach to EC2 inst.
- Support: multi-attach
- Bound to AZ
- Move across AZ or Region: take snapshot



## Snapshots

- Archive: 75% cheaper, takes 24-72 hrs for restore.
- Recycle bin: setup rules to retain deleted snapshots.
- Fast snapshot restore (FSR): full init of snapshot w/ 0 latency on the first use, Hi $.



## EBS Volume Types

- Character: Size, Thruput, IOPS
- ❌ HDD be boot volumes
- General SSD: `gp2` / `gp3`
- Provisioned IOPS (PIOPS) SSD: 
  - `io1`: 64,000 IOPS
  - `io2 Block Express`: 256,000 IOPS
- HDD: 
  - `sc1`: lowest $
  - `st1`: lo $, freq acc, thruput optm



## EBS Multi-Attach

- Attach an EBS Max *16* EC2 inst in 1 AZ.
- Must use cluster-aware FS (not XFS, ext4)
- Support: `io1`, `io2 Block Express`



## EBS Encryption

- Util KMS keys (AES-256)

Enc un-encrypted EBS volume: 

1. Create EBS snapshot of the un-encrypted EBS.
2. Select snapshot > Actions > Create volume from snapshot > ✅ Encrypt, select KMS key.

# EC2 Instance Store

- Hi-perf hard disk, directly on phys server the EC2 inst is provisoned.
- ~`emptyDir` in Kubernetes volume, Direct Attached Storage (DAS) / Local Datastore in trad infra.
- Lose storage if stopped
- Scenario: buffer, cache, scratch data, tmp data



# EFS: Elastic File System

- NFS mounted on multi EC2, multi-AZ
- Scenario: content mgmt, web serving, data sharing.
- SG to control acc to EFS
- Marche only w/ Linux based AMI
- Enc at-rest w/ KMS



## Modes

- Performance: 
  - General: lo-latency
  - Max I/O: hi-latency, for parallelism
- Thruput:
  - Elastic: auto scale thruput
  - Provisioned: set thruput regardlesss of storage size
  - Bursting



## Storage Class

- Move file after N days.
- Lifecycle policy: move files b/w storage tiers.



### Tiers

- Standard
- Infrequent Access (EFS-IA)
- Archive



### Availability & Durability

- Standard: Multi-AZ
- One Zone: 1 AZ



# ELB: Elastic Load Balancer

- Application (ALB): HTTP, HTTPS, WebSocket
- Network (NLB): TCP, TLS (secure TCP), UDP 
- Gateway (GWLB): Layer 3 IP
- Classic (CLB): deprecated
- EC2 SG: only allow traffic from LB (HTTP, TCP, 80. ALB SG)



## ALB: Application LB

- Routing: path, hostname, query string
- Target group: EC2 inst (ASG), ECS, Lambda (HTTP -> JSON), private IP
- App servers do not see client info directly, but in headers: IP: `X-Forwarded-For`, Port: `X-Forwarded-Port`, Protocol: `X-Forwarded-Proto`



## NLB: Network LB

- *1 Static IP per AZ*
- Target group: EC2 inst, private IP, ALB
- Health check support: TCP, HTTP, HTTPS
- EC2 SG: add NLB SG (HTTP, TCP, 80. NLB SG)



## GWLB: Gateway LB

- Manage 3e party NVA in AWS (Firewall, Intrusion detection, Pkt inspection sys)
- Transparent: single entry/exit for all traffic. 
- GENEVE protocol, port: 6081
- Request -> GWLB -> NVA target group (proceed or drop) -> GWLB -> App



## Sticky Session

- Marche: CLB, ALB, NLB
- App-based cookie: cookie name spec. individually for each target group. Reserved: AWSALB, AWSALBAPP, AWSALBTG
- Duration-based cookie: gen by LB
- Target group > Actions > Edit attributes > Target selection configuration



## Cross-Zone Load Balancing

- #EC2 across AZ are not uniformly distributed, with Cross Zone LB, LBs consider the distribution to achieve true LB.
- ALB: enabled (always), disable at Target group level, $0 for inter AZ data.
- NLB: disabled (default), $ for inter AZ data
- LB lvl: ELB > Attributes
- Target group lvl: Target Group > Attributes


## SSL/TLS Cert

- Mng certs: AWS Certificate Manager (ACM)
- Clients spec. Server Name Indication (SNI) w/ hostname, solves multi TLS certs in 1 web srever. Marche: ALB, NLB, CloudFront.
- ELB > Listeners > Add listener > Secure listener settings



## Deregistration Delay

- Time to complete in-transit requests while EC2 is de-registering or unhealthy
- Stops sending new req to the de-registering EC2
- 0-3600s, default: 300s



# ASG: Auto Scaling Group

- Scale out/in (+/-) EC2
- Recreate EC2 in case current one is terminated
- $0
- Launch template: AMI, Inst type, EC2 user data, EBS volumes, SG, SSH key pair, IAM roles, VPC, Subnet, LB
- ASG+ELB: Step 3: Integrate with other services > Health checks > ✅ ELB health checks



## Scaling Policy



### Dynamic

- Target Tracking: avg ASG CPU @40%
- Simple / Step: CloudWatch Alarm -> scale out/in
- Metrics: CPUUtilization, RequestCountPerTarget, Average Network I/O



### Scheduled

Scale out min capacity: 10, 17:00, Fri.

### Predictive

ASG auto forecast and schedule scaling

### Scaling Cooldown

- Cooldown period (default 300s) post-scaling.
- During cooldown ASG will not launch / terminate EC2.
- Cooldown period-: ready-to-use AMI



# Aurora & RDS: RDBMS

- Support: Postgres, MySQL, MariaDB, Oracle, MS SQL, IBM DB2, Aurora
- Continuous backup and restore to spec timestamp (PITR)
- DR: Multi-AZ 
- Not accessible via SSH



## Storage Auto Scaling
- Storage > Additional storage configuration > Maximum Storage Threshold



## Read Replicas

- Max 15
- Intra, inter AZ, cross-region 
- Async replication: reads are consistent
- Can be promoted to indep DB
- App updates conn. string to util RR
- `SELECT` SQL only
- DB > Actions > Create read replica



### Data Replication

- Same region RR: $0
- Cross-region RR: $



## [RDS Multi-AZ (DR)](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.Migrating.html)

- Sync block-lvl (EBS) replication
- 1 DNS name: active-standby failover
- Not for scaling
- Single -> Multi-AZ
  - 0 downtime
  - RDS > Actions > Convert to Multi-AZ deployment
  - BTS: Snapshot -> Restore on Standby -> Sync b/w primary & standby vol

## RDS Custom

- Oracle or MS SQL w/ OS & DB customisation
- Acc. underlying EC2 via SSH or SSM Session Manager
- De-activate automation mode, take DB snapshot pre-customisation



# Aurora

- Support: Postgres, MySQL
- AWS cloud optm: 5x performance vs. MySQL, 3x vs. Postgres (on RDS)
- Auto storage incr: 10GB, Max 256TB
- Max 15 replicas, <10ms replica lag
- $: +20% vs. RDS

## Aurora DSQL
- Serverless, Dstb RDBMS
- Active-active HA: single/multi region
- Postgres compatible


## HA

- 6 replicas across 3 AZ, each AZ holds 2
  - 4/6 quorum for writes
  - 3/6 quorum for reads
- Against 1 AZ + 1 server failure
- 1 Aurora as master
- Auto master failover <30s
- Client-Server conn: 
  - Client - Writer Endpt - Master
  - Client - Reader Endpt (LB) - RR



## Custom Endpoint
- Diff RR inst type for diff usage
- 1:1 Mapping Custom Endpt - RR group 
- Reader Endpt generally discarded



## Aurora Serverless

- Auto DB instantiation & auto-scaling
- Infreqeent, intermittent, unpredictable workloads
- $: per sec
- Client comm. w/ Proxy Fleet



## Global Aurora

- 1 primary region (R/W)
- Max 10 secondary regions (read-only), replication lag <1s.
- Max 10 RR / secondary region
- Promote another region as primary (DR): RTO <1min.



## Aurora ML

- Support: SageMaker, Comprehend (sentiment analysis)
- App -> Aurora -> ML -> Aurora -> App



## Babelfish for Aurora PostgreSQL

- MS SQL server migrate to Aurora PostgreSQL
- T-SQL -> Babelfish -> PL/pgSQL



# Backup & Restore

## RDS

- Daily auto full backup
- Transation logs backup every 5min: PITR
- Retention: 1-35 days, 0: disable auto backup
- Manual: retention as user desires
- Hack: If not using RDS for a long time -> backup + restore



## Aurora
- Retention: 1-35 days, PITR

### Aurora DB Cloning

- Faster than backup & restore
- Copy-on-write:
  - New DB uses same volume as orig.
  - Update: allo additional storage, data copied & separated


## Restore

- Backup to S3
- On-prem -> Aurora: Percona XtraBackup -> S3


# Security

- Enc at-rest
  - Def at launch w/ AWS KMS
  - Master un-encrypted, RR cannot be encrypted
  - Enc post-launch: backup & restore
- IAM auth: IAM roles conn to DB
- SG
- ❌ SSH, except RDS custom



# RDS Proxy

- Reduce DB CPU & RAM
- Serverless, HA (multi-AZ)
- RDS & Aurora failover time-: max 66%
- Enforce IAM auth 
- Acc from VPC only



# ElastiCache

- Redis, Memcached
- ElastiCache as DB cache: reduce load for DB
- App write data into ElastiCache: Stateless-ise app
- Require code change



## Redis

- Multi-AZ w/ auto failover
- Data durability w/ AOF persistence 
- Backup & restore
- Sorted sets: guarantee uniqueness & elem ordering, e.g. real-time ranking.



## Memcached

- Multi-node for data partitioning (sharding)
- ❌ HA
- Non persistent
- Backup & restore only for Serverless type
- Multi-thread arch



## Security

- IAM auth: Redis only
- IAM policy on ElastiCache only for AWS API-level sec
- Redis AUTH: set "password/token", support TLS in-transit enc
- Memchched supports SASL based auth



## Patterns

- Lazy loading: all the read data is cached, can become stale
- Write through: Add/update data in cache when written to a DB, no stale data
- Session store: store temp session data (TTL)



# Route 53

- Authoritative DNS: customer can update DNS records.
- Domain registrar
- Record
  - Domain / subdomain name
  - RecordType: A, AAAA
  - Value: 1.2.3.4
  - Routing Policy
  - TTL: cache time in client
- Record Types
  - A: hostname to IPv4
  - AAAA: hostname to IPv6
  - CNAME: hostname to another hostname. Not allowed for top node of a DNS ns, e.g. ❌ `example.com` ✅ `www.example.com`
  - NS: name servers for the hosted zone



## Hosted Zone

- Container of records, def how to route traffic
- Public: how to route on internet
- Private: how to route w/in VPCs (private domains)
- $0.5 per mo per hosted zone



## CNAME vs. Alias

CNAME: only for non-root domain

Alias

- Hostname to an AWS resource 
- Marche: root & non-root domain
- $0
- Native health check 
- Auto recog resource IP change
- A or AAAA
- Targets: ELB, CloudFront distribution, API Gateway, Elastic Beanstalk, S3 website, VPC Interface Endpoint, Global Accelerator, Route 53 record in the same hosted zone
- No ALIAS for an EC2 DNS
- Hosted zone (Domain Name) > Create record > A/AAAA, Route traffic to: ✅ Alias, choose endpoint



## Routing Policy



### Simple

- 1 record, multi val
- If multi val -> one chosen by client randomly
- If Alias: only 1 AWS resource



### Weighted

- Control % of requests that go to each resource, like rolling a dice
- DNS records w/ the same name (app.example.com) and type (A/AAAA)
- Scenario: LB across regions 
- Weight: 0 to stop sending request to a resource
- If all records w/ weight 0, records be returned equally.



### Latency

- Redirect to the resource w/ lowest latency
- Based on client and AWS region
- Create record: 
  - Value: resource
  - Region: AWS region, if client closest to this region, go to the resource (Value)



### Failover (Active-Passive)

- 2 records, same name
- Primary: mandatory health check
- Secondary (DR): opt health check



### Geolocation

- Routing based on client loc by Continent, Country
- Spec "Default" in case there's no match



### Geoproximity

- Shift traffic from 1 region to another
- Bias: expand [1, 99]/ shrink [-99, -1]
- AWS resource, on-prem (latitude, longitude)



### IP

- Routing based on IP
- Provide a list of CIDRs
- Scenario: route client from a parti. ISP to a spec endpt



### Multi-Value

- Multi records, same name, diff. val
- Routing to multi resources
- Route 53 returns multi val / resources
- Max 8 healthy records returned 
- NOT a substitute for ELB



## Health Check

- HTTP health check only for *public* resources



### Endpoint

- ~15 global health checkers will check endpoint
- (Un)Healthy threshold for an endpt: 3 (default)
- Interval: 30s (can be 10s, Hi $)
- HTTP, HTTPS, TCP
- If >18% health checkers pass -> Healthy
- Healthy: 2xx, 3xx status codes, head 5120 bytes resp
- Config router / firewall: allow inbound request: Route 53 health checkers



### Calculated

- Combine res of multi health checks
- Logic: OR, AND, NOT
- Max 256 child health checks 
- Spec #health checks threshold
- Scenario: website maintenace



### Router 53 - CloudWatch Alarm

- For Private Hosted Zone
- Health checkers are outside VPC
- Create CloudWatch Metric, check CloudWatch



## 3e Party Domain Registrar & DNS Service

- Domain registrar: buy domain name
- DNS service: mng DNS records
- Example: GoDaddy as Registrar & Route 53 as DNS service
  1. Route 53 public hosted zone: copy Name servers
  2. Paste on GoDaddy Nameservers



## Route 53 Resolver & Hybrid DNS

- Resolve DNS queries b/w VPC (Route 53 Resolver) & On-prem networks (other DNS Resolvers)
- Conn. VPC & On-prem w/ AWS Direct Connect or AWS VPN first



### Inbound / Outbound Endpoint

- Allow on-prem DNS resolvers to resolve AWS resource domain names (inbound), vice versa (outbound)
- Inbound: On-prem server -> DNS Resolvers -> Inbound Endpoint -> Route 53 Resolver -> Private Hosted Zone (VPC)


# RAM: Resource Access Manager
- Share resources across AWS accounts/Organizations, e.g. TGW, Subnet, License Manager, Route 53 Profiles

# Case Study: E-commerce

- ELB sticky session
- Stateless app: Web clients store cookies OR ElastiCache OR DynamoDB
- ElastiCache: store sessions, RDS data cache, Multi-AZ
- RDS: RR for scaling reads, Multi-AZ for DR
- SG: 
  - HTTP/HTTPS 0.0.0.0 -> ELB
  - HTTP ELB -> EC2
  - EC2 SG -> ElastiCache
  - EC2 SG -> RDS



# Elastic Beanstalk

- $0, Centralised deploy mgmt: EC2, ASG, ELB, RDS, etc.
- Developer only responsible for code

## Components

- Application: collection of Environments, Application versions, config
  - Application versions: app code
  - Environment: collection of AWS resources, tiers



### Environment Tier

- Web Server: ELB + ASG
- Worker: SQS Queue + ASG. EC2 as worker pull msg from SQS queue



# S3

## Bucket

- Contains objects
- Region lvl
- Global unique name, No uppercase, underscore, IP. No 2 buckets in the world have the same name.
  - Global namespace: custom name
  - Account Regional namespace: reuse the same name, AWS adds suffix (Account ID).
- Type: General purpose, Table, Vector, Directory (Express One Zone)


## Object (file)

- Key (path): `s3://my-bucket/folder/file.txt`, prefix: `folder`, obj name: `file.txt`
- Value: content, Max 50 TB, "multi-part upload" for obj > 5GB
- Metadata: list of kv pairs
- Tags: Max 10 kv pairs



## Policy

- IAM
- Resource-based: bucket (allow cross account), obj ACL
- Cond. IAM principal acc. S3 obj: (IAM policy OR Resource policy) AND !Explicit Deny
- Block public access: ✅ (default for protection)



## Versioning

- Enable @ bucket lvl
- File not versioned pre-enable: null
- Suspend versioning does not delete prev ver

Delete obj behaviour: **Show versions** switch 
- On: permanent delete
- Off: add *Delete marker*

## Replication

✅ Versioning in both src & dest buckets

- CRR vs. SRR: Cross-Region Replication vs. Same-Region Replication
- Can be diff AWS accounts
- Async copy
- IAM policy to S3
- ❌ Chaining: bucket A -> bucket B, bucket B -> bucket C. Obj created in bucket A -> replica in bucket B, but not bucket C.
- Practice: Src S3 > Management > Replication rules: Create replication rule



### Existing & New Obj

- Only new obj replicated post-enable Replication
- Existing: S3 Batch Replication



### Delete Marker Replication

- Delete markers created by S3 delete op will be replicated.
- Permanent delete (spec version ID) not replicated.



## Storage Class


| Storage Class                  | min Storage Duration | min Obj Size | Retrieval $              | 1e Byte Latency |
| ------------------------------ | -------------------- | ------------ | ------------------------ | --------------- |
| **Standard**                   | None                 | None         | None                     | ms              |
| **Express One Zone**           | None                 | None         | None                     | <10 ms          |
| **Intelligent-Tiering**        | None                 | None         | None                     | ms              |
| **Standard-IA**                | 30 days              | 128 KB       | Per GB                   | ms              |
| **One Zone-IA**                | 30 days              | 128 KB       | Per GB                   | ms              |
| **Glacier Instant Retrieval**  | 90 days              | 128 KB       | Per GB                   | ms              |
| **Glacier Flexible Retrieval** | 90 days              | 40 KB        | Per GB (varies by speed) | min-hr          |
| **Glacier Deep Archive**       | 180 days             | 40 KB        | Per GB                   | 12-48 hr        |


- Durability: 99.999999999% (11 9's), loss of an obj per 10,000,000 obj per 10,000 yr.
- Availability: Standard: 99.99%, N/A 53 min per yr.
- Practice: 
  - Obj > Actions > Edit storage class
  - Bucket > Management > Lifecycle rules



### Standard

- 99.99% Avail
- Lo latency, Hi thruput
- Sustain 2 concurrent facility failures



### Standard-Infrequent Access (IA)

- 99.9% Avail
- Scenario: DR, backups



### One Zone-Infrequent Access (IA)

- 99.5% Avail
- Scenario: secondary backup copy



### Glacier



#### Glacier Instant Retrieval



#### Glacier Flexible Retrieval

- Retrieval
  - Expedited: 1-5 min
  - Standard: 3-5 hr
  - Bulk: 5-12 hr



#### Glacier Deep Archive

- Retrieval
  - Standard: 12 hr
  - Bulk: 48 hr



### Intelligent Tiering

- $: Monthly monitoring & auto-tiering
- $0: retrieval



### Express One Zone

- 1 AZ
- Directory bucket: directory hierarchical stru for Hi performance
- 100,000s requests, < 10ms latency
- 99.95% Avail



## Lifecycle Rule

- Per prefix or obj Tag
- Transition action: obj to another storage class
- Expiration action: obj to be deleted after some time



## Requester Pays

- Enable in bucket, requester pays, not owner
- Requester must be authn in AWS



## Event Notification

- `s3:Object[Created, Removed, Restore]`, `s3:Replication`, etc.
- Obj name filtering, e.g. `*.jpg`
- Send event to SNS, SQS, Lambda or EventBridge. Def. acc policy on dest, i.e. SNS, SQS (`sqs:SendMessage`), Lambda



## Performance

- 3,500 PUT/COPY/POST/DELETE, 5,500 GET/HEAD req per sec per prefix in a bucket.
- Multi-part upload: recom file >100MB, upload parallelism
- Transfer acceleration: Src S3 -> AWS edge FW -> Target S3 in another region.



### Get Partial Data

- Byte-range fetch
- S3 Select: SQL to get partial content, support CSV, JSON, Parquet



## Batch

- Enc un-encrypted obj
- Mod obj metadata, properties
- Copy obj b/w buckets
- Restore from Glacier
- Invoke Lambda to perform custom action on each obj
- Def: list of Obj, Action, Param
- Batch mng retry, progress, completion notification, gen report
- S3 Inventory: get obj list, Athena: query & filtre obj



## Storage Lens

- Dashboard: default or custom
- Config: Org, Accounts, Regions, Buckets
- Aggeregation



### Metrics

- Summary: StorageBytes, ObjectCount
- Cost-Optm: NonCurrentVersionStorageBytes, IncompleteMultipartUploadStorageBytes
- Data-Protection: VersioningEnabledBucketCount, MFADelteEnabledBucketCount, CrossRegionReplicationRuleCount
- Acc-mgmt: ObjectOwnershipBucket
- Event: EventNotificationEnabledBucketCount
- Performance: TransferAccelerationEnabledBucketCount
- Activity ($): AllRequests, GetRequests, ListRequests, BytesDownloaded
- Detailed status code ($): 200OKStatusCount, 403ForbiddenErrorCount
- Advanced feat ($):CloudWatch publishing, prefix aggregation, data avail for query for 15 mo.



## Encryption

- Set per bucket or obj (override)



### SSE: Server-Side Encryption

- SSE-S3: default, AWS mng key
  - Header: `"x-amz-server-side-encryption": "AES256"`
- SSE-KMS: KMS mng key
  - Header: `"x-amz-server-side-encryption": "aws:kms"`
  - Limit: KMS API quota
    - Upload: call GenerateDataKey KMS API
    - Download: call Dec KMS API
- SSE-C: customer provided key (CLI only),
  - S3 does NOT store key
  - HTTPS req
  - Header: key, in all HTTP req.



### CSE (Client-Side Encryption)

Encrypted files upload to S3

### Encryption in-Transit (SSL/TLS): HTTPS

### Enforce Encryption w/ Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "*",
      "Condition": {
        // SSL/TLS
        "Bool": {
          "aws:SecureTransport": "false"
        },
        // SSE-KMS
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws-kms"
        },
        // SSE-C
        "Null": {
          "s3:x-amz-server-side-encryption-customer-algorithm": "true"
        }
      }
    }
  ]
}
```



## CORS

Origin: scheme (protocol) + host (domain) + port

- Same origin: [http://example.com/app1](http://example.com/app1) and [http://exmaple.com/app2](http://exmaple.com/app2) 
- Diff origin [http://www.example.com](http://www.example.com) and [http://other.example.com](http://other.example.com)

CORS Headers: `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods`

- Practice: Dest origin > Permissions > CORS

```json
[
    {
        "AllowedHeaders": [
            "Authorization"
        ],
        "AllowedMethods": [
            "GET"
        ],
        "AllowedOrigins": [
            "<url of first bucket with http://... No slash at the end>"
            ""
        ],
        "ExposeHeaders": [],
        "MaxAgeSeconds": 3000
    }
]
```



## MFA Delete

- MFA required: permanent delete an obj ver, suspend versioning
- Only Root account has perm to enable/disable MFA delete w/ AWS CLI

## Access Logs

- S3 logs will be logged into another S3
- Logging bucket in the same region
- Do NOT set the monitored and logging bucket as the same
- Practice: Bucket > Properties > Server access logging



## Pre-Signed URL

- User w/ pre-signed URL inherit the perm of the user who gen URL 
- URL expiration:
  - S3 Console: 1-720min
  - CLI: param `--expires-in` sec, default: 3600, max 604800s (168hr)
  `aws s3 presign s3://<bucket>/<obj>  --expires-in <sec> --region <region>`
- Practice: obj > Object actions > Share with a presigned URL



## Glacier Vault Lock

- WORM (Write Once Read Many) model
- Create Vault Lock Policy
- Lock the policy, not editable
- Compliance



## Object Lock

- Enable Versioning
- Block an obj ver delete for a period
- Retention mode:
  - Compliance: nobody can change or delete the obj ver, mode not changable, retention cannot be shrotened.
  - Governance: Previlige users can change obj ver
- Legal hold: protect obj ♾️⏱️, indep from retention period, add/remove  w/ `s3:PutObjectLegalHold` IAM policy.



## Access Point

- DNS: Internet or VPC
- Policy: R/W, prefix (sub-dir) perm



### VPC Origin Access Point

- AP only avail to VPC
- Create VPC Endpoint to acc AP. Policy: AP, S3 bucket



## S3 Object Lambda

- Lambda changes obj before retrieved by caller app
- App - S3 Object Lambda AP - Lambda - S3 AP - S3
- Scenario: redact personal data, convert data, resize & watermark image



# CloudFront: CDN

- Content cached at edge

Origin:

- S3: Origin Access Control (OAC) Policy: allow CloudFront get S3 obj 
- VPC: private ALB, NLB, EC2
- Custom: S3 website, public HTTP backend



## CloudFront vs. S3 CRR (Cross-Region Replication)


|             | CloudFront          | S3 CRR           |
| ----------- | ------------------- | ---------------- |
| Regionality | Global Edge network | Few Regions      |
| Up-to-date  | Cache TTL           | Real-time update |
| Content     | Static              | Dynamic          |
| P.S.        |                     | Read-only        |




## VPC Origin

Client -> CloudFront (edge loc) -> VPC Origin -> EC2, ALB, NLB (VPC)

### Public Network ALB & EC2

SG Setup 

- EC2: allow edge loc public IP
- ALB: 
  - EC2 (public or private): allow ALB SG
  - ALB (public): allow edge loc public IP



## Geo Restriction

- Allowlist / Blocklist
- Scenario: copyright laws



## CloudFront Invalidation

- Back-end origin update -> Invalidation (Cache refresh, bypass TTL) 
- Spec path: `*`, `/images/*`



# Global Accelerator

- Util AWS internal network to route to app
- 2 Anycast IP for the app
- Endpoint Groups: add region
- Endpoints: EIP, EC2, ALB, ELB (public & private)
- Health check + failover
- AWS Shield: DDoS protect



## CloudFront vs. Global Accelerator


|               | CloudFront                           | Global Accelerator                          |
| ------------- | ------------------------------------ | ------------------------------------------- |
| Common        | Util AWS global network & AWS Shield |                                             |
| Functionality | Cache content @ Edge                 | Proxy pkt b/w Edge & app across AWS regions |




# Snowball

- Phys device: 104 vCPUs, 416 GB mem
  - Snowcone: 14 TB 
  - Snowball Edge: 210 TB SSD
- Scenario: data migration, edge computing
- Snowball -> S3 -> Glacier



# FSx

Deployment Opt:

- Scratch: temp storage, data not replicated, Hi-burst
- Persistent: long-term, data replication intra AZ



## Windows

- SMB, Win NTFS
- AD, ACL, user quotas
- Mounted on Linux EC2
- Support MS Distributed FS (DFS) namespaces
- Daily backup to S3



## Lustre (Linux + Cluster)

- Parallel DFS
- Lustre vs. EFS: HPC vs. Normal Linux FS
- ML, HPC
- S3 integration: Read S3 as FS, Write computation output back to S3



## NetApp ONTAP

- Hi OS compatibility
- Compatible: NFS, SMB, iSCSI
- Marche w/ Linux, Win, MacOS, VMware Cloud on AWS, EC2, ECS, EKS
- PIT instantaneous cloning
- Data deduplication



## OpenZFS

- Compatible: NFS
- Marche w/ Linux, Win, MacOS, VMware Cloud on AWS, EC2, ECS, EKS
- PIT instantaneous cloning



# Storage Gateway

- GW b/w on-prem & AWS cloud for hybrid storage
- On-prem VM as GW (ESXi, Hyper-V, KVM), or EC2 (less frequent)



## S3 File GW

- NFS or SMB
- Most recently used data cached in GW
- Support: Standard, Standatd-IA, One Zone-IA, Intelligent Tiering
- ❌ Support: Express One Zone, Glacier
- Transfer to Glacier via S3 Lifecycle Policy
- GW acc. S3 w/ IAM role
- On-prem app server -> NFS/SMB -> S3 File GW -> HTTPS -> S3 -> S3 Glacier



## Volume GW

- Block storage, iSCSI protocol
- EBS snapshots helps restore on-prem vol
- On-prem app server -> iSCSI -> Volume GW -> HTTPS -> S3 -> EBS Snapshots
- Cached: lo-latency acc to most recent data
- Stored: entire dataset on-prem, scheduled backup to S3



## Tape GW

- On-prem backup server -> iSCSI-VTL -> Tape GW -> HTTPS -> S3 -> S3 Glacier



# Transfer Family

- FTP transfer service from/to S3 & EFS w/ IAM role. HA
- Protocols: FTP, FTPS, SFTP
- $: per provisioned endpoint per hr, data transfer in GB
- Authn: AD, LDAP, Okta AWS Cognito



# DataSync

- Bi-dir data sync
- On-prem/other cloud <-> AWS: agent
- AWS <-> AWS: no agent, *b/w diff. storage services*
- S3 (all storage classes), EFS, FSX
- Sechdule: hr, day, week
- *Preserve file perm & metadata* (NFS, POSIX, SMB)
- NFS/SMB server <-> DataSync Agent <-> TLS <-> DataSync <-> AWS Storage Services (S3, EFS, FSx)
- DataSync (S3 service) vs. Stored Volume GW: Move files vs. blocks (RDBMS)



# SQS: Simple Queue Service

- Decouple apps: App <-> Queue <-> App (Async/Event)
- ♾️ thruput, #msg
- Msg persistence: consumer deletes msg or retention
- Retention: 4 days (default), Max 14 days
- Lo-latency: <10ms on publish and recv
- Msg Max size: 1024 KB
- Duplicate msgs: at-least-once delivery
- Best-effort msg ordering
- Producer [`SendMessage` API] -> SQS <-> [`DeleteMessage` API] Consumer
- In-transit enc: HTTPS, At-rest enc: KMS
- SQS API acc control: IAM policy



## Message Visibility Timeout

- Invisible to other consumers Post-consumer polling, 30s default
- Consumer calls `ChangeMessageVisibility` API to get more time
- After visibility timeout, msg visible in SQS



## Long Polling

- Consumer waits for msg if SQS is empty
- API calls -, Latency -
- Wait time: 1-20s
- Enable at queue or API (`WaitTimeSeconds`) lvl



## FIFO Queue

- Deduplication ID: exactly-once processing, remove duplicates
- Order by Message Group ID
- Thruput: 300 msg/s w/o batch, 3000 msg/s w/ batch



## SQS + ASG

- Horizontal autoscale w/ CloudWatch Metric: Queue Length (ApproximateNumberOfMessages) -> CloudWatch Alarm -> ASG
- SQS qua buffer to DB write: When INSERT complete, delete msg in SQS. Enqueue ASG -> SQS -> Dequeue ASG -> DB



# SNS: Simple Notification Service

- Topic: queue, Max: 100,000
- Subscriber: recvr, e.g. SQS, Lambda, Data Firehose, Email, SMS, HTTP(S) endpoint. Max: 12,500,000 per Topic.
- Security: enc, Acc control, etc. same as SQS



## SNS + SQS: Fan Out Pattern

- SQS qua subscribers, not bounded by region
- Allow SNS write on SQS policy
- FIFO opt: same as SQS



## Subscription Filter Policy

- JSON policy to control which messages a subscribe recv.
- Subscription w/o filter policy recv. all msg



# Kinesis

- Retention Max 365 days
- Data Max 10 MiB
- Partition key: ordering
- Ability: Replay (reprocess) data by consumer
- Kinesis Producer Library (KPL): write producer app, Kinesis Client Library (KCL): write consumer app



## Mode

Provisioned: 

- Set #shards: total capacity for a stream
- Shard: 1 MB/s write, 2 MB/s read
- $: per shard provision per hr

On-demand:

- 4 MB/s
- Autoscale based on observed thruput peak in the last 30 days



# Data Firehose

- Batch write to S3, RedShift, AWS OpenSearch, 3e party, custom HTTP endpoint
- Set: Buffer size (MiB) & interval (sec)
- Autoscale, serverless
- ~ Real-time
- Support CSV, JSON, Parquet, Raw text, binary data
- Convert to Parquet, ORC, Compression w/ gzip, snappy
- ❌ Replay, storage



# Amazon MQ

- Message broker service for RabbitMQ & ActiveMQ
- Queue: ~SQS, Topic: ~SNS
- HA w/ failover



# ECS

- ECR: Elastic Container Registry
- Group of Docker container on AWS = ECS task
- Task Role: IAM role for a task to make API requests to AWS services, def in *Task definition*
- Integration: ALB (recom), NLB
- Volumes: EFS



## Launch Type



### EC2

- Self-mng EC2 infra
- EC2 runs ECS Agent
- EC2 instance profile: IAM role for ECS agent to make API calls to ECS, send container logs to CloudWatch, pull image from ECR, ref sensitive data in Secrets Manager / SSM Parameter Store



### Fargate

- Serverless



## Autoscaling

- ECS Auto Scaling util AWS Application Auto Scaling
- Target tracking: CloudWatch metric target val
- Step scaling: CloudWatch alarm
- Scheduled: date/time
cf. Auto Scaling Group (ASG) > Scaling Policy



### Autoscaling for EC2 Launch Type

- ASG
- ✅ ECS Cluster Capacity Provider: paired w/ ASG



## ECS Sol Arch

- Upload obj -> S3 event -> EventBridge -> ECS get S3 obj
- EventBridge trigger ECS every hr
- ECS task exited -> EventBridge -> SNS -> email



# EKS: Elastic Kubernetes Service



## Node Type



### Managed node group

- AWS create & mng Nodes (EC2)
- EKS mng Nodes in ASG
- Support: on-demand, spot EC2 inst



### Self-Managed Node

- User create & register Nodes to EKS, ASG mng Nodes
- Util pre-built AMI or EKS optm AMI
- Support: on-demand, spot EC2 inst



### AWS Fargate

- No need for maintenance, Node mgmt



## Volume

- Setup `StorageClass`, util CSI
- EBS, EFS, FSx Lustre, FSx NetApp ONTAP
- *Fargate only w/ EFS*



# Serverless

- Lambda, DynamoDB, Cognito, API Gateway, S3, SQS, SNS, Data Firehose, Aurora Serverless, Step Functions, Fargate



# Lambda

- Virtual function, short exec, run on-demand, autoscaling
- $: $0.2 per 1,000,000 request, $1 per 600,000 GB-sec compute time
- Free tier: 1,000,000 Lambda requests, 400,000 GB-sec compute time
- Max 10 GB RAM per function
- Language support: node.js, python, C#, etc.
- Scenario: Cronjob

**Integration**

- API Gateway: REST API to invoke Lambda
- Kinesis: util Lambda for data transform
- DynamoDB: trigger Lambda on DB change
- CloudWatch: automation on code pipeline pipeline change
- Cognito: whenever user login to DB
- S3, etc.



## Limits



### Execution

- Mem: 128 MB - 10 GB
- Exec time: 900s (15min)
- Env var: 4 KB
- Function container disk (`/tmp`): 512 MB - 10 GB
- Concurrency: 1000 per region



### Deployment

- Size: 50 MB (compressed .zip), 250 MB (uncompressed code + dep)
- `/tmp` to load other files at startup
- Env var: 4 KB



## Concurrency

- Max: 1000, *Support Ticket* for higher limit
- Set Reserved concurrency @ function lvl
- Invocation over concurrency limit trig. Throttle
- Throttle: sync invoc: `ThrottleError 429`, async invoc: retry then go to DLQ
- Throttling error (429) & System error (5xx) events: enqueue event -> retry Max: 6hr
- Retry interval: exp. incr, 1s - 5min



### Cold Start & Provisioned Concurrency

- Init code takes time, 1e req has Hi-latency
- Provisioned concurrency: concurrency allo. pre-invoke
- Application Auto Scaling mng concurrency (schedule or target)



## SnapStart

- Improve Lambda perf Max 10x, $0 for Python, Java, .NET
- Function invoked from pre-init state, no init 
- Normal: Init -> Invoke -> Shutdown; SnapStart: Invoke -> Shutdown
- New version publish -> Lambda init func -> Take snapshot of mem & disk state of init-ed func -> Snapshot cached for lo-latency



## Lambda - VPC

- Lambda in VPC: def VPC ID, Subnet, SG. Lambda creates ENI
- Lambda -> RDS Proxy -> RDS, all w/in VPC



## RDS Invoke Lambda

- Support: RDS Postgres, Aurora Postgres / MySQL
- Proc *data events*
- Allow outbound traffic: DB -> Lambda (Public, NATGW, VPC endpoint)
- DB perm to invoke Lambda: Lambda resource-based policy, IAM policy



## RDS Event Notification

- DB info, no data
- Subscribe: DB inst, DB snapshot, DB param group, DB SG, RDS Proxy, Custom engine ver
- ~ Real-time
- Send to SNS or EventBridge



# CloudFront Function & Lambda@Edge

- Edge function: code on CloudFront to run close to users
- Global deploy
- $: pay only for what you use
- Scenario: custom CDN content, website sec & privacy, dynamic web app, SEO, bot mitigation at edge, user auth, user prioritisation



## CloudFront Function

- Func lang: JS
- Millions req/sec
- Change: Viewer Request, Viewer Response
- Scenario: cache key normalisation (header, cookie, query string, URL), header manipulation, URL redirect, user auth (JWT)



## Lambda@Edge

- Func lang: NodeJS, Python
- Thousands req/sec
- Change: Viewer Request, Viewer Response, Origin Request, Origin Response
- Publish func in 1 region, CloudFront replicates to its loc
- Longer exec time
- Adjustable CPU & mem
- Network acc for external service
- FS, Request body acc
- Deploy to CloudFront edge


# DynamoDB

- NoSQL, dstb DB, HA across multi-AZ
- Transaction support
- Millions req/sec, Trillions rows, Hundreds TB storage
- <10ms performance
- Serverless: no maintenance, patching
- Table Class: Standard | IA



## Basics

- Table, Primary Key
- Max Item size: 400 KB
- Data type: 
  - Scalar: String, Number, Binary, Boolean, Null
  - Document: List, Map
  - Set: String Set, Number Set, Binary Set
- Rapid evolve schema



## R/W Capacity Mode



### Provisioned Mode (default)

- Set: #R/W per sec
- Plan capacity beforehand
- $: provisioned Read/Write Capacity Unit (RCU, WCU)
- Add autoscaling mode for RCU & WCU



### On-Demand Mode

- $+
- Scenario: unpredictable workloads, sudden spikes



## DynamoDB Accelerator (DAX)

- In-mem cache for DynamoDB
- Solve read congestion
- Cached data: microsec latency
- 5 min cache TTL (default)
- *Store Aggregation result w/ ElastiCache*



## DynamoDB Streams

- Ordered item-lvl mod (create/update/delete) stream 
- Scenario: real-time analytics, welcome email, insert derivative table, cross-region replication, invoke Lambda



### DynamoDB Streams vs. Kinesis Data Streams


|                     | DynamoDB Streams         | Kinesis Data Streams       |
| ------------------- | ------------------------ | -------------------------- |
| Retention           | 24h                      | 1yr                        |
| #Consumers          | Limited                  | Hi                         |
| Processing Pipeline | Lambda, Kinesis (w/ KCL) | ibid., Data Firehose, etc. |




## Global Tables

- Lo-latency acc. in multi-regions
- Active-active pattern: R/W in any region 
- Pre: DynamoDB Streams



## TTL

- Auto delete items after expiry timestamp
- Attr: ExpTime in Table
- Scenario: regulation (1yr expiration), session mgmt



## Backup & DR

- PITR: last 35 days
- DR creates new Table



### On-demand Backup

- Full backup, explicit delete
- Conf & mng in AWS Backup: cross-region copy



### DynamoDB - S3

Export to S3

- Enable PITR
- Data analysis on top of DynamoDB
- Retain snapshots for audit
- Format: JSON, ION

Import from S3

- Format: CSV, JSON, ION



# API Gateway

- Handle API versioning, diff env (dev,test,prod), auth
- API keys for request throttling
- Transform / validate req & resp
- *Cache*
- API + Lambda: serverless
- Practice: 
  - API > Resources > Create method
  - API > Deploy API



- Integration: Lambda (expose Lambda REST API), HTTP (on-prem HTTP API, ALB), AWS Service
- Why integrate w/ HTTP & AWS Service? Rate limiting, caching, user auth



## Endpoint Type



### Edge-Optimized (default)

- Request routed thru CloudFront edge loc
- API Gateway still in 1 region



### Regional

- Clients w/in the region
- Manual combine w/ CloudFront



### Private

- Acc from VPC w/ VPC Interdace Endpoint (ENI)
- Resource policy: def acc



## API Gateway Security

- User auth: IAM role, Cognito, custom



### Custom Domain Name HTTPS

- Integration: AWS Certificate Manager (ACM)
- Setup CNAME or A-alias in Route 53

Cert Loc:

- Edge-Optimized endpoint: `us-east-1`
- Regional endpoint: API region



# Step Functions

- Serverless visual workflow 
- Orchestrate Lambda, EC2, ECS, on-prem, API Gateway, SQS, etc.
- Seq, Parallelism, Cond, Timeout, Error handling, Human approval



# Cognito

- Non-AWS user auth (web/mobile app, SAML)



## User Pool (CUP)

- Sign-in functionality for app users
- Serverless user DB
- Userpass login, password reset, MFA, federated identity (Facebook, Google, OIDC, SAML)
- Integration: API Gateway, ALB



## Identity Pool

- Provide temp AWS cred to users to acc AWS resources
- User source: CUP, 3e party
- Web/mobile app login ->  IdP / CUP (token) -> Web/mobile app -> Identity Pool (AWS cred + IAM policy) -> Web/mobile app -> AWS resources



# Serverless Arch

## Micro-service

Services:

- ELB -> ECS -> DynamoDB
- API Gateway -> Lambda -> ElastiCache
- ELB -> EC2 ASG -> RDS
- Sync: API Gateway, ELB
- Async: SQS, SNS, Kinesis, Lambda trig S3

Challenges

- Overhead: repeated creation of new micro service
- Optm server util
- Complex: multi ver of micro service simultaneously



## Software Update Distribution

**CloudFront** <- EC2 ASG <- EFS

# Databases

- RDBMS (SQL/OLTP): RDS, Aurora, for `JOIN`
- NoSQL: DynamoDB (JSON), ElastiCache (kv-pair), Neptune (graph), DocumentDB (MangoDB), Keyspaces (Cassandra)
- Object store: S3, Glacier
- Data warehouse (SQL Analytics / BI): Athena, EMR, Redshift (OLAP)
- Search: OpenSearch (JSON): free text, unstructured search
- Graph: Neptune
- Ledger: Quantum Ledger Database
- Time series: Timestream



# DocumentDB

- MongoDB
- ~ Deployment concept as Aurora: HA: replication across 3 AZ, storage incr: 10 GB



# Neptune

- Graph DB, e.g. social network



## Neptune Streams

- Real-time ordered change seq
- HA: 3 AZ, 15 RR
- No duplicates, strict order
- REST API acc
- Replicate Neptune across regions
- Scenario: sync graph data in another data store, e.g. S3, OpenSearch, ElastiCache



# Keyspaces

- Cassandra NoSQL dstb DB
- Tables replicated 3 times, multi-AZ
- Cassandra Query Language (CQL)
- <10ms latency, thousands req/sec
- Capacity: Provisioned mode + autoscaling | On-demand
- PITR: Max 35 days



# Timestream

- Time series DB
- 1000x faster & 1/10 cost of RDBMS
- Scheduled query, multi-measure records, SQL compatibility
- Storage Tier: recent data: mem, historical data: cost-optm storage
- Input: IoT, Kinesis, Prometheus
- Output: QuickSight, SageMaker, Grafana, JDBC connection



# Athena

- Serverless query service
- Source: S3
- Support: CSV, JSON, ORC, Avro, Parquet
- $: $5 per TB data scanned
- Combine w/ QuickSight for dashboard
- Scenario: BI, analytics, logs analysis (VPC Flow, ELB), CloudTrail trails

```SQL
CREATE EXTERNAL TABLE ...
ROW FORMAT ...
LOCATION 's3://target-bucket/prefix/';
```

## Optimisation

- Columnar data: less scan, less cost -> Parquet or ORC
- Glue: convert to Parquet, ORC
- Compress data for small retrieval
- Partition datasets in S3: easy query: `s3://my-bucket/pathToTable/<PARTITION_COLUMN_NAME>=<VALUE>/<PARTITION_COLUMN_NAME>=<VALUE>/...` 
e.g. `s3://my-bucket/flight/year=2026/month=1/day=1/`
- Larger file (>128MB): minimise overhead



## Federated Query

- Run SQL across relational, non-relational, custom data sources, both AWS and on-prem
- Lambda qua Data Source Connector to run query
- Store results to S3

# Redshift

- OLAP, column store, based on Postgres
- Cluster: Provisioned | Serverless 
- SQL interface
- Integration: BI, e.g. QuickSight, Tableau
- Faster query, join, aggregation by indexes vs. Athena



## Cluster

- Leader node: query planning, aggregation
- Compute node: perform query, send results to Leader
- Provisioned mode: choose inst type, RI



## Snapshot & DR

- Multi-AZ mode for some clusters
- PITR from S3
- Incremental backup
- Restore to new cluster
- Auto backup: every 8 hr, every 5 GB, schedule
- Auto copy snapshot to another region



## Data Source

- Data Firehose
- S3: COPY command, can add Enhanced VPC Routing

```SQL
COPY customer
FROM 's3://amzn-s3-demo-bucket/customer' 
iam_role 'arn:aws:iam::0123456789012:role/MyRedshiftRole';
```

- JDBC driver: EC2 batch write



## Spectrum

- Query data already in S3 w/o loading
- Query submit to thousands Redshift Spectrum nodes



# OpenSearch

- Search any field even partial match. Solve DynamoDB query by primary key or indexes
- Cluster: Managed | Serverless
- No native support for SQL, enable via plugin
- Ingestion: Data Firehose, AWS IoT, CloudWatch Logs
- Builtin Dashboard

Patterns

- DynamoDB: DynamoDB -> DynamoDB Streams -> Lambda -> OpenSearch
- CloudWatch: CloudWatch Logs -> Subscription Filter -> Lambda / Data Firehose -> OpenSearch
- Kinesis: Kinesis Data Streams -> Data Firehose + Lambda (~real-time) / Lambda (real-time) -> OpenSearch



# EMR: Elastic MapReduce

- Create Hadoop cluster (100+ EC2) for *Big data proc & analysis*
- Bundle w/ Spark, HBase, Flink, Presto
- Takes care provision & config
- Autoscaling & integrate w/ Spot inst
- Long-running or Transient (temp) cluster
- Scenario: data proc, ML, web index, big data



## Node Type

- Master: mng, coordinate, long running
- Core: run tasks and store data, long running
- Task (opt): run tasks, Spot inst
- EC2 purchase opt:
  - On-demand & RI (min 1 yr): Master & Core nodes
  - Spot: Task nodes



# QuickSight

- Serverless ML-powered BI dashboard
- SPICE engine: in-mem comp if using data import
- Column-Level Security (CLS)(Enterprise ver): prevent some clmns disp to some users



## Data Sources

- AWS Services: RDS, Aurora, Redshift, Athena, S3, OpenSearch, Timestream
- Import (SPICE): CSV, JSON, TSV, XLSX, ELF, CLF
- SaaS: salesforce, Jira
- On-prem DB (JDBC)



## Dashboard

- Read-only snapshot of an analysis to share
- Preserve conf of analysis
- Def User (Standard ver) & Group (Enterprise ver): only exist in QuickSight, NOT IAM
- Share analysis / dashboard to spec user or group
- User w/ perm to dashboard can see underlying data



# Glue

- Serverless ETL 
- Convert to Parquet: S3 Event Notification -> Lambda / EventBridge -> Glue (import data from S3) -> S3 out bucket -> Athena

Components:

- Job bookmark: prevent re-proc old data
- Glue DataBrew: clean & normalise data w/ pre-built transformation
- Studio: GUI to create, run, monitor ETL jobs
- Streaming ETL: based on Spark Structured Streaming. Compatibility: Kinesis, Kafka, MSK (managed Kafka)



## Data Catalog

- Data src -> Glue Data Crawler [Write Metadata] -> Data Catalog -> Glue
- Data Catalog [Data/Schema discovery] -> Athena / Redshift Spectrum / EMR



# Lake Formation

- Data lake
- Discover, cleanse, transform, ingest data
- Automate complex manual steps: collecting, cleansing, moving, cataloging, deduplicate
- Combine structured & unstructured data in data lake
- Blueprint: migration to Lake Formation, e.g. S3, RDS, RDBMS, NoSQL
- ***Row & Clmn lvl*** *Fine-grained acc control* for apps (Athena, Redshift, EMR, Spark): centralised perm control
- Data stored in S3
- Glue as backend


# Managed Apache Flink
- Framework for data stream proc
- AWS: provision comp resource, parallel comp, autoscaling, app backup (checkpoint, snapshot)
- Data src: Kinesis, MSK
- *No support: Data Firehose*

# MWAA: Managed Workflows for Apache Airflow
- Workflow: collection of tasks as DAG
- Integration: Apache Hadoop, Presto, Hive, Spark, S3, Redshift, EMR, AWS Batch, SageMaker


# MSK: Managed Streaming for Apache Kafka

- Alt to Kinesis
- MSK: mng Kafka Broker & Zookeeper nodes, auto recovery
- MSK cluster in VPC, multi-AZ
- Data in EBS
- MSK Serverless: MSK mng capacity, provision resource, autoscaling



## Kinesis vs. MSK


|               | Kinesis Data Streams                                     | MSK                              |
| ------------- | -------------------------------------------------------- | -------------------------------- |
| Msg Max Size  | 1MB                                                      | 1MB (default, config for higher) |
| Data Seq Unit | Shard                                                    | Topic w/ Partition (mapping)     |
| Data Seq Op   | Split / Merge                                            | Add Partition only               |
| Security      | TLS                                                      | PLAINTEXT / TLS                  |
| KMS Enc       | ✅                                                        | ✅                                |
| Consumer      | Managed Apache Flink, Glue, Lambda, app on EC2, ECS, EKS |                                  |




# Big Data Ingestion Pipeline

- IoT Core -> Kinesis -> Data Firehose (every 1 min) -> S3 -> Lambda -> Athena (pull data from S3) -> S3 out bucket -> Redshift / QuickSight
- IoT Core: harvest data from IoT devices
- Kinesis: real-time data collection
- Data Firehose: deliver to S3 ~real-time (1min)
- Lambda: data transformation for Data Firehose
- S3 trig SQS (opt) or Lambda directly
- Athena store results to S3 out bucket
- Redshift / QuickSight read S3 out bucket



# AI / ML

## Bedrock
- API acc to Foundation models (LLM)
- Knowledge Base: RAG, sources: S3, Aurora, etc.


## Rekognition

- ML for image & video
- Obj labelling, content moderation, text detection, facial analysis/search
- Content moderation: set min Confidence Threshold, flag sensitive content for manual review w/ Augmented AI (A2I)



## Transcribe

- Speech-to-text w/ ASR
- Auto remove Personally Identifiable Information (PII) using redaction
- Support auto language identification for multi-lingual audio



## Polly

- Text-to-audio
- Lexicon: customise word pronunciation, use in SynthesizeSpeech
  - Stylised word: 3x4mpl3 -> example
  - Acronym: AWS -> Amazon Web Services
- SSML: Speech Synthesis Markup Language
  - Emphasise spec words / phrases
  - Phonetic pronunciation
  - Breathing sounds, whispering



## Translate

- Localise content



## Lex & Connect

- Lex: ASR + Natural Language Understanding, like Alexa
- Connect: virtual contact center, Integration: CRM, AWS
- Phone call -> Connect -> Lex -> Lambda -> CRM



## Comprehend

- Serverless NLP
- Scenario: customer interaction analysis, group articles



### Comprehend Medical

- NLP to detect Protected Health Information (PHI) w/ DetectPHI API
- S3 / Data Firehose / Transcribe -> Comprehend Medical



## SageMaker

- Build ML models



## Kendra

- Document Search service powered by ML
- Extract answer from docs: text, pdf, HTML, PowerPoint, MS Word, etc.
- Incremental Learning: learn from user interactions/feedback to promote preferred results
- Manual fine-tuning search results



## Personalize

- Personalised recom, real-time
- S3 / Personalize API (real-time) -> Personalize -> Website / App / SMS / Email



## Textract

- Extract text from scanned docs



# CloudWatch



## Metrics

- Metric: var to monitor, e.g. CPU util
- Namespace: where metrics belong to, 1 Namespace per service
- Dimension: metric attr (inst id, env), Max 30 per metric
- Metrics have timestamps
- Create CloudWatch dashboards for metrics
- Create CloudWatch Custom Metrics



### Metric Streams

- ~Real-time stream metrics to Data Firehose, Datadog, Dynatrace, New Relic, Splunk, etc.
- Filter by namespace



## Logs

- Log group: arbitrary name, usually an app
- Log stream: inst w/in app, log files, containers
- Retention: never, 1 day - 10 yr
- Export to S3: log data up to 12 hr avail for export, API call: `CreateExportTask`
- Logs encrypted (default)
- Setup KMS-based enc w/ own keys



### Log Source

- SDK, CloudWatch Unified Agent
- Elastic Beanstalk: app log collection
- ECS: containers collection
- Lambda: function logs
- VPC Flow logs
- API Gateway
- CloudTrail: based on filter
- Route 53: DNS queries



### Insights

- Auto discover fields from AWS services and JSON logs
- Save queries to CloudWatch dashboard
- Query multi groups in diff AWS accounts
- Query engine, not real-time



### Log Subscription

- Send real-time logs: Kinesis, Data Firehose, Lambda, OpenSearch
- Subscription Filter



#### [Cross-Account Subscription](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CreateDestination.html)

- Doc step 3-7 
- Subscription Filter [Sender Account] -> Subscription Destination [Recipient Account] -> Kinesis

1. IAM Role: CloudWatch Logs -> Kinesis

```sh
aws iam create-role --role-name CWLtoKinesisRole \
  --assume-role-policy-document TrustPolicyForCWL.json
```

`TrustPolicyForCWL.json`

```json
{
    "Statement": {
        "Effect": "Allow",
        "Principal": {
            "Service": "logs.amazonaws.com"
        },
        "Condition": {
            "StringLike": {
                "aws:SourceArn": [
                    "arn:aws:logs:region:sourceAccountId:*",
                    "arn:aws:logs:region:recipientAccountId:*"
                ]
            }
        },
        "Action": "sts:AssumeRole"
    }
}
```

2. Role Perm (action) policy
  ```sh
  aws iam put-role-policy \
    --role-name CWLtoKinesisRole \
    --policy-name Permissions-Policy-For-CWL \
    --policy-document PermissionsForCWL.json
  ```

  `PermissionsForCWL.json`

  ```json
  {
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "kinesis:PutRecord",
        "Resource": "arn:aws:kinesis:region:999999999999:stream/RecipientStream"
      }
    ]
  }
  ```

3. Create Destination: asso Role & Kinesis to it
  ```sh
  aws logs put-destination \
    --destination-name "testDestination" \
    --target-arn "arn:aws:kinesis:region:999999999999:stream/RecipientStream" \
    --role-arn "arn:aws:iam::999999999999:role/CWLtoKinesisRole" \
    --access-policy AccessPolicy.json
  ```

  `AccessPolicy.json`: grant sender account acc
  ```json
  {
      "Version":"2012-10-17",
      "Statement": [
          {
              "Sid": "",
              "Effect": "Allow",
              "Principal": {
                  "AWS": "111111111111"
              },
              "Action": "logs:PutSubscriptionFilter",
              "Resource": "arn:aws:logs:us-east-1:999999999999:destination:testDestination"
          }
      ]
  }
  ```



### Live Tail

Log Management > Log Group > Start tailing

### CloudWatch Agent

- Run CloudWatch Agent in EC2/on-prem to send logs 
- IAM role: EC2 -> CloudWatch Logs
- Logs Agent: only send to CloudWatch Logs, older



#### Unified Agent

- Collect system lvl metrics, e.g. RAM, proc
- Centralised config: SSM Parameter Store
- Granular metrics
  - CPU: active, idle ,system, user
  - Disk: free, used, total; Disk IO: bytes, iops
  - RAM: free, inactive
  - Netstat: TCP, UDP
  - Process
  - Swap space:



## CloudWatch Alarm

- Trigger notification for metrics
- States: `OK`, `INSUFFICIENT_DATA`, `ALARM`
- Period: time length to evaluate the metric, time resolution
- Test: `aws cloudwatch set-alarm-state --alarm-name "test" --state-value ALARM --state-reason "testing"`



### Composite Alarm

- AND / OR cond
- CPU Hi AND Mem Lo -> Alarm



#### EC2 Inst Recovery

Status check:

- Inst: EC2 VM
- System: underlying HW
- Attached EBS status
- CloudWatch Alarm: StatusCheckFailed_System -> EC2 inst recovery
- Recovery: same private/public/Elastic IP, metadata, placement group



## Network Synthetic Monitor

- Monitor network issue b/w AWS & On-prem
- No agnet
- Test ICMP, TCP to on-prem dest IP thru Direct Connect or S2S VPN
- Publish to CloudWatch Metrics



## CloudWatch Insights

- Containers: ECS, EKS, K8s on EC2. In EKS / K8s, CloudWatch Insights is a CloudWatch Agent container
- Lambda
- Contributor: top-N contributors for some metrics
- Application: select tech on EC2 (Java, IIS, DB, etc.). Can select other AWS resources



# EventBridge

- Schedule (cronjob): trigger Lambda every 12 hr
- Event: Rule to react to an event, e.g. IAM Root User Sign in -> SNS Topic w/ Email notification
- Gen JSON to dest



## Event Bus

- default, partner, custom
- Archive & Replay archived events
- Resource-based Policy: allow events from other AWS account/region



## Schema Registry

- Analyse events in bus and infer schema
- Schema: versioned



# CloudTrail

- Gov, Compliance, Audit for AWS account
- *Record API calls (What, Who, When) in the AWS account*
- CloudTrail logs -> CloudWatch / S3
- All regions (default) or single region
- Separate Read Events from Write Events
- Events retention: 90 days
- CloudTrail -> EventBridge



## Management Event

- Operations perf on resources in AWS account
- Config sec, rules, logging
- CloudTrail logs Management Event (default)



## Data Event

- CloudTrail does NOT log (default)
- S3 obj lvl activity: GetObject, DeleteObject, PutObject
- Lambda: Invoke API



## CloudTrail Insights Event

- Detect unusual activity
- Cont. analysis on *Write Events*



# AWS Config

- Audit & Record Compliance of AWS resources
- Per-region, can aggregate across regions & accounts
- Custom config rules def in Lambda
- Rule trigger/evaluation: On config change, Periodic
- $: $0.003 per config rule, $0.001 per evaluation
- Does NOT prevent actions from happening
- Non-Compliant Remediation: trig SSM Automation Document
- Notification: EventBridge, SNS



# KMS: Key Management Service

- Encryption key mgmt
- Integrated w/ IAM for auth
- Symmetric: AWS services - KMS
- Asymmetric: public key downloadable

Key Types:

- AWS Owned: SSE-S3, SSE- SQS, etc.
- AWS managed: `aws/<service>` 
- Customer managed: Create / Import (External), $1 per mo
- KMS API call: $0.03 / 10000 calls

Key Rotation:

- AWS managed: auto every yr
- Customer managed: auto & on-demand
- Customer managed Import: manual using alias (of ARN)
- EBS snapshot copy to other region: EBS + KMS key A Snapshot -> Re-enc w/ KMS key B (AWS dec key A)

Enc & Dec w/ CLI

```sh
# 1. Enc
aws kms encrypt --key-id alias/<alias> --plaintext fileb://SecretFile.txt \
--output text \
--query CiphertextBlob  \
--region eu-west-2 > SecretFileEnc.base64

# --key-id: arn or alias

# base64 decode
cat SecretFileEnc.base64 | base64 -d > SecretFileEnc

# 2. Dec
aws kms decrypt --ciphertext-blob fileb://SecretFileEnc \
--output text \
--query Plaintext \
--region eu-west-2 > FileDec.base64  

# base64 decode
cat FileDec.base64 | base64 -d > FileDec.txt
```



## Key Policy

- Must use Key Policy to control acc to KMS key
- Cross-account acc



## Multi-Region Key

- Identical KMS key in diff. regions
- ARN: same except region
  - `arn:aws:kms:<region-1>:<account-id>:key/mrk-id`
  - `arn:aws:kms:<region-2>:<account-id>:key/mrk-id`
- No need re-enc or cross-region API call
- Not global: Primary + Replicas
- Scenario: global client-side enc, Global Aurora / DynamoDB: enc attr (clmn), e.g. SSN



## [S3 Replication Encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html)

- Un-encrypted & SSE-S3 obj replicated (default)
- SSE-KMS obj:
  - Spec key in target bucket
  - Key policy for target key
  - IAM Role: `kms:Decrypt` source KMS key, `kms:Encrypt` target KMS key
- Might get KMS throttling error, ask incr Service Quotas
- Can use Multi-region key, but S3 treats them as indepedent keys


## Share Encrypted AMI

- AMI: Launch Permission: target AWS account
- Key policy:

```json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<account-id>:role/<role>"
      },
      "Action": ["kms:Decrypt", "kms:ReEncrypt*", "kms:CreateGrant", "kms:DescribeKey"],
    }
  ]
}
```

- Target account can use new key to re-encrypt on launching EC2



# SSM Parameter Store

- Config & secret store
- Can enc w/ KMS
- Versioning
- Hierarchical structure
- Ref to secret: `/aws/reference/secretsmanager/<secret-id>`

```sh
aws ssm get-parameters --names <param-name> <param-name> ...
aws ssm get-parameters --names <param-name> --with-decryption
aws ssm get-parameters-by-path --path /path/to/param --recursive
```



## Parameter Policy

- TTL (expiration) to force update/delete 
- Advanced tier only
- `Expiration`: Delete
- `ExpirationNotification`: notify before exp
- `NoChangeNotification`: notify if no change happened



# Secrets Manager

- Secret store
- Capability to force secret rotation every X days
- Automate secret gen on rotation w/ Lambda
- Integration: RDS



## Multi-Region Secret

- Keep RR in sync w/ primary
- Able to promote RR to standalone



# ACM: AWS Certificate Manager

- TLS cert mgmt
- $0: public cert
- Auto cert renewal
- Integration: ELB, CloudFront, APIs on API Gateway



## Request Public Cert

1. Domain names: FQDN, wildcard (*.example.com)
2. Validation method:
  - DNS: for automation, util CNAME to DNS config
  - Email: send email to contact adr in WHOIS DB
3. Public cert auto renewal: 60 days bofore expiry



## Import Public Cert

- ❌ auto renewal
- ACM sends daily expiration event 45 days (default) before expiry
- AWS Config rule (alt): `acm-certificate-expiration-check`



## ACM - API Gateway

- Create Custom domain name in API Gateway
- Edge-Optimized: cert in `us-east-1`
- Regional: cert in the same region as API
- Private: acc from VPC w/ VPC endpoint (ENI)
- Setup CNAME or A-alias in Route 53



# CloudHSM

- User mng keys himself
- Redshift support CloudHSM for DB enc & key mgmt
- Scenario: SSE-C enc
- IAM policy: CRUD HSM cluster (HA)
- Integration: AWS Services (config KMS Custom Key Store: CloudHSM)



# WAF: Web Application Firewall

- *Layer 7* (HTTP) protection
- Deploy on: ALB, API Gateway CloudFront, AppSync GrpahQL API, Cognito User Pool
- ❌ NLB
- IP Set: Max 10,000 IP adr, multi rules for more IP
- Rule Group: reusable set of rules to add to ACL



## Web ACL Rules

- IP-based rule: select IP set
- Geo-based rule: allow/block
- Rate-based rule: DDoS 
- Request component: HTTP headers, body, query, URI string MATCH SQL injection, Cross-Site Scripting (XSS), Request Size constraint
- Web ACL are regional, except CloudFront



## WAF + ALB + Global Accelerator

- ALB does not have fixed IP
- WAF does NOT support NLB
- Global Accelerator for fixed IP



# Shield

Against DDoS

Standard:

- $0 for all customers
- Protect from SYN/UDP floods, reflection attacks, other Layer 3, 4 attacks

Advanced:

- Opt DDoS mitigation service: $3,000 per mo per organization
- Protect from more sophisticated attack on EC2, ELB, CloudFront, Global Accelerator, Route 53
- 24/7 to AWS DDoS response team (DRP)
- Protect from higher $ during DDoS 
- Auto create, evaluate & deploy WAF rules to mitigate Layer 7 attacks



# Firewall Manager

- Rules in an Org mgmt
- WAF rules, Shield advanced, SG for EC2 & ALB, ENI in VPC, Network Firewall (VPC), Route 53 resolver DNS firewall, Policies at region lvl
- Rules applied to new resources across Org



# DDoS Best Practices



## Edge Services

- CloudFront: app delivery at edge
- Global Accelerator: acc app from edge, i.e. AWS internal network proxy, Integration: AWS Shield

### Route 53
- Domain name resolution at edge
- NXDOMAIN (Non-Existent Domain) DDoS: A/Alias wildcard record 
  - Explicit A/Alias records precede wildcard
  - Wildcard: A/Alias: `*.example.com` to AWS resources, query not be charged 


## Infra Layer

- Global Accelerator + Route 53 + ELB
- Protect EC2 from Hi traffic



## Autoscaling

- ASG for flash crowd or DDoS



## Detect & Filtre Malicious Request

- CloudFront + WAF
- CloudFront: cache static content and serve from edge, geo block
- WAF: on top of CloudFront & ALB, filtre & block request



## Obfuscate AWS Resources

- CloudFront + ELB + API Gateway: hide backend EC2, Lambda



## SG + NACL (VPC)

- Filtre traffic from IP at subnet, ENI
- EIP protected by Shield Advanced
- SG: Inbound: IP `0.0.0.0/0`, Port `80`, `443`; Outbound: IP `0.0.0.0/0`, Port: `*`. SG becomes stateless, rely on NACL & WAF



## Protect API Endpoints: API Gateway

- Hide EC2, Lambda
- Edge-optimized mode / Regional mode + CloudFront
- Integration: WAF



# GuardDuty

- Intelligent threat discovery w/ ML, 3e party data, anomaly detection, crypto attack
- Inputs: CloudTrail Event logs, VPC Flow logs, DNS logs, etc. NO CloudWatch
- Logs -> GuardDuty -> EventBridge -> Lambda / SNS



# Inspector

- Sec assessment automation
- EC2: util AWS System Manager (SSM) agent, analyse unintended network acc, running OS against known vulnerabilities
- Container image push to ECR
- Lambda: Software vulnerabilites in func code & pkg dep
- Integration: AWS Security Hub, EventBridge



# Macie

- ML & pattern matching for sensitive data discovery
- Identify & alert sensitive data, e.g. PII

# Security Hub 
- Source: Inspector, GuardDuty, Macie, Security Hub CSPM, IAM Access Analyzer

## Security Hub CSPM: Cloud Security Posture Management
- Assess AWS resources against security standards, e.g. FSBP, CIS, PCI DSS, NIST
- Backend: AWS Config

# VPC

- Max 5 VPC per region (default)
- Max CIDR per VPC: 5; CIDR Max: /16, min: /28
- Only Private IPv4 ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- VPC CIDR NOT overlap w/ other VPC & on-prem network



## Subnet

- Reserved IP: 5, first 4 & last 1
  - `.0`: Network adr
  - `.1`: VPC router
  - `.2`: Amazon DNS
  - `.3`: future use
  - `.255` (or last): Network Broadcast
- Actions > Edit subnet settings > Auto-assign IP settings > Enable auto-assign public IPv4 address: yes/no



## IGW: Internet Gateway

- Allow resources in VPC to Internet
- Horizontal scale & HA
- 1:1 Mapping VPC-IGW
- IGW alone not allow Internet acc
- Route Table route: 0.0.0.0/0 -> IGW
- 1 Route Table per Subnet



## Bastion Host

- EC2 in Public Subnet conn to Private Subnet EC2
- SG: Inbound, SSH 22, Source: restricted public CIDR
- Private EC2 SG: Inbound, SSH 22, Source: Bastion Host SG or private IP



## NAT Gateway

- Allow Private EC2 to Internet
- HA, no admin
- $: per hr for usage & BW
- Zonal: provisioned in an AZ 
- NATGW in Public Subnet
- Attach EIP
- Route Table: 0.0.0.0/0 -> NATGW
- No SG
- Cannot used by EC2 w/in its Subnet, only from other subnets
- Private Subnet -> NATGW -> IGW
- BW: 5-100 Gbps
- Multi NATGW in multi-AZ for fault-tolerance, no cross-AZ failover



### RNAT: Regional NAT Gateway

- HA
- Provisioned in VPC
- Own Route Tables
- No need Public Subnet 
- Auto detect resources (Private Subnets) in new AZ and expand to the AZ



### NAT Instance

- Outdated
- In Public Subnet
- Attach EIP 
- Route Table: 0.0.0.0/0 -> NAT inst
- AMI avail
- Not HA -> create ASG in multi-AZ, resilient user-data
- SG:
  - Inbound: HTTP/HTTPS, Source: Private Subnets
  - Inbound: ICMP, Source: Private Subnets
  - Inbound: SSH, Source: user network
  - Outbound: HTTP/HTTPS, Destination: Internet
- Practice: NAT inst > Actions > Networking > Change source/destination check > ❌ Source / destination checking


## NACL: Network ACL

- Firewall policy at Subnet lvl
- 1 NACL per Subnet
- Stateless vs. Stateful (SG): return traffic must be explicitly set w/ allow rules; while Stateful auto allow return traffic
- Rule
  - Number (1-32766): smaller -> higher priority
  - Last (*): deny request in case no rule match
  - Add rule by increment of 100



### Ephemeral Port

- Client send request with an ephemeral port in a defined range (IANA & Win10: 49152-65535; Linux: 32768-60999), Server NACL must define outbound w/ ephemeral port range



### SG vs. NACL


|                      | SG       | NACL         |
| -------------------- | -------- | ------------ |
| Lvl                  | EC2      | Subnet       |
| Op                   | Allow    | Allow / Deny |
| Request Statefulness | Stateful | Stateless    |




## VPC Peering

- Conn 2 VPC w/ AWS network, cross-region & account
- ❌ CIDR overlap
- Non-transitive: VPC: A, B, C; Peering: A-B, B-C. A cannot go to C, must setup A-C.
- Update Route Tables in every subnet of VPC on both sides
- *SG rule: ref a peer VPC SG marche for diff accounts, but same region*



## VPC Endpoint

- VPC -> AWS service via VPC Endpoint
- Redundant, horizontal scale
- ⚠️ Issue: check DNS resolution in VPC



### Interface Endpoint

- ENI (private IP) as entry point
- Attach SG onto it
- Support most AWS services
- Acc from on-prem (S2S VPN / Direct Connect)
- $ per hr + per GB



### Gateway Endpoint

- Support:S3, DynamoDB
- Set as Target in Route Table
- No SG
- $0



## VPC Flow Logs

- Interface IP traffic: VPC, Subnet, ENI 
- Integration: S3, CloudWatch Logs, Data Firehose
- Capture also info from AWS managed interfaces: ELB, RDS, ElastiCache, Redshift, NATGW, TGW, etc.
- Syntax: `<version> <account-id> <interface-id> <srcaddr> <dstaddr> <srcport> <dstport> <protocol> <packets> <bytes> <start> <end> <action> <log-status>`
- VPC Flow Logs -> CloudWatch Logs -> CloudWatch Contributor Insights: Top-N IP
- VPC Flow Logs -> CloudWatch Logs (Metric filter: SSH, RDP) -> CloudWatch Alarm -> SNS
- VPC Flow Logs -> S3 -> Athena
- IAM Role: VPC Flow Logs -> CloudWatch Logs, `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`



### Troubleshoot SG & NACL

- Field: `<action>`
- Incoming: 
  - Inbound REJECT: NACL or SG
  - Inbound ACCEPT, Outbound REJECT: NACL
- Outgoing:
  - Outbound REJECT: NACL or SG
  - Outbound ACCEPT, Inbound REJECT: NACL



## Site-to-Site VPN (S2S VPN)

Pre:

- Virtual Private Gateway (VGW): VPN concentrator on AWS, 1:1 Mapping VGW-VPC, opt custom Autonomous System Number (ASN)
- Customer Gateway (CGW): on-prem VPN

Setup:

- CGW IP: if public -> public in AWS, if private -> NAT public IP (CGW behind this NAT device)
- Route Table: enable Route Propagation for VGW
- On-prem -> EC2 ping: SG: Inbound, ICMP



### VPN CloudHub

- Multi VPN conn, hub-and-spoke model
- 1:N Mapping VPC-VPN
- Setup Dynamic routing, config Route Tables



## DX: Direct Connect

- Private on-prem -> VPC conn, NOT via internet (VPN)
- On-prem Router / Firewall -> DX Location -> VGW
- Setup: 
  - Public Virtual Interface (VIF): on-prem -> AWS public resources
  - Private VIF: on-prem -> VGW
- Acc public (S3) & private resources (EC2) w/ DX 
- AWS | Customer/Partner Cage in DX Location
- *>1 month to estab a conn*
- If encrypted traffic desired: VPN b/w on-prem & DX

Scenario:
- BW thruput +, $ -
- Consistent network 
- Hybrid env
- In case DX fails, backup: S2S VPN (best), DX

### DX Gateway

- On-prem to VPCs in diff regions
- Asso. to VGWs or TGW


### Connection Type

Dedicated Connection: 1-400 Gbps

- Phys ethernet port
- Request to AWS, completed by DX partners

Hosted Connection: 50 Mbps - 25 Gbps

- Capacity +/- on-demand
- Request made via DX partners



### Resiliency

- High Resiliency: 1 conn in multi loc
  - On-prem 1 -> DX Loc 1 -> VGW
  - On-prem 2 -> DX Loc 2 -> VGW
- Maximum Resiliency: separate conn on separate devices in multi loc
  - On-prem 1 Router 1 -> DX Loc 1 Router 1 -> VGW
  - On-prem 1 Router 2 -> DX Loc 1 Router 2 -> VGW
  - On-prem 2 Router 1 -> DX Loc 2 Router 1 -> VGW
  - On-prem 2 Router 2 -> DX Loc 2 Router 2 -> VGW



## Transit Gateway

- Peering b/w VPCs & on-prem w/ hub-and-spoke topology
- Regional resource
- Marche cross-region
- Cross-account w/ Resource Access Manager (RAM)
- Peer TGW across regions
- Route Tables: limit which VPC can talk w/ other VPC
- Marche w/ VPN, DX Gateway
- Support *IP Multicast*, only TGW
- Multi account & VPC Direct conn: On-prem Router / Firewall -> DX Location -> DX Gateway -> TGW -> VPC



### S2S VPN ECMP: Equal-Cost Multi-Path Routing

- Allow pkt FW over multi best path
- Multi S2S VPN: incr BW to AWS
- On-prem Router / Firewall -> S2S VPNs -> TGW -> VPCs
- 1 S2S VPN - TGW conn util 2 tunnels, cf. S2S VPN: 2 tunnels, util 1, 1 for failover
- VPN -> VGW: 1.25 Gbps; VPN -> TGW: 2.5 Gbps (1x, ECMP), more VPN, more thruput



## Traffic Mirroring

- Capture & inspect VPC traffic
- Send To security appliances
- From (Source): ENI, To (Target): ENI / NLB
- Capture all or interested pkt
- Source & Target: same VPC or VPC Peering



## IPv6

- All IPv6 adr in AWS are public



## Egress-Only Internet Gateway

- IPv6 only Internet GW, ~ NATGW for IPv4
- Allow VPC outbound over IPv6, while preventing internet to init IPv6 conn to the inst
- Private Subnet Route Table


| Dest          | Target    |
| ------------- | --------- |
| IPv4 VPC CIDR | local     |
| IPv6 VPC CIDR | local     |
| 0.0.0.0/0     | NATGW-id  |
| ::/0          | EIGW-id   |




## Others

- PrivateLink / VPC Endpoint Service: Conn. VPC as service provider to others accounts' VPC as customer. Pre: NLB, ENI



## Network Firewall

- Layer 3-7 protection for VPC
- GWLB as backend
- Rule: IP, port, protocol, stateful domain list (*.example.com, 3e party repo)
- Allow, drop, alert




# AWS Networking Costs

- Ingress to EC2: $0
- Inter-EC2 w/ Private IP w/in AZ: $0
- Inter-EC2 w/ Private IP cross-AZ: $0.01 per GB
- Inter-EC2 w/ Public IP/EIP cross-AZ: $0.02 per GB
- Inter-EC2 cross-region: $0.02 per GB



## Egress Traffic

- AWS -> outside
- DX Location co-loc in the same Region



## S3 Data Transfer (US)

- S3 Ingress: $0
- S3 -> Internet: $0.09 per GB
- S3 Transfer Acceleration: Additional cost $0.04-0.08 per GB
- S3 -> CloudFront -> Internet: $0, $0.085 per GB
- S3 CRR: $0.02 per GB



## NATGW vs. VPC Endpoint


|                  | NATGW                         | VPC Endpoint             |
| ---------------- | ----------------------------- | ------------------------ |
| $                | $0.045 per hr + $0.045 per GB | 0                        |
| S3 Data Transfer | $0.09*, 0**                   | $0.01 per GB***, 0****   |


- *: cross-region
- **: same-region
- ***: same-region, Interface Endpoint
- ****: GW Endpoint



# DR

- RPO: Recovery Point Objective. Backup freq (time), lower -> better, det data loss in a time period
- RTO: Recovery Time Objective. RTO - Disaster = Downtime
- Methods (slow -> fast RTO): Backup & Restore -> Pilot Light -> Warm Standby -> Hot Site / Multi Site
- Failover: Route 53 + Application Recovery Controller (ARC)
  - ✅ Data plane: create Route 53 health checks qua on/oﬀ switches
  - ❌ Control plane: weighted routing policy



## Backup & Restore

- On-prem -> Storage GW / Snowball -> S3
- EBS, Redshift, RDS Snapshots
- Hi RPO, Hi RTO



## Pilot Light

- Pilot light: cirtical core, small ver of app always running on cloud
- On-prem DB replicate to RDS



## Warm Standby

- Full sys up & running @ min size on cloud
- ASG (min) -> Primary DB (on-prem), Primary DB replicate to RDS
- Disaster: Route 53 failover, ASG failover to RDS



## Hot Site / Multi Site

- Full prod scale on cloud
- Route 53 to on-prem & AWS active-active



# DRS: Elastic DR

- Cont. block lvl replication 
- AWS Replication Agent on-prem -> replication (sec) -> AWS Staging env
- Failover: mins
- Failback once recovered



# DMS: Database Migration Service

- Soruce DB remain avail during migration
- Cont. data replication w/ CDC
- EC2: running DMS, perform replication tasks
- Source: on-prem & EC2 DB, Azure SQL, RDS, Aurora, S3, DocumentDB
- Target: on-prem & EC2 DB, RDS, Redshift, DynamoDB, S3, OpenSearch, Kinesis, Kafka, DocumentDB, Neptune, Redis, Babelfish



## AWS SCT: Schema Conversion Tool

- Convert schema b/w  *engines*
- Schema conversion: Src SB -> On-prem server w/ SCT -> Target DB
- Migration: Src DB -> EC2: DMS -> Target DB



# RDS & Aurora Migrations

- RDS -> Aurora
  - Snapshot
  - Aurora RR, once replication lag = 0, promote as indepedent DB cluster
- External -> Aurora
  - MySQL: Percona XtraBackup -> S3 -> Restore from S3
  - MySQL (alt): Create Aurora MySQL -> `mysqldump` to Aurora
  - Postgres: Backup -> S3 -> Import w/ `aws_s3` Aurora extension
- DMS



# On-prem Strategy w/ AWS

- Download Amazon Linux AMI .iso
- VM Import / Export: migrate to EC2, DR repo for on-prem VMs, EC2 -> on-prem export back
- Application Discovery Service
- DMS
- MGN: on-prem live servers -> AWS incremental replication



# AWS Backup

- Mng & automate backups
- Support: EC2, EBS, EFS, FSx (Lustre, Win) S3, RDS, Aurora, DynamoDB, DocumentDB, Neptune, Storage GW
- Cross-Region & Account backup
- PITR (supported services)
- On-demand / Schedu;e
- Tag-based backup 
- Backup Plan: freq, window, transition to Cold Storage, retention
- Backup Vault Lock: enforce WORM, defend against inadvertent/malicious delete, updates qui shorten/alter retention. Root user cannot delete backups



# Application Discovery Service

- Gather on-prem info for migration
- Server util data, dependency mapping
- AWS Agentless Discovery Connector: VM inventory, config, performance history
- AWS Application Discovery Agent: sys config, performance, running proc, network conn
- View result in Migration Hub



# MGN: Application Migration Service

- Lift-and-shift (rehost)
- AWS Replication Agent on-prem -> AWS Staging env



# Transfer Large Data to AWS

- Internet / S2S VPN: BW, long
- DX: 1 mo setup + BW
- Snowball: 1 week, combined w/ DMS
- On-going replication: S2S VPN, DX, DataSync



# VMware Cloud on AWS

- Extend capacity to AWS



# Event Processing Arch

- SQS (retry, DLQ) -> Lambda 
- SNS -> Lambda (retry, DLQ to SQS), Lambda send to DLQ for its async
- Fan-out pattern: SDK -> SNS -> SQS subscriptions
- S3 Events: gen image thumbnail
- S3 -> EventBridge: 
  - Filtre w/ JSON rules
  - Multi dest
  - EventBridge capabilities: Archive, Replay, Reliable delivery
- EventBridge: API call -> AWS services -> CloudTrail -> EventBridge -> SNS



# Caching Strategy

- CloudFront -> API Gateway -> EC2/Lambda -> Redis/Memcached/DAX -> DB
- CloudFront -> S3



# HPC



## Data Mgmt & Transfer

- DX
- Snowball
- DataSync



## Compute & Networking

- EC2: CPU/GPU optm
- Spot inst/fleet + autoscaling
- Placement group: `Cluster` for network perf



### EC2 Enhanced Networking (SR-IOV)

- Hi BW, PPS (pkt per sec)
- *ENA: Elastic Network Adapter. Max 100 Gbps*
- Intel 82599 VF: Max 10 Gbps



### EFA: Elastic Fabric Adapter

- Improved ENA
- Linux only
- Inter-node comm, tightly coupled workloads
- Util MPI standard: bypass OS for lo-latency, reliable transport



## Storage



### Instance Attached Storage

- EBS: `io2 Block Express`
- Instance Store



### Network Storage

- S3: blob
- EFS: scale IOPS based on total size
- FSx for Lustre



## Automation & Orchestration

- AWS Batch: multi-node parallel jobs, single job across multi EC2
- AWS ParallelCluster: 
  - Config w/ text file, automate VPC, Subnet, cluster type, inst type
  - *Enable EFA*



# EC2 HA

- EIP
- ASG: min: 1, max: 1, desired: 1, AZ: >=2
- IAM Role for EC2 + User Data: allow API call + script to attach EIP to new EC2 based on Tag

```json
...
"Action": [
  "ec2:DescribeAddresses",
  "ec2:AssociateAddress"
]
```

- EBS: 
  1. Snapshot + tag on ASG Terminate lifecycle hook
  2. Create & attach EBS on ASG Launch lifecycle hook



# CloudFormation

- Decl. for AWS infra, IaC
- Cost saving: resources w/in a stack is tagged w/ an identifier, cost estimation w/ template
- Integration: Infrastructure Composer for resource visualisation



## Service Role

- IAM Role for CloudFormation to CRUD resources
- Give user ability w/o perm to control stack resources: `iam:PassRole`



# SES: Simple Email Service

- Allow in/out-bound emails
- Support: DomainKeys Identified Mail (DKIM), Sender Policy Framework (SPF)
- Flexible IP deployment
- Send emails w/ app using AWS Console, API, SMTP



# Pinpoint

- In/Out-bound marketing comm. service
- Support: email, SMS, push, voice, in-app messaging
- Pinpoint vs. SNS / SES:
  - SNS & SES: mng msg audience, content, delivery schedule
  - Pinpoint: create templates, delivery schedule, highly-targeted segments



# SSM Session Manager

- Start a SSH on EC2 & on-prem
- No need SSH acc, port 22, bastion host, SSH keys 
- Support: Linux, macOS, Win
- Session log data -> S3 / CloudWatch Logs
- User (IAM policy) -> SSM Session Manager -> EC2
- EC2 Launch instance ❌ key pair, SG allow SSH; ✅ IAM instance profile: policy: `AmazonSSMManagedInstanceCore` 
- SSM > Node Tools > Fleet Manager > Managed Nodes: check EC2 in the list
- SSM > Node Tools > Session Manager



# SSM Other Services



## Run Command

- Exec command/script across multi EC2/on-prem
- No need SSH
- Output: S3, CloudWatch Logs
- Trigger: EventBridge



## Patch Manager

- Patching automation: OS, app, security updates
- Support: EC2/on-prem Linux, macOS, Win
- On-demand / Maintenance Window
- Maintenance Window: Schedule, Duration, Set of registered inst, Set of registered tasks



## Automation

- Common maintenance & deployment tasks of EC2, EBS, RDS, etc.
- Automation Runbook: SSM Document, def action on AWS resources
- Trigger: AWS Console, CLI, SDK, EventBridge, Maintenance Window, AWS Config (rule remediations)



# Other Services



## Cost Explorer

- AWS costs & usage visualisation, understanding, mgmt
- Choose optm Savings Plan 
- Forecast: Max 18 mo



## Cost Anomaly Detection

- Cont. monitor costs & usage w/ ML



## AWS Outposts

- Hybrid cloud: server racks qui offer same AWS infra, services, APIs, tools
- AWS setup & mng Outposts racks w/in on-prem
- Customer responsible for phys sec

## AWS Batch

- Batch proc at scale
- Dynamic launch EC2 / Spot inst
- Submit/shcedule batch jobs, AWS Batch handles rest
- Docker image qua Batch job
- Run on ECS, EKS, Fargate



### AWS Batch vs. Lambda
|              | AWS Batch            | Lambda        |
| ------------ | -------------------- | ------------- |
| Time Limit   | ♾️                   | 15min         |
| Runtimes     | Docker image         | few prog lang |
| Temp Storage | EBS / Instance Store | 512MB - 10GB  |
|              | EC2                  | Serverless    |

## AppFlow
- Integrate AWS & SaaS
- Source: Salesforce, SAP, Zendesk, Slack
- Dest: AWS services, other SaaS
- Freq: schedule, event, on-demand

## Amplify 
- Elastic Beanstalk for web/mobile app
- Tools & Lib to build on AWS
- Backend: AWS services
- Frontend: React, Angular, Flutter, Android, etc.

## Instance Scheduler
- Sol, not Service, deployed thru CloudFormation
- Auto start/stop AWS services: $ -
- Support: EC2, ASG, RDS, cross-region & account
- DynamoDB Table: Schedule mgmt
- Resource Tag & Lambda: start/stop inst


# AWS Well-Architected Framework
## Principles
- Stop guessing capacity: ASG
- Test sys @ prod scale
- Automation for easy arch experiment: CloudWatch template
- Allow evolutionary arch: EC2 -> Lambda
- Drive arch thru data
- Improve thru game days: sim app for sale days

## 6 Pillars
1. Operational Excellence
2. Security
3. Reliability
4. Performance Efficiency
5. Cost Optimization
6. Sustainability

- AWS Well-Architected Tool: review arch against 6 pillars

# Trust Advisor
- Analyse AWS account on 6 categories: Operational excellence, Security, Fault tolerance, Performance, Cost optm, Service limits

# Ref
[AWS Architecture Center: Examples & Diagrams](https://aws.amazon.com/architecture/)
[AWS Solutions Library: Business & Tech Use Cases](https://aws.amazon.com/solutions/)
