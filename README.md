# Grafana SOC Dashboard - Setup Guide

A containerized Security Operations Center (SOC) monitoring stack with Grafana, Prometheus, Loki, and Alertmanager.

## Architecture

| Service | Purpose | Port |
|---------|---------|------|
| Grafana | Visualization & dashboards | 3000 |
| Prometheus | Metrics collection & alerting | 9090 |
| Alertmanager | Alert routing & notifications | 9093 |
| Node Exporter | System metrics (CPU, memory, disk, network) | 9100 |
| Loki | Log aggregation & indexing | 3100 |
| Promtail | Log collection agent | — |

## Prerequisites

- Docker & Docker Compose installed
- Ports 3000, 9090, 9093, 9100, 3100 available

## Setup Steps

### 1. Configure Environment

```bash
cp .env.example .env
# Edit .env to set your admin password and ports
```

### 2. Start the Stack

```bash
docker-compose up -d
```

### 3. Wait for Services

```bash
# Services use health checks - wait until all are healthy
docker-compose ps
```

All services should show "healthy" status.

## Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | Set in .env file |
| Prometheus | http://localhost:9090 | No auth |
| Alertmanager | http://localhost:9093 | No auth |
| Loki | http://localhost:3100/ready | No auth |
| Node Exporter | http://localhost:9100/metrics | No auth |

## Dashboards

Four pre-provisioned dashboards are available under the **Security** folder:

1. **SOC Security Overview** — CPU/memory graphs, authentication events, failed login stats, error sources
2. **SOC Security Dashboard** — System gauges, security event stream, critical error log
3. **Node Exporter Metrics** — Detailed host metrics (CPU, memory, network, disk, load)
4. **Loki Logs Dashboard** — Live log stream, error rates, log volume, authentication failures

## Alert Rules

Prometheus evaluates the following alerts (routed via Alertmanager):

| Alert | Condition | Severity |
|-------|-----------|----------|
| HighCPUUsage | CPU > 80% for 5m | warning |
| HighMemoryUsage | Memory > 90% for 5m | warning |
| DiskSpaceLow | Disk < 10% free for 5m | critical |
| InstanceDown | Target down for 1m | critical |
| HighFilesystemUsage | Any mount > 85% full for 5m | warning |

To configure alert receivers (Slack, email, webhook, etc.), edit `alertmanager/alertmanager.yml`.

## Quick Verification

### 1. Check Services Running
```bash
docker-compose ps
```

### 2. Verify Prometheus Targets
http://localhost:9090/targets
- All targets should show "UP"

### 3. Verify Loki
```bash
curl http://localhost:3100/ready
```
Should return "ready"

### 4. Access Grafana
http://localhost:3000
- Login with credentials from your .env file
- Go to Configuration > Data Sources
- Both Prometheus and Loki should show "Connected"

### 5. Generate Test Data
```bash
# Generate some logs
for i in {1..10}; do
  logger "Test log message $i"
  sleep 1
done
```

### 6. View Data in Grafana
- Go to Explore (compass icon)
- Select Prometheus > Run query: `up`
- Select Loki > Run query: `{job=~".+"}`
- You should see data

## Log Collection

Promtail collects logs from:
- `/var/log/*log` — General system logs (job: `varlogs`)
- `/var/log/auth.log` — Authentication logs (job: `authlog`)
- `/var/log/syslog` — Syslog (job: `syslog`)
- Docker container logs — All container JSON logs (job: `containers`)

## Data Retention

- **Prometheus**: 30 days (configurable via `--storage.tsdb.retention.time`)
- **Loki**: 30 days (configurable via `retention_period` in `loki/loki-config.yml`)

## Stop Everything
```bash
docker-compose down
```

## Clean Start (Reset Everything)
```bash
docker-compose down -v
docker-compose up -d
```

## Troubleshooting

Service not starting?
```bash
docker-compose logs [service-name]
```

No data showing?
```bash
# Check Prometheus
curl http://localhost:9090/api/v1/targets

# Check Loki
curl http://localhost:3100/loki/api/v1/labels

# Check Alertmanager
curl http://localhost:9093/-/healthy
```
