# SOC Dashboard - Quick Setup Guide

## Prerequisites
- Docker & Docker Compose installed
- Ports 3000, 9090, 9100, 3100 available

## Setup Steps

### 1. Clone/Create Project Structure
```bash
cd soc-dashboard
```

### 2. Start the Stack
```bash
docker-compose up -d
```

### 3. Wait for Services (30 seconds)
```bash
sleep 30
docker-compose ps
```
All services should show "Up" status.

## Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / socadmin123 |
| Prometheus | http://localhost:9090 | No auth |
| Loki | http://localhost:3100/ready | No auth |
| Node Exporter | http://localhost:9100/metrics | No auth |

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
- Login: admin / socadmin123
- Go to Configuration → Data Sources
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
- Select Prometheus → Run query: `up`
- Select Loki → Run query: `{job=~".+"}`
- You should see data

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
```

---
That's it! Your SOC dashboard is running.
