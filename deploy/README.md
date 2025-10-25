# Deployment Guide

This directory contains deployment configurations for the Power Analysis Tool.

## Deployment Options

### Option 1: shinyapps.io (Easiest)

1. Install rsconnect package:
   ```r
   install.packages("rsconnect")
   ```

2. Configure your account (first time only):
   ```r
   rsconnect::setAccountInfo(
     name = "your-account",
     token = "your-token",
     secret = "your-secret"
   )
   ```

3. Deploy from RStudio:
   - Open `app.R` in the project root
   - Click the blue "Publish" button
   - Select your shinyapps.io account
   - Click "Publish"

4. Or deploy from command line:
   ```r
   rsconnect::deployApp(
     appName = "power-analysis-tool",
     appTitle = "Power Analysis Tool for RWE Studies",
     account = "your-account"
   )
   ```

### Option 2: Docker (Local or Cloud)

#### Build and Run Locally

```bash
# Navigate to project root
cd ..

# Build the Docker image
docker build -f deploy/Dockerfile -t power-analysis-tool:latest .

# Run the container
docker run -p 3838:3838 power-analysis-tool:latest

# Access at http://localhost:3838
```

#### Using Docker Compose

```bash
# Navigate to deploy directory
cd deploy

# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

#### Deploy to Cloud

**AWS ECS:**
```bash
# Tag and push to ECR
docker tag power-analysis-tool:latest <account-id>.dkr.ecr.<region>.amazonaws.com/power-analysis-tool:latest
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/power-analysis-tool:latest
```

**Google Cloud Run:**
```bash
# Tag and push to GCR
docker tag power-analysis-tool:latest gcr.io/<project-id>/power-analysis-tool:latest
docker push gcr.io/<project-id>/power-analysis-tool:latest

# Deploy
gcloud run deploy power-analysis-tool \
  --image gcr.io/<project-id>/power-analysis-tool:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### Option 3: Posit Connect (Enterprise)

1. Ensure you have access to a Posit Connect server

2. Configure rsconnect for Posit Connect:
   ```r
   rsconnect::connectApiUser(
     account = "your-account",
     server = "your-connect-server.com",
     apiKey = "your-api-key"
   )
   ```

3. Deploy:
   ```r
   rsconnect::deployApp(
     server = "your-connect-server.com",
     account = "your-account"
   )
   ```

## Environment Variables

- `GOLEM_APP_PROD`: Set to `TRUE` for production mode
- `GOLEM_CONFIG_ACTIVE`: Set to `production`, `development`, or `staging`

## Resource Requirements

Minimum recommended resources:
- CPU: 1 vCPU
- RAM: 2GB
- Storage: 5GB

For production with multiple concurrent users:
- CPU: 2-4 vCPUs
- RAM: 4-8GB
- Storage: 10GB

## Troubleshooting

### Docker build fails

- Check that all renv packages are properly restored
- Verify system dependencies are installed
- Review Dockerfile for missing packages

### App fails to start

- Check logs with `docker-compose logs`
- Verify port 3838 is not in use
- Ensure all environment variables are set

### Performance issues

- Increase container memory allocation
- Use multi-core deployments
- Consider caching strategies
- Profile the app with `profvis`

## Health Checks

The Docker container includes a health check that pings the app every 30 seconds. Monitor with:

```bash
docker ps
docker inspect power-analysis-tool | grep -A 10 Health
```

## Updating Deployment

### shinyapps.io
Simply redeploy with `rsconnect::deployApp()` - it will update the existing deployment.

### Docker
```bash
# Rebuild image
docker build -f deploy/Dockerfile -t power-analysis-tool:latest .

# Restart container
docker-compose down
docker-compose up -d
```

## Support

For deployment issues:
1. Check application logs
2. Review this documentation
3. Consult the main project README
4. Open an issue in the project repository
