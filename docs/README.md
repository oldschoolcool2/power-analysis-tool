# Documentation Index

Welcome to the Power Analysis Tool documentation! This directory follows the **[Diataxis documentation framework](https://diataxis.fr/)** for systematic, user-centered documentation.

---

## 📚 Quick Navigation

### For End Users
👉 **[Main README](../README.md)** - Application overview, features, quick start, and usage examples

### For Developers

**Learning to develop?** → [Tutorials](001-tutorials/)
**Solving a specific problem?** → [How-To Guides](002-how-to-guides/)
**Looking up technical details?** → [Reference](003-reference/)
**Understanding design decisions?** → [Explanation](004-explanation/)

### For Project History
👉 **[Reports](reports/)** - Historical enhancement and quality reports

---

## 📂 Documentation Structure

```
docs/
├── README.md (this file)          # Documentation index
├── 001-tutorials/                 # Learning-oriented guides
│   └── (link to 003-reference/003-developer-guide.md#getting-started-tutorials)
├── 002-how-to-guides/             # Task-oriented instructions
│   ├── 001-contributing.md        # How to contribute to the project
│   ├── 002-advanced-statistical-features-implementation.md # Implementation guide
│   ├── 003-quick-start-guide.md   # Quick start for development
│   ├── 004-end-to-end-testing-with-shinytest2.md # E2E testing guide
│   ├── 005-using-shiny-modules-and-helpers.md # Shiny modules refactoring guide
│   ├── 006-security-scanning-with-trivy.md # Security scanning guide
│   ├── 007-maintain-docker-best-practices.md # Docker best practices
│   └── 008-add-new-analysis-type.md # How to add new analysis types
├── 003-reference/                 # Information-oriented specifications
│   ├── 001-code-quality-tools.md  # Code quality tools reference
│   ├── 002-antipatterns-guide.md  # Antipatterns reference
│   └── 003-developer-guide.md     # Comprehensive developer guide (Diataxis)
├── 004-explanation/               # Understanding-oriented discussions
│   ├── 001-feature-proposals.md   # Feature enhancement ideas
│   ├── 002-ui-ux-modernization.md # UI/UX design rationale
│   ├── 003-comprehensive-feature-analysis-2025.md # Feature analysis
│   └── 004-testing-strategy-and-shinytest2.md # Testing strategy rationale
└── reports/                       # Historical reports & analysis
    ├── enhancements/              # Feature implementation reports
    └── quality/                   # Code quality reports
```

---

## 🎯 The Diataxis Framework

This documentation follows the **[Diataxis framework](https://diataxis.fr/)**, which organizes content into four distinct types based on user needs:

### 1. 📚 Tutorials (Learning-Oriented)
**What:** Practical lessons that teach through hands-on experience
**When to use:** You're new and want to learn by doing
**Example:** "Your First Development Session"

### 2. 🛠️ How-To Guides (Task-Oriented)
**What:** Step-by-step instructions for specific tasks
**When to use:** You have a specific problem to solve
**Example:** "How to Add a New Analysis Type"

### 3. 📖 Reference (Information-Oriented)
**What:** Technical specifications and API documentation
**When to use:** You need to look up specific details
**Example:** "Helper Functions API", "Input Naming Conventions"

### 4. 💡 Explanation (Understanding-Oriented)
**What:** Discussion of design decisions and concepts
**When to use:** You want to understand why things work the way they do
**Example:** "Why Monolithic app.R Structure?", "Why Delayed Evaluation Pattern?"

---

## 🚀 Getting Started Paths

### "I want to use the application"
1. Read [Main README](../README.md) for features and usage
2. Follow Quick Start section to run locally or with Docker
3. Try the usage examples

### "I want to contribute code"
1. Read [Contributing Guide](002-how-to-guides/001-contributing.md) for setup and guidelines
2. Read [Developer Guide - Tutorials](003-reference/003-developer-guide.md#getting-started-tutorials) for hands-on lessons
3. Follow the development workflow

### "I want to understand the architecture"
1. Read [Developer Guide - Reference](003-reference/003-developer-guide.md#reference) for technical specifications
2. Read [Developer Guide - Explanation](003-reference/003-developer-guide.md#explanation) for design decisions
3. Review [Enhancement Reports](reports/enhancements/) for feature history

### "I want to understand code quality"
1. Read [Code Quality Tools Reference](003-reference/001-code-quality-tools.md) for standards
2. Read [Antipatterns Guide](003-reference/002-antipatterns-guide.md) for common mistakes
3. Review [Quality Reports](reports/quality/) for analysis

### "I want to add a new analysis type" ✨ NEW
1. Read [How to Add a New Analysis Type](002-how-to-guides/008-add-new-analysis-type.md) for complete step-by-step guide
2. Read [Using Shiny Modules and Helpers](002-how-to-guides/005-using-shiny-modules-and-helpers.md) to understand available components
3. Review existing tabs in `app.R` for reference patterns

### "I want to refactor code using Shiny modules"
1. Read [Code Duplication Analysis](004-explanation/003-code-duplication-and-refactoring-analysis.md) for the full analysis
2. Read [Using Shiny Modules and Helpers](002-how-to-guides/005-using-shiny-modules-and-helpers.md) for step-by-step guide
3. Review [REFACTORING_SUMMARY.md](../REFACTORING_SUMMARY.md) for implementation status and impact metrics

### "I want to set up logging and monitoring" ✨ NEW
1. Read [Logging Best Practices](002-how-to-guides/018-logging-best-practices.md) for structured logging guidelines
2. Use the Shiny monitoring dashboard in `inst/app_monitoring/app.R` for real-time log analysis
3. Read [Analyze Logs with CLI Tool](002-how-to-guides/019-analyze-logs-with-loganalyzer.md) for command-line log analysis
4. Read [External Log Service Integrations](002-how-to-guides/020-external-log-services.md) to send logs to Loggly, CloudWatch, Datadog, or Loki

---

## 📝 Documentation Standards

### File Naming Convention

All documentation files follow this naming pattern:
```
###-document-name.md
```

Where:
- `###` = Three-digit number with leading zeros (e.g., `001`, `002`, `010`)
- `document-name` = Kebab-case descriptive name
- `.md` = Markdown extension

**Examples:**
- ✅ `001-contributing.md`
- ✅ `002-antipatterns-guide.md`
- ✅ `010-advanced-features.md`
- ❌ `1-contributing.md` (missing leading zeros)
- ❌ `contributing.md` (missing number prefix)
- ❌ `001_contributing.md` (wrong separator)

### Numbering System

Files are numbered within each Diataxis category:
- **tutorials/**: `001-*`, `002-*`, ...
- **how-to-guides/**: `001-*`, `002-*`, ...
- **reference/**: `001-*`, `002-*`, ...
- **explanation/**: `001-*`, `002-*`, ...

Numbers indicate reading order or logical grouping, not strict sequence. Leave gaps (e.g., `001`, `010`, `020`) to allow future insertions.

### Content Guidelines

- **Format:** Markdown (.md) for all documentation
- **Style:** Clear, concise, with code examples
- **Structure:** Follow Diataxis principles (see category above)
- **Links:** Use relative links within documentation
- **Code blocks:** Always specify language (```r, ```bash, etc.)
- **Tone:** Professional but approachable
- **Headers:** Use sentence case (not title case)
- **Lists:** Consistent bullet style (- not *)

---

## 🔄 Documentation Maintenance

### When to Add Documentation

**Tutorials:**
- Adding a new getting-started workflow
- Creating hands-on learning materials
- Documenting a step-by-step lesson

**How-To Guides:**
- Documenting a specific task or procedure
- Adding deployment or configuration instructions
- Creating troubleshooting guides

**Reference:**
- Documenting APIs, functions, or components
- Creating configuration references
- Adding tool or package documentation

**Explanation:**
- Documenting design decisions
- Explaining architectural choices
- Discussing trade-offs and alternatives
- Proposing new features

### When to Update Documentation

**Main README.md (root):**
- Adding/changing user-facing features
- Updating installation/deployment instructions
- Changing statistical methods or analysis types

**Reference documentation:**
- Adding new architectural patterns
- Changing helper functions or core logic
- Adding dependencies
- Modifying API or configuration

**How-to guides:**
- Changing contribution process
- Updating code style guidelines
- Adding new testing requirements
- Modifying workflows

### Documentation Workflow

1. **During development:** Update relevant docs in the same PR as code changes
2. **For new features:** Update Main README + reference docs + create enhancement report
3. **For refactoring:** Create quality report in reports/quality/
4. **For documentation itself:** Update this index (docs/README.md) if structure changes
5. **Before commit:** Ensure file names follow the naming convention

---

## 📄 Adding New Documentation

### Step 1: Determine the Category

Ask yourself:
- **Am I teaching someone?** → 001-tutorials/
- **Am I solving a specific problem?** → 002-how-to-guides/
- **Am I documenting technical details?** → 003-reference/
- **Am I explaining "why"?** → 004-explanation/

### Step 2: Choose a Number

1. Look at existing files in the category
2. Choose the next available number (or leave gaps for flexibility)
3. Use three digits with leading zeros

### Step 3: Name the File

```bash
# Format: ###-document-name.md
# Examples:
docs/002-how-to-guides/004-deploy-to-production.md
docs/004-explanation/003-performance-optimization-strategy.md
docs/003-reference/004-api-endpoints.md
```

### Step 4: Create the File

Use this template:

```markdown
# Document Title

**Type:** [Tutorial | How-To | Reference | Explanation]
**Audience:** [Developers | Contributors | Architects]
**Last Updated:** YYYY-MM-DD

## Overview

Brief description of what this document covers and who should read it.

## [Main Content Sections]

[Your content here]

---

**Related Documentation:**
- [Link to related docs]

**References:**
- [External references if applicable]
```

### Step 5: Update the Index

Add your document to this README.md in the appropriate section.

### Step 6: Use Git History Preservation

If moving/renaming existing files, use `git mv` to preserve history:

```bash
git mv old-path/file.md docs/###-category/###-new-name.md
```

---

## 🔍 Finding Documentation

### By Search

```bash
# Search all documentation
grep -r "search term" docs/

# Search specific category
grep -r "search term" docs/002-how-to-guides/

# Search excluding reports
grep -r "search term" docs/ --exclude-dir=reports
```

### By Category

| I want to... | Go to |
|--------------|-------|
| Learn how to develop | [001-tutorials/](001-tutorials/) or [Developer Guide Tutorials](003-reference/003-developer-guide.md#getting-started-tutorials) |
| Solve a specific problem | [002-how-to-guides/](002-how-to-guides/) |
| Look up technical details | [003-reference/](003-reference/) |
| Understand design decisions | [004-explanation/](004-explanation/) |
| View historical reports | [reports/](reports/) |

### By Topic

| Topic | Location |
|-------|----------|
| Contributing to the project | [002-how-to-guides/001-contributing.md](002-how-to-guides/001-contributing.md) |
| Advanced features implementation | [002-how-to-guides/002-advanced-statistical-features-implementation.md](002-how-to-guides/002-advanced-statistical-features-implementation.md) |
| Quick start guide | [002-how-to-guides/003-quick-start-guide.md](002-how-to-guides/003-quick-start-guide.md) |
| E2E testing with shinytest2 | [002-how-to-guides/004-end-to-end-testing-with-shinytest2.md](002-how-to-guides/004-end-to-end-testing-with-shinytest2.md) |
| **Docker best practices maintenance** | **[002-how-to-guides/007-maintain-docker-best-practices.md](002-how-to-guides/007-maintain-docker-best-practices.md)** |
| Logging best practices | [002-how-to-guides/018-logging-best-practices.md](002-how-to-guides/018-logging-best-practices.md) |
| Analyze logs with CLI tool | [002-how-to-guides/019-analyze-logs-with-loganalyzer.md](002-how-to-guides/019-analyze-logs-with-loganalyzer.md) |
| **External log service integrations** | **[002-how-to-guides/020-external-log-services.md](002-how-to-guides/020-external-log-services.md)** |
| Code quality tools | [003-reference/001-code-quality-tools.md](003-reference/001-code-quality-tools.md) |
| Antipatterns | [003-reference/002-antipatterns-guide.md](003-reference/002-antipatterns-guide.md) |
| Developer guide (comprehensive) | [003-reference/003-developer-guide.md](003-reference/003-developer-guide.md) |
| **Docker CI/CD validation** | **[003-reference/008-docker-cicd-validation.md](003-reference/008-docker-cicd-validation.md)** |
| Feature proposals | [004-explanation/001-feature-proposals.md](004-explanation/001-feature-proposals.md) |
| UI/UX design | [004-explanation/002-ui-ux-modernization.md](004-explanation/002-ui-ux-modernization.md) |
| Comprehensive feature analysis | [004-explanation/003-comprehensive-feature-analysis-2025.md](004-explanation/003-comprehensive-feature-analysis-2025.md) |
| Testing strategy and shinytest2 | [004-explanation/004-testing-strategy-and-shinytest2.md](004-explanation/004-testing-strategy-and-shinytest2.md) |

---

## 🆘 Need Help?

- **User questions:** See [Main README](../README.md)
- **Development questions:** See [Developer Guide](003-reference/003-developer-guide.md)
- **Contributing questions:** See [Contributing Guide](002-how-to-guides/001-contributing.md)
- **Can't find something:** Search within docs/ or check this index

---

## 📜 Version History

- **v5.0** - Continuous outcomes and equivalence: Continuous outcomes, non-inferiority testing (current)
- **v4.0** - Professional polish: Modern UI, Bootstrap 5, help system
- **v3.0** - UI/UX modernization: Survival analysis, matched case-control
- **v2.0** - Advanced statistical features: Two-group comparisons, effect measures

See [Enhancement Reports](reports/enhancements/) for detailed version documentation.

---

**Last Updated:** 2025-10-27
**Documentation Framework:** [Diataxis](https://diataxis.fr/)
**Maintained By:** Development Team
