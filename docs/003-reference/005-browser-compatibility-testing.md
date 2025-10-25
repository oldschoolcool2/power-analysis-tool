# Browser Compatibility Testing Guide

**Type:** Reference
**Audience:** Developers, QA Testers
**Last Updated:** 2025-10-25

## Overview

This document provides a comprehensive testing guide for verifying the Power Analysis Tool works correctly across different browsers and platforms. It supports the Phase 8 testing requirements of the UI/UX modernization project.

---

## Browser Support Matrix

### Supported Browsers

| Browser | Version | Operating Systems | Priority | Status |
|---------|---------|-------------------|----------|--------|
| Chrome | Latest (120+) | Windows, macOS, Linux | High | ⏳ To Test |
| Firefox | Latest (120+) | Windows, macOS, Linux | High | ⏳ To Test |
| Safari | Latest (17+) | macOS, iOS | High | ⏳ To Test |
| Edge | Latest (120+) | Windows | Medium | ⏳ To Test |
| Chrome Mobile | Latest | Android 10+ | Medium | ⏳ To Test |
| Safari Mobile | Latest | iOS 14+ | Medium | ⏳ To Test |

### Minimum Supported Versions

- **Chrome:** 100+
- **Firefox:** 100+
- **Safari:** 15+
- **Edge:** 100+
- **iOS Safari:** 14+
- **Android Chrome:** 10+

### Known Limitations

- **Internet Explorer:** Not supported (end of life 2022)
- **Safari < 15:** Limited CSS custom property support
- **Older Android (<10):** May have touch target issues

---

## Testing Environment Setup

### Local Testing

```bash
# Start the application locally
docker-compose up

# Access at:
# http://localhost:3838
```

### Browser Testing Tools

**Recommended Tools:**

1. **BrowserStack** (https://www.browserstack.com/)
   - Real device testing
   - Screenshots across browsers
   - Automated testing capabilities

2. **Chrome DevTools Device Toolbar**
   - Keyboard: Ctrl+Shift+M (Windows/Linux) or Cmd+Shift+M (Mac)
   - Emulate mobile devices
   - Responsive design testing

3. **Firefox Developer Tools**
   - Keyboard: Ctrl+Shift+M (Windows/Linux) or Cmd+Shift+M (Mac)
   - Responsive design mode
   - Accessibility inspector

4. **Safari Responsive Design Mode**
   - Develop > Enter Responsive Design Mode
   - iOS device emulation

### Virtual Machines for OS Testing

**Windows Testing on Mac/Linux:**
- VirtualBox + Windows 11 VM
- Parallels Desktop (Mac only)

**macOS Testing on Windows:**
- Use BrowserStack or similar cloud service
- Physical Mac machine

---

## Core Functionality Test Cases

### Test Suite 1: Navigation

**Objective:** Verify sidebar navigation works across all browsers

**Test Steps:**

1. **Sidebar Visibility**
   - [ ] Sidebar appears on left side (desktop)
   - [ ] Sidebar is 280px wide (desktop)
   - [ ] Sidebar background is dark teal (`#1A3A52`)
   - [ ] All 6 navigation groups visible

2. **Collapsible Groups**
   - [ ] Click "Single Proportion" - expands to show 2 children
   - [ ] Click again - collapses children
   - [ ] Chevron icon rotates 90° on expand
   - [ ] Transition is smooth (300ms)

3. **Navigation Links**
   - [ ] Click "Power Analysis" under Single Proportion
   - [ ] Page content changes to show power analysis form
   - [ ] Active link has lighter background
   - [ ] Active link has amber left border (4px, `#F59E0B`)

4. **Mobile Sidebar (< 640px)**
   - [ ] Sidebar hidden by default on mobile
   - [ ] Hamburger button appears in top-left
   - [ ] Click hamburger - sidebar slides in from left
   - [ ] Backdrop blur effect visible
   - [ ] Click outside sidebar - sidebar closes
   - [ ] Press ESC key - sidebar closes

**Expected Results:** All navigation interactions work smoothly without JavaScript errors.

**Browser-Specific Notes:**
- **Safari:** Check for backdrop-filter support (blur may not work on older versions)
- **Firefox:** Verify smooth transitions (may need `will-change` CSS)

---

### Test Suite 2: Input Components

**Objective:** Verify all input types render and function correctly

**Test Steps:**

1. **Numeric Inputs**
   - [ ] Navigate to "Power Analysis (Single Proportion)"
   - [ ] Input fields have clean borders (`#E2E8F0`)
   - [ ] Click input field - blue focus ring appears
   - [ ] Focus ring is 3px, color `#EBF4FC`
   - [ ] Type value - input updates
   - [ ] Increment/decrement arrows work (where applicable)

2. **Segmented Controls (Alpha Selection)**
   - [ ] Alpha selector shows 4 buttons: 0.01, 0.025, 0.05, 0.10
   - [ ] Default selection is 0.05 (highlighted)
   - [ ] Selected button has white background
   - [ ] Selected button has blue text (`#2B5876`)
   - [ ] Selected button has subtle shadow
   - [ ] Click different value - updates immediately
   - [ ] Hover over button - background changes to `#EDF2F7`

3. **Sliders (Withdrawal Rate, etc.)**
   - [ ] Slider track visible
   - [ ] Thumb is circular, 20px diameter
   - [ ] Filled portion shows in primary color
   - [ ] Drag thumb - value updates
   - [ ] Value display updates in real-time

4. **Buttons**
   - [ ] "Calculate" button is full width
   - [ ] "Calculate" button has primary blue background
   - [ ] "Load Example" and "Reset" are half-width
   - [ ] Hover effects work (slight translation, shadow change)
   - [ ] Click "Calculate" - results appear below

**Expected Results:** All inputs are functional and visually correct.

**Browser-Specific Notes:**
- **Safari iOS:** Test touch interactions on actual device
- **Firefox:** Verify custom radio button styling works
- **Edge:** Check slider appearance (may differ from Chrome)

---

### Test Suite 3: Theme Toggle

**Objective:** Verify light/dark theme switching works

**Test Steps:**

1. **Default Theme**
   - [ ] App loads in light theme
   - [ ] Background is soft gray (`#F8F9FA`)
   - [ ] Text is dark gray (`#1D2A39`)
   - [ ] Theme toggle button shows moon icon

2. **Switch to Dark Theme**
   - [ ] Click theme toggle button (moon icon)
   - [ ] Background changes to dark (`#1D2A39` or similar)
   - [ ] Text changes to light (`#F7FAFC` or similar)
   - [ ] Icon changes to sun
   - [ ] Transition is smooth (200ms)
   - [ ] Sidebar adjusts colors appropriately

3. **Persistence**
   - [ ] Refresh page - dark theme persists
   - [ ] Open new tab - dark theme applies
   - [ ] Close browser, reopen - dark theme persists (localStorage)

4. **Keyboard Shortcut**
   - [ ] Press Ctrl+Shift+D (Windows/Linux) or Cmd+Shift+D (Mac)
   - [ ] Theme toggles

**Expected Results:** Theme switching works without visual glitches.

**Browser-Specific Notes:**
- **Safari:** Verify localStorage persistence
- **Firefox:** Check for color flickering on transition

---

### Test Suite 4: Help & Modals

**Objective:** Verify help modal and accordions work

**Test Steps:**

1. **Help Button**
   - [ ] Click "Help" button in header
   - [ ] Modal appears centered on screen
   - [ ] Modal has white background
   - [ ] Modal has shadow and backdrop
   - [ ] Click outside modal - modal closes
   - [ ] Press ESC - modal closes
   - [ ] Click X button - modal closes

2. **Help Accordion**
   - [ ] Scroll to bottom of any analysis page
   - [ ] "About this Analysis" accordion visible
   - [ ] Click accordion header - content expands
   - [ ] Chevron rotates
   - [ ] Content is readable with proper spacing
   - [ ] Links in content are clickable and colored blue

3. **Tooltips**
   - [ ] Hover over question mark icon next to input label
   - [ ] Tooltip appears after 300ms
   - [ ] Tooltip has dark background with white text
   - [ ] Tooltip is readable (WCAG AA contrast)
   - [ ] Move mouse away - tooltip disappears

**Expected Results:** All interactive help elements function correctly.

**Browser-Specific Notes:**
- **Safari iOS:** Tooltips may require tap instead of hover
- **Firefox:** Verify modal backdrop blur works

---

### Test Suite 5: Calculations

**Objective:** Verify analysis calculations work correctly

**Test Steps:**

1. **Power Calculation (Single Proportion)**
   - [ ] Enter n=230, event rate=100, alpha=0.05
   - [ ] Click "Calculate"
   - [ ] Results appear within 2 seconds
   - [ ] Power curve plot renders correctly
   - [ ] Results table shows values
   - [ ] No JavaScript errors in console

2. **Sample Size Calculation (Two-Group)**
   - [ ] Enter p1=0.15, p2=0.10, power=0.80, alpha=0.05
   - [ ] Click "Calculate"
   - [ ] Sample size result appears
   - [ ] Result is formatted correctly (e.g., "n=584 per group")

3. **All Analysis Types**
   - [ ] Test at least one calculation per analysis type:
     - Single Proportion (Power)
     - Single Proportion (Sample Size)
     - Two-Group (Power)
     - Two-Group (Sample Size)
     - Survival Analysis (Power)
     - Survival Analysis (Sample Size)
     - Matched Case-Control
     - Continuous Outcomes (Power)
     - Continuous Outcomes (Sample Size)
     - Non-Inferiority

**Expected Results:** All calculations execute without errors and produce valid results.

**Browser-Specific Notes:**
- **All browsers:** Check console for R/Shiny errors
- **Mobile browsers:** Verify plots render correctly at small sizes

---

### Test Suite 6: Responsive Layout

**Objective:** Verify layout adapts to different screen sizes

**Test Steps:**

1. **Desktop (≥1024px)**
   - [ ] Sidebar is 280px wide, always visible
   - [ ] Main content is centered with max-width 1200px
   - [ ] Cards have proper shadows and spacing
   - [ ] Footer is 40px height at bottom

2. **Tablet (640px - 1023px)**
   - [ ] Sidebar is 280px wide
   - [ ] Sidebar overlays content (not side-by-side)
   - [ ] Hamburger menu appears
   - [ ] Main content takes full width minus padding

3. **Mobile (< 640px)**
   - [ ] Sidebar is full-width overlay
   - [ ] Hamburger menu in header
   - [ ] Content cards have reduced padding
   - [ ] Quick preview footer hides CTA text
   - [ ] Buttons stack vertically or reduce padding

4. **Extra Small (< 375px)**
   - [ ] Content still readable
   - [ ] No horizontal scrolling
   - [ ] Touch targets remain ≥44px

**Test Viewports:**
- 2560x1440 (4K desktop)
- 1920x1080 (Full HD desktop)
- 1366x768 (Laptop)
- 1024x768 (Tablet landscape)
- 768x1024 (Tablet portrait)
- 414x896 (iPhone 11/12/13 Pro)
- 390x844 (iPhone 14)
- 375x667 (iPhone SE)
- 360x640 (Android small)
- 320x568 (iPhone 5/SE gen 1 - minimum)

**Expected Results:** Layout is usable and visually correct at all breakpoints.

**Browser-Specific Notes:**
- **Safari iOS:** Test on actual device for notch/safe areas
- **Chrome Android:** Test on actual device for navigation bar overlap

---

### Test Suite 7: Print Functionality

**Objective:** Verify print styles produce clean output

**Test Steps:**

1. **Print Preview**
   - [ ] Open Chrome print preview (Ctrl+P / Cmd+P)
   - [ ] Sidebar is hidden
   - [ ] Header is hidden
   - [ ] Footer is hidden
   - [ ] Mobile toggle button is hidden

2. **Content Layout**
   - [ ] All accordions are expanded
   - [ ] Content is readable in black on white
   - [ ] No colored backgrounds (ink efficiency)
   - [ ] Shadows are removed
   - [ ] Page breaks avoid orphan headings

3. **Typography**
   - [ ] Body text is 12pt
   - [ ] Headings are 18pt (H1), 16pt (H2), 14pt (H3)
   - [ ] Line spacing is comfortable (1.5)

4. **Charts & Images**
   - [ ] Plots/charts are visible
   - [ ] Charts don't break across pages (page-break-inside: avoid)

5. **Links**
   - [ ] External links show URLs in parentheses
   - [ ] Internal links don't show URLs

**Expected Results:** Printed output is clean, professional, and readable.

**Browser-Specific Notes:**
- **Safari:** May render differently than Chrome
- **Firefox:** Check page break behavior

---

### Test Suite 8: Performance

**Objective:** Verify app performs well across browsers

**Test Steps:**

1. **Page Load Time**
   - [ ] Hard refresh (Ctrl+Shift+R / Cmd+Shift+R)
   - [ ] Time to interactive < 3 seconds
   - [ ] No flash of unstyled content (FOUC)

2. **Network Tab (Chrome DevTools)**
   - [ ] Total CSS size < 100KB
   - [ ] Total JS size < 150KB
   - [ ] Number of requests < 30
   - [ ] All resources load successfully (no 404s)

3. **Animation Performance**
   - [ ] Sidebar open/close is smooth (60fps)
   - [ ] Accordion expand/collapse is smooth
   - [ ] Theme toggle transition is smooth
   - [ ] No janky scrolling

4. **Memory Usage**
   - [ ] Open DevTools > Performance Monitor
   - [ ] Navigate through all pages
   - [ ] Memory doesn't grow excessively (< 100MB)
   - [ ] No memory leaks

**Expected Results:** App feels fast and responsive.

**Browser-Specific Notes:**
- **Safari:** May use more memory than Chrome
- **Firefox:** Check for CSS rendering performance issues

---

### Test Suite 9: Accessibility (Keyboard & Screen Reader)

**Objective:** Verify keyboard navigation and screen reader compatibility

**Test Steps:**

1. **Keyboard Navigation**
   - [ ] Press Tab - focus moves to first interactive element
   - [ ] Tab through header, sidebar, main content
   - [ ] Focus indicators are visible (blue ring)
   - [ ] Enter activates buttons and links
   - [ ] Space toggles checkboxes and expands accordions
   - [ ] Arrow keys navigate radio buttons (segmented controls)
   - [ ] Shift+Tab moves focus backwards

2. **Skip Links**
   - [ ] Tab to first element - "Skip to main content" link appears
   - [ ] Press Enter - focus jumps to main content

3. **Screen Reader Testing (NVDA/JAWS/VoiceOver)**
   - [ ] Turn on screen reader
   - [ ] Navigate through page
   - [ ] Landmarks are announced (navigation, main, etc.)
   - [ ] Buttons have meaningful labels
   - [ ] Form inputs are associated with labels
   - [ ] Links describe destination
   - [ ] Images have alt text

4. **ARIA States**
   - [ ] Accordions announce expanded/collapsed state
   - [ ] Modal announces when opened
   - [ ] Live regions announce calculation results

**Expected Results:** App is fully navigable via keyboard and screen reader.

**Browser-Specific Notes:**
- **Windows:** Test with NVDA (free) or JAWS (paid)
- **macOS:** Test with VoiceOver (built-in, Cmd+F5)
- **iOS:** Test with VoiceOver (Settings > Accessibility)
- **Android:** Test with TalkBack

---

## Bug Reporting Template

When you find a bug, report it with this template:

```markdown
**Bug Title:** [Brief description]

**Browser:** [Chrome/Firefox/Safari/Edge] [Version]
**Operating System:** [Windows/macOS/Linux/iOS/Android] [Version]
**Device:** [Desktop/Laptop/Tablet/Phone] [Model if applicable]

**Steps to Reproduce:**
1. Navigate to [page]
2. Click [element]
3. Observe [issue]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Screenshots:**
[Attach screenshots or video]

**Console Errors:**
[Copy JavaScript console errors if any]

**Additional Context:**
[Screen size, zoom level, browser extensions, etc.]
```

---

## Testing Checklist Summary

### Desktop Browsers (High Priority)

**Chrome (Latest)**
- [ ] Navigation works
- [ ] Inputs render correctly
- [ ] Theme toggle works
- [ ] Calculations succeed
- [ ] Performance is good
- [ ] Print preview looks clean

**Firefox (Latest)**
- [ ] Navigation works
- [ ] Inputs render correctly
- [ ] Theme toggle works
- [ ] Calculations succeed
- [ ] Performance is good
- [ ] Print preview looks clean

**Safari (Latest, macOS)**
- [ ] Navigation works
- [ ] Inputs render correctly
- [ ] Theme toggle works
- [ ] Calculations succeed
- [ ] Performance is good
- [ ] Print preview looks clean

**Edge (Latest, Windows)**
- [ ] Navigation works
- [ ] Inputs render correctly
- [ ] Theme toggle works
- [ ] Calculations succeed

### Mobile Browsers (Medium Priority)

**Safari iOS (Latest)**
- [ ] Sidebar overlay works
- [ ] Touch targets ≥44px
- [ ] Inputs work (no zoom on focus)
- [ ] Calculations succeed
- [ ] Scrolling is smooth

**Chrome Android (Latest)**
- [ ] Sidebar overlay works
- [ ] Touch targets ≥44px
- [ ] Inputs work
- [ ] Calculations succeed
- [ ] Scrolling is smooth

---

## Automated Testing Recommendations

### Playwright/Cypress Tests

Consider adding automated tests for critical flows:

```javascript
// Example Playwright test
test('navigation works', async ({ page }) => {
  await page.goto('http://localhost:3838');

  // Click sidebar link
  await page.click('text=Single Proportion');
  await page.click('text=Power Analysis');

  // Verify page changed
  await expect(page.locator('h1')).toContainText('Single Proportion');
});
```

### Visual Regression Testing

Tools to consider:
- **Percy.io:** Visual regression testing
- **BackstopJS:** Screenshot comparison
- **Chromatic:** Component visual testing

---

## Compatibility Notes by Browser

### Chrome/Chromium-Based (Chrome, Edge, Brave, Opera)

**Strengths:**
- Best CSS custom property support
- Smooth animations and transitions
- Excellent DevTools
- Fastest JavaScript engine

**Known Issues:**
- None expected for modern features used

### Firefox

**Strengths:**
- Excellent CSS standards support
- Good accessibility tools
- Privacy-focused

**Known Issues:**
- Older versions (<100) may have backdrop-filter issues
- Slightly slower JavaScript than Chrome

### Safari

**Strengths:**
- Industry-standard on macOS/iOS
- Good standards support in recent versions

**Known Issues:**
- Older versions (<15) limited CSS variable support
- backdrop-filter requires -webkit- prefix
- iOS Safari has unique touch/scroll behavior
- Date input rendering differs from Chrome

### Mobile Browsers

**iOS Safari:**
- Fixed position elements can be tricky with safe areas
- Input zoom on focus (use `font-size: 16px` minimum to prevent)
- Touch scrolling momentum is different

**Android Chrome:**
- Generally similar to desktop Chrome
- Address bar hides on scroll (affects viewport height)
- Various OEM browsers (Samsung Internet) may differ

---

## Appendix: CSS Feature Support

### Critical Features Used

All features below are well-supported in target browsers:

| Feature | Chrome | Firefox | Safari | Edge |
|---------|--------|---------|--------|------|
| CSS Custom Properties | ✅ 49+ | ✅ 31+ | ✅ 9.1+ | ✅ 15+ |
| CSS Grid | ✅ 57+ | ✅ 52+ | ✅ 10.1+ | ✅ 16+ |
| Flexbox | ✅ 29+ | ✅ 28+ | ✅ 9+ | ✅ 11+ |
| CSS Transitions | ✅ 26+ | ✅ 16+ | ✅ 9+ | ✅ 12+ |
| backdrop-filter | ✅ 76+ | ✅ 103+ | ✅ 9+ (-webkit-) | ✅ 79+ |
| CSS :focus-visible | ✅ 86+ | ✅ 85+ | ✅ 15.4+ | ✅ 86+ |

### Progressive Enhancement

Features that degrade gracefully:
- `backdrop-filter`: Falls back to solid background
- `:focus-visible`: Falls back to `:focus`
- CSS animations: Fall back to instant state changes

---

## Resources

**Browser Testing:**
- [BrowserStack](https://www.browserstack.com/)
- [Can I Use](https://caniuse.com/)
- [MDN Browser Compatibility](https://developer.mozilla.org/en-US/docs/Web/CSS)

**Accessibility Testing:**
- [WAVE Browser Extension](https://wave.webaim.org/extension/)
- [axe DevTools](https://www.deque.com/axe/devtools/)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)

**Performance Testing:**
- [WebPageTest](https://www.webpagetest.org/)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/)

---

**Last Updated:** 2025-10-25
**Related Documents:**
- `docs/003-reference/004-cross-device-testing-checklist.md`
- `docs/004-explanation/002-ui-ux-modernization.md`
- `docs/reports/enhancements/ui-ux-modernization/003-ui-ux-modernization-progress.md`
