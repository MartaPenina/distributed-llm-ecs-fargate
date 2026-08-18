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

echo "Installing nginx and certbot for HTTPS..."
sudo dnf install -y nginx python3-certbot-nginx

echo "Configuring nginx as reverse proxy to Grafana (localhost:3000)..."
sudo tee /etc/nginx/conf.d/grafana.conf > /dev/null <<'NGINX'
server {
    listen 80;
    server_name grafana.ecs.fault-lens-penina.pp.ua;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

sudo systemctl enable nginx
sudo systemctl start nginx

# NOTE: certbot is NOT run here at image-build time — DNS must already point
# at this instance's Elastic IP before certbot can validate ownership
# (HTTP-01 challenge), and the EIP isn't attached yet during the Packer
# build. Certbot runs once, automatically, after boot instead.

echo "Setting up one-shot certbot service (runs after boot, once EIP + DNS are live)..."
sudo tee /etc/systemd/system/certbot-init.service > /dev/null <<'SVC'
[Unit]
Description=Obtain Let's Encrypt certificate for Grafana (one-shot, after network is up)
After=network-online.target nginx.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot --nginx -d grafana.ecs.fault-lens-penina.pp.ua --non-interactive --agree-tos -m marta.penina.academic@gmail.com --redirect
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SVC

sudo systemctl daemon-reload
sudo systemctl enable certbot-init.service
# Not started here — DNS won't resolve to this host during the Packer build.
# It runs automatically on first real boot instead.

echo "Certbot auto-renewal is installed system-wide by the certbot package (systemd timer certbot-renew.timer) — no extra config needed."

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
