# Performance Optimization Guide

**Type:** Reference
**Audience:** Developers
**Last Updated:** 2025-10-25

## Overview

This document provides performance benchmarks, optimization strategies, and testing procedures for the Power Analysis Tool. It supports Phase 8 testing requirements of the UI/UX modernization project.

**Performance Goals:**
- Page load time < 3 seconds
- Time to interactive < 4 seconds
- First Contentful Paint < 1.8 seconds
- Lighthouse Performance score ≥ 90

---

## Performance Metrics

### Core Web Vitals

Google's Core Web Vitals measure real-world user experience:

| Metric | Good | Needs Improvement | Poor | Target |
|--------|------|-------------------|------|--------|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | 2.5s - 4.0s | > 4.0s | ≤ 2.0s |
| **FID** (First Input Delay) | ≤ 100ms | 100ms - 300ms | > 300ms | ≤ 50ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | 0.1 - 0.25 | > 0.25 | ≤ 0.05 |

### Additional Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| **FCP** (First Contentful Paint) | Time to first content render | ≤ 1.8s |
| **TTI** (Time to Interactive) | Time until page is fully interactive | ≤ 3.8s |
| **SI** (Speed Index) | How quickly content is visually displayed | ≤ 3.4s |
| **TBT** (Total Blocking Time) | Sum of blocking time after FCP | ≤ 200ms |

---

## Current Performance Baseline

### Asset Sizes (Estimated)

| Asset Type | Unminified | Minified | Gzipped | Target |
|------------|------------|----------|---------|--------|
| **CSS** | ~120 KB | ~95 KB | ~20 KB | < 100 KB |
| **JavaScript** | ~180 KB | ~140 KB | ~35 KB | < 150 KB |
| **Fonts** | ~60 KB | ~60 KB | ~60 KB | < 80 KB |
| **Images/Icons** | ~15 KB | ~15 KB | ~10 KB | < 20 KB |
| **Total** | ~375 KB | ~310 KB | ~125 KB | < 350 KB |

**CSS Breakdown:**
- `design-tokens.css`: ~25 KB (363 lines)
- `modern-theme.css`: ~50 KB (761 lines)
- `sidebar.css`: ~30 KB (440 lines)
- `responsive.css`: ~40 KB (615 lines)
- `input-components.css`: ~18 KB (270 lines)
- Bootstrap (partial): ~150 KB (Shiny includes this)

**JavaScript Breakdown:**
- `sidebar-navigation.js`: ~15 KB (210 lines)
- `theme-switcher.js`: ~12 KB (176 lines)
- Shiny core: ~300 KB (included by Shiny framework)
- jQuery (Shiny dependency): ~90 KB

---

## Performance Testing Procedures

### 1. Lighthouse Audit (Chrome DevTools)

**Setup:**
1. Open Chrome (or Edge)
2. Navigate to application: `http://localhost:3838`
3. Open DevTools: F12 (Windows/Linux) or Cmd+Option+I (Mac)
4. Click "Lighthouse" tab
5. Select categories: Performance, Accessibility, Best Practices, SEO
6. Select device: Desktop or Mobile
7. Click "Analyze page load"

**Interpreting Results:**

**Performance Score Breakdown:**
- **90-100:** Excellent (green)
- **50-89:** Needs improvement (orange)
- **0-49:** Poor (red)

**Key Metrics to Check:**
- First Contentful Paint (FCP)
- Speed Index (SI)
- Largest Contentful Paint (LCP)
- Time to Interactive (TTI)
- Total Blocking Time (TBT)
- Cumulative Layout Shift (CLS)

**Common Issues:**
- Large CSS/JS bundles
- Unoptimized images
- Render-blocking resources
- Unused CSS/JS
- Layout shifts during load

---

### 2. Network Analysis (Chrome DevTools)

**Setup:**
1. Open DevTools > Network tab
2. Disable cache: Check "Disable cache"
3. Throttle connection (optional): "Fast 3G" or "Slow 3G"
4. Hard refresh page: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

**Metrics to Record:**

| Resource | Size | Time | Status |
|----------|------|------|--------|
| HTML (index) | XX KB | XXms | 200 |
| CSS (total) | XX KB | XXms | 200 |
| JS (total) | XX KB | XXms | 200 |
| Fonts | XX KB | XXms | 200 |
| Images | XX KB | XXms | 200 |
| **Total** | **XX KB** | **XXXms** | - |

**Red Flags:**
- Any resource > 500 KB
- Total load time > 5 seconds (on fast connection)
- More than 50 requests
- 404 errors (missing resources)
- Slow server response (> 600ms)

---

### 3. Performance Tab (Chrome DevTools)

**Measuring Runtime Performance:**

1. Open DevTools > Performance tab
2. Click Record button (⚫)
3. Interact with the app:
   - Navigate sidebar
   - Fill out form
   - Submit calculation
   - Toggle theme
4. Stop recording
5. Analyze timeline

**What to Look For:**

**Frame Rate:**
- Target: 60 FPS (16.7ms per frame)
- Acceptable: 30 FPS (33ms per frame)
- Poor: < 30 FPS (> 33ms per frame)

**Long Tasks:**
- Any task > 50ms blocks the main thread
- Ideal: All tasks < 50ms
- Investigate tasks > 100ms

**JavaScript Execution Time:**
- Sidebar open/close: < 50ms
- Theme toggle: < 30ms
- Accordion expand: < 20ms
- Form validation: < 10ms

**Rendering Time:**
- Paint: < 5ms
- Composite: < 2ms

---

### 4. Memory Profiling

**Check for Memory Leaks:**

1. Open DevTools > Memory tab
2. Take heap snapshot
3. Interact with app (navigate pages, open modals, etc.)
4. Take another heap snapshot
5. Compare snapshots

**Acceptable Memory Usage:**
- Initial load: 20-40 MB
- After navigation: 30-60 MB
- Memory growth per action: < 5 MB
- Total cap: < 100 MB

**Warning Signs:**
- Memory steadily increasing without plateau
- Detached DOM nodes accumulating
- Event listeners not being removed

---

## Optimization Strategies

### CSS Optimization

#### 1. Minification

**Tool:** `cssnano` (Node.js)

```bash
# Install
npm install -g cssnano-cli

# Minify single file
cssnano design-tokens.css design-tokens.min.css

# Minify all CSS files
for file in www/css/*.css; do
  cssnano "$file" "${file%.css}.min.css"
done
```

**Expected Savings:** ~20-30% file size reduction

#### 2. Combine Files

Instead of loading 5 separate CSS files, create one combined file:

```bash
cat www/css/design-tokens.css \
    www/css/modern-theme.css \
    www/css/sidebar.css \
    www/css/responsive.css \
    www/css/input-components.css \
    > www/css/app.min.css
```

**Benefit:** Reduces HTTP requests from 5 to 1

#### 3. Remove Unused CSS

**Tool:** PurgeCSS or UnCSS

```bash
# Install
npm install -g purgecss

# Remove unused CSS
purgecss --css www/css/*.css --content app.R --output www/css/purged/
```

**Expected Savings:** 30-50% reduction (especially Bootstrap)

#### 4. Critical CSS

Extract critical above-the-fold CSS and inline it:

```html
<style>
  /* Critical CSS here - only what's needed for first paint */
  :root { --color-primary-800: #1A3A52; }
  .sidebar { background: var(--color-primary-800); }
</style>
<link rel="stylesheet" href="www/css/app.min.css" media="print" onload="this.media='all'">
```

**Benefit:** Eliminates render-blocking CSS

---

### JavaScript Optimization

#### 1. Minification

**Tool:** Terser (Node.js)

```bash
# Install
npm install -g terser

# Minify JavaScript
terser www/js/sidebar-navigation.js -o www/js/sidebar-navigation.min.js -c -m
terser www/js/theme-switcher.js -o www/js/theme-switcher.min.js -c -m
```

**Expected Savings:** ~30-40% file size reduction

#### 2. Defer Non-Critical JavaScript

```html
<!-- Current -->
<script src="www/js/sidebar-navigation.js"></script>

<!-- Optimized -->
<script src="www/js/sidebar-navigation.js" defer></script>
```

**Benefit:** Doesn't block HTML parsing

#### 3. Code Splitting

For larger apps, load JS only when needed:

```javascript
// Load theme switcher only when toggle is clicked
document.getElementById('theme-toggle').addEventListener('click', async () => {
  const module = await import('./theme-switcher.js');
  module.toggleTheme();
});
```

**Benefit:** Reduces initial bundle size

---

### Font Optimization

#### 1. Font Subsetting

Load only characters you need (Latin subset):

```css
/* Current - loads entire font */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

/* Optimized - subset */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap&subset=latin');
```

#### 2. Font Display Strategy

Prevent invisible text during font load:

```css
@font-face {
  font-family: 'Inter';
  src: url('fonts/inter.woff2') format('woff2');
  font-display: swap; /* Show fallback font immediately */
}
```

#### 3. Preload Critical Fonts

```html
<link rel="preload" href="fonts/inter-regular.woff2" as="font" type="font/woff2" crossorigin>
```

---

### Image Optimization

#### 1. Use SVG for Icons

Current approach is good - Font Awesome icons are SVG-based and scale perfectly.

#### 2. Optimize Plots (if raster images)

If R plots are rendered as PNG:
- Use smaller dimensions (max 800px width)
- Compress with tools like `optipng` or `pngquant`
- Consider SVG output instead

```r
# In Shiny renderPlot()
renderPlot({
  # Plot code
}, width = 800, height = 600)
```

---

### Caching Strategies

#### 1. Browser Caching (HTTP Headers)

In production server configuration (nginx, Apache):

```nginx
# Cache static assets for 1 year
location ~* \.(css|js|woff2|png|jpg|svg)$ {
  expires 1y;
  add_header Cache-Control "public, immutable";
}
```

#### 2. Service Worker (PWA)

For advanced caching:

```javascript
// sw.js - Service Worker
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('v1').then((cache) => {
      return cache.addAll([
        '/www/css/app.min.css',
        '/www/js/app.min.js',
        // other static assets
      ]);
    })
  );
});
```

---

### Shiny-Specific Optimizations

#### 1. Debounce Reactive Inputs

Prevent excessive recalculation:

```r
# Debounce numeric inputs
observe({
  input$sample_size %>% debounce(500)  # Wait 500ms after user stops typing
  # Calculations here
})
```

#### 2. Caching Expensive Calculations

```r
# Cache power curve calculations
power_curve_cache <- memoise::memoise(function(n, p1, p2, alpha) {
  # Expensive calculation
})

output$power_plot <- renderPlot({
  plot(power_curve_cache(input$n, input$p1, input$p2, input$alpha))
})
```

#### 3. Conditional Rendering

Only render visible elements:

```r
output$results <- renderUI({
  req(input$calculate_button)  # Only render after button click
  # Results UI
})
```

---

## Performance Benchmarks

### Desktop (Fast Connection)

| Metric | Target | Acceptable | Poor |
|--------|--------|------------|------|
| Page Load | < 1.5s | 1.5-3s | > 3s |
| Time to Interactive | < 2.5s | 2.5-4s | > 4s |
| FCP | < 1.0s | 1-1.8s | > 1.8s |
| LCP | < 1.5s | 1.5-2.5s | > 2.5s |
| CLS | < 0.05 | 0.05-0.1 | > 0.1 |

### Mobile (3G Connection)

| Metric | Target | Acceptable | Poor |
|--------|--------|------------|------|
| Page Load | < 3s | 3-5s | > 5s |
| Time to Interactive | < 5s | 5-8s | > 8s |
| FCP | < 2.5s | 2.5-3.5s | > 3.5s |
| LCP | < 4s | 4-6s | > 6s |
| CLS | < 0.1 | 0.1-0.2 | > 0.2 |

---

## Performance Testing Checklist

### Initial Load

- [ ] Hard refresh (Ctrl+Shift+R)
- [ ] Measure total page load time
- [ ] Verify no render-blocking resources
- [ ] Check FCP < 1.8s
- [ ] Check LCP < 2.5s
- [ ] Check CLS < 0.1
- [ ] Verify no layout shifts during load

### Navigation Performance

- [ ] Click sidebar link - measures response time
- [ ] Target: < 100ms
- [ ] Verify smooth transition (no jank)
- [ ] Check memory usage doesn't spike

### Interaction Performance

- [ ] Click theme toggle - measure time to update
- [ ] Target: < 200ms (includes transition)
- [ ] Open accordion - measure expand time
- [ ] Target: < 300ms
- [ ] Fill form and submit - measure to results
- [ ] Target: < 3s (includes R calculation)

### Animation Performance

- [ ] Open sidebar (mobile) - verify 60 FPS
- [ ] Scroll page - verify smooth scrolling
- [ ] Hover buttons - verify instant feedback
- [ ] Theme transition - verify smooth color change

### Resource Usage

- [ ] Initial memory: < 40 MB
- [ ] After navigation: < 60 MB
- [ ] CPU usage during idle: < 5%
- [ ] CPU usage during calculation: < 50%

---

## Common Performance Issues & Fixes

### Issue 1: Flash of Unstyled Content (FOUC)

**Symptom:** Page loads with default styles, then jumps to custom styles

**Fix:**
```html
<style>
  /* Inline critical CSS */
  body { font-family: Inter, sans-serif; }
  .sidebar { background: #1A3A52; }
</style>
<link rel="stylesheet" href="www/css/app.css">
```

---

### Issue 2: Large CSS Bundle

**Symptom:** CSS file > 100 KB, slow to download

**Fix:**
1. Remove unused Bootstrap components
2. Minify CSS files
3. Use PurgeCSS to remove unused rules
4. Consider CSS-in-JS for component-specific styles

---

### Issue 3: Slow Sidebar Animation

**Symptom:** Sidebar opens/closes with janky animation

**Fix:**
```css
/* Use transform instead of width for animations */
.sidebar {
  transform: translateX(-280px);
  transition: transform 300ms ease;
}

.sidebar.open {
  transform: translateX(0);
}

/* Also use will-change hint */
.sidebar {
  will-change: transform;
}
```

---

### Issue 4: Layout Shift on Font Load

**Symptom:** Text changes size/position when web font loads

**Fix:**
```css
/* Use font-display: swap */
@font-face {
  font-family: 'Inter';
  font-display: swap;
}

/* Or preload font */
/* <link rel="preload" href="inter.woff2" as="font"> */
```

---

### Issue 5: Slow R Calculations

**Symptom:** Long wait after clicking Calculate

**Fix:**
```r
# Use efficient algorithms
# Cache results with memoise
library(memoise)

calc_power_cached <- memoise(calc_power)

# Use promises for async calculations (advanced)
library(promises)
library(future)
plan(multisession)

output$results <- renderPlot({
  future({
    # Heavy calculation
  }) %...>% plot()
})
```

---

## Monitoring Performance Over Time

### Lighthouse CI

Automate performance testing in CI/CD:

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI
on: [push]
jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: treosh/lighthouse-ci-action@v8
        with:
          urls: 'http://localhost:3838'
          budgetPath: './budget.json'
```

**budget.json:**
```json
{
  "resourceSizes": [
    { "resourceType": "stylesheet", "budget": 100 },
    { "resourceType": "script", "budget": 150 }
  ],
  "timings": [
    { "metric": "interactive", "budget": 4000 }
  ]
}
```

---

### Real User Monitoring (RUM)

For production apps, consider adding RUM:

```javascript
// Google Analytics 4 - Web Vitals
import {getCLS, getFID, getFCP, getLCP, getTTFB} from 'web-vitals';

function sendToAnalytics(metric) {
  gtag('event', metric.name, {
    value: Math.round(metric.value),
    metric_id: metric.id,
    metric_delta: metric.delta,
  });
}

getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getFCP(sendToAnalytics);
getLCP(sendToAnalytics);
getTTFB(sendToAnalytics);
```

---

## Performance Budget

Set limits to prevent regression:

| Resource Type | Budget | Current | Status |
|---------------|--------|---------|--------|
| Total CSS | 100 KB | ~95 KB | ✅ |
| Total JS | 150 KB | ~140 KB | ✅ |
| Total Fonts | 80 KB | ~60 KB | ✅ |
| Total Images | 50 KB | ~15 KB | ✅ |
| Page Load (Desktop) | 3s | ~2s | ✅ |
| Time to Interactive | 4s | ~3s | ✅ |
| Lighthouse Score | 90 | TBD | ⏳ |

---

## Resources

**Testing Tools:**
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)
- [WebPageTest](https://www.webpagetest.org/)
- [PageSpeed Insights](https://pagespeed.web.dev/)

**Optimization Tools:**
- [cssnano](https://cssnano.co/) - CSS minification
- [Terser](https://terser.org/) - JavaScript minification
- [PurgeCSS](https://purgecss.com/) - Remove unused CSS

**Learning Resources:**
- [Web.dev Performance](https://web.dev/performance/)
- [Chrome DevTools Performance](https://developer.chrome.com/docs/devtools/performance/)
- [Core Web Vitals](https://web.dev/vitals/)

---

## Next Steps

1. **Run Baseline Audit**
   - [ ] Run Lighthouse audit
   - [ ] Record current metrics
   - [ ] Identify top 3 issues

2. **Implement Quick Wins**
   - [ ] Minify CSS and JavaScript
   - [ ] Add font-display: swap
   - [ ] Defer non-critical JS

3. **Optimize Assets**
   - [ ] Combine CSS files
   - [ ] Remove unused CSS with PurgeCSS
   - [ ] Compress images

4. **Set Up Monitoring**
   - [ ] Add Lighthouse CI
   - [ ] Set performance budgets
   - [ ] Monitor over time

---

**Last Updated:** 2025-10-25
**Related Documents:**
- `docs/003-reference/004-cross-device-testing-checklist.md`
- `docs/003-reference/005-browser-compatibility-testing.md`
- `docs/004-explanation/002-ui-ux-modernization.md`
