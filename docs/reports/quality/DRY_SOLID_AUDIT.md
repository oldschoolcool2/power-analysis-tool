# DRY/SOLID Audit Report

## Executive Summary

**Status**: ⚠️ **SIGNIFICANT VIOLATIONS FOUND**

- **DRY Violations**: 8 major issues (420+ lines of repetitive code)
- **SOLID Violations**: 3 major issues
- **Recommended Refactoring**: High priority (will reduce codebase by ~300 lines)

---

## DRY (Don't Repeat Yourself) Violations

### 🔴 CRITICAL: Repetitive Example/Reset Button Handlers (Lines 504-687)

**Issue**: 20 observeEvent handlers with identical structure
**Lines of Code**: 183 lines (12% of entire codebase!)
**Violation Severity**: CRITICAL

```r
# Current approach (repeated 20 times):
observeEvent(input$example_power_single, {
    updateNumericInput(session, "power_n", value = 1500)
    updateNumericInput(session, "power_p", value = 500)
    updateSliderInput(session, "power_discon", value = 15)
    showNotification("Example loaded: ...", type = "message", duration = 3)
})
```

**Solution**: Create data-driven approach with configuration list

```r
# Proposed refactored approach:
example_configs <- list(
  power_single = list(
    power_n = 1500,
    power_p = 500,
    power_discon = 15,
    power_alpha = 0.05,
    message = "Rare adverse event study with 1,500 participants"
  ),
  # ... other configs
)

# Single handler using lapply
lapply(names(example_configs), function(tab_name) {
  observeEvent(input[[paste0("example_", tab_name)]], {
    config <- example_configs[[tab_name]]
    # Dynamic update based on config
  })
})
```

**Impact**: Reduces 183 lines → ~50 lines (73% reduction)

---

### 🟡 MEDIUM: Repetitive Validation Logic (Lines 690-760)

**Issue**: validate_inputs() function has 10 if/else blocks with similar validation patterns
**Lines of Code**: 70 lines
**Violation Severity**: MEDIUM

```r
# Current approach (repeated pattern):
if (input$tabset == "Power (Single)") {
    validate(
        need(input$power_n > 0, "Sample size must be positive"),
        need(input$power_p > 0, "Event frequency must be positive"),
        need(input$power_discon >= 0 && input$power_discon <= 100, "...")
    )
}
# ... repeated for 9 more tabs
```

**Solution**: Validation rule configuration

```r
validation_rules <- list(
  "Power (Single)" = list(
    list(expr = quote(input$power_n > 0), msg = "Sample size must be positive"),
    list(expr = quote(input$power_p > 0), msg = "Event frequency must be positive")
  )
)

validate_inputs <- function() {
  rules <- validation_rules[[input$tabset]]
  if (!is.null(rules)) {
    lapply(rules, function(rule) {
      validate(need(eval(rule$expr), rule$msg))
    })
  }
}
```

**Impact**: Reduces 70 lines → ~30 lines (57% reduction)

---

### 🟡 MEDIUM: Repetitive CSV Export Logic (Lines 1330-1540)

**Issue**: Download handler has 10 if/else blocks constructing similar data frames
**Lines of Code**: 210 lines
**Violation Severity**: MEDIUM

**Current Pattern**:
```r
if (input$tabset == "Power (Single)") {
    results <- data.frame(
        Analysis_Type = "Single Proportion - Power Calculation",
        Sample_Size = input$power_n,
        # ... 15 more fields
    )
} else if (input$tabset == "Sample Size (Single)") {
    results <- data.frame(
        Analysis_Type = "Single Proportion - Sample Size Calculation",
        # ... similar fields
    )
}
# ... repeated 8 more times
```

**Solution**: Factory function for result data frames

```r
create_result_dataframe <- function(tab_type) {
  base_fields <- list(
    Analysis_Type = get_analysis_type(tab_type),
    Date = Sys.Date()
  )

  tab_specific_fields <- get_tab_fields(tab_type, input)

  do.call(data.frame, c(base_fields, tab_specific_fields))
}
```

**Impact**: Reduces 210 lines → ~80 lines (62% reduction)

---

### 🟢 LOW: Repeated req() Validation Pattern (Line 840-845)

**Issue**: Partial adoption of req() pattern alongside validate()
**Lines of Code**: 6 lines (but sets bad precedent)
**Violation Severity**: LOW

**Note**: This was added in recent improvements but creates duplication with existing validate_inputs().

**Solution**: Choose ONE validation approach (either req() OR validate(), not both)

---

## SOLID Violations

### 🔴 CRITICAL: Single Responsibility Principle (SRP)

**Issue**: The server function does EVERYTHING (Lines 435-1520)

**Current Responsibilities**:
1. Input handling (example/reset buttons)
2. Validation
3. Power analysis calculations
4. Plot generation
5. Table rendering
6. CSV generation
7. PDF generation
8. Scenario management
9. State management

**Violation**: A single function should have ONE reason to change. This has 9+ reasons.

**Solution**: Extract responsibilities into focused functions

```r
# Proposed structure:
server <- function(input, output, session) {
  # State management
  v <- init_reactive_values()

  # Delegate to specialized modules
  handle_button_interactions(input, output, session, v)
  handle_validation(input)
  handle_calculations(input, output, v)
  handle_exports(input, output, v)
  handle_scenarios(input, output, session, v)
}
```

---

### 🟡 MEDIUM: Open/Closed Principle (OCP)

**Issue**: Adding a new analysis type requires modifying ~15 different locations

**Locations that need modification**:
1. UI tab definition
2. Example button handler
3. Reset button handler
4. Validation rules
5. Result text rendering
6. Effect measures rendering
7. Plot rendering
8. Table rendering
9. CSV export logic
10. Scenario comparison

**Violation**: Should be open for extension, closed for modification

**Solution**: Plugin/registry architecture

```r
# Define analysis type as a configuration object
analysis_types <- list(
  power_single = AnalysisType$new(
    ui = power_single_ui,
    validation = power_single_validation,
    calculation = power_single_calc,
    export = power_single_export
  )
)

# Adding new type = adding new config, no modification to core logic
```

---

### 🟢 LOW: Dependency Inversion Principle (DIP)

**Issue**: Hard dependencies on specific package functions throughout code

**Example**:
```r
power <- pwr.p.test(sig.level=input$power_alpha, ...)$power
```

**Better**:
```r
# Wrapper functions for testability
calculate_single_proportion_power <- function(n, p, alpha) {
  pwr.p.test(sig.level=alpha, h = ES.h(p, 0), alt="greater", n = n)$power
}

# In tests, can mock calculate_single_proportion_power()
```

**Impact**: Currently makes unit testing difficult

---

## Summary of Issues

| Category | Severity | Lines | Reduction Potential |
|----------|----------|-------|---------------------|
| Example/Reset handlers | 🔴 CRITICAL | 183 | 73% (133 lines) |
| Validation logic | 🟡 MEDIUM | 70 | 57% (40 lines) |
| CSV export logic | 🟡 MEDIUM | 210 | 62% (130 lines) |
| **TOTAL** | | **463** | **~300 lines** |

---

## Recommended Refactoring Priority

### Phase 1: Quick Wins (2-3 hours)
1. ✅ Refactor example/reset button handlers (data-driven approach)
2. ✅ Refactor validation logic (rule-based system)
3. ✅ Extract calculation wrapper functions (better testability)

### Phase 2: Medium Effort (4-6 hours)
4. Refactor CSV export logic (factory pattern)
5. Extract rendering logic into focused functions

### Phase 3: Long-term (1-2 days)
6. Consider plugin architecture for analysis types
7. Split into Shiny modules if app exceeds 2,000 lines

---

## Metrics

**Current State**:
- Total lines: ~1,530
- Repetitive code: ~463 lines (30%!)
- Cyclomatic complexity: High (many nested if/else)

**After Phase 1 Refactoring**:
- Total lines: ~1,230 (20% reduction)
- Repetitive code: ~160 lines (10%)
- Cyclomatic complexity: Medium (data-driven patterns)

---

## Conclusion

The codebase has **significant DRY violations** that should be addressed. The good news:
- ✅ No major architectural issues
- ✅ Code is well-commented and organized
- ✅ Recent performance improvements are excellent
- ✅ Package management (renv) is best-practice

**Recommendation**: Proceed with Phase 1 refactoring to eliminate the most egregious repetition.
