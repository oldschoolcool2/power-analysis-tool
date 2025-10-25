# Cross-Device Testing Checklist

**Type:** Reference
**Audience:** Developers, QA Engineers
**Last Updated:** 2025-10-25
**Related:** `docs/004-explanation/002-ui-ux-modernization.md`, Phase 7

## Overview

This document provides a comprehensive checklist for testing the Power Analysis Tool across different devices, browsers, and screen sizes. Use this checklist to ensure consistent user experience and functionality across all supported platforms.

**Recommendation:** Test on actual devices whenever possible, as emulators may not accurately represent touch interactions, performance, or rendering issues.

---

## Testing Matrix

### Priority Levels

- **🔴 High:** Critical for most users, must pass before release
- **🟡 Medium:** Important but affects fewer users
- **🟢 Low:** Nice to have, edge cases

---

## Browser & OS Combinations

### Desktop Browsers (🔴 High Priority)

| Browser | OS | Min Version | Test Status |
|---------|----|--------------|----|
| Chrome | Windows 10+ | Latest | ⬜ |
| Chrome | macOS | Latest | ⬜ |
| Firefox | Windows 10+ | Latest | ⬜ |
| Firefox | macOS | Latest | ⬜ |
| Safari | macOS | 14+ | ⬜ |
| Edge | Windows 10+ | Latest | ⬜ |

### Mobile Browsers (🔴 High Priority)

| Browser | OS | Device Type | Test Status |
|---------|----|--------------|----|
| Safari | iOS 14+ | iPhone SE (small) | ⬜ |
| Safari | iOS 14+ | iPhone 12/13/14 (medium) | ⬜ |
| Safari | iOS 14+ | iPhone 14 Pro Max (large) | ⬜ |
| Safari | iPadOS 14+ | iPad (10.2") | ⬜ |
| Safari | iPadOS 14+ | iPad Pro (12.9") | ⬜ |
| Chrome | Android 10+ | Small phone (<6") | ⬜ |
| Chrome | Android 10+ | Medium phone (6-6.5") | ⬜ |
| Chrome | Android 10+ | Large phone (>6.5") | ⬜ |
| Chrome | Android 10+ | Tablet (7-10") | ⬜ |

### Additional Browsers (🟡 Medium Priority)

| Browser | OS | Notes | Test Status |
|---------|----|---------|----|
| Firefox | Linux (Ubuntu) | Developer/research users | ⬜ |
| Chrome | Linux (Ubuntu) | Developer/research users | ⬜ |
| Samsung Internet | Android | Popular Samsung default | ⬜ |

---

## Responsive Breakpoints

Test the following viewport sizes in browser DevTools:

| Breakpoint | Width | Device Example | Test Status |
|------------|-------|-----------------|-----|
| Mobile S | 320px | iPhone SE | ⬜ |
| Mobile M | 375px | iPhone 12/13 | ⬜ |
| Mobile L | 425px | iPhone 14 Pro Max | ⬜ |
| Tablet | 768px | iPad | ⬜ |
| Tablet L | 1024px | iPad Pro | ⬜ |
| Laptop | 1280px | MacBook Air | ⬜ |
| Desktop | 1440px | Standard desktop | ⬜ |
| Desktop L | 1920px | Full HD monitor | ⬜ |
| 4K | 2560px | 4K monitor | ⬜ |

---

## Test Cases by Feature

### 1. Navigation & Sidebar (🔴 High)

| Test Case | Desktop | Tablet | Mobile | Notes |
|-----------|---------|--------|--------|-------|
| Sidebar visible on load | ⬜ | ⬜ | ⬜ | Desktop: expanded, Mobile: collapsed |
| Sidebar toggle works | ⬜ | ⬜ | ⬜ | Mobile: hamburger menu |
| Parent groups expand/collapse | ⬜ | ⬜ | ⬜ | Smooth animation |
| Active page highlighted | ⬜ | ⬜ | ⬜ | Amber left border |
| Navigation links work | ⬜ | ⬜ | ⬜ | All 10 analysis pages |
| Mobile overlay closes on nav | ⬜ | N/A | ⬜ | Auto-close on selection |
| Mobile overlay closes on ESC | ⬜ | N/A | ⬜ | Keyboard accessibility |
| Backdrop click closes sidebar | ⬜ | ⬜ | ⬜ | Mobile/tablet only |
| Sidebar width appropriate | ⬜ | ⬜ | ⬜ | 280px desktop, 100% mobile |

### 2. Header & Footer (🔴 High)

| Test Case | Desktop | Tablet | Mobile | Notes |
|-----------|---------|--------|--------|-------|
| Header sticky on scroll | ⬜ | ⬜ | ⬜ | Always visible at top |
| Logo/title visible | ⬜ | ⬜ | ⬜ | Text readable |
| Subtitle hidden on mobile | N/A | N/A | ⬜ | Space saving |
| Theme toggle works | ⬜ | ⬜ | ⬜ | Smooth transition |
| Help button opens modal | ⬜ | ⬜ | ⬜ | Modal fully visible |
| Footer fixed at bottom | ⬜ | ⬜ | ⬜ | Doesn't overlap content |
| Footer preview text updates | ⬜ | ⬜ | ⬜ | Real-time reactive |
| Footer CTA hidden on mobile | N/A | N/A | ⬜ | "(Click Calculate...)" |

### 3. Input Components (🔴 High)

| Test Case | Desktop | Tablet | Mobile | Notes |
|-----------|---------|--------|--------|-------|
| Numeric inputs functional | ⬜ | ⬜ | ⬜ | Can type numbers |
| Segmented controls (alpha) work | ⬜ | ⬜ | ⬜ | Button group selection |
| Active alpha button highlighted | ⬜ | ⬜ | ⬜ | Visual feedback |
| Input focus states visible | ⬜ | ⬜ | ⬜ | Primary color ring |
| Tooltips don't overflow screen | ⬜ | ⬜ | ⬜ | Especially on mobile |
| Form labels readable | ⬜ | ⬜ | ⬜ | Proper contrast |
| Sliders functional (if any) | ⬜ | ⬜ | ⬜ | Withdrawal rate, etc. |
| Dropdowns/selects work | ⬜ | ⬜ | ⬜ | Options visible |

### 4. Touch Targets (🔴 High Priority on Mobile)

**All interactive elements should be ≥44x44px on mobile**

| Element | Min Size Met | Tappable | Notes |
|---------|--------------|----------|-------|
| Primary buttons | ⬜ | ⬜ | Calculate button |
| Secondary buttons | ⬜ | ⬜ | Load Example, Reset |
| Navigation links | ⬜ | ⬜ | Sidebar items |
| Segmented control buttons | ⬜ | ⬜ | Alpha selection |
| Accordion headers | ⬜ | ⬜ | Help sections |
| Form inputs | ⬜ | ⬜ | Text/number inputs |
| Checkboxes/radios | ⬜ | ⬜ | If present |
| Theme toggle | ⬜ | ⬜ | Header button |
| Help button | ⬜ | ⬜ | Header button |
| Mobile menu toggle | ⬜ | ⬜ | Hamburger icon |

### 5. Content Layout (🔴 High)

| Test Case | Desktop | Tablet | Mobile | Notes |
|-----------|---------|--------|--------|-------|
| Cards have proper spacing | ⬜ | ⬜ | ⬜ | Not cramped |
| No horizontal scroll | ⬜ | ⬜ | ⬜ | Content fits viewport |
| Typography readable | ⬜ | ⬜ | ⬜ | Good line length |
| Tables responsive | ⬜ | ⬜ | ⬜ | Scrollable on mobile |
| Images/plots scale properly | ⬜ | ⬜ | ⬜ | No overflow |
| White space balanced | ⬜ | ⬜ | ⬜ | Not too dense/sparse |

### 6. Accordions & Modals (🔴 High)

| Test Case | Desktop | Tablet | Mobile | Notes |
|-----------|---------|--------|--------|-------|
| Accordions expand/collapse | ⬜ | ⬜ | ⬜ | Smooth animation |
| Chevron icons rotate | ⬜ | ⬜ | ⬜ | Visual feedback |
| Accordion content readable | ⬜ | ⬜ | ⬜ | Proper spacing |
| Modals centered on screen | ⬜ | ⬜ | ⬜ | Fully visible |
| Modals scrollable if tall | ⬜ | ⬜ | ⬜ | No content cutoff |
| Modal close button accessible | ⬜ | ⬜ | ⬜ | Easy to tap/click |
| Backdrop prevents interaction | ⬜ | ⬜ | ⬜ | Behind modal |

### 7. Calculations & Results (🔴 High)

| Test Case | Desktop | Tablet | Mobile | Notes |
|-----------|---------|--------|--------|-------|
| Calculate button triggers calc | ⬜ | ⬜ | ⬜ | All analysis types |
| Results display properly | ⬜ | ⬜ | ⬜ | Tables, plots, text |
| Power curves render | ⬜ | ⬜ | ⬜ | Plotly charts |
| Tables fit viewport | ⬜ | ⬜ | ⬜ | Horizontal scroll if needed |
| Export buttons work | ⬜ | ⬜ | ⬜ | Download results |
| Error messages visible | ⬜ | ⬜ | ⬜ | Validation feedback |

### 8. Accessibility (🔴 High)

| Test Case | Result | Notes |
|-----------|--------|-------|
| Keyboard navigation works | ⬜ | Tab through all elements |
| Focus indicators visible | ⬜ | Primary color ring |
| Skip navigation link | ⬜ | Keyboard users |
| ARIA labels present | ⬜ | Icon-only buttons |
| Screen reader compatible | ⬜ | Test with NVDA/JAWS/VoiceOver |
| Color contrast WCAG AA | ⬜ | 4.5:1 for text, 3:1 for large |
| Alt text on images | ⬜ | If any images present |
| Form labels associated | ⬜ | No orphaned labels |

### 9. Performance (🟡 Medium)

| Metric | Target | Desktop | Mobile | Tool |
|--------|--------|---------|--------|------|
| First Contentful Paint | <1.8s | ⬜ | ⬜ | Lighthouse |
| Largest Contentful Paint | <2.5s | ⬜ | ⬜ | Lighthouse |
| Time to Interactive | <3.8s | ⬜ | ⬜ | Lighthouse |
| Cumulative Layout Shift | <0.1 | ⬜ | ⬜ | Lighthouse |
| Total Blocking Time | <200ms | ⬜ | ⬜ | Lighthouse |
| CSS bundle size | <100KB | ⬜ | ⬜ | Network tab |
| JS bundle size | <150KB | ⬜ | ⬜ | Network tab |
| Smooth animations | 60fps | ⬜ | ⬜ | Performance tab |

### 10. Print Functionality (🟢 Low)

| Test Case | Chrome | Firefox | Safari | Notes |
|-----------|--------|---------|--------|-------|
| Sidebar hidden | ⬜ | ⬜ | ⬜ | Print only content |
| Header/footer hidden | ⬜ | ⬜ | ⬜ | UI chrome removed |
| Buttons hidden | ⬜ | ⬜ | ⬜ | Interactive elements |
| Accordions expanded | ⬜ | ⬜ | ⬜ | All content visible |
| Tables formatted | ⬜ | ⬜ | ⬜ | Borders, no shadows |
| Page breaks clean | ⬜ | ⬜ | ⬜ | No orphan headings |
| Black text on white | ⬜ | ⬜ | ⬜ | Ink-friendly |
| Link URLs shown | ⬜ | ⬜ | ⬜ | External links only |

### 11. Theme Toggle (🟡 Medium)

| Test Case | Desktop | Tablet | Mobile | Notes |
|-----------|---------|--------|--------|-------|
| Toggle button visible | ⬜ | ⬜ | ⬜ | Moon/sun icon |
| Theme switches smoothly | ⬜ | ⬜ | ⬜ | Transition animation |
| Icon rotates | ⬜ | ⬜ | ⬜ | Visual feedback |
| Preference persists | ⬜ | ⬜ | ⬜ | localStorage |
| Keyboard shortcut works | ⬜ | ⬜ | ⬜ | Ctrl+Shift+D |
| Dark mode readable | ⬜ | ⬜ | ⬜ | If implemented |

---

## Device-Specific Tests

### iOS-Specific

| Test Case | Status | Notes |
|-----------|--------|-------|
| Safari 14+ compatibility | ⬜ | Older iOS versions |
| Touch scrolling smooth | ⬜ | Momentum scrolling |
| Pinch zoom works (if enabled) | ⬜ | Accessibility |
| Safe area insets respected | ⬜ | iPhone notch |
| No unintended zooming | ⬜ | Form input focus |
| VoiceOver navigation | ⬜ | Screen reader |
| Landscape orientation | ⬜ | Horizontal layout |

### Android-Specific

| Test Case | Status | Notes |
|-----------|--------|-------|
| Chrome compatibility | ⬜ | Latest version |
| Samsung Internet works | ⬜ | Popular default |
| Touch scrolling smooth | ⬜ | Various devices |
| Back button behavior | ⬜ | Sidebar closes first |
| TalkBack navigation | ⬜ | Screen reader |
| Landscape orientation | ⬜ | Horizontal layout |
| Various screen densities | ⬜ | hdpi, xhdpi, xxhdpi |

---

## Testing Tools

### Browser DevTools

**Chrome DevTools (F12):**
- Device Toolbar (Ctrl+Shift+M): Responsive testing
- Lighthouse: Performance, accessibility, best practices
- Network tab: Bundle sizes, load times
- Performance tab: Rendering performance
- Accessibility tree: Screen reader simulation

**Firefox DevTools (F12):**
- Responsive Design Mode (Ctrl+Shift+M)
- Accessibility inspector
- Network monitor

**Safari Web Inspector (Cmd+Option+I):**
- Responsive Design Mode
- Network tab
- Accessibility audit

### Testing Services

**BrowserStack** (Recommended for comprehensive testing):
- Real devices (iOS, Android)
- All major browsers
- Screenshot comparison
- Automated testing

**Free Alternatives:**
- LambdaTest (limited free tier)
- Sauce Labs (open source projects)
- CrossBrowserTesting

### Accessibility Tools

**Automated:**
- axe DevTools (browser extension)
- WAVE (web accessibility evaluation tool)
- Lighthouse accessibility audit

**Manual:**
- NVDA (Windows, free)
- JAWS (Windows, paid)
- VoiceOver (macOS/iOS, built-in)
- TalkBack (Android, built-in)

### Performance Tools

- Lighthouse (Chrome DevTools)
- WebPageTest (webpagetest.org)
- PageSpeed Insights (Google)
- Chrome User Experience Report

---

## Test Execution

### Pre-Testing Checklist

- [ ] Application running (local or deployed)
- [ ] Clear browser cache
- [ ] Disable browser extensions (may interfere)
- [ ] Note browser version
- [ ] Note OS version
- [ ] Screen recording tool ready (for bug reports)

### Testing Process

1. **Start with desktop Chrome/Firefox**
   - Easiest to debug
   - Establish baseline

2. **Test responsive breakpoints in DevTools**
   - Use device toolbar
   - Check all major breakpoints
   - Note any layout issues

3. **Test on actual mobile devices**
   - Touch interactions differ from mouse
   - Performance may vary
   - Real-world conditions

4. **Run automated accessibility audit**
   - Lighthouse
   - axe DevTools
   - Fix critical issues

5. **Manual accessibility testing**
   - Keyboard navigation
   - Screen reader
   - Color blindness simulation

6. **Performance testing**
   - Lighthouse audit
   - Network throttling (3G/4G)
   - Note load times

7. **Print testing**
   - Print preview in each browser
   - Check formatting

### Bug Reporting Template

When you find an issue, document:

```markdown
**Issue:** [Brief description]
**Severity:** Critical / High / Medium / Low
**Browser:** [Name + Version]
**OS:** [Name + Version]
**Device:** [If mobile/tablet]
**Screen Size:** [Width x Height]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected:** [What should happen]
**Actual:** [What actually happens]

**Screenshot/Video:** [Link or attachment]
**Console Errors:** [If any]
```

---

## Sign-Off

### Final Verification

Before marking Phase 7 complete, ensure:

- [ ] All 🔴 High Priority tests pass on major browsers (Chrome, Firefox, Safari)
- [ ] All 🔴 High Priority tests pass on iOS and Android
- [ ] No critical accessibility issues
- [ ] Performance meets targets (Lighthouse >90)
- [ ] Print styles functional in at least Chrome and Firefox
- [ ] Touch targets ≥44px on mobile
- [ ] No horizontal scrolling on any device
- [ ] All navigation and core functionality works

### Testing Sign-Off

**Tester:** ___________________________
**Date:** ___________________________
**Overall Status:** ⬜ Pass / ⬜ Fail / ⬜ Pass with minor issues
**Notes:**

---

## Related Documentation

- Main plan: `docs/004-explanation/002-ui-ux-modernization.md`
- Progress tracker: `docs/reports/enhancements/ui-ux-modernization/003-ui-ux-modernization-progress.md`
- Developer guide: `docs/003-reference/003-developer-guide.md`
- Antipatterns guide: `docs/003-reference/002-antipatterns-guide.md`

---

**Last Updated:** 2025-10-25
**Maintainer:** Development Team
**Status:** ✅ Active reference document
