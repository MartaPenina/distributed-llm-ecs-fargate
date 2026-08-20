packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "aws_region" {
  default = "eu-central-1"
}
variable "aws_profile" {
  default = "distributed-llm-aws"
}
variable "base_ami" {
  # Amazon Linux 2023 base image — update if needed via:
  # aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*-x86_64" --query 'Images | sort_by(@, &CreationDate)[-1].ImageId'
  default = "ami-0ae7d073c75a47c24"
}

source "amazon-ebs" "bastion" {
  profile       = var.aws_profile
  region        = var.aws_region
  source_ami    = var.base_ami
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"

  ami_name        = "distributed-llm-ecs-fargate-grafana-bastion-{{timestamp}}"
  ami_description = "Amazon Linux 2023 Grafana Bastion Host with SSM Agent (Task3 - self-hosted Grafana, no Prometheus)"

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Project     = "distributed-llm-ecs-fargate"
    ManagedBy   = "packer"
    Type        = "grafana-bastion"
    BuildDate   = "{{timestamp}}"
    BuildSource = "{{build_name}}"
  }
}

build {
  sources = ["source.amazon-ebs.bastion"]

  provisioner "file" {
    source      = "${path.root}/scripts/grafana-datasource-cloudwatch.yaml"
    destination = "/tmp/grafana-datasource-cloudwatch.yaml"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/grafana-dashboard-provider.yaml"
    destination = "/tmp/grafana-dashboard-provider.yaml"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/grafana-dashboard-all-services.json"
    destination = "/tmp/grafana-dashboard-all-services.json"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/grafana-dashboard-db-health.json"
    destination = "/tmp/grafana-dashboard-db-health.json"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/grafana-dashboard-web-service-usage.json"
    destination = "/tmp/grafana-dashboard-web-service-usage.json"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/grafana-dashboard-container-health.json"
    destination = "/tmp/grafana-dashboard-container-health.json"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/grafana-dashboard-llm-service-performance.json"
    destination = "/tmp/grafana-dashboard-llm-service-performance.json"
  }
  
  provisioner "file" {
    source      = "${path.root}/scripts/grafana-alert-rules.yaml"
    destination = "/tmp/grafana-alert-rules.yaml"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/grafana-contact-points.yaml"
    destination = "/tmp/grafana-contact-points.yaml"
  }

  provisioner "shell" {
    script = "${path.root}/scripts/install-bastion.sh"
  }
}
