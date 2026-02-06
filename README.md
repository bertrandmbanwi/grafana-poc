# SOC Monitoring Stack

A containerized Security Operations Center (SOC) monitoring and observability stack with Grafana, Prometheus, Loki, Alertmanager, and a built-in alert logger.

## Architecture

| Service | Purpose | Port |
|---------|---------|------|
| Grafana | Visualization & dashboards | 3000 |
| Prometheus | Metrics collection & alerting | 9090 |
| Alertmanager | Alert routing & notifications | 9093 |
| Alert Logger | Webhook alert receiver (logs to stdout) | 5001 |
| Node Exporter | System metrics (CPU, memory, disk, network) | 9100 |
| Loki | Log aggregation & indexing | 3100 |
| Promtail | Log collection agent | — |

## Prerequisites

- Docker & Docker Compose installed
- Ports 3000, 3100, 5001, 9090, 9093, 9100 available

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
| Alert Logger | docker logs alert-logger | — |
| Loki | http://localhost:3100/ready | No auth |
| Node Exporter | http://localhost:9100/metrics | No auth |

## Dashboards

Four pre-provisioned dashboards are available under the **Security** folder. All dashboards include **template variables** (Instance, Log Source, Mount Point) for filtering:

1. **SOC Security Overview** — CPU/memory graphs, authentication events, failed login stats, error sources
2. **SOC Security Dashboard** — System gauges, security event stream, critical error log
3. **Node Exporter Metrics** — Detailed host metrics (CPU, memory, network, disk, load with CPU core context)
4. **Loki Logs Dashboard** — Live log stream, error rates by job, log volume breakdown, authentication failures

## Alert Rules

Prometheus evaluates the following alerts (routed via Alertmanager to the alert-logger):

| Alert | Condition | Severity |
|-------|-----------|----------|
| HighCPUUsage | CPU > 80% for 5m | warning |
| HighMemoryUsage | Memory > 90% for 5m | warning |
| DiskSpaceLow | Any filesystem < 10% free for 3m | critical |
| InstanceDown | Target down for 1m | critical |
| HighFilesystemUsage | Any mount > 85% full for 5m | warning |
| HighNetworkErrors | Interface errors > 10/sec for 5m | warning |
| HighLoadAverage | Load/CPU ratio > 1.5 for 10m | warning |

### Viewing Fired Alerts

Alerts are delivered to the built-in alert-logger container:

```bash
# View all fired alerts with timestamps
docker logs alert-logger

# Follow alerts in real-time
docker logs -f alert-logger
```

You can also view alert status in the Alertmanager UI at http://localhost:9093.

To configure external receivers (Slack, email, PagerDuty), edit `alertmanager/alertmanager.yml`.

## HTTPS / TLS (Free, Local)

You can enable HTTPS for Grafana using free, locally-generated certificates:

```bash
# Generate certificates (uses mkcert if installed, otherwise openssl)
chmod +x setup-tls.sh
./setup-tls.sh

# Add to your .env file:
GF_SERVER_PROTOCOL=https
GF_SERVER_CERT_FILE=/etc/grafana/certs/grafana.crt
GF_SERVER_CERT_KEY=/etc/grafana/certs/grafana.key

# Restart
docker-compose down && docker-compose up -d
```

Access Grafana at **https://localhost:3000**.

**For browser-trusted certs** (no security warnings), install [mkcert](https://github.com/FiloSottile/mkcert) first:
- macOS: `brew install mkcert`
- Linux: see [mkcert installation guide](https://github.com/FiloSottile/mkcert#installation)

Without mkcert, openssl self-signed certs are generated (browser shows a warning you can click through).

## Quick Verification

### 1. Check Services Running
```bash
docker-compose ps
```

### 2. Verify Prometheus Targets
http://localhost:9090/targets — All targets should show "UP"

### 3. Verify Loki
```bash
curl http://localhost:3100/ready
```
Should return "ready"

### 4. Access Grafana
http://localhost:3000
- Login with credentials from your .env file
- Go to Dashboards → Security folder
- Both Prometheus and Loki data sources should show "Connected"

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
- Select Prometheus → Run query: `up`
- Select Loki → Run query: `{job=~".+"}`

## Log Collection

Promtail collects logs from:
- `/var/log/*log` — General system logs (job: `varlogs`), health check noise filtered out
- `/var/log/auth.log` — Authentication logs (job: `authlog`)
- `/var/log/syslog` — Syslog (job: `syslog`)
- Docker container logs — All container JSON logs (job: `containers`), with timestamp parsing and noise filtering

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

Alerts not appearing in alert-logger?
```bash
# Check Alertmanager is receiving from Prometheus
curl http://localhost:9093/api/v2/alerts

# Check alert-logger is running
docker logs alert-logger
```
