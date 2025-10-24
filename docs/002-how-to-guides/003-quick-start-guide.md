# UI/UX Modernization - Quick Start Guide

**Read this first, then dive into the full plan: [UI_UX_MODERNIZATION_PLAN.md](./UI_UX_MODERNIZATION_PLAN.md)**

## Key Decisions Made

### 1. Color Palette ✓
**Decision:** Deep teal/slate blue (#2B5876 primary) instead of bright blue (#3498db)
- More sophisticated and professional
- Better for pharmaceutical/enterprise context
- Accent: Warm amber (#F59E0B) for warnings and CTAs

### 2. Layout ✓
**Decision:** Left sidebar navigation + single content column
- **Before:** Top horizontal tabs + left sidebar inputs + right content
- **After:** Left hierarchical nav + unified main content area
- Simpler information architecture
- Better scalability

### 3. Navigation Structure ✓
```
Single Proportion
├── Power Analysis
└── Sample Size (Rule of Three)
Two-Group Comparisons
├── Power Analysis
└── Sample Size Calculation
Survival Analysis (Cox)
├── Power Analysis
└── Sample Size Calculation
...
```

### 4. Typography ✓
**Decision:** Inter font family (unified)
- Replaces: Open Sans + Montserrat
- Why: Modern, excellent readability, professional
- Fallback: System fonts (-apple-system, Segoe UI)

### 5. Key UX Improvements ✓

#### Significance Level Input
**Before:** Slider (imprecise)
**After:** Segmented control with 4 buttons
```
┌────┬────┬─────┬─────┐
│0.01│0.02│0.05*│0.10 │
└────┴────┴─────┴─────┘
```
**Why:** Common statistical values, faster selection, more precise

#### Input Layout
**Before:** Labels beside inputs
**After:** Labels above inputs
**Why:** Better readability, responsive-friendly, modern standard

#### Content Organization
**Before:** Accordions with heavy blue headers
**After:** Clean accordions with minimal borders and chevron icons
```
▼ Two-Group Comparisons
  Content here...
▶ Survival Analysis (Cox Regression)
```

### 6. Semantic Design System ✓

All styling uses CSS custom properties (variables):
```css
/* Semantic, not arbitrary */
var(--text-primary)      /* Not: #000000 */
var(--bg-card)           /* Not: #FFFFFF */
var(--color-primary-600) /* Not: #3498db */
```

**Benefits:**
- Easy theme updates (change one variable)
- Consistent styling
- Dark mode ready (future)
- Maintainable codebase

## Implementation Priority (Start Here)

### Phase 1: Foundation (Day 1)
1. Create `www/css/design-tokens.css` - All semantic variables
2. Create `www/css/modern-theme.css` - Component styles
3. Link CSS files in `app.R`
4. Test: Verify app still works

**Time:** 3-4 hours
**Risk:** Low

### Phase 2: Navigation (Day 2)
1. Create hierarchical sidebar HTML structure
2. Replace top `tabsetPanel()` with sidebar navigation
3. Update reactive logic for navigation
4. Style sidebar with new colors

**Time:** 4-5 hours
**Risk:** Medium (major structural change)

### Phase 3: Inputs & Buttons (Day 3)
1. Replace significance level sliders with segmented controls
2. Restyle numeric inputs (labels above)
3. Update button hierarchy (primary/secondary)
4. Test all input interactions

**Time:** 3-4 hours
**Risk:** Low

### Phase 4: Content & Layout (Day 4)
1. Wrap content in card components
2. Update accordion styling
3. Add professional header
4. Enhance quick preview footer

**Time:** 3-4 hours
**Risk:** Low

### Phase 5: Polish & Test (Day 5)
1. Responsive testing (mobile, tablet, desktop)
2. Accessibility audit (keyboard, screen reader)
3. Cross-browser testing
4. Performance optimization

**Time:** 3-4 hours
**Risk:** Low

**Total:** ~18-23 hours (approximately 1 work week)

## Files to Create

```
www/
├── css/
│   ├── design-tokens.css       ← Semantic variables (NEW)
│   ├── modern-theme.css        ← Component styles (NEW)
│   └── responsive.css          ← Media queries (NEW)
├── js/
│   ├── sidebar-toggle.js       ← Navigation behavior (NEW)
│   └── segmented-control.js    ← Custom input (NEW)
└── images/
    └── logo.svg                ← App logo (optional)
```

## Quick Wins (Implement First for Immediate Impact)

### 1. Update Colors (30 minutes)
Just change the `bs_theme()` primary color in app.R:
```r
theme = bs_theme(
  version = 5,
  bootswatch = "cosmo",
  primary = "#2B5876",  # ← Change from #3498db
  base_font = font_google("Inter"),  # ← Change from Open Sans
  heading_font = font_google("Inter")  # ← Change from Montserrat
)
```

### 2. Add Card Styling (1 hour)
Add to app.R header:
```r
tags$head(
  tags$style(HTML("
    .content-card {
      background: white;
      border-radius: 8px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      padding: 24px;
      margin-bottom: 24px;
    }
  "))
)
```

Wrap panels in `div(class = "content-card", ...)`

### 3. Improve Button Hierarchy (30 minutes)
Update Calculate button:
```r
actionButton("go", "Calculate",
  class = "btn-primary btn-lg w-100",  # ← Add w-100 for full width
  style = "box-shadow: 0 4px 6px rgba(0,0,0,0.1); font-weight: 600;"
)
```

Update secondary buttons:
```r
actionButton("example_power_single", "Load Example",
  icon = icon("lightbulb"),
  class = "btn-outline-primary btn-sm"  # ← Change from btn-info
)
```

## Testing Checklist

After each phase, verify:

- [ ] App loads without errors
- [ ] All tabs/navigation items work
- [ ] Inputs accept values correctly
- [ ] Calculate button triggers analysis
- [ ] Results display properly
- [ ] Quick preview updates
- [ ] Example buttons populate inputs
- [ ] Reset buttons clear inputs
- [ ] Tooltips still appear
- [ ] Responsive on mobile (test with browser dev tools)
- [ ] Keyboard navigation works
- [ ] No visual regressions

## Rollback Plan

If anything breaks:

1. **CSS Issues:** Comment out CSS file link in app.R
2. **Navigation Issues:** Keep old `tabsetPanel()` code commented in app.R
3. **Input Issues:** Revert to original input widgets
4. **Git:** All changes should be in commits - use `git revert`

## Support Resources

### Full Documentation
- [Complete Plan](./UI_UX_MODERNIZATION_PLAN.md) - Full 40+ page spec
- [Current App](../../app.R) - Existing code
- [Screenshot](../../capture.png) - Current state

### Design Systems to Reference
- Material Design 3: https://m3.material.io/
- Bootstrap 5 Docs: https://getbootstrap.com/docs/5.3/
- Inter Font: https://fonts.google.com/specimen/Inter

### Shiny Resources
- bslib Theming: https://rstudio.github.io/bslib/
- Shiny Custom CSS: https://shiny.posit.co/r/articles/build/css/
- Bootstrap 5 + Shiny: https://rstudio.github.io/bslib/articles/bs5-variables.html

## Expected Outcomes

### Before
- Default Bootstrap blue theme
- Functional but dated appearance
- Horizontal tabs + sidebar layout
- Mix of slider/numeric inputs
- Heavy blue accordions
- No distinct header

### After
- Professional teal/slate color palette
- Modern, enterprise-grade design
- Clean hierarchical sidebar navigation
- Optimized input patterns (segmented controls)
- Minimal, clean accordions
- Branded header + enhanced footer
- Card-based content hierarchy
- Semantic design system

### User Experience Improvements
- 🚀 **Faster navigation** - Hierarchical sidebar shows all options at once
- 🎯 **Precise inputs** - Segmented controls for common values
- 📱 **Better mobile** - Responsive layout with collapsible sidebar
- ♿ **More accessible** - WCAG AA compliant, keyboard-friendly
- 🎨 **Professional** - Suitable for pharmaceutical enterprise use
- 🔧 **Maintainable** - Semantic variables make future updates easy

## Questions? Issues?

If you encounter problems during implementation:

1. **Check the full plan** - Detailed specs in UI_UX_MODERNIZATION_PLAN.md
2. **Test incrementally** - Don't change everything at once
3. **Use git branches** - Create `feature/ui-modernization` branch
4. **Keep backups** - Commit working state before major changes
5. **Ask for help** - Reference specific section numbers in questions

---

**Ready to start?** → Begin with Phase 1: Create design-tokens.css

**Want to see quick wins first?** → Implement the 3 quick wins above
