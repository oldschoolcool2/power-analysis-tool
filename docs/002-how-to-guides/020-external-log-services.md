# How to integrate with external log services

**Type:** How-To Guide
**Audience:** DevOps Engineers, System Administrators
**Last Updated:** 2025-10-27

## Overview

This guide explains how to send Power Analysis Tool logs to external log aggregation and monitoring services. We provide integration scripts for four popular services:

- **Loggly** - Cloud-based log management
- **AWS CloudWatch** - Amazon Web Services log monitoring
- **Datadog** - Application performance monitoring
- **Grafana Loki** - Open-source log aggregation

All integration scripts follow the same pattern:
1. Read recent logs from local `logs/` directory
2. Convert logs to service-specific format
3. Send via HTTP API
4. Track state to avoid duplicates
5. Support automated scheduling via cron

---

## Loggly integration

Loggly is a cloud-based log management service with powerful search and alerting.

### Prerequisites

- Loggly account (free tier available at https://www.loggly.com/)
- Customer token from Loggly dashboard

### Setup

1. **Get your Loggly token**:
   - Log into Loggly
   - Go to Source Setup → Customer Tokens
   - Copy your customer token

2. **Configure environment variables** in `.Renviron`:
   ```bash
   LOGGLY_TOKEN=your-customer-token-here
   LOGGLY_TAG=power-analysis-tool
   ```

3. **Test the connection**:
   ```bash
   Rscript scripts/integrations/loggly_integration.R test
   ```

### Usage

**Send recent logs**:
```bash
# Send logs from last hour (default)
Rscript scripts/integrations/loggly_integration.R send

# Send logs from last 24 hours
Rscript scripts/integrations/loggly_integration.R send --hours=24

# Send logs from last 5 minutes (for frequent cron jobs)
Rscript scripts/integrations/loggly_integration.R send --hours=0.083
```

**Set up automated sending** (add to crontab):
```bash
# Send logs every 5 minutes
*/5 * * * * cd /path/to/power-analysis-tool && Rscript scripts/integrations/loggly_integration.R send --hours=0.1 >> /var/log/loggly_sync.log 2>&1
```

### View logs in Loggly

After logs are sent, view them in Loggly:
1. Go to https://yourcompany.loggly.com/search
2. Search for: `tag:power-analysis-tool`
3. Filter by level: `json.level:ERROR`
4. Filter by module: `json.module:two_group`

### Troubleshooting

**Error: "LOGGLY_TOKEN not set"**
- Add token to `.Renviron` file
- Restart R session or source `.Renviron`

**Logs not appearing in Loggly**
- Wait 1-2 minutes (ingestion delay)
- Check token is valid
- Verify network connectivity

---

## AWS CloudWatch integration

AWS CloudWatch provides log monitoring, metrics, and alarms integrated with AWS infrastructure.

### Prerequisites

- AWS account
- AWS CLI installed and configured
- R package `paws.management` installed

### Setup

1. **Install AWS CLI** (if not already installed):
   ```bash
   # macOS
   brew install awscli

   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. **Configure AWS credentials**:
   ```bash
   aws configure
   # Enter: AWS Access Key ID
   # Enter: AWS Secret Access Key
   # Enter: Default region (e.g., us-east-1)
   # Enter: Default output format (json)
   ```

3. **Install required R package**:
   ```r
   install.packages("paws.management")
   ```

4. **Configure environment variables** in `.Renviron`:
   ```bash
   AWS_REGION=us-east-1
   CLOUDWATCH_LOG_GROUP=/power-analysis-tool/production
   CLOUDWATCH_LOG_STREAM=app-logs
   ```

5. **Create CloudWatch resources**:
   ```bash
   # Option 1: Using the integration script
   Rscript scripts/integrations/cloudwatch_integration.R setup

   # Option 2: Using AWS CLI
   aws logs create-log-group --log-group-name /power-analysis-tool/production
   aws logs create-log-stream \
     --log-group-name /power-analysis-tool/production \
     --log-stream-name app-logs
   ```

### Usage

**Send recent logs**:
```bash
# Send logs from last hour
Rscript scripts/integrations/cloudwatch_integration.R send

# Send logs from last 24 hours
Rscript scripts/integrations/cloudwatch_integration.R send --hours=24
```

**Test connection**:
```bash
Rscript scripts/integrations/cloudwatch_integration.R test
```

**Set up automated sending**:
```bash
# Send logs every 5 minutes
*/5 * * * * cd /path/to/power-analysis-tool && Rscript scripts/integrations/cloudwatch_integration.R send --hours=0.1
```

### View logs in CloudWatch

1. Go to AWS Console → CloudWatch → Logs → Log groups
2. Select `/power-analysis-tool/production`
3. Select log stream `app-logs`
4. Use CloudWatch Insights for queries:
   ```
   fields @timestamp, level, msg, module
   | filter level = "ERROR"
   | sort @timestamp desc
   | limit 100
   ```

### Cost considerations

CloudWatch pricing (as of 2025):
- First 5 GB ingested per month: Free
- Additional ingestion: $0.50 per GB
- Storage: $0.03 per GB per month
- Log Insights queries: $0.005 per GB scanned

For typical usage (10-100 MB/day), costs are minimal.

### Troubleshooting

**Error: "AWS credentials not configured"**
- Run `aws configure`
- Or set environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

**Error: "ResourceNotFoundException"**
- Run setup command: `Rscript scripts/integrations/cloudwatch_integration.R setup`
- Or create resources manually via AWS Console

---

## Datadog integration

Datadog provides comprehensive monitoring, APM, and log management in one platform.

### Prerequisites

- Datadog account (free trial available at https://www.datadoghq.com/)
- Datadog API key

### Setup

1. **Get your Datadog API key**:
   - Log into Datadog
   - Go to Organization Settings → API Keys
   - Create new key or copy existing key

2. **Configure environment variables** in `.Renviron`:
   ```bash
   DATADOG_API_KEY=your-api-key-here
   DATADOG_SITE=datadoghq.com        # Use datadoghq.eu for EU region
   DATADOG_SERVICE=power-analysis-tool
   DATADOG_ENV=production
   ```

3. **Test the connection**:
   ```bash
   Rscript scripts/integrations/datadog_integration.R test
   ```

### Usage

**Send recent logs**:
```bash
# Send logs from last hour
Rscript scripts/integrations/datadog_integration.R send

# Send logs from last 24 hours
Rscript scripts/integrations/datadog_integration.R send --hours=24
```

**Set up automated sending**:
```bash
# Send logs every 5 minutes
*/5 * * * * cd /path/to/power-analysis-tool && Rscript scripts/integrations/datadog_integration.R send --hours=0.1
```

### View logs in Datadog

1. Go to https://app.datadoghq.com/logs
2. Search for: `service:power-analysis-tool`
3. Facets available:
   - `status`: error, warn, info, debug
   - `env`: production, staging, development
   - `module`: two_group, survival, etc.

### Create alerts in Datadog

1. Go to Monitors → New Monitor → Logs
2. Define search query: `service:power-analysis-tool status:error`
3. Set alert threshold: "Alert threshold: > 10 errors in 1 hour"
4. Configure notifications (email, Slack, PagerDuty, etc.)

### Troubleshooting

**Logs not appearing**
- Wait 1-2 minutes for ingestion
- Verify API key is correct
- Check site parameter (US vs EU)

**Rate limiting errors**
- Reduce batch size in script
- Increase delay between batches
- Contact Datadog support for rate limit increase

---

## Grafana Loki integration

Grafana Loki is an open-source log aggregation system that integrates seamlessly with Grafana.

### Prerequisites

- Loki server running (or Grafana Cloud account)
- Grafana for visualization (optional but recommended)

### Setup - Self-hosted Loki

1. **Install Loki with Docker**:
   ```bash
   # Create config file
   cat > loki-config.yaml <<EOF
   auth_enabled: false

   server:
     http_listen_port: 3100

   ingester:
     lifecycler:
       ring:
         kvstore:
           store: inmemory
         replication_factor: 1
     chunk_idle_period: 5m
     chunk_retain_period: 30s

   schema_config:
     configs:
       - from: 2020-10-24
         store: boltdb
         object_store: filesystem
         schema: v11
         index:
           prefix: index_
           period: 168h

   storage_config:
     boltdb:
       directory: /tmp/loki/index
     filesystem:
       directory: /tmp/loki/chunks

   limits_config:
     enforce_metric_name: false
     reject_old_samples: true
     reject_old_samples_max_age: 168h
   EOF

   # Run Loki
   docker run -d --name=loki -p 3100:3100 \
     -v $(pwd)/loki-config.yaml:/etc/loki/local-config.yaml \
     grafana/loki:latest
   ```

2. **Install Grafana** (if not already installed):
   ```bash
   docker run -d --name=grafana -p 3000:3000 grafana/grafana:latest
   ```

3. **Configure Loki as data source in Grafana**:
   - Open Grafana: http://localhost:3000 (admin/admin)
   - Go to Configuration → Data Sources → Add data source
   - Select Loki
   - URL: `http://localhost:3100`
   - Save & Test

4. **Configure environment variables** in `.Renviron`:
   ```bash
   LOKI_URL=http://localhost:3100
   # Optional: for authentication
   # LOKI_USERNAME=your-username
   # LOKI_PASSWORD=your-password
   # LOKI_TENANT_ID=your-tenant-id
   ```

### Setup - Grafana Cloud

1. **Get Grafana Cloud credentials**:
   - Sign up at https://grafana.com/
   - Go to My Account → Cloud Portal
   - Find Logs → Details
   - Copy: URL, Username, Password

2. **Configure environment variables** in `.Renviron`:
   ```bash
   LOKI_URL=https://logs-prod-012.grafana.net
   LOKI_USERNAME=123456
   LOKI_PASSWORD=your-api-key
   ```

### Usage

**Test connection**:
```bash
Rscript scripts/integrations/loki_integration.R test
```

**Send recent logs**:
```bash
# Send logs from last hour
Rscript scripts/integrations/loki_integration.R send

# Send logs from last 24 hours
Rscript scripts/integrations/loki_integration.R send --hours=24
```

**Set up automated sending**:
```bash
# Send logs every 5 minutes
*/5 * * * * cd /path/to/power-analysis-tool && Rscript scripts/integrations/loki_integration.R send --hours=0.1
```

### Query logs in Grafana

Open Grafana Explore and use LogQL:

**Basic queries**:
```logql
# All logs from app
{app="power-analysis-tool"}

# Only errors
{app="power-analysis-tool",level="error"}

# Specific module
{app="power-analysis-tool"} | json | module="two_group"

# Search for text
{app="power-analysis-tool"} |= "calculate_power"

# Count errors per minute
sum(rate({app="power-analysis-tool",level="error"}[5m])) by (module)
```

**Create dashboard**:
1. Create new dashboard
2. Add panel with query:
   ```logql
   sum(count_over_time({app="power-analysis-tool"}[1m])) by (level)
   ```
3. Visualization: Bar gauge or Time series
4. Repeat for different metrics (errors, sessions, performance)

### Troubleshooting

**Error: Connection refused**
- Verify Loki is running: `curl http://localhost:3100/ready`
- Check LOKI_URL is correct

**Logs not appearing in Grafana**
- Verify data source configuration
- Check LogQL query syntax
- Ensure logs were sent successfully

---

## Comparison of services

| Feature | Loggly | AWS CloudWatch | Datadog | Grafana Loki |
|---------|--------|----------------|---------|--------------|
| **Hosting** | Cloud only | Cloud only | Cloud / On-prem | Self-hosted / Cloud |
| **Cost** | Free tier then paid | Pay per GB | Free trial then paid | Free (self-hosted) |
| **Setup difficulty** | Easy | Medium | Easy | Medium-Hard |
| **Search speed** | Fast | Fast | Very fast | Fast |
| **Alerting** | Built-in | Built-in | Built-in | Via Grafana |
| **Integration** | Limited | AWS ecosystem | Many integrations | Grafana ecosystem |
| **Data retention** | 7 days (free) | Configurable | Configurable | Configurable |

### Recommendations

**Choose Loggly if**:
- You want quick setup with minimal configuration
- You need powerful search and filtering
- You prefer cloud-based solution

**Choose CloudWatch if**:
- You're already using AWS infrastructure
- You need integration with AWS services
- You want built-in metrics and alarms

**Choose Datadog if**:
- You need comprehensive APM and monitoring
- You want logs, metrics, and traces in one platform
- You have budget for enterprise solution

**Choose Grafana Loki if**:
- You prefer open-source solutions
- You're already using Grafana
- You want full control over data and infrastructure
- You have technical resources to manage infrastructure

---

## Advanced: Multiple service integration

You can send logs to multiple services simultaneously for redundancy:

```bash
#!/bin/bash
# scripts/send_logs_all.sh

# Send to all services
Rscript scripts/integrations/loggly_integration.R send --hours=0.1
Rscript scripts/integrations/cloudwatch_integration.R send --hours=0.1
Rscript scripts/integrations/datadog_integration.R send --hours=0.1
Rscript scripts/integrations/loki_integration.R send --hours=0.1
```

Make executable and add to cron:
```bash
chmod +x scripts/send_logs_all.sh
```

Crontab:
```bash
*/5 * * * * /path/to/power-analysis-tool/scripts/send_logs_all.sh
```

---

## Security considerations

### Protect API keys

**Never commit API keys to git**:
```bash
# Add to .gitignore
echo ".Renviron" >> .gitignore
```

**Use environment-specific configuration**:
```bash
# .Renviron.production
LOGGLY_TOKEN=prod-token-here
DATADOG_API_KEY=prod-key-here

# .Renviron.staging
LOGGLY_TOKEN=staging-token-here
DATADOG_API_KEY=staging-key-here
```

### Limit log data

Avoid logging sensitive information:
- User passwords
- API keys or tokens
- Personal identifiable information (PII)
- Financial data

Review `R/utils_logging.R` and modules to ensure sensitive data is not logged.

### Network security

When using self-hosted Loki:
- Use HTTPS with TLS certificates
- Enable authentication (basic auth or OAuth)
- Restrict network access via firewall
- Use VPN for remote access

---

## Monitoring the integrations

Track integration health:

```bash
# Check last successful send time
ls -lh logs/.loggly_state.rds
ls -lh logs/.cloudwatch_state.rds
ls -lh logs/.datadog_state.rds
ls -lh logs/.loki_state.rds

# View cron logs
tail -f /var/log/cron
tail -f /var/log/loggly_sync.log
```

Set up alerts for integration failures:
1. Monitor cron job exit codes
2. Alert if state file hasn't updated in X hours
3. Check destination service for log ingestion

---

## Related documentation

- [017-logging-best-practices.md](017-logging-best-practices.md) - Logging guidelines
- [018-monitor-logs-with-dashboard.md](018-monitor-logs-with-dashboard.md) - Shiny monitoring dashboard
- [019-analyze-logs-with-loganalyzer.md](019-analyze-logs-with-loganalyzer.md) - CLI log analysis

---

## References

- Loggly API Documentation: https://documentation.solarwinds.com/en/success_center/loggly/content/admin/http-bulk-endpoint.htm
- AWS CloudWatch Logs API: https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/
- Datadog Logs API: https://docs.datadoghq.com/api/latest/logs/
- Grafana Loki Documentation: https://grafana.com/docs/loki/latest/
- LogQL Query Language: https://grafana.com/docs/loki/latest/logql/
