# Testing Strategy and Why We Chose shinytest2

**Type:** Explanation
**Audience:** Developers, Architects, Contributors
**Last Updated:** 2025-10-25

## Overview

This document explains our testing strategy for the Power Analysis Tool, why we chose shinytest2 for end-to-end testing, and how it fits into our overall quality assurance approach.

## The Testing Challenge

### Context

The Power Analysis Tool is a Shiny application with complex statistical calculations and interactive visualizations. Users depend on it for critical study design decisions, making correctness and reliability paramount.

### The Problem

We needed a testing strategy that would:

1. **Ensure calculation accuracy** - Statistical functions must produce correct results
2. **Validate user workflows** - The entire UI-to-calculation pipeline must work
3. **Prevent regressions** - Changes shouldn't break existing functionality
4. **Support refactoring** - Tests should enable confident code improvements
5. **Be maintainable** - Tests must be easy to write, read, and update
6. **Run in CI/CD** - Automated testing for every code change

### Why Traditional Testing Wasn't Enough

Before adding E2E testing, we had:

**Unit Tests (testthat)**
- ✅ Test individual functions in isolation
- ✅ Fast execution
- ✅ Easy to debug
- ❌ Don't test UI interactions
- ❌ Don't test reactive logic
- ❌ Don't catch integration issues

**Server Tests (testServer)**
- ✅ Test reactive logic in server.R
- ✅ Test Shiny modules
- ✅ No browser required
- ❌ Don't test UI rendering
- ❌ Don't test JavaScript interactions
- ❌ Don't test visual output

**Manual Testing**
- ✅ Catches UX issues
- ✅ Tests real user workflows
- ❌ Time-consuming
- ❌ Not reproducible
- ❌ Can't run in CI/CD
- ❌ Easy to miss edge cases

## Testing Strategy Overview

Our comprehensive testing approach uses three complementary layers:

```
┌─────────────────────────────────────────────┐
│  E2E Tests (shinytest2)                     │  ← User workflows, full stack
│  - Test entire application                  │
│  - Browser-based simulation                 │
│  - Visual regression testing                │
└─────────────────────────────────────────────┘
              ↑ calls
┌─────────────────────────────────────────────┐
│  Server Tests (testServer)                  │  ← Reactive logic, modules
│  - Test reactive expressions                │
│  - Test observers and reactive values       │
│  - Test modules in isolation                │
└─────────────────────────────────────────────┘
              ↑ calls
┌─────────────────────────────────────────────┐
│  Unit Tests (testthat)                      │  ← Pure functions
│  - Test helper functions                    │
│  - Test calculations                        │
│  - Test data transformations                │
└─────────────────────────────────────────────┘
```

### The Testing Pyramid

We follow the testing pyramid principle:

```
         /\
        /  \     E2E Tests (10-20%)
       /----\    - Fewer, high-value tests
      /      \   - Test critical user paths
     /--------\  - Slower, more fragile
    /          \
   /   Server   \ Server Tests (20-30%)
  /    Tests     \ - Moderate coverage
 /--------------\ - Test reactive logic
/                \
/   Unit Tests    \ Unit Tests (50-70%)
/                  \ - Majority of tests
--------------------  - Fast, focused, reliable
```

## Why We Chose shinytest2

### Alternatives Considered

#### Option 1: shinytest (v1)

**Pros:**
- Mature, battle-tested
- Good snapshot testing
- PhantomJS-based

**Cons:**
- Uses deprecated PhantomJS (unmaintained since 2018)
- No active development
- Limited modern browser features
- Poor DevTools support
- Slower than modern alternatives

**Verdict:** ❌ Rejected due to deprecated dependencies

#### Option 2: Selenium/RSelenium

**Pros:**
- Industry standard for web testing
- Supports multiple browsers
- Extensive ecosystem

**Cons:**
- Complex setup and configuration
- Not designed for Shiny
- Verbose test syntax
- Requires separate driver management
- Steeper learning curve

**Verdict:** ❌ Rejected due to complexity and Shiny-specific needs

#### Option 3: Cypress (via JavaScript)

**Pros:**
- Modern, developer-friendly
- Excellent debugging tools
- Fast execution
- Great documentation

**Cons:**
- JavaScript-only (team uses R)
- Requires learning new ecosystem
- Extra complexity for R-centric workflow
- Additional build tooling needed

**Verdict:** ❌ Rejected due to language mismatch and added complexity

#### Option 4: Manual Testing Only

**Pros:**
- No framework to learn
- Flexible, exploratory testing
- Can catch UX issues

**Cons:**
- Not scalable
- Can't run in CI/CD
- Prone to human error
- Time-consuming
- Inconsistent coverage

**Verdict:** ❌ Rejected as sole strategy (still used for exploratory testing)

#### Option 5: shinytest2 (Chosen)

**Pros:**
- ✅ Modern Chrome/Chromium via chromote
- ✅ Native R integration with testthat
- ✅ Official RStudio support
- ✅ Active development
- ✅ Snapshot testing built-in
- ✅ Great debugging tools (Chrome DevTools)
- ✅ CI/CD friendly
- ✅ Shiny-first design

**Cons:**
- Relatively new (but stable)
- Chrome/Chromium only (acceptable for our use case)
- Slightly slower than testServer

**Verdict:** ✅ **Selected** - Best fit for our needs

## Decision Rationale

### Technical Alignment

**Language consistency**
- Written in R, like our application
- Integrates seamlessly with testthat
- No context switching for developers

**Modern browser engine**
- Uses Chrome/Chromium (80%+ market share)
- Maintained and actively developed
- Supports modern web features

**Shiny-optimized**
- Built specifically for Shiny apps
- Understands Shiny's reactive model
- Handles Shiny's async operations

### Developer Experience

**Easy to write**
```r
# Clean, readable test syntax
app <- AppDriver$new(app_dir = "../../")
app$set_inputs(p1 = 0.15, p2 = 0.10)
app$expect_values(output = "results")
app$stop()
```

**Easy to debug**
```r
# Open visible browser for debugging
app <- AppDriver$new(app_dir = "../../", view = TRUE)
```

**Record and replay**
```r
# Generate tests by interacting with the app
shinytest2::record_test()
```

### Maintenance Considerations

**Snapshot testing**
- Automatically detect UI changes
- Visual regression testing via screenshots
- JSON snapshots for output verification

**Page Object Model support**
- Encapsulate UI interactions
- Reduce test duplication
- Easy to update when UI changes

**CI/CD integration**
- Works headlessly in GitHub Actions
- No display server required
- Reliable cross-platform

## What We Test at Each Layer

### Unit Tests (testthat)

**What:**
- `calc_effect_measures()` - Effect size calculations
- `validate_inputs()` - Input validation logic
- Helper functions for data transformation
- Utility functions

**Why:**
- Fast feedback loop
- Easy to debug
- Test edge cases thoroughly

**Example:**
```r
test_that("calc_effect_measures handles zero proportions", {
  result <- calc_effect_measures(0, 0)
  expect_equal(result$RD, 0)
  expect_true(is.na(result$RR))
})
```

### Server Tests (testServer)

**What:**
- Reactive expressions
- Observers
- Module logic
- State management

**Why:**
- Test Shiny-specific logic
- No browser overhead
- Faster than E2E

**Example:**
```r
testServer(app = server, {
  session$setInputs(p1 = 0.15, p2 = 0.10)
  expect_true(!is.null(output$results))
})
```

### E2E Tests (shinytest2)

**What:**
- Complete user workflows
- Tab navigation
- Form submission
- Plot rendering
- Cross-tab consistency
- Visual regressions

**Why:**
- Validate entire stack
- Test user perspective
- Catch integration issues

**Example:**
```r
test_that("Sample size workflow works end-to-end", {
  app <- AppDriver$new(app_dir = "../../")
  app$set_inputs(tabs = "sample_size")
  app$set_inputs(p1 = 0.15, p2 = 0.10, alpha = 0.05, power = 0.80)
  app$wait_for_idle()
  app$expect_values(output = "results")
  app$get_screenshot("sample-size-results")
  app$stop()
})
```

## Trade-offs and Limitations

### What We Gained

✅ **Confidence in refactoring** - Can safely improve code
✅ **Regression prevention** - Catch breakages early
✅ **Documentation** - Tests demonstrate usage
✅ **CI/CD integration** - Automated quality checks
✅ **Visual regression testing** - Catch UI changes

### What We Accepted

⚠️ **Slower test execution** - E2E tests take longer than unit tests
⚠️ **Chrome dependency** - Requires Chromium/Chrome installation
⚠️ **Occasional flakiness** - Timing-dependent tests can be fragile
⚠️ **Maintenance overhead** - Snapshots need periodic review
⚠️ **CI resource usage** - Headless browser needs RAM

### Mitigation Strategies

**For slow tests:**
- Limit E2E tests to critical paths
- Run unit tests more frequently
- Use parallel execution where possible

**For flakiness:**
- Use `wait_for_idle()` liberally
- Avoid hard-coded sleep times
- Test at appropriate abstraction level

**For maintenance:**
- Use Page Object Model pattern
- Keep tests focused and independent
- Review snapshot changes carefully

## Best Practices We Follow

### 1. Test Behavior, Not Implementation

❌ **Don't:**
```r
# Testing internal reactive state
expect_equal(app$get_value(export = "reactive_n"), 1000)
```

✅ **Do:**
```r
# Testing user-visible behavior
app$expect_values(output = "results")
```

### 2. Use the Right Test Level

**Unit test:** Pure calculation
**Server test:** Reactive logic
**E2E test:** User workflow

### 3. Keep Tests Independent

Each test should:
- Start fresh (`AppDriver$new()`)
- Not depend on other tests
- Clean up (`app$stop()`)

### 4. Make Tests Readable

Use descriptive names:
```r
test_that("MDE increases when sample size decreases", { ... })
```

Not:
```r
test_that("test_1", { ... })
```

### 5. Limit Snapshot Scope

```r
# Focused - only check relevant output
app$expect_values(output = "results")

# Too broad - spurious failures
app$expect_values()
```

## Future Considerations

### When We Might Revisit This Decision

We would reconsider shinytest2 if:

1. **RStudio stops maintaining it** - Would evaluate alternatives
2. **Performance becomes prohibitive** - Would optimize or reduce E2E coverage
3. **Multi-browser testing becomes critical** - Would add Selenium for specific cases
4. **Team switches to Python Shiny** - Would use py-shinytest2

### Planned Improvements

1. **Increase coverage** - Add more E2E tests for edge cases
2. **Visual regression baselines** - Establish screenshot baselines
3. **Performance benchmarks** - Add timing assertions
4. **Accessibility testing** - Integrate a11y checks
5. **Load testing** - Test concurrent users (separate tool)

## Metrics and Success Criteria

### Current Coverage (as of 2025-10-25)

- **Unit tests:** ~85% of utility functions
- **Server tests:** ~60% of reactive logic
- **E2E tests:** Core workflows for 3 main tabs

### Goals

- Maintain >80% unit test coverage
- E2E tests for all critical user paths
- Zero high-severity bugs in production
- <5% test flakiness rate

### How We Measure Success

✅ **Prevented regressions:** Tests caught before production
✅ **Refactoring safety:** Code improvements without breakage
✅ **Development velocity:** Confidence to move faster
✅ **Bug detection rate:** Issues found in tests vs. production

## Conclusion

We chose shinytest2 because it:

1. **Aligns with our tech stack** - R-native, Shiny-first
2. **Balances trade-offs** - Modern, maintainable, CI-friendly
3. **Complements other testing** - Works with testthat and testServer
4. **Has strong support** - Official RStudio tool with active development
5. **Enables confidence** - Comprehensive testing strategy

This decision supports our goal of delivering a reliable, well-tested statistical tool that researchers can depend on for critical study design decisions.

---

**Related Documentation:**
- `../002-how-to-guides/004-end-to-end-testing-with-shinytest2.md` - How to write E2E tests
- `../003-reference/` - API documentation
- `001-feature-proposals.md` - Feature development process

**References:**
- [shinytest2 documentation](https://rstudio.github.io/shinytest2/)
- [Testing chapter in Mastering Shiny](https://mastering-shiny.org/scaling-testing.html)
- [Testing Pyramid by Martin Fowler](https://martinfowler.com/bliki/TestPyramid.html)
- [Page Object Model pattern](https://martinfowler.com/bliki/PageObject.html)
