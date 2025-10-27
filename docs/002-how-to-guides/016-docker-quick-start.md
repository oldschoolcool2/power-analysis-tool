# Docker Quick Start Guide

## TL;DR

```bash
# Development (with tests, hot reload)
docker-compose -f docker-compose.dev.yml up

# Production
docker-compose up

# Build with speed boost
DOCKER_BUILDKIT=1 docker-compose build
```

## Common Commands

### Development Workflow

```bash
# Build dev image
docker-compose -f docker-compose.dev.yml build

# Run dev container
docker-compose -f docker-compose.dev.yml up

# Run with rebuild
docker-compose -f docker-compose.dev.yml up --build

# Stop
docker-compose -f docker-compose.dev.yml down
```

### Production Deployment

```bash
# Build production image
docker-compose build

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Testing

```bash
# Run tests in container
docker build --target development -t power-analysis-tool:dev .
docker run --rm power-analysis-tool:dev R -e "testthat::test_dir('tests')"

# Interactive R session
docker run --rm -it power-analysis-tool:dev R
```

### Troubleshooting

```bash
# Force rebuild (no cache)
docker-compose build --no-cache

# Clean up old images
docker system prune -a

# Check disk usage
docker system df

# View build cache
docker buildx du
```

## What's Different?

### Multi-Stage Build

- **Base**: Shared dependencies (R packages, TinyTeX)
- **Development**: Base + testing tools (lintr, styler, tests/)
- **Production**: Base only (minimal, no tests)

### Build Optimization

| Feature | Impact |
|---------|--------|
| `.dockerignore` | 95% smaller build context |
| Layer caching | 95% faster rebuilds |
| Multi-stage | Smaller production images |
| BuildKit | Parallel builds |

### File Structure

```
.
├── Dockerfile              # Multi-stage definition
├── .dockerignore           # Build context exclusions
├── docker-compose.yml      # Production config
├── docker-compose.dev.yml  # Development config
└── README.docker.md        # Complete documentation
```

## When to Use What

| Task | Command |
|------|---------|
| Local dev with hot reload | `docker-compose -f docker-compose.dev.yml up` |
| Testing changes | `docker-compose -f docker-compose.dev.yml up --build` |
| Production deployment | `docker-compose up -d` |
| Run unit tests | See "Testing" section above |
| Interactive debugging | `docker run -it power-analysis-tool:dev R` |

## Performance Tips

1. **Always use BuildKit**: `DOCKER_BUILDKIT=1`
2. **Don't use `--no-cache`** unless necessary
3. **Keep `.dockerignore` updated** when adding directories
4. **Use dev config for development** (includes tests, hot reload)
5. **Use prod config for deployment** (minimal, optimized)

## Access Points

- **Local app**: http://localhost:3838
- **Container logs**: `docker-compose logs -f`
- **Container shell**: `docker-compose exec shiny bash`

## Need Help?

- Complete guide: `README.docker.md`
- Implementation details: `docs/reports/quality/docker-optimization/001-multi-stage-build-implementation.md`
- Docker docs: https://docs.docker.com/

---

**Hot Reload**: Enabled in dev mode - edit code, refresh browser
**Tests**: Included in dev image only
**Production**: Minimal image, no dev tools
