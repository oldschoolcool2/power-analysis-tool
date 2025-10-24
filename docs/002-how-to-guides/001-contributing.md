# Contributing to Power Analysis Tool

Thank you for your interest in contributing to the Power & Sample Size Calculator for Real-World Evidence Studies!

This document provides guidelines for contributing to the project. For comprehensive developer documentation, see [CLAUDE.md](CLAUDE.md).

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Setup](#development-setup)
3. [Code Style & Quality](#code-style--quality)
4. [Testing Requirements](#testing-requirements)
5. [Submitting Changes](#submitting-changes)
6. [Documentation](#documentation)

---

## Getting Started

### Prerequisites

- R ≥ 4.2.0 (recommended 4.4.0)
- Git
- Basic familiarity with R and Shiny
- (Optional) Docker for containerized development

### Project Structure

This is an R Shiny application with a monolithic structure (~1,815 lines in `app.R`). Key files:

- `app.R` - Main application (UI + server logic)
- `analysis-report.Rmd` - PDF export template
- `tests/testthat/test-power-analysis.R` - Test suite
- `CLAUDE.md` - Comprehensive developer documentation (Diataxis framework)
- `README.md` - User-facing documentation

### First Steps

1. Read the [Getting Started tutorial](CLAUDE.md#getting-started-tutorials) in CLAUDE.md
2. Set up your development environment (see below)
3. Run the application locally
4. Make a small change to familiarize yourself with the codebase

---

## Development Setup

### Using R Directly

```r
# Clone the repository
git clone <repo-url>
cd power-analysis-tool

# Open R in this directory
# renv will automatically activate (via .Rprofile)

# Install dependencies from lockfile
renv::restore()

# Run the application
shiny::runApp("app.R")
```

### Using Docker

```bash
# Build and run
docker-compose up

# Access at http://localhost:3838

# Rebuild after changes
docker-compose up --build
```

### Package Management with renv

This project uses **renv** for reproducible package management (R's equivalent of Python's `uv`):

```r
# After installing new packages
install.packages("new_package")
renv::snapshot()  # Updates renv.lock

# Check if packages are in sync
renv::status()

# Troubleshooting
renv::restore(clean = TRUE)  # Clean reinstall
```

**Important:** Always run `renv::snapshot()` after adding new packages and commit the updated `renv.lock` file.

---

## Code Style & Quality

### Code Style Guidelines

This project follows standard R and Shiny conventions:

1. **Indentation:** 2 spaces (no tabs)
2. **Line length:** Aim for ≤100 characters
3. **Naming conventions:**
   - Functions: `snake_case` (e.g., `calc_effect_measures`)
   - Variables: `snake_case` (e.g., `sample_size`)
   - UI inputs: `{tab}_{parameter}` (e.g., `power_n`, `twogrp_pow_n1`)
4. **Comments:** Use `#` for single-line comments, explain "why" not "what"

### Automated Quality Checks

This project uses **pre-commit hooks** for code quality:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

**Quality checks include:**
- `lintr` - R code style and syntax
- `trailing-whitespace` - Remove trailing spaces
- `end-of-file-fixer` - Ensure files end with newline
- `check-yaml` - Validate YAML syntax

### R Code Linting

The project includes a `.lintr` configuration file. Run lintr before committing:

```r
# Install lintr (if not in renv)
install.packages("lintr")

# Lint the main application file
lintr::lint("app.R")
```

**Key lintr rules:**
- Line length ≤100 characters
- No trailing whitespace
- Consistent indentation
- Proper spacing around operators

---

## Testing Requirements

### Running Tests

```r
# Run all tests
testthat::test_file("tests/testthat/test-power-analysis.R")

# Run specific test
testthat::test_file(
  "tests/testthat/test-power-analysis.R",
  filter = "calc_effect_measures"
)
```

### What to Test

**✅ DO test:**
- Helper functions (e.g., `calc_effect_measures`, `solve_n1_for_ratio`)
- Edge cases (division by zero, NA values, boundary conditions)
- Input validation logic
- Statistical calculation correctness

**❌ DON'T test:**
- Core statistical packages (`pwr`, `powerSurvEpi`, `epiR` - already tested)
- Base R functionality
- Shiny framework itself

### Writing Tests

When adding new helper functions, include tests:

```r
test_that("your_function returns correct values", {
  result <- your_function(input1, input2)

  expect_equal(result$value1, expected1)
  expect_equal(result$value2, expected2)
})

test_that("your_function handles edge cases", {
  result <- your_function(0, 0)

  expect_true(is.na(result$value))
})
```

See [Tutorial 3: Adding Your First Test](CLAUDE.md#tutorial-3-adding-your-first-test) in CLAUDE.md for detailed guidance.

### Manual Testing Checklist

Before submitting a PR, manually test:

1. All analysis tabs work with Calculate button
2. Example and Reset buttons function correctly
3. Input validation shows appropriate errors
4. CSV/PDF export generates files
5. Tab switching hides stale results
6. Power curves display correctly

---

## Submitting Changes

### Branching Strategy

- `master` - Main branch (stable, production-ready)
- `feature/your-feature-name` - Feature branches
- `fix/bug-description` - Bug fix branches

### Commit Messages

Follow conventional commit format:

```
type(scope): brief description

Detailed explanation (optional)

Closes #issue-number (if applicable)
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style (formatting, no logic change)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance (dependencies, build, etc.)

**Examples:**
```
feat(continuous): add ANOVA power analysis tab

Add new analysis type for ANOVA designs with effect size (f).
Includes power curve, CSV export, and example scenarios.

Closes #42
```

```
fix(effect-measures): handle p2=0 edge case

Return NA instead of Inf when calculating RR/OR with p2=0.
Improves user clarity and prevents downstream errors.
```

### Pull Request Process

1. **Create a feature branch** from `master`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following code style guidelines

3. **Run quality checks**:
   ```bash
   pre-commit run --all-files
   testthat::test_file("tests/testthat/test-power-analysis.R")
   ```

4. **Update renv.lock** if you added packages:
   ```r
   renv::snapshot()
   ```

5. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request** on GitHub with:
   - Clear description of changes
   - Link to related issue (if applicable)
   - Screenshots (if UI changes)
   - Manual testing checklist results

### PR Review Checklist

Your PR will be reviewed for:

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] New tests added for new functionality
- [ ] Documentation updated (README.md, CLAUDE.md if needed)
- [ ] `renv.lock` updated if packages added
- [ ] No merge conflicts with `master`
- [ ] Manual testing checklist completed

---

## Documentation

### When to Update Documentation

**Update README.md when:**
- Adding new analysis types
- Changing user-facing features
- Updating installation/deployment instructions

**Update CLAUDE.md when:**
- Adding new architectural patterns
- Changing helper functions
- Adding new dependencies
- Modifying development workflow

### Documentation Framework

This project follows the **Diataxis documentation framework**:

- **Tutorials** (learning-oriented) - Hands-on lessons for new developers
- **How-to Guides** (task-oriented) - Specific task instructions
- **Reference** (information-oriented) - Technical specifications
- **Explanation** (understanding-oriented) - Design decisions and context

When updating CLAUDE.md, place content in the appropriate section:
- New development guide → How-To Guides
- New function API → Reference
- Architecture decision → Explanation

### Documentation Style

- Use clear, concise language
- Include code examples
- Explain "why" in addition to "how"
- Keep user perspective in mind
- Use markdown formatting consistently

---

## Common Contribution Scenarios

### Adding a New Analysis Type

See [How to Add a New Analysis Type](CLAUDE.md#how-to-add-a-new-analysis-type) in CLAUDE.md for step-by-step instructions.

**Summary:**
1. Create new UI tab in `tabsetPanel()`
2. Add validation logic in server section
3. Add output renderers using delayed evaluation pattern
4. Create CSV export handler
5. Add Example and Reset buttons
6. Add tests for new calculations
7. Update documentation

### Fixing a Bug

1. Create issue describing the bug with reproducible example
2. Create fix branch: `fix/bug-description`
3. Write test that reproduces bug (should fail)
4. Fix the bug
5. Verify test passes
6. Submit PR with issue reference

### Improving Performance

1. Profile the application (use `profvis` package)
2. Identify bottleneck
3. Implement optimization
4. Benchmark improvement
5. Document changes in PR description

### Updating Dependencies

```r
# Update specific package
renv::update("package_name")

# Update all packages
renv::update()

# Snapshot changes
renv::snapshot()

# Test thoroughly (regression testing)
```

Commit updated `renv.lock` with explanation of why packages were updated.

---

## Getting Help

### Resources

- **Developer Documentation:** [CLAUDE.md](CLAUDE.md) - Comprehensive technical documentation
- **User Documentation:** [README.md](README.md) - User-facing features and usage
- **Shiny Documentation:** https://shiny.rstudio.com/
- **renv Documentation:** https://rstudio.github.io/renv/

### Architecture Questions

Before asking architecture questions:
1. Check [Explanation section](CLAUDE.md#explanation) in CLAUDE.md
2. Search existing issues
3. Review related code with comments

### Feature Requests

Before proposing a feature:
1. Check if it aligns with project goals (pharmaceutical RWE research)
2. Search existing issues/PRs
3. Consider if it fits within the monolithic structure (~1,815 lines)
4. Open an issue for discussion before implementing

---

## Project Goals & Scope

### In Scope

- Statistical power analysis for pharmaceutical RWE studies
- Binary, continuous, and survival outcomes
- Non-inferiority testing
- User-friendly interface for non-statisticians
- Export functionality (CSV, PDF)
- Scenario comparison

### Out of Scope

- Clustering/multilevel designs (beyond simple matching)
- Multiple comparison corrections (apply separately)
- Bayesian methods
- Adaptive designs
- Sample size re-estimation
- Real-time data integration

---

## Code of Conduct

### Our Standards

- Be respectful and professional
- Focus on constructive feedback
- Welcome diverse perspectives
- Prioritize scientific accuracy
- Maintain pharmaceutical research standards

### Review Process

- Code reviews focus on correctness, clarity, and maintainability
- Statistical methods must be evidence-based (cite references)
- All feedback should be actionable and specific
- Reviewers should explain "why" when requesting changes

---

## License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project.

---

## Recognition

Contributors will be acknowledged in:
- Git commit history
- Release notes for significant contributions
- Project documentation for major features

Thank you for contributing to better pharmaceutical research tools!

---

## Quick Reference

```bash
# Development workflow
git checkout -b feature/my-feature
# ... make changes ...
pre-commit run --all-files
R -e "testthat::test_file('tests/testthat/test-power-analysis.R')"
R -e "renv::snapshot()"
git add .
git commit -m "feat(scope): description"
git push origin feature/my-feature
# ... open PR on GitHub ...
```

For detailed guidance, see [CLAUDE.md](CLAUDE.md).
