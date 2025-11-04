# Power Analysis Tool - Deployment Guide

**Version:** 5.0.0
**Last Updated:** 2025-11-04
**Target Audience:** DevOps, System Administrators, Deployment Engineers

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start (Docker)](#quick-start-docker)
3. [Production Deployment](#production-deployment)
4. [Configuration](#configuration)
5. [Monitoring & Logging](#monitoring--logging)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)
8. [Security Considerations](#security-considerations)

---

## Prerequisites

### System Requirements

**Minimum:**
- CPU: 2 cores
- RAM: 4 GB
- Disk: 2 GB
- OS: Linux (Ubuntu 20.04+), macOS, Windows 10+

**Recommended:**
- CPU: 4+ cores
- RAM: 8 GB
- Disk: 5 GB (for logs and cache)
- OS: Linux (Ubuntu 22.04 LTS)

### Software Dependencies

**Option 1: Docker (Recommended)**
```bash
docker --version  # >= 20.10
docker-compose --version  # >= 1.29
```

**Option 2: Native R**
```bash
R --version  # >= 4.2.0 (recommended 4.4.0)
```

---

## Quick Start (Docker)

### 1. Clone Repository

```bash
git clone https://github.com/oldschoolcool2/power-analysis-tool.git
cd power-analysis-tool
```

### 2. Build & Run (Development)

```bash
# Build production image
docker-compose build

# Start application
docker-compose up

# Access at http://localhost:3838
```

### 3. Verify Deployment

```bash
# Check health
curl http://localhost:3838

# Check logs
docker-compose logs -f shiny
```

**Expected Output:**
```
PowerAnalysisTool v5.0.0 loaded with logging enabled (level: INFO)
Application starting...
Shiny app created successfully
```

---

## Production Deployment

### Step 1: Pre-deployment Checklist

- [ ] Clone repository to production server
- [ ] Review `docker-compose.yml` configuration
- [ ] Set production environment variables
- [ ] Configure logging destination
- [ ] Set up SSL/TLS (if exposing publicly)
- [ ] Configure firewall rules
- [ ] Set up monitoring/alerting

### Step 2: Environment Configuration

Create `.env` file:

```bash
# Production configuration
R_CONFIG_ACTIVE=production
PAT_LOG_LEVEL=INFO
PAT_LOG_DIR=/var/log/power-analysis-tool
PAT_LOG_FORMAT=json

# Optional: External logging
# LOGGLY_TOKEN=your_token
# AWS_REGION=us-east-1
# DATADOG_API_KEY=your_key
```

### Step 3: Build Production Image

```bash
# Build with production target
docker build --target production -t power-analysis-tool:5.0.0 .

# Tag for registry (if using)
docker tag power-analysis-tool:5.0.0 registry.example.com/power-analysis-tool:5.0.0
```

### Step 4: Deploy with Docker Compose

**Production docker-compose.yml:**

```yaml
version: '3.8'

services:
  app:
    image: power-analysis-tool:5.0.0
    container_name: power-analysis-tool
    restart: unless-stopped
    ports:
      - "3838:3838"
    environment:
      - R_CONFIG_ACTIVE=production
      - PAT_LOG_LEVEL=INFO
      - PAT_LOG_DIR=/var/log/pat
      - PAT_LOG_FORMAT=json
    volumes:
      - ./logs:/var/log/pat
      - ./app_cache:/srv/shiny-server/app_cache
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3838/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

**Start production:**

```bash
docker-compose -f docker-compose.prod.yml up -d

# Verify
docker-compose ps
docker-compose logs -f
```

### Step 5: Configure Reverse Proxy (nginx)

**Example nginx configuration:**

```nginx
upstream power_analysis {
    server localhost:3838;
}

server {
    listen 80;
    server_name power-analysis.example.com;

    # Redirect to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name power-analysis.example.com;

    # SSL certificates
    ssl_certificate /etc/ssl/certs/power-analysis.crt;
    ssl_certificate_key /etc/ssl/private/power-analysis.key;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logging
    access_log /var/log/nginx/power-analysis-access.log;
    error_log /var/log/nginx/power-analysis-error.log;

    # WebSocket support (for Shiny)
    location / {
        proxy_pass http://power_analysis;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://power_analysis;
        access_log off;
    }
}
```

**Enable and restart nginx:**

```bash
sudo ln -s /etc/nginx/sites-available/power-analysis /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Configuration

### Application Configuration

**File:** `inst/golem-config.yml`

```yaml
default:
  golem_name: PowerAnalysisTool
  golem_version: 5.0.0
  app_prod: no

production:
  app_prod: yes
  golem_wd: /srv/shiny-server
  log_level: INFO
```

### Logging Configuration

**Environment Variables:**

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `PAT_LOG_LEVEL` | TRACE, DEBUG, INFO, WARN, ERROR, FATAL | INFO | Minimum log level |
| `PAT_LOG_DIR` | Path | ./logs | Log file directory |
| `PAT_LOG_FORMAT` | console, json, auto | auto | Log output format |

**Examples:**

```bash
# Development (verbose)
export PAT_LOG_LEVEL=DEBUG
export PAT_LOG_FORMAT=console

# Production (structured)
export PAT_LOG_LEVEL=INFO
export PAT_LOG_FORMAT=json
export PAT_LOG_DIR=/var/log/power-analysis-tool
```

### Performance Tuning

**Docker resource limits:**

```yaml
services:
  app:
    # ... other config
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
```

**R session options** (add to `R/app_config.R`):

```r
options(
  shiny.maxRequestSize = 50 * 1024^2,  # 50 MB max upload
  shiny.reactlog = FALSE,              # Disable in production
  shiny.error = browser                # Custom error handler
)
```

---

## Monitoring & Logging

### 1. Built-in Monitoring Dashboard

Access the log monitoring dashboard:

```bash
# Run monitoring dashboard separately
docker run -d \
  -p 3839:3838 \
  -v $(pwd)/logs:/logs \
  -e PAT_LOG_DIR=/logs \
  power-analysis-tool:5.0.0 \
  R -e "shiny::runApp('/srv/shiny-server/inst/app_monitoring', host='0.0.0.0', port=3838)"

# Access at http://localhost:3839
```

**Features:**
- Real-time log streaming
- Error/warning tracking
- Module usage analytics
- Session tracking
- Performance metrics

### 2. External Logging Integration

#### Loggly

```bash
# Set environment variables
export LOGGLY_TOKEN=your_token_here
export LOGGLY_SUBDOMAIN=your_subdomain

# Run integration script
Rscript scripts/integrations/loggly_integration.R
```

#### AWS CloudWatch

```bash
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export CLOUDWATCH_LOG_GROUP=/power-analysis-tool
export CLOUDWATCH_LOG_STREAM=production

Rscript scripts/integrations/cloudwatch_integration.R
```

#### Datadog

```bash
export DATADOG_API_KEY=your_api_key
export DATADOG_APP_KEY=your_app_key
export DATADOG_SITE=datadoghq.com

Rscript scripts/integrations/datadog_integration.R
```

### 3. Automated Alerts

**Email alerts for errors:**

```bash
# Configure email
export ALERT_EMAIL=admin@example.com
export SMTP_SERVER=smtp.example.com
export SMTP_PORT=587
export SMTP_USER=alerts@example.com
export SMTP_PASS=your_password

# Run alert monitor (cron job)
*/5 * * * * cd /path/to/power-analysis-tool && Rscript scripts/alert_email.R
```

**Alert thresholds:**
- Error rate > 10 per hour
- Warning rate > 50 per hour
- Session failures > 5 per hour

### 4. Application Metrics

**Health check endpoint:**

```bash
curl http://localhost:3838/
```

**Expected:** HTTP 200 OK

**Docker health check:**

```bash
docker inspect power-analysis-tool --format='{{.State.Health.Status}}'
```

**Expected:** `healthy`

---

## Troubleshooting

### Issue 1: App Won't Start

**Symptoms:**
- Container exits immediately
- Error: "cannot open file 'R/sidebar_ui.R'"

**Cause:** Running old version before Nov 2025 fixes

**Solution:**
```bash
git pull origin claude/investigate-app-issues-011CUnrPsuLfCr9vGi2Jdimt
docker-compose build --no-cache
docker-compose up
```

---

### Issue 2: Missing Functions

**Symptoms:**
- Error: "could not find function 'xyz'"

**Cause:** NAMESPACE not regenerated after adding exports

**Solution:**
```bash
# In R console or Docker
R -e "devtools::document()"

# Rebuild
docker-compose build
```

---

### Issue 3: High Memory Usage

**Symptoms:**
- Container using > 4GB RAM
- Slow performance

**Diagnostics:**
```bash
docker stats power-analysis-tool
```

**Solutions:**
1. Increase Docker memory limit
2. Reduce concurrent users
3. Enable caching:

```r
# In module server functions
results <- reactive({
  # ... calculation
}) %>% bindCache(inputs(), ...)
```

---

### Issue 4: Logs Not Appearing

**Symptoms:**
- No logs in `PAT_LOG_DIR`
- Silent failures

**Check:**
```bash
# Verify log directory permissions
ls -la /var/log/power-analysis-tool

# Check environment variables
docker exec power-analysis-tool env | grep PAT_LOG
```

**Fix:**
```bash
# Create log directory with proper permissions
mkdir -p /var/log/power-analysis-tool
chown 1000:1000 /var/log/power-analysis-tool
```

---

### Issue 5: Calculation Errors

**Symptoms:**
- "Validation failed" errors
- Unexpected results

**Debug:**
```bash
# Enable debug logging
export PAT_LOG_LEVEL=DEBUG

# Check validation logs
tail -f logs/app_$(date +%Y-%m-%d).log | grep WARN
```

**Common causes:**
- Invalid input values (check ranges)
- Cross-field validation failures (e.g., p1 == p2)
- Missing required inputs

---

## Maintenance

### Regular Tasks

**Daily:**
- [ ] Check application health
- [ ] Review error logs
- [ ] Monitor resource usage

**Weekly:**
- [ ] Rotate log files
- [ ] Check for security updates
- [ ] Review performance metrics

**Monthly:**
- [ ] Update base Docker images
- [ ] Update R packages (test first!)
- [ ] Backup configuration

### Log Rotation

**Using logrotate:**

```bash
# /etc/logrotate.d/power-analysis-tool
/var/log/power-analysis-tool/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 shiny shiny
    sharedscripts
    postrotate
        docker kill -s HUP power-analysis-tool 2>/dev/null || true
    endscript
}
```

### Backup Strategy

**What to backup:**
- Configuration files (`.env`, `docker-compose.yml`)
- Logs (keep 30 days)
- App cache (optional)

**Example backup script:**

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR=/backups/power-analysis-tool
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR/$DATE

# Backup configuration
cp .env docker-compose*.yml $BACKUP_DIR/$DATE/

# Backup logs (last 30 days)
find logs/ -name "*.log" -mtime -30 -exec cp {} $BACKUP_DIR/$DATE/ \;

# Compress
tar -czf $BACKUP_DIR/backup-$DATE.tar.gz $BACKUP_DIR/$DATE/
rm -rf $BACKUP_DIR/$DATE

# Clean old backups (keep 90 days)
find $BACKUP_DIR -name "backup-*.tar.gz" -mtime +90 -delete
```

### Updating the Application

**Minor updates (patches):**

```bash
git pull
docker-compose build
docker-compose down
docker-compose up -d
```

**Major updates (version changes):**

```bash
# Test in staging first!
git checkout main
git pull
docker-compose -f docker-compose.test.yml up --build

# If tests pass, deploy to production
docker-compose build --no-cache
docker-compose down
docker-compose up -d

# Monitor logs
docker-compose logs -f --tail=100
```

---

## Security Considerations

### 1. Network Security

**Firewall rules:**
```bash
# Allow only reverse proxy to access app
sudo ufw allow from proxy_ip to any port 3838

# Block direct access
sudo ufw deny 3838
```

**SSL/TLS:**
- Use Let's Encrypt for free certificates
- Enable HSTS headers
- Use strong cipher suites (TLSv1.2+)

### 2. Application Security

**Error sanitization:**
- ✅ Enabled in production (`R_CONFIG_ACTIVE=production`)
- Prevents information leakage via error messages

**Input validation:**
- ✅ Server-side validation implemented (88% of modules)
- Allowlist-based categorical inputs
- Range checking for numeric inputs

**Session security:**
```r
# Add to app initialization
options(
  shiny.sanitize.errors = TRUE,
  shiny.maxRequestSize = 30 * 1024^2  # 30 MB limit
)
```

### 3. Container Security

**Run as non-root:**
```dockerfile
USER shiny  # Already configured
```

**Scan for vulnerabilities:**
```bash
docker scan power-analysis-tool:5.0.0
```

**Keep images updated:**
```bash
docker pull rocker/shiny:4.4.0
docker-compose build --no-cache
```

### 4. Access Control

**Basic authentication (nginx):**

```nginx
location / {
    auth_basic "Power Analysis Tool";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://power_analysis;
}
```

**Create users:**
```bash
sudo htpasswd -c /etc/nginx/.htpasswd user1
sudo htpasswd /etc/nginx/.htpasswd user2
```

---

## Performance Optimization

### 1. Enable Caching

**For expensive calculations:**

```r
results <- reactive({
  # Expensive calculation
  compute_power_curve(inputs())
}) %>% bindCache(
  inputs()$n,
  inputs()$p,
  inputs()$alpha
)
```

### 2. Database Connection Pooling

If connecting to external databases:

```r
library(pool)

pool <- dbPool(
  drv = RPostgres::Postgres(),
  dbname = "mydb",
  host = "localhost",
  minSize = 1,
  maxSize = 10
)

# Use pool instead of direct connection
```

### 3. Resource Limits

**Per-session limits:**

```r
# In app initialization
session$onSessionEnded(function() {
  gc()  # Garbage collection
})
```

**Global limits:**
```yaml
# docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 4G
```

---

## Scaling

### Horizontal Scaling (Multiple Containers)

**Docker Swarm:**

```yaml
version: '3.8'
services:
  app:
    image: power-analysis-tool:5.0.0
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
```

**Load Balancer (nginx):**

```nginx
upstream power_analysis_cluster {
    least_conn;
    server app1:3838 max_fails=3 fail_timeout=30s;
    server app2:3838 max_fails=3 fail_timeout=30s;
    server app3:3838 max_fails=3 fail_timeout=30s;
}
```

---

## Support & Contacts

### Documentation
- **User Guide:** `/README.md`
- **Developer Docs:** `/docs/README.md`
- **Implementation Status:** `/IMPLEMENTATION_STATUS.md`

### Logs Location
- **Container:** `/var/log/pat/app_YYYY-MM-DD.log`
- **Host (mounted):** `./logs/app_YYYY-MM-DD.log`

### Common Commands

```bash
# View logs
docker-compose logs -f shiny

# Restart app
docker-compose restart shiny

# Shell access
docker-compose exec shiny bash

# R console
docker-compose exec shiny R

# Check health
curl http://localhost:3838 | grep "Power"
```

---

**Last Updated:** 2025-11-04
**Maintained By:** Development Team
**Version:** 5.0.0
