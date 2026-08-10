# Task 3 — Containerization with ECS Fargate and Self-Hosted Monitoring

## Overview
Migration of the distributed LLM application from EC2/ASG-based deployment (Task 2)
to a containerized architecture on AWS ECS Fargate. Application services (LLM app,
web UI, Prometheus, Grafana) run as separate Docker containers, with persistent
monitoring storage on EFS and traffic routed through an Application Load Balancer.

Based on source code and infrastructure decisions carried over from Task 2
(`distributed-llm-aws`), which remains available as a reference/archive.

## Status: Planning / Setup

This repo was just created and populated with Task 2 source as a starting point.
Nothing below is implemented yet — this is a live checklist, not a completion report.

| Requirement | Status | Notes |
|---|---|---|
| Container Registry (ECR) | Not started | |
| ECS Cluster (Fargate, 2 AZs) | Not started | |
| Dockerize: LLM App (Ollama) | Not started | |
| Dockerize: Web Service | Not started | |
| Dockerize: Prometheus | Not started | |
| Dockerize: Grafana | Not started | |
| EFS for Prometheus data | Not started | |
| ECS Task Definitions (8+ CPU) | Not started | |
| ECS Services + autoscaling | Not started | |
| ALB with path-based routing | Not started | |
| RDS PostgreSQL connectivity | Reused from Task 2 | RDS instance kept alive outside Terraform state; VPC/subnets/SG being reconciled |
| Prometheus scraping all services | Not started | |
| Grafana dashboards | Not started | |
| Slack alerting | Not started | Task 2 used Discord — needs migration per Task 3 spec |
| CI/CD: build/push images, deploy task defs | Not started | |
| IAM least-privilege for ECS tasks | Not started | |
| Image vulnerability scanning | Not started | |
| Secrets management for containers | Not started | |
| NAT Gateways / routing | Reused from Task 2 (to be rebuilt) | Task 2 infra mostly destroyed; VPC/RDS subnets survived |

## Architecture (planned)

- VPC and RDS carried over from Task 2 environment (subject to reconciliation —
  see `docs/` for destroy/state notes).
- New: ECR repositories, ECS Fargate cluster, ALB, EFS, task definitions/services.
- Old (Task 2, being removed): ASG, Launch Templates, Packer AMI baking, bastion
  host, nginx reverse proxy, systemd-managed services.

## Repo structure

```
terraform/     # infra as code — being migrated from EC2/ASG to ECS/ECR/EFS
packer/        # Task 2 AMI baking — likely to be removed, kept for reference
lambda/        # Task 2 Discord notifier — kept for reference, may be replaced
bootstrap/     # cloud project bootstrap scripts
local-testing/ # local dev/test helpers
docs/          # Task 3 documentation and planning notes
```

## Notes
This README will be updated as each requirement above moves from
"Not started" to "In progress" to "Done" — no status will be marked
Done without a working, verifiable deployment behind it.