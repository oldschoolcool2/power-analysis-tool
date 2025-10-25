# Docker Build Guide

## Multi-Stage Build Architecture

This project uses a multi-stage Dockerfile with three stages:

1. **Base Stage**: Shared dependencies (system packages, renv, TinyTeX)
2. **Development Stage**: Includes testing tools and code quality packages
3. **Production Stage**: Minimal runtime without tests or dev tools

## Building Images

### Production Build (Default)

```bash
# Using docker-compose (recommended)
docker-compose build

# Using docker directly
docker build --target production -t power-analysis-tool:prod .

# With BuildKit for faster builds (recommended)
DOCKER_BUILDKIT=1 docker build --target production -t power-analysis-tool:prod .
```

### Development Build

```bash
# Using docker-compose
docker-compose -f docker-compose.dev.yml build

# Using docker directly
docker build --target development -t power-analysis-tool:dev .
```

## Running Containers

### Production

```bash
docker-compose up
```

Access the app at http://localhost:3838

### Development

```bash
docker-compose -f docker-compose.dev.yml up
```

In development mode, you have:
- All testing tools (testthat)
- Code quality tools (lintr, styler, precommit)
- Tests directory mounted

## Performance Optimizations

This Dockerfile implements several best practices for fast builds:

1. **`.dockerignore` file**: Excludes unnecessary files from build context
   - Estimated impact: 40-60% faster builds
   
2. **Multi-stage builds**: Separates dev dependencies from production
   - Smaller production images
   - Faster production deployments

3. **Layer caching optimization**: 
   - System dependencies cached separately
   - renv.lock and dependencies cached before app code
   - App code copied last (changes most frequently)

4. **BuildKit**: Use `DOCKER_BUILDKIT=1` for parallel builds

## Build Context Exclusions

The `.dockerignore` file excludes:
- Git history and documentation
- Test files (in production build)
- IDE configurations
- Temporary and cache files
- Development tools

## Troubleshooting

### Slow builds?

1. Ensure `.dockerignore` exists and is comprehensive
2. Use BuildKit: `DOCKER_BUILDKIT=1 docker build ...`
3. Check Docker's build cache: `docker system df`
4. Prune old images: `docker system prune -a`

### Cache not working?

If dependency cache isn't working after renv.lock changes:
1. The base stage will rebuild (expected)
2. This is intentional - ensures correct dependencies
3. App code changes won't trigger renv rebuild

### Need to force rebuild?

```bash
# Rebuild without cache
docker-compose build --no-cache

# Or with docker directly
docker build --no-cache --target production -t power-analysis-tool:prod .
```

## Image Size Comparison

- **Development image**: ~2.5-3GB (includes all dev tools)
- **Production image**: ~2-2.5GB (minimal runtime)
- **Base stage**: Shared by both (system deps + R packages)

## Advanced Usage

### Running tests in container

```bash
# Build dev image
docker build --target development -t power-analysis-tool:dev .

# Run tests
docker run --rm power-analysis-tool:dev R -e "testthat::test_dir('tests')"
```

### Interactive R session

```bash
# Development container
docker run --rm -it power-analysis-tool:dev R

# Production container
docker run --rm -it power-analysis-tool:prod R
```

### Custom renv cache location

Set `RENV_PATHS_CACHE` in the Dockerfile if you want to use a custom cache location.

## CI/CD Integration

For automated builds:

```bash
# Production build
DOCKER_BUILDKIT=1 docker build --target production -t power-analysis-tool:prod .

# Run tests in development build
DOCKER_BUILDKIT=1 docker build --target development -t power-analysis-tool:dev .
docker run --rm power-analysis-tool:dev R -e "testthat::test_dir('tests')"

# Tag and push
docker tag power-analysis-tool:prod registry/power-analysis-tool:latest
docker push registry/power-analysis-tool:latest
```

## Best Practices Implemented

1. ✅ Multi-stage builds for dev/prod separation
2. ✅ Comprehensive `.dockerignore` file
3. ✅ Layer caching optimization
4. ✅ Minimal production images
5. ✅ BuildKit compatibility
6. ✅ Non-root user (shiny)
7. ✅ Proper permissions for app_cache
8. ✅ Volume mounts for hot reloading during development

## References

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [renv Docker Guide](https://rstudio.github.io/renv/articles/docker.html)
- [Rocker Project](https://rocker-project.org/)
