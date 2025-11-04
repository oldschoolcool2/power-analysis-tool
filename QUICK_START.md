# Power Analysis Tool - Quick Start Guide

**⚡ Get up and running in 5 minutes**

---

## 🚀 Fastest Path to Running App

### Option 1: Docker (Recommended)

```bash
# 1. Clone
git clone https://github.com/oldschoolcool2/power-analysis-tool.git
cd power-analysis-tool

# 2. Build & Run
docker-compose up

# 3. Access
# Open http://localhost:3838 in your browser
```

**That's it!** 🎉

---

### Option 2: Native R

```bash
# 1. Clone
git clone https://github.com/oldschoolcool2/power-analysis-tool.git
cd power-analysis-tool

# 2. Install package
R -e "devtools::install()"

# 3. Run
R -e "PowerAnalysisTool::run_app()"

# 4. Access
# Open http://127.0.0.1:XXXX (port shown in console)
```

---

## 📚 Quick Links

- **User Guide:** [README.md](README.md) - How to use the app
- **Deployment:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Production deployment
- **Status:** [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) - What's implemented
- **Docs:** [docs/README.md](docs/README.md) - All documentation

---

## 🎯 Common Tasks

### Test the App

```bash
# Quick tests
./scripts/quick_test.sh

# Full tests (requires R or Docker)
./scripts/quick_test.sh --full
```

### Regenerate NAMESPACE

```bash
# If you've added @export tags
Rscript scripts/regenerate_namespace.R

# Or in R console
devtools::document()
```

### View Logs

```bash
# Docker
docker-compose logs -f

# Native R (if configured)
tail -f logs/app_$(date +%Y-%m-%d).log
```

### Update & Redeploy

```bash
git pull
docker-compose down
docker-compose build
docker-compose up -d
```

---

## 🧪 Quick Test

Try these calculations to verify everything works:

### Test 1: Single Proportion Power
1. Navigate to **"Power (Single)"**
2. Sample Size: **500**
3. Event Frequency: **200** (1 in 200)
4. Click **Calculate**
5. **Expected:** ~91.8% power

### Test 2: Two-Group Sample Size
1. Navigate to **"Sample Size (Two-Group)"**
2. Power: **80%**
3. Event Rate Group 1: **15%**
4. Event Rate Group 2: **10%**
5. Click **Calculate**
6. **Expected:** n₁=303, n₂=303

### Test 3: Interactive Plot
1. Stay on any analysis page
2. Look for **power curve plot** below results
3. **Hover** over plot lines
4. **Expected:** Interactive tooltips showing values

---

## ⚙️ Configuration

### Environment Variables

Create `.env` file:

```bash
# Development
R_CONFIG_ACTIVE=default
PAT_LOG_LEVEL=DEBUG

# Production
R_CONFIG_ACTIVE=production
PAT_LOG_LEVEL=INFO
PAT_LOG_FORMAT=json
```

### Port Configuration

Change port in `docker-compose.yml`:

```yaml
ports:
  - "8080:3838"  # Change 8080 to your desired port
```

---

## 🛠️ Troubleshooting

### App won't start

**Error:** "cannot open file 'R/sidebar_ui.R'"

**Fix:**
```bash
git pull  # Get latest fixes
docker-compose build --no-cache
```

### Missing functions

**Error:** "could not find function 'xyz'"

**Fix:**
```bash
Rscript scripts/regenerate_namespace.R
docker-compose build
```

### Port already in use

**Error:** "port 3838 is already allocated"

**Fix:**
```bash
# Stop conflicting service or change port
docker-compose down
# Edit docker-compose.yml to use different port
docker-compose up
```

---

## 📖 Full Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| [README.md](README.md) | User guide & features | End users |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Production deployment | DevOps/Admins |
| [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) | What's implemented | Developers |
| [REGENERATE_NAMESPACE.md](REGENERATE_NAMESPACE.md) | Fix missing exports | Developers |
| [docs/README.md](docs/README.md) | All developer docs | Developers |
| [CLAUDE.md](CLAUDE.md) | Documentation guidelines | Contributors |

---

## 🆘 Getting Help

### Check Logs

```bash
# Docker
docker-compose logs shiny | tail -100

# Look for ERROR or WARN messages
docker-compose logs shiny | grep -E "ERROR|WARN"
```

### Common Issues

1. **Calculation errors:** Check input validation warnings
2. **Slow performance:** Enable caching (see DEPLOYMENT_GUIDE.md)
3. **Missing features:** Check IMPLEMENTATION_STATUS.md

### Report Issues

If you find a bug:

1. Check logs for errors
2. Note your R version: `R --version`
3. Note your Docker version: `docker --version`
4. Document steps to reproduce
5. Include error messages

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] App accessible at http://localhost:3838
- [ ] No errors in logs: `docker-compose logs`
- [ ] All 8 analysis types load
- [ ] Calculations return results
- [ ] Interactive plots work (hover tooltips)
- [ ] Example buttons load data
- [ ] Reset buttons work
- [ ] Export to CSV works

---

## 🎓 Learn More

### For Users
- **Tutorial:** Try built-in **Example** buttons on each page
- **Help:** Click **"ℹ Help"** button on each analysis page
- **Examples:** See [README.md](README.md) "Usage Examples" section

### For Developers
- **Architecture:** See [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md)
- **Contributing:** See [docs/development/CONTRIBUTING.md](docs/development/CONTRIBUTING.md)
- **Code Guide:** See [docs/README.md](docs/README.md)

---

## 🚀 Next Steps

1. **Test** - Run `./scripts/quick_test.sh`
2. **Explore** - Try different analysis types
3. **Deploy** - Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
4. **Monitor** - Set up logging (see Deployment Guide)
5. **Customize** - See developer docs for extending functionality

---

**Need help?** Check the full documentation or review the logs.

**Found a bug?** See the issue reporting section above.

**Want to contribute?** See [docs/development/CONTRIBUTING.md](docs/development/CONTRIBUTING.md)

---

**Version:** 5.0.0
**Last Updated:** 2025-11-04
**Status:** ✅ Production Ready
