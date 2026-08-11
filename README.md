# Task 3 — Containerization with ECS Fargate and Self-Hosted Monitoring

## Overview
Migration of the distributed LLM application from EC2/ASG-based deployment (Task 2)
to a containerized architecture on AWS ECS Fargate. Application services run as
separate Docker containers behind an ALB, with persistent monitoring storage on
EFS. Metrics visualization uses AWS Managed Grafana rather than a self-hosted
Grafana container.

Based on source code and infrastructure decisions carried over from Task 2
(`distributed-llm-aws`). Full requirements: see `docs/task3-requirements.md`.

## Status: Planning / Setup

This repo was just created and populated with Task 2 source as a starting point
(branch `task3`). Nothing below is implemented yet — this is a live checklist.

## Guidance (execution plan)

1. **Order of execution**: Container Registry Setup (ECR) is done manually in
   the AWS Console first, to build hands-on understanding, before automating it
   in Terraform. All other requirements are automated (Terraform) from the start.
2. Every existing Terraform resource gets explained/reviewed before being
   modified or removed — no blind deletion of Task 2 code.
3. Before starting each requirement, the relevant new AWS concept/technology is
   explained first.
4. Nothing gets deleted from this repo until each `terraform/modules/*` folder
   has been reviewed together, module by module, and a keep/modify/remove
   decision is recorded (see `docs/task3-module-review.md`, to be created as we
   go).

## Container image strategy

| Component | Registry | Why |
|---|---|---|
| LLM App (Ollama + model) | **Amazon ECR** — custom image, model baked in at build time | Avoids re-downloading the model (several GB) from the internet on every task start/restart; costs time and data-transfer money otherwise |
| Web Service (AnythingLLM) | Docker Hub — unmodified upstream image | No code changes made to it; no benefit to mirroring into ECR |
| Prometheus | Docker Hub — unmodified upstream image + own `prometheus.yml` mounted at runtime | Config supplied via EFS/task definition, not baked into the image — keeps the image generic and avoids unnecessary ECR storage |
| Grafana | **Not containerized** — AWS Managed Grafana (AMG) | Task requirement specifies "Managed Grafana"; runs as a separate AWS service, not an ECS task |

**ECR persistence across `destroy`**: the ECR repository (and the Ollama+model
image inside it) will live in its own Terraform state — mirroring how RDS is
already kept separate in this project (`terraform/rds/`). A nightly
`terraform destroy` on the main stack (ECS, ALB, EFS, etc.) will not touch ECR,
so the baked model image never needs re-uploading. Lifecycle policy will prune
old/unused image tags so the repo doesn't grow unbounded.

## Architecture (planned, pending diagram update)

- VPC and RDS carried over from Task 2 environment.
- New: ECR (Ollama+model image, separate state), ECS Fargate cluster (2 AZs),
  ALB with path-based routing, EFS for Prometheus data, AWS Managed Grafana.
- Note: current draft architecture diagram shows Grafana as an ECS task in each
  AZ — this is outdated and will be corrected to reflect AWS Managed Grafana as
  a separate service, per the decision above.
- Old (Task 2, being reviewed for removal): ASG, Launch Templates, Packer AMI
  baking, bastion host, nginx reverse proxy, systemd-managed services.

## Repo structure

```
terraform/     # infra as code — being migrated from EC2/ASG to ECS/ECR/EFS
  rds/         # existing separate state for RDS (kept)
  modules/     # under review module-by-module (see docs/task3-module-review.md)
packer/        # Task 2 AMI baking — under review, likely removed
lambda/        # Task 2 Discord notifier — under review, Slack replaces Discord per Task 3
bootstrap/     # cloud project bootstrap scripts
local-testing/ # local dev/test helpers
docs/          # Task 3 documentation, requirements, and planning notes
```

## Requirement checklist

| Requirement | Status | Notes |
|---|---|---|
| ECR (registry, tagging, repo policy) | Not started | Manual in console first, then Terraform (separate state) |
| ECS Cluster (Fargate, 2 AZs) | Not started | |
| Dockerize: LLM App (Ollama + model) | Not started | Custom image -> ECR |
| Web Service (AnythingLLM) | Not started | Docker Hub, unmodified |
| Dockerize: Prometheus | Not started | Docker Hub image + mounted config |
| Grafana | Not started | AWS Managed Grafana, not containerized |
| EFS for Prometheus data | Not started | |
| ECS Task Definitions (8+ CPU) | Not started | |
| ECS Services + autoscaling | Not started | |
| ALB with path-based routing | Not started | |
| RDS PostgreSQL connectivity | Reused from Task 2 | Connection pooling to be added |
| Prometheus scraping all services | Not started | |
| Managed Grafana dashboards | Not started | |
| Slack alerting | Not started | Task 2 used Discord — migrating to Slack per Task 3 spec |
| CI/CD: build/push images, deploy task defs | Not started | |
| IAM least-privilege for ECS tasks | Not started | |
| Image vulnerability scanning | Not started | |
| Secrets management for containers | Not started | |
| NAT Gateways / routing | Reused from Task 2 (being rebuilt) | |

## Notes
This README updates as each requirement moves from "Not started" to
"In progress" to "Done" — no status marked Done without a working,
verifiable deployment behind it.