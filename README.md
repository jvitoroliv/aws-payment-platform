# Payment Processing Platform — AWS Infrastructure

Enterprise payment processing infrastructure running on AWS. Terraform modules, ECS Fargate services, Jenkins and GitHub Actions pipelines, backup automation, and a tagging system that tracks costs and ownership across hundreds of resources.

I work on the platform team maintaining and extending the IaC that runs the payment processing stack. Card processing workers, APIs, SFTP integrations, and the surrounding infrastructure.

## What this is

The platform processes payment card transactions at scale. The platform runs on ECS Fargate with SQS-driven job workers handling different payment flows (Visa, Mastercard, Corecard, CorePlatform, and several proprietary processors). Everything's in AWS, spread across multiple accounts with environment isolation.

The repos here cover:

- **Shared Terraform modules** — reusable building blocks that every team pulls from
- **Tag operations platform** — the main payment processing stack (15+ workers, 4 services, queues, email, SFTP)
- **Account infrastructure** — per-environment AWS setup with separate pipelines
- **Common modules** — ECS services, load balancers, backups, SNS, SQS, EC2 ASGs, Active Directory

## Architecture

### Payment processing core (`ps-tag-ops`)

This is the big one. A single Terraform configuration that orchestrates the entire payment processing platform:

**ECS Fargate Cluster** (`tagcore`)
- 15+ SQS-driven job workers, each with its own queue and autoscaling threshold
- 4 long-running Fargate services behind ALBs

**Job Workers:**

| Worker | What it processes |
|---|---|
| `card-processor` | Corecard payment events |
| `coreplatform` | CorePlatform transaction processing |
| `file-arrival` | Inbound file detection and routing |
| `mastercard` | Mastercard network events |
| `visa` | Visa network events |
| `finserv` | FINSERV-specific card events |
| `partner` | Partner account finance processing |
| `statements` | Statement generation |
| `card-migration` | Card migration batch jobs |
| `partner-a-coreplatform` | Partner-A via CorePlatform |
| `partner-a-fi` | Partner-A financial institution events |
| `partner-b-fi` | Partner-B financial institution events |
| `mail` | Email notification processing |
| `scheduled-event` | Time-triggered batch operations |

Each worker reads from its own SQS queue. Autoscaling is based on `ApproximateNumberOfMessagesVisible`. When messages pile up, more tasks spin up. When the queue drains, they scale back down. The thresholds vary per worker depending on processing speed and message volume.

**Services:**

| Service | Type | Access |
|---|---|---|
| `common-api` | Internal API | Internal ALB, allowlist SG |
| `web` | Web frontend | Public ALB, allowlist SG |
| `api` | External API | Public ALB, allowlist SG |
| `payment-api` | Payment processing API | Internal ALB, allowlist SG |

Every service gets:
- Its own ALB (public or internal depending on the service)
- Security groups with IP allowlists, no open-to-the-world endpoints
- Datadog logging sidecar
- CrowdStrike Falcon endpoint security agent
- Container images pulled from Artifactory (not ECR, corporate registry)

**Supporting infrastructure:**
- SQS queues for each worker (with dead-letter queues)
- SNS topics for event fanout
- SES for transactional email with bounce handling (SNS notifications on bounces)
- CloudWatch scheduled events triggering the `scheduled-event` worker
- SFTP Transfer Family server for file-based integrations
- Multi-region support with `local.active_region` selection for DR

### Shared modules (`cpt-common-modules`)

These are the building blocks every team uses. Each module lives at the top level of the repo:

| Module | Purpose |
|---|---|
| `ecs_service` | Complete ECS service: IAM roles, task definition, ALB target group, listener rule, placement strategy |
| `load_balancer` | ALB with optional WAF, access logs, security groups |
| `sqs_queue` | SQS queue with DLQ, encryption, retention policies |
| `sns_topic` | SNS topic with subscriptions and access policies |
| `ec2_asg` | Auto Scaling Group with launch template, scaling policies, lifecycle hooks |
| `backups` | Automated AMI backup via Lambda (orchestrator + worker pattern) |
| `aws_managed_ad` | AWS Directory Service Managed AD setup |
| `cifs_instance` | CIFS/SMB file share EC2 instance |
| `central-account` | Cross-account IAM roles and policies |
| `controlm_ec2` | Control-M agent EC2 instances |
| `cpt_tags` | Standard tagging module (cost center, environment, owner) |
| `docker` | Docker build and push to ECR |

The `ecs_service` module is the workhorse. It creates everything a service needs in one `module` block:

- Service IAM role with ECS + ELB permissions
- Task IAM role with ECS task assume + EC2 permissions
- ALB target group with configurable health checks (path, interval, thresholds)
- Listener rule attached to the ALB
- ECS task definition with Docker volume support
- ECS service with spread placement across AZs and `distinctInstance` constraint
- Lifecycle ignore on `desired_count` so autoscaling doesn't fight Terraform

The module uses Terraform 0.11-era interpolation syntax (`${var.xxx}`). Legacy code that's been running in production for years. It works, it's tested, and rewriting it for HCL2 syntax isn't worth the risk.

### Backup system

Two-Lambda architecture:

1. **`backup_initiator_lambda`** — Orchestrator. Invokes the AMI backup worker, waits 120 seconds for the snapshots to complete, then invokes the log storage function. Sequential flow, nothing fancy.

2. **`schedule_ami_backup_worker_backups`** — Worker. Takes a list of EC2 instances, creates AMIs with timestamps in the name, tags them for retention.

3. **`store-logs`** — Ships the backup results to the logging pipeline.

The 120-second sleep in the orchestrator isn't elegant, but it's reliable. AMI creation is async in AWS. You call `create_image` and it returns immediately. The sleep gives the snapshots time to start before the log function tries to report on them.

### Account infrastructure (`coreplatform-account-infrastructure`)

Per-environment AWS account setup. Each environment (DEMO, PROD, etc.) has its own pipeline directory with separate YAML files per component:

```
pipelines/
├── DEMO/
│   ├── LAMBDAS.yml
│   ├── DB.yml
│   └── PET_CERBERUS_RESTORE.yml
├── PROD/
│   ├── LAMBDAS.yml
│   ├── DB.yml
│   └── ...
└── ...
```

This separation means you can deploy just the Lambda functions in DEMO without touching the database config, or update the database in PROD without redeploying anything else. Each component pipeline runs independently.

## CI/CD

Two pipeline systems coexist. Legacy Jenkins and newer GitHub Actions:

**Jenkins (existing):**
- `DeployJenkinsfile` — Terraform apply for deployments
- `MergeJenkinsfile` — Runs on PR merge to main
- `PRJenkinsfile` — Terraform plan on pull requests (no apply)

**GitHub Actions (migration in progress):**
- New workflows replacing Jenkins jobs one at a time
- Same Terraform plan-on-PR, apply-on-merge pattern
- Benefits: better parallelism, native GitHub integration, no Jenkins server to maintain

The migration from Jenkins to GitHub Actions is incremental. Both systems point at the same Terraform state, so there's no conflict risk. Only one runs at a time per environment.

## Security

PCI-DSS compliance is a constant here. Every piece of infrastructure reflects that:

- **Network isolation:** Each service's security group uses IP allowlists. No `0.0.0.0/0` ingress rules on any production resource.
- **Endpoint security:** CrowdStrike Falcon agent runs as a sidecar in every ECS task definition.
- **Logging:** Datadog agent sidecar in every task captures container logs. No gaps in the audit trail.
- **Encryption:** SQS queues use server-side encryption. S3 buckets have default encryption enabled.
- **IAM:** Task roles follow least privilege. Each service gets only the permissions it needs, not a shared role.
- **Container registry:** Images come from Artifactory with vulnerability scanning, not direct pulls from Docker Hub.

## Tech stack

| Layer | Tools |
|---|---|
| Cloud | AWS (ECS Fargate, SQS, SNS, SES, ALB, S3, CloudWatch, Transfer Family) |
| IaC | Terraform (0.11 through 1.x, varies by repo age) |
| CI/CD | Jenkins (legacy) + GitHub Actions (migration) |
| Containers | ECS Fargate, Artifactory registry |
| Monitoring | Datadog |
| Security | CrowdStrike Falcon, PCI-DSS controls |
| Queue | SQS with autoscaling |
| Email | SES with bounce handling via SNS |
| File transfer | AWS Transfer Family (SFTP) |

## Repository structure

```
finserv/repos/
├── ps-tag-ops/                         # Main payment platform
│   ├── terraform/
│   │   └── tag_core/
│   │       └── tag-core.tf             # ~400 lines, the whole platform
│   ├── docker/
│   ├── scripts/
│   ├── DeployJenkinsfile
│   ├── MergeJenkinsfile
│   └── PRJenkinsfile
├── cpt-common-modules/                 # Shared Terraform modules
│   ├── ecs_service/
│   ├── load_balancer/
│   ├── sqs_queue/
│   ├── sns_topic/
│   ├── ec2_asg/
│   ├── backups/
│   │   └── lambda/
│   │       └── backup_initiator_lambda.py
│   ├── aws_managed_ad/
│   ├── cifs_instance/
│   ├── central-account/
│   ├── controlm_ec2/
│   ├── cpt_tags/
│   └── docker/
├── coreplatform-account-infrastructure/   # Per-environment account setup
│   └── pipelines/
│       ├── DEMO/
│       ├── PROD/
│       └── .../
└── [20 more repos]                     # Additional infrastructure repos
```

## Design decisions

**Why SQS-driven workers instead of direct API calls?** Decoupling. A Visa network event doesn't block while Mastercard processing is slow. Each worker scales independently based on its own queue depth. If the Visa worker needs 10 tasks but mail only needs 1, that's exactly what happens. A failure in one worker doesn't cascade to another.

**Why separate ALBs per service?** Security boundaries. `payment-api` sits behind an internal ALB, unreachable from the internet. `web` is public-facing but locked to specific IP ranges. Different services, different exposure profiles, different security groups.

**Why Artifactory and not ECR?** Corporate standard. Artifactory provides a single registry across the organization with centralized vulnerability scanning and access policies. ECR would be simpler per-account, but you'd lose the centralized view.

**Why keep Terraform 0.11 syntax?** Risk management. These modules run in production handling real payment transactions. A syntax migration touches every file and every variable interpolation. The benefit of cleaner HCL doesn't justify the risk of a missed variable reference in a payment processing module. The migration happens module by module, tested end to end, not as a bulk rewrite.

**Why the 120-second sleep in the backup orchestrator?** Pragmatism. AWS AMI creation is async. You could poll `describe_images` in a loop waiting for the state to change, but that adds complexity, API calls, and failure modes. The sleep is crude but it works, and backup timing isn't latency-sensitive. If the snapshot takes longer than 120 seconds, the logs just show it as "in progress." Nothing breaks.
