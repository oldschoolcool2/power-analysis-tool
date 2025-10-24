# UI/UX Modernization Plan
## Statistical Power Analysis Tool - Frontend Redesign

**Date:** October 24, 2025
**Status:** Implementation Plan
**Target:** Enterprise-grade pharmaceutical research tool

---

## Executive Summary

This plan transforms the current functional-but-dated interface into a modern, enterprise-grade application suitable for pharmaceutical and real-world evidence research. The redesign focuses on clarity, hierarchy, professional aesthetics, and improved information architecture.

### Key Objectives
- Move from default blue to sophisticated professional color palette
- Consolidate navigation from top tabs to hierarchical left sidebar
- Implement semantic design tokens for maintainable theming
- Modernize input components with better UX patterns
- Create clear visual hierarchy through typography and spacing
- Add professional header and enhance existing quick preview footer

---

## Phase 1: Design System & Semantic Variables

### 1.1 Color Palette - Professional & Accessible

**Current:** Single primary blue (#3498db), stark white backgrounds, pure black text
**New:** Sophisticated, layered color system with semantic meaning

#### Core Color Tokens

```css
/* Primary Colors - Deep Teal/Slate Professional Palette */
--color-primary-900: #0F2A3F;     /* Darkest - headers, primary text */
--color-primary-800: #1A3A52;     /* Dark - navigation background */
--color-primary-700: #2B5876;     /* Main primary - active states */
--color-primary-600: #4E7FA0;     /* Medium - buttons, links */
--color-primary-500: #6B9EC7;     /* Light - hover states */
--color-primary-400: #8FB5D9;     /* Lighter - borders */
--color-primary-300: #B3CDEB;     /* Very light - backgrounds */
--color-primary-200: #D6E7F7;     /* Subtle backgrounds */
--color-primary-100: #EBF4FC;     /* Whisper - section backgrounds */

/* Accent Color - Warm Amber/Orange for Warnings & CTAs */
--color-accent-700: #D97706;      /* Dark amber */
--color-accent-600: #F59E0B;      /* Main accent */
--color-accent-500: #FBBF24;      /* Light amber */
--color-accent-400: #FCD34D;      /* Very light */

/* Neutral Grays - Soft, Professional */
--color-neutral-900: #1D2A39;     /* Off-black for text */
--color-neutral-800: #2D3748;     /* Dark gray */
--color-neutral-700: #4A5568;     /* Medium gray */
--color-neutral-600: #718096;     /* Label gray */
--color-neutral-500: #A0AEC0;     /* Placeholder gray */
--color-neutral-400: #CBD5E0;     /* Border gray */
--color-neutral-300: #E2E8F0;     /* Light border */
--color-neutral-200: #EDF2F7;     /* Subtle background */
--color-neutral-100: #F7FAFC;     /* Whisper background */
--color-neutral-50: #F8F9FA;      /* Base background (NOT pure white) */
--color-white: #FFFFFF;           /* Card backgrounds */

/* Semantic Colors */
--color-success-600: #059669;     /* Green - success states */
--color-success-100: #D1FAE5;     /* Green background */
--color-warning-600: #D97706;     /* Orange - warnings */
--color-warning-100: #FEF3C7;     /* Orange background */
--color-error-600: #DC2626;       /* Red - errors */
--color-error-100: #FEE2E2;       /* Red background */
--color-info-600: #2563EB;        /* Blue - info */
--color-info-100: #DBEAFE;        /* Blue background */
```

#### Semantic Application Tokens

```css
/* Backgrounds */
--bg-app: var(--color-neutral-50);           /* Main app background */
--bg-card: var(--color-white);               /* Content cards/panels */
--bg-sidebar: var(--color-primary-800);      /* Navigation sidebar */
--bg-header: var(--color-white);             /* App header */
--bg-footer: var(--color-primary-100);       /* Quick preview footer */
--bg-input: var(--color-white);              /* Input fields */
--bg-input-disabled: var(--color-neutral-100);

/* Text Colors */
--text-primary: var(--color-neutral-900);    /* Main body text */
--text-secondary: var(--color-neutral-700);  /* Secondary text */
--text-tertiary: var(--color-neutral-600);   /* Labels, captions */
--text-placeholder: var(--color-neutral-500);
--text-inverse: var(--color-white);          /* On dark backgrounds */
--text-link: var(--color-primary-600);
--text-link-hover: var(--color-primary-700);

/* Borders */
--border-subtle: 1px solid var(--color-neutral-200);
--border-default: 1px solid var(--color-neutral-300);
--border-strong: 1px solid var(--color-neutral-400);
--border-radius-sm: 4px;
--border-radius-md: 6px;
--border-radius-lg: 8px;
--border-radius-xl: 12px;

/* Shadows - Subtle Depth */
--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);

/* Spacing System (8px base) */
--space-1: 0.25rem;  /* 4px */
--space-2: 0.5rem;   /* 8px */
--space-3: 0.75rem;  /* 12px */
--space-4: 1rem;     /* 16px */
--space-5: 1.25rem;  /* 20px */
--space-6: 1.5rem;   /* 24px */
--space-8: 2rem;     /* 32px */
--space-10: 2.5rem;  /* 40px */
--space-12: 3rem;    /* 48px */
--space-16: 4rem;    /* 64px */
```

### 1.2 Typography System

**Current:** Open Sans (body), Montserrat (headings)
**New:** Inter (unified, professional, excellent readability)

#### Font Tokens

```css
/* Font Families */
--font-family-base: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--font-family-mono: 'JetBrains Mono', 'Fira Code', 'Courier New', monospace;

/* Font Sizes - Type Scale */
--font-size-xs: 0.75rem;    /* 12px */
--font-size-sm: 0.875rem;   /* 14px */
--font-size-base: 1rem;     /* 16px */
--font-size-lg: 1.125rem;   /* 18px */
--font-size-xl: 1.25rem;    /* 20px */
--font-size-2xl: 1.5rem;    /* 24px */
--font-size-3xl: 1.875rem;  /* 30px */
--font-size-4xl: 2.25rem;   /* 36px */

/* Font Weights */
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;

/* Line Heights */
--line-height-tight: 1.25;
--line-height-normal: 1.5;
--line-height-relaxed: 1.75;

/* Letter Spacing */
--letter-spacing-tight: -0.01em;
--letter-spacing-normal: 0;
--letter-spacing-wide: 0.025em;

/* Text Styles - Semantic Typography */
--text-display: var(--font-weight-bold) var(--font-size-3xl)/var(--line-height-tight);
--text-h1: var(--font-weight-semibold) var(--font-size-2xl)/var(--line-height-tight);
--text-h2: var(--font-weight-semibold) var(--font-size-xl)/var(--line-height-tight);
--text-h3: var(--font-weight-semibold) var(--font-size-lg)/var(--line-height-normal);
--text-body: var(--font-weight-normal) var(--font-size-base)/var(--line-height-normal);
--text-body-sm: var(--font-weight-normal) var(--font-size-sm)/var(--line-height-normal);
--text-caption: var(--font-weight-normal) var(--font-size-xs)/var(--line-height-normal);
--text-label: var(--font-weight-medium) var(--font-size-sm)/var(--line-height-normal);
```

#### Typography Implementation

- **Display/Hero Text:** App title, major section headers
- **H1:** Page titles (e.g., "Single Proportion Analysis")
- **H2:** Section headers (e.g., "Input Parameters")
- **H3:** Subsection headers (e.g., accordion items)
- **Body:** Main content, explanations
- **Body Small:** Secondary content, helper text
- **Caption:** Footnotes, disclaimers
- **Label:** Form labels, input labels

---

## Phase 2: Navigation Redesign - Hierarchical Sidebar

### 2.1 Current State Issues

- **Top horizontal tabs** compete with page header
- Navigation and content are not clearly separated
- Difficult to show nested relationships (e.g., Power vs. Sample Size for each analysis type)
- Poor scalability for adding new analysis types

### 2.2 New Navigation Architecture

**Single Source of Truth:** Left sidebar navigation with hierarchical menu

#### Navigation Structure

```
SIDEBAR (280px width, collapsible to 64px on mobile)
├── Header
│   └── App Logo/Title
├── Main Navigation
│   ├── Single Proportion
│   │   ├── Power Analysis
│   │   └── Sample Size (Rule of Three)
│   ├── Two-Group Comparisons
│   │   ├── Power Analysis
│   │   └── Sample Size Calculation
│   ├── Survival Analysis (Cox)
│   │   ├── Power Analysis
│   │   └── Sample Size Calculation
│   ├── Matched Case-Control
│   │   └── Analysis
│   ├── Continuous Outcomes
│   │   ├── Power Analysis (t-tests)
│   │   └── Sample Size Calculation
│   └── Non-Inferiority Testing
│       └── Generic/Biosimilar Analysis
├── Utilities Section
│   ├── Scenario Manager
│   └── Help & Documentation
└── Footer
    └── Version info
```

#### Sidebar Visual Design

**Collapsed State (Mobile/Tablet):**
- 64px width
- Icons only
- Hover to expand

**Expanded State (Desktop):**
- 280px width
- Icons + labels
- Nested indentation for hierarchy
- Active state highlighting
- Smooth transitions

**Styling:**
- Background: `var(--bg-sidebar)` (dark teal)
- Text: `var(--text-inverse)` (white)
- Active item: Lighter background + accent border-left
- Hover: Subtle background lightening
- Dividers: Semi-transparent white

### 2.3 Implementation Approach

**Shiny Implementation:**
- Replace top `tabsetPanel()` with custom sidebar HTML
- Use `shinydashboard::sidebarMenu()` or custom `tags$div()` structure
- Add collapsible menu with JS (Bootstrap collapse or custom)
- Store active selection in reactive value
- Render appropriate content panel based on selection

---

## Phase 3: Layout Simplification - 1+1 Column Design

### 3.1 New Page Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ HEADER (60px height, white bg, shadow)                         │
│ [Logo] Statistical Power Analysis Tool         [User] [?]      │
└─────────────────────────────────────────────────────────────────┘
┌────────────┬────────────────────────────────────────────────────┐
│            │                                                    │
│ SIDEBAR    │ MAIN CONTENT AREA                                 │
│ (280px)    │ (fluid, max-width 1200px, centered)               │
│            │                                                    │
│ Navigation │ ┌──────────────────────────────────────────────┐  │
│  • Single  │ │ PAGE TITLE                                   │  │
│    - Power │ │ Single Proportion: Sample Size (Rule of 3)  │  │
│    - SS    │ └──────────────────────────────────────────────┘  │
│  • Two-Grp │                                                    │
│    - Power │ ┌──────────────────────────────────────────────┐  │
│    - SS    │ │ INPUT CARD                                   │  │
│  • Surviv  │ │ Clean white card with shadow                 │  │
│    - Power │ │                                              │  │
│    - SS    │ │ [Input Fields]                               │  │
│  ...       │ │ [Sliders → Segmented Controls]               │  │
│            │ │                                              │  │
│            │ │ [Calculate] [Load Example] [Reset]           │  │
│            │ └──────────────────────────────────────────────┘  │
│            │                                                    │
│            │ ┌──────────────────────────────────────────────┐  │
│            │ │ RESULTS CARD (appears after calculation)     │  │
│            │ │                                              │  │
│            │ │ • Summary text                               │  │
│            │ │ • Power curve plot                           │  │
│            │ │ • Results table                              │  │
│            │ │ • Export buttons                             │  │
│            │ └──────────────────────────────────────────────┘  │
│            │                                                    │
│            │ ┌──────────────────────────────────────────────┐  │
│            │ │ HELP & METHODOLOGY (accordion)               │  │
│            │ │                                              │  │
│            │ │ ▼ About this Analysis                        │  │
│            │ │   [Expanded content]                         │  │
│            │ │ ▶ Use Cases                                  │  │
│            │ │ ▶ References                                 │  │
│            │ └──────────────────────────────────────────────┘  │
│            │                                                    │
└────────────┴────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│ QUICK PREVIEW FOOTER (40px, docked, subtle bg)                 │
│ ℹ Preview: Testing n=230 participants for event rate 1 in 100  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Card-Based Content Design

**All content sections become distinct cards:**

```css
.content-card {
  background: var(--bg-card);
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow-md);
  padding: var(--space-6);
  margin-bottom: var(--space-6);
}

.content-card-title {
  font: var(--text-h2);
  color: var(--text-primary);
  margin-bottom: var(--space-4);
  padding-bottom: var(--space-3);
  border-bottom: var(--border-subtle);
}
```

---

## Phase 4: Input Component Modernization

### 4.1 Numeric Input Fields

**Current:** Basic Shiny `numericInput()`
**New:** Modern styled inputs with better visual hierarchy

#### Design Specifications

```css
.modern-numeric-input {
  /* Label above field, not beside */
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.modern-numeric-input label {
  font: var(--text-label);
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.modern-numeric-input input {
  font: var(--text-body);
  color: var(--text-primary);
  background: var(--bg-input);
  border: var(--border-default);
  border-radius: var(--border-radius-md);
  padding: var(--space-3) var(--space-4);
  transition: all 0.2s ease;
}

.modern-numeric-input input:focus {
  outline: none;
  border-color: var(--color-primary-600);
  box-shadow: 0 0 0 3px var(--color-primary-100);
}

.modern-numeric-input input:disabled {
  background: var(--bg-input-disabled);
  color: var(--text-tertiary);
  cursor: not-allowed;
}
```

**Features:**
- Labels above inputs (not beside) for better readability
- Clear focus states with primary color
- Tooltips positioned to the right
- Proper spacing and visual weight

### 4.2 Significance Level - Segmented Control

**Current:** Slider (imprecise, requires fine motor control)
**New:** Button group / segmented control (precise, common values)

#### Design

```
┌─────────────────────────────────────────────────────┐
│ Significance Level (α)                         [?]  │
│                                                     │
│ ┌────┬────┬─────┬─────┐                            │
│ │0.01│0.02│0.05*│0.10 │  * = selected              │
│ └────┴────┴─────┴─────┘                            │
└─────────────────────────────────────────────────────┘
```

#### CSS Implementation

```css
.segmented-control {
  display: inline-flex;
  background: var(--color-neutral-100);
  border-radius: var(--border-radius-md);
  padding: var(--space-1);
  gap: var(--space-1);
}

.segmented-control-button {
  padding: var(--space-2) var(--space-4);
  font: var(--text-body-sm);
  font-weight: var(--font-weight-medium);
  color: var(--text-secondary);
  background: transparent;
  border: none;
  border-radius: var(--border-radius-sm);
  cursor: pointer;
  transition: all 0.2s ease;
}

.segmented-control-button:hover {
  background: var(--color-neutral-200);
  color: var(--text-primary);
}

.segmented-control-button.active {
  background: var(--color-white);
  color: var(--color-primary-700);
  font-weight: var(--font-weight-semibold);
  box-shadow: var(--shadow-sm);
}
```

#### Shiny Implementation

Replace `sliderInput("power_alpha", ...)` with:

```r
radioButtons(
  "power_alpha",
  "Significance Level (α):",
  choices = c("0.01" = 0.01, "0.025" = 0.025, "0.05" = 0.05, "0.10" = 0.10),
  selected = 0.05,
  inline = TRUE
)
# Add custom CSS class via tags$div(class = "segmented-control", ...)
```

**Benefits:**
- Precise selection (no slider imprecision)
- Faster interaction (single click)
- Common statistical values readily available
- Clearer visual feedback

### 4.3 Slider Improvements (for continuous values)

**For sliders that remain (e.g., Withdrawal Rate %):**

```css
/* Modern range slider */
.modern-slider {
  width: 100%;
  height: 8px;
  border-radius: 4px;
  background: linear-gradient(to right,
    var(--color-primary-600) 0%,
    var(--color-primary-600) var(--slider-percentage),
    var(--color-neutral-200) var(--slider-percentage),
    var(--color-neutral-200) 100%);
  appearance: none;
}

.modern-slider::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--color-white);
  border: 3px solid var(--color-primary-600);
  cursor: pointer;
  box-shadow: var(--shadow-md);
}

.modern-slider::-webkit-slider-thumb:hover {
  transform: scale(1.1);
  box-shadow: var(--shadow-lg);
}
```

**Features:**
- Large value display above slider
- Filled track showing current value
- Prominent, easy-to-grab thumb
- Smooth animations

### 4.4 Button Hierarchy

**Current:** Mix of primary buttons and colored buttons
**New:** Clear visual hierarchy

#### Primary Button (Calculate)

```css
.btn-calculate {
  font: var(--text-body);
  font-weight: var(--font-weight-semibold);
  color: var(--text-inverse);
  background: var(--color-primary-600);
  border: none;
  border-radius: var(--border-radius-md);
  padding: var(--space-4) var(--space-8);
  box-shadow: var(--shadow-md);
  cursor: pointer;
  transition: all 0.2s ease;
  width: 100%;  /* Full width in form */
}

.btn-calculate:hover {
  background: var(--color-primary-700);
  box-shadow: var(--shadow-lg);
  transform: translateY(-1px);
}

.btn-calculate:active {
  transform: translateY(0);
  box-shadow: var(--shadow-sm);
}
```

#### Secondary Buttons (Load Example, Reset)

```css
.btn-secondary {
  font: var(--text-body-sm);
  font-weight: var(--font-weight-medium);
  color: var(--color-primary-700);
  background: transparent;
  border: var(--border-default);
  border-radius: var(--border-radius-md);
  padding: var(--space-2) var(--space-4);
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-secondary:hover {
  background: var(--color-primary-50);
  border-color: var(--color-primary-600);
}
```

**Button Layout:**
```
┌────────────────────────────────────┐
│                                    │
│         [Calculate]                │  ← Full width, primary
│                                    │
└────────────────────────────────────┘
┌─────────────────┬──────────────────┐
│ [Load Example]  │  [Reset]         │  ← Half width each, secondary
└─────────────────┴──────────────────┘
```

---

## Phase 5: Content Presentation - Clean Accordions

### 5.1 Current Accordion Issues

- Heavy solid blue headers feel dated
- Difficult to distinguish collapsed vs. expanded
- Accordion items blend together visually

### 5.2 Modern Accordion Design

```css
.modern-accordion {
  background: var(--bg-card);
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow-md);
  overflow: hidden;
}

.modern-accordion-item {
  border-bottom: var(--border-subtle);
}

.modern-accordion-item:last-child {
  border-bottom: none;
}

.modern-accordion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-4) var(--space-6);
  background: transparent;
  border: none;
  width: 100%;
  cursor: pointer;
  transition: background 0.2s ease;
}

.modern-accordion-header:hover {
  background: var(--color-neutral-50);
}

.modern-accordion-title {
  font: var(--text-h3);
  color: var(--text-primary);
  text-align: left;
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.modern-accordion-icon {
  font-size: var(--font-size-lg);
  color: var(--color-primary-600);
  transition: transform 0.3s ease;
}

.modern-accordion-header[aria-expanded="true"] .modern-accordion-icon {
  transform: rotate(90deg);  /* Right arrow (▶) rotates to down arrow */
}

.modern-accordion-content {
  padding: 0 var(--space-6) var(--space-6) var(--space-6);
  font: var(--text-body);
  color: var(--text-primary);
  line-height: var(--line-height-relaxed);
}

.modern-accordion-content p {
  margin-bottom: var(--space-4);
}

.modern-accordion-content strong {
  font-weight: var(--font-weight-semibold);
  color: var(--text-primary);
}

.modern-accordion-content a {
  color: var(--text-link);
  text-decoration: underline;
  text-decoration-color: var(--color-primary-300);
  text-underline-offset: 2px;
  transition: all 0.2s ease;
}

.modern-accordion-content a:hover {
  color: var(--text-link-hover);
  text-decoration-color: var(--color-primary-600);
}
```

**Visual Example:**

```
┌────────────────────────────────────────────────────────┐
│ ▶  Single Proportion Analysis (Rule of Three)         │  ← Collapsed
├────────────────────────────────────────────────────────┤
│ ▼  Two-Group Comparisons                              │  ← Expanded
│                                                        │
│    The two-group comparison analysis allows you to    │
│    compare binary outcomes between two independent    │
│    groups (e.g., treatment vs. control).              │
│                                                        │
│    Example: Testing whether a new drug reduces...     │
│                                                        │
│    [Learn more in FDA guidance]                       │
│                                                        │
├────────────────────────────────────────────────────────┤
│ ▶  Survival Analysis (Cox Regression)                 │  ← Collapsed
└────────────────────────────────────────────────────────┘
```

---

## Phase 6: Header & Footer Enhancement

### 6.1 Professional Application Header

**Current:** No distinct header (title merged with content)
**New:** Clean, professional header bar

#### Design

```
┌─────────────────────────────────────────────────────────────────┐
│  ⚡ Statistical Power Analysis Tool    [Scenarios] [Help] [⋮]  │
│                                       for Real-World Evidence   │
└─────────────────────────────────────────────────────────────────┘
```

#### CSS Implementation

```css
.app-header {
  height: 60px;
  background: var(--bg-header);
  border-bottom: var(--border-subtle);
  box-shadow: var(--shadow-sm);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--space-6);
  position: sticky;
  top: 0;
  z-index: 100;
}

.app-header-brand {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.app-header-logo {
  font-size: var(--font-size-2xl);
  color: var(--color-primary-600);
}

.app-header-title {
  display: flex;
  flex-direction: column;
}

.app-header-title-main {
  font: var(--text-h2);
  color: var(--text-primary);
  line-height: 1;
}

.app-header-title-sub {
  font: var(--text-caption);
  color: var(--text-tertiary);
  line-height: 1;
}

.app-header-actions {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.app-header-action-btn {
  padding: var(--space-2) var(--space-4);
  font: var(--text-body-sm);
  font-weight: var(--font-weight-medium);
  color: var(--color-primary-700);
  background: transparent;
  border: var(--border-default);
  border-radius: var(--border-radius-md);
  cursor: pointer;
  transition: all 0.2s ease;
}

.app-header-action-btn:hover {
  background: var(--color-primary-50);
  border-color: var(--color-primary-600);
}
```

**Features:**
- Sticky position (always visible)
- App logo/icon (⚡ or custom icon)
- Clear title + subtitle
- Quick access to Scenarios and Help
- Optional user menu (future: login, settings)

### 6.2 Enhanced Quick Preview Footer

**Current:** Blue background footer with preview text
**New:** Subtle, always-visible docked footer

#### Design

```css
.quick-preview-footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 40px;
  background: var(--bg-footer);  /* Light primary color */
  border-top: var(--border-subtle);
  box-shadow: 0 -2px 4px rgba(0, 0, 0, 0.05);
  display: flex;
  align-items: center;
  padding: 0 var(--space-6);
  z-index: 90;
  transition: all 0.3s ease;
}

.quick-preview-content {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  font: var(--text-body-sm);
  color: var(--text-secondary);
}

.quick-preview-icon {
  color: var(--color-info-600);
  font-size: var(--font-size-lg);
}

.quick-preview-text {
  font: var(--text-body-sm);
  color: var(--text-primary);
}

.quick-preview-cta {
  font: var(--text-caption);
  color: var(--text-tertiary);
  font-style: italic;
  margin-left: var(--space-2);
}
```

**Features:**
- Fixed position at bottom
- Subtle background (not distracting)
- Icon for visual interest
- Real-time updates as inputs change
- Clear CTA: "(Click Calculate to run full analysis)"

---

## Phase 7: Responsive Design & Accessibility

### 7.1 Responsive Breakpoints

```css
/* Mobile-first approach */

/* Small devices (phones, < 640px) */
@media (max-width: 639px) {
  .sidebar {
    width: 100%;
    height: auto;
    position: static;
  }

  .main-content {
    margin-left: 0;
    padding: var(--space-4);
  }

  .content-card {
    padding: var(--space-4);
  }

  .btn-calculate {
    font-size: var(--font-size-sm);
    padding: var(--space-3) var(--space-6);
  }
}

/* Medium devices (tablets, 640px - 1023px) */
@media (min-width: 640px) and (max-width: 1023px) {
  .sidebar {
    width: 64px;  /* Collapsed with icons only */
  }

  .sidebar:hover {
    width: 280px;  /* Expand on hover */
  }

  .main-content {
    margin-left: 64px;
  }
}

/* Large devices (desktops, ≥ 1024px) */
@media (min-width: 1024px) {
  .sidebar {
    width: 280px;  /* Full sidebar */
  }

  .main-content {
    margin-left: 280px;
    max-width: 1200px;
    margin-right: auto;
  }
}
```

### 7.2 Accessibility Features

**Keyboard Navigation:**
- All interactive elements must be keyboard-accessible
- Clear focus indicators (primary color ring)
- Logical tab order
- Skip navigation link

**Screen Reader Support:**
- Semantic HTML5 elements (`<nav>`, `<main>`, `<aside>`, `<article>`)
- ARIA labels for icon-only buttons
- ARIA expanded/collapsed states for accordions
- ARIA live regions for dynamic content (results, quick preview)

**Color Contrast:**
- All text meets WCAG AA standards (4.5:1 for body, 3:1 for large text)
- Color is not the only means of conveying information
- Focus indicators visible on all backgrounds

**Tooltips & Help:**
- Maintain existing comprehensive tooltip system
- Add keyboard-accessible tooltip triggers
- Ensure tooltips don't obscure critical content

---

## Phase 8: Implementation Roadmap

### Step 1: Create CSS Custom Properties File (2 hours)
**File:** `www/css/design-tokens.css`
- Define all semantic variables
- Create comprehensive comment documentation
- Set up fallback values

### Step 2: Create Main Custom Stylesheet (3 hours)
**File:** `www/css/modern-theme.css`
- Import design tokens
- Define component styles (buttons, inputs, cards, accordions)
- Responsive media queries
- Print styles

### Step 3: Update app.R Theme Configuration (1 hour)
- Link new CSS files in `ui` section
- Update `bs_theme()` to use semantic variables
- Test Bootstrap compatibility

### Step 4: Refactor Navigation to Sidebar (4 hours)
- Create hierarchical navigation structure
- Replace `tabsetPanel()` with custom sidebar
- Implement collapse/expand functionality
- Add active state management

### Step 5: Modernize Input Components (3 hours)
- Replace sliders with segmented controls (significance level)
- Restyle numeric inputs
- Update button hierarchy
- Add proper spacing and labels

### Step 6: Implement Card-Based Layout (2 hours)
- Wrap input sections in `.content-card`
- Wrap results sections in `.content-card`
- Add proper spacing and shadows

### Step 7: Redesign Accordions (2 hours)
- Update accordion HTML structure
- Apply modern accordion CSS
- Add smooth transitions
- Test expand/collapse behavior

### Step 8: Add Header and Enhance Footer (2 hours)
- Create sticky app header
- Add app logo/title
- Update quick preview footer styling
- Test responsiveness

### Step 9: Test & Refine (3 hours)
- Cross-browser testing (Chrome, Firefox, Safari, Edge)
- Responsive testing (mobile, tablet, desktop)
- Accessibility audit (keyboard nav, screen reader)
- Performance optimization

### Step 10: Documentation (1 hour)
- Document semantic variable usage
- Create component style guide
- Add inline comments to CSS
- Update README with theme info

**Total Estimated Time:** 23 hours

---

## Success Metrics

### Visual Quality
- ✅ Modern, professional appearance suitable for enterprise pharma
- ✅ Clear visual hierarchy (primary/secondary/tertiary content)
- ✅ Consistent spacing and alignment
- ✅ Subtle depth with shadows and layers

### Usability
- ✅ Intuitive navigation with clear information architecture
- ✅ Faster input selection (segmented controls vs. sliders)
- ✅ Reduced cognitive load (single-column content)
- ✅ Persistent quick preview for constant feedback

### Accessibility
- ✅ WCAG AA compliance for color contrast
- ✅ Full keyboard navigation support
- ✅ Screen reader compatibility
- ✅ Responsive across all device sizes

### Maintainability
- ✅ Semantic design tokens for easy theme updates
- ✅ Consistent component styling
- ✅ Well-documented CSS with comments
- ✅ Modular structure for future enhancements

---

## Future Enhancements (Phase 9+)

1. **Dark Mode Support**
   - Duplicate semantic variables with dark theme values
   - Add theme toggle in header
   - Store preference in browser localStorage

2. **Advanced Data Visualization**
   - Replace base R plots with interactive plotly charts
   - Add power surface plots (3D visualizations)
   - Interactive scenario comparison charts

3. **User Accounts & Saved Projects**
   - Login system
   - Cloud storage for scenarios
   - Project sharing and collaboration

4. **Export Enhancements**
   - Branded PDF reports with company logo
   - PowerPoint export for presentations
   - Word document generation for regulatory submissions

5. **Guided Tours & Onboarding**
   - Interactive tutorial for new users
   - Contextual tips and best practices
   - Video walkthroughs embedded in help sections

6. **API Integration**
   - RESTful API for programmatic access
   - Python/R package for direct integration
   - Batch analysis capabilities

---

## Appendix A: File Structure

```
power-analysis-tool/
├── app.R
├── www/
│   ├── css/
│   │   ├── design-tokens.css       ← NEW: Semantic variables
│   │   ├── modern-theme.css        ← NEW: Component styles
│   │   └── responsive.css          ← NEW: Media queries
│   ├── js/
│   │   ├── sidebar-toggle.js       ← NEW: Navigation behavior
│   │   └── segmented-control.js    ← NEW: Custom input component
│   └── images/
│       └── logo.svg                ← NEW: App logo
├── docs/
│   └── ideas/
│       ├── UI_UX_MODERNIZATION_PLAN.md  ← This document
│       └── COMPONENT_STYLE_GUIDE.md     ← Future: Visual reference
└── README.md
```

---

## Appendix B: Component Examples

### Example 1: Modern Numeric Input HTML

```html
<div class="modern-numeric-input">
  <label for="sample-size">
    Available Sample Size
    <span class="tooltip-trigger" data-bs-toggle="tooltip" title="Total participants">
      <i class="fa fa-question-circle"></i>
    </span>
  </label>
  <input
    type="number"
    id="sample-size"
    name="sample-size"
    value="230"
    min="1"
    step="1"
    class="form-control"
  />
</div>
```

### Example 2: Segmented Control HTML

```html
<div class="input-group">
  <label>Significance Level (α)</label>
  <div class="segmented-control" role="radiogroup" aria-label="Significance level">
    <button
      type="button"
      role="radio"
      aria-checked="false"
      data-value="0.01"
      class="segmented-control-button"
    >
      0.01
    </button>
    <button
      type="button"
      role="radio"
      aria-checked="false"
      data-value="0.025"
      class="segmented-control-button"
    >
      0.025
    </button>
    <button
      type="button"
      role="radio"
      aria-checked="true"
      data-value="0.05"
      class="segmented-control-button active"
    >
      0.05
    </button>
    <button
      type="button"
      role="radio"
      aria-checked="false"
      data-value="0.10"
      class="segmented-control-button"
    >
      0.10
    </button>
  </div>
</div>
```

### Example 3: Modern Accordion HTML

```html
<div class="modern-accordion">
  <div class="modern-accordion-item">
    <button
      class="modern-accordion-header"
      aria-expanded="false"
      aria-controls="accordion-panel-1"
    >
      <div class="modern-accordion-title">
        <span class="modern-accordion-icon">▶</span>
        Single Proportion Analysis (Rule of Three)
      </div>
    </button>
    <div
      id="accordion-panel-1"
      class="modern-accordion-content"
      role="region"
      hidden
    >
      <p>The 'Rule of Three' states that if a certain event did not occur in a sample with n participants...</p>
    </div>
  </div>
</div>
```

---

## Appendix C: Color Palette Visual Reference

```
PRIMARY PALETTE (Teal/Slate):
█ #0F2A3F  900 - Darkest
█ #1A3A52  800 - Dark
█ #2B5876  700 - Main
█ #4E7FA0  600 - Medium
█ #6B9EC7  500 - Light
█ #8FB5D9  400 - Lighter
█ #B3CDEB  300 - Very Light
█ #D6E7F7  200 - Subtle
█ #EBF4FC  100 - Whisper

ACCENT PALETTE (Amber):
█ #D97706  700 - Dark
█ #F59E0B  600 - Main
█ #FBBF24  500 - Light
█ #FCD34D  400 - Very Light

NEUTRAL PALETTE (Grays):
█ #1D2A39  900 - Off-black
█ #2D3748  800 - Dark Gray
█ #4A5568  700 - Medium Gray
█ #718096  600 - Label Gray
█ #A0AEC0  500 - Placeholder
█ #CBD5E0  400 - Border
█ #E2E8F0  300 - Light Border
█ #EDF2F7  200 - Subtle BG
█ #F7FAFC  100 - Whisper BG
█ #F8F9FA  50  - Base BG
█ #FFFFFF  White - Cards
```

---

**End of Plan**

*This document represents a comprehensive roadmap for transforming the Statistical Power Analysis Tool into a modern, enterprise-grade application. Implementation should follow the phased approach, with regular user testing and feedback incorporated throughout the process.*
