#!/bin/bash
set -e

echo "SSM Agent is pre-installed on Amazon Linux 2023 — verifying it's enabled..."
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

echo "Installing Docker..."
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

echo "Installing AWS CLI (needed to read SSM secrets at boot)..."
sudo dnf install -y aws-cli

echo "Setting up Grafana provisioning (CloudWatch data source)..."
sudo mkdir -p /etc/grafana-provisioning/datasources
sudo cp /tmp/grafana-datasource-cloudwatch.yaml /etc/grafana-provisioning/datasources/cloudwatch.yaml

echo "Setting up Grafana dashboard provisioning..."
sudo mkdir -p /etc/grafana-provisioning/dashboards
sudo cp /tmp/grafana-dashboard-provider.yaml /etc/grafana-provisioning/dashboards/provider.yaml
sudo cp /tmp/grafana-dashboard-db-health.json /etc/grafana-provisioning/dashboards/db-health.json
sudo cp /tmp/grafana-dashboard-web-service-usage.json /etc/grafana-provisioning/dashboards/web-service-usage.json
sudo cp /tmp/grafana-dashboard-container-health.json /etc/grafana-provisioning/dashboards/container-health.json
sudo cp /tmp/grafana-dashboard-llm-service-performance.json /etc/grafana-provisioning/dashboards/llm-service-performance.json

echo "Setting up Grafana alerting provisioning..."
sudo mkdir -p /etc/grafana-provisioning/alerting
sudo cp /tmp/grafana-alert-rules.yaml /etc/grafana-provisioning/alerting/alert-rules.yaml
sudo cp /tmp/grafana-contact-points.yaml /etc/grafana-provisioning/alerting/contact-points.yaml

echo "Setting up Grafana systemd service (fetches admin password + Discord webhook from SSM at boot)..."
sudo tee /etc/systemd/system/grafana.service > /dev/null <<'SVC'
[Unit]
Description=Grafana (Docker)
After=docker.service network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/bin/docker rm -f grafana
ExecStart=/bin/bash -c '\
  GRAFANA_PASSWORD=$(aws ssm get-parameter --name "/distributed-llm-ecs-fargate/dev/grafana_admin_password" --with-decryption --query "Parameter.Value" --output text --region eu-central-1) && \
  DISCORD_WEBHOOK=$(aws ssm get-parameter --name "/distributed-llm-ecs-fargate/dev/discord_webhook_url" --with-decryption --query "Parameter.Value" --output text --region eu-central-1) && \
  sed -i "s|__DISCORD_WEBHOOK_URL__|$DISCORD_WEBHOOK|" /etc/grafana-provisioning/alerting/contact-points.yaml && \
  docker run -d --name grafana --restart always -p 3000:3000 \
    -v /etc/grafana-provisioning:/etc/grafana/provisioning \
    -e "GF_SECURITY_ADMIN_USER=admin" \
    -e "GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_PASSWORD" \
    grafana/grafana'

[Install]
WantedBy=multi-user.target
SVC
sudo systemctl daemon-reload
sudo systemctl enable grafana

echo "Bastion image build complete — Grafana will start automatically on first boot via grafana.service"
