# Documentation Index

Welcome to the Power Analysis Tool documentation! This directory contains all project documentation organized by purpose.

---

## 📚 Quick Navigation

### For End Users
👉 **[Main README](../README.md)** - Application overview, features, quick start, and usage examples

### For Developers
👉 **[Developer Guide (CLAUDE.md)](development/CLAUDE.md)** - Comprehensive developer documentation (Diataxis framework)
👉 **[Contributing Guidelines (CONTRIBUTING.md)](development/CONTRIBUTING.md)** - How to contribute to the project
👉 **[Code Quality Standards (CODE_QUALITY.md)](development/CODE_QUALITY.md)** - Coding standards and quality tools

### For Project History
👉 **[Enhancement Reports](reports/enhancements/)** - Feature implementation summaries
👉 **[Quality Reports](reports/quality/)** - Code quality audits and analysis

---

## 📂 Documentation Structure

```
docs/
├── README.md (this file)          # Documentation index
├── development/                   # Developer documentation
│   ├── CLAUDE.md                  # Comprehensive dev guide (Diataxis framework)
│   ├── CONTRIBUTING.md            # Contribution guidelines
│   └── CODE_QUALITY.md           # Code quality standards
└── reports/                       # Historical reports & analysis
    ├── enhancements/              # Feature implementation reports
    │   ├── TIER3_ENHANCEMENTS.md
    │   ├── TIER4_ENHANCEMENTS.md
    │   └── IMPLEMENTATION_SUMMARY.txt
    └── quality/                   # Code quality reports
        ├── DRY_SOLID_AUDIT.md
        ├── DRY_SOLID_SUMMARY.md
        ├── LINTR_ANALYSIS.md
        └── QUALITY_TOOLS_IMPLEMENTATION.md
```

---

## 🎯 Documentation by Purpose

### Development Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| [CLAUDE.md](development/CLAUDE.md) | Comprehensive developer guide with tutorials, how-tos, reference, and architectural explanations. Follows Diataxis framework. | Developers (new and experienced) |
| [CONTRIBUTING.md](development/CONTRIBUTING.md) | Guidelines for contributing: setup, code style, testing, PR process | Contributors |
| [CODE_QUALITY.md](development/CODE_QUALITY.md) | Code quality standards, tools (lintr, pre-commit), and best practices | Developers |

### Enhancement Reports

| Document | Purpose | Created |
|----------|---------|---------|
| [TIER3_ENHANCEMENTS.md](reports/enhancements/TIER3_ENHANCEMENTS.md) | Version 4.0 features: Modern UI, Bootstrap 5, example buttons, help system | Tier 3 |
| [TIER4_ENHANCEMENTS.md](reports/enhancements/TIER4_ENHANCEMENTS.md) | Version 5.0 features: Continuous outcomes, non-inferiority testing | Tier 4 |
| [IMPLEMENTATION_SUMMARY.txt](reports/enhancements/IMPLEMENTATION_SUMMARY.txt) | Overall implementation summary and feature list | Current |

### Quality Reports

| Document | Purpose | Created |
|----------|---------|---------|
| [DRY_SOLID_AUDIT.md](reports/quality/DRY_SOLID_AUDIT.md) | Detailed audit of DRY/SOLID principles implementation | Quality initiative |
| [DRY_SOLID_SUMMARY.md](reports/quality/DRY_SOLID_SUMMARY.md) | Summary of DRY/SOLID refactoring (eliminated 131 lines of repetition) | Quality initiative |
| [LINTR_ANALYSIS.md](reports/quality/LINTR_ANALYSIS.md) | Lintr code analysis results and recommendations | Quality initiative |
| [QUALITY_TOOLS_IMPLEMENTATION.md](reports/quality/QUALITY_TOOLS_IMPLEMENTATION.md) | Documentation of quality tooling setup (pre-commit, lintr, etc.) | Quality initiative |

---

## 🚀 Getting Started Paths

### "I want to use the application"
1. Read [Main README](../README.md) for features and usage
2. Follow Quick Start section to run locally or with Docker
3. Try the usage examples

### "I want to contribute code"
1. Read [CONTRIBUTING.md](development/CONTRIBUTING.md) for setup and guidelines
2. Read [CLAUDE.md - Getting Started Tutorials](development/CLAUDE.md#getting-started-tutorials) for hands-on lessons
3. Follow the development workflow in CONTRIBUTING.md

### "I want to understand the architecture"
1. Read [CLAUDE.md - Reference](development/CLAUDE.md#reference) for technical specifications
2. Read [CLAUDE.md - Explanation](development/CLAUDE.md#explanation) for design decisions
3. Review [Enhancement Reports](reports/enhancements/) for feature history

### "I want to understand code quality"
1. Read [CODE_QUALITY.md](development/CODE_QUALITY.md) for standards
2. Review [Quality Reports](reports/quality/) for analysis
3. Check [QUALITY_TOOLS_IMPLEMENTATION.md](reports/quality/QUALITY_TOOLS_IMPLEMENTATION.md) for tooling

---

## 📖 About the Documentation Framework

This project's developer documentation follows the **[Diataxis documentation framework](https://diataxis.fr/)**, a systematic approach to technical documentation that organizes content into four distinct types:

1. **Tutorials** (learning-oriented) - Practical lessons that teach skills
2. **How-to Guides** (task-oriented) - Directions for specific tasks
3. **Reference** (information-oriented) - Complete technical specifications
4. **Explanation** (understanding-oriented) - Context and design rationale

This structure ensures developers can quickly find the right information for their current need, whether they're learning, working on specific tasks, looking up details, or seeking deeper understanding.

---

## 🔄 Documentation Maintenance

### When to Update Documentation

**Main README.md (root):**
- Adding/changing user-facing features
- Updating installation/deployment instructions
- Changing statistical methods or analysis types

**CLAUDE.md:**
- Adding new architectural patterns
- Changing helper functions or core logic
- Adding dependencies
- Modifying development workflow

**CONTRIBUTING.md:**
- Changing contribution process
- Updating code style guidelines
- Adding new testing requirements

### Documentation Workflow

1. **During development:** Update relevant docs in the same PR as code changes
2. **For new features:** Update Main README + CLAUDE.md + create report in reports/enhancements/
3. **For refactoring:** Create report in reports/quality/
4. **For documentation itself:** Update this index (docs/README.md) if structure changes

---

## 📝 Documentation Standards

- **Format:** Markdown (.md) for all documentation except legacy .txt files
- **Style:** Clear, concise, with code examples
- **Structure:** Follow Diataxis principles (see CLAUDE.md)
- **Links:** Use relative links within documentation
- **Code blocks:** Always specify language (```r, ```bash, etc.)
- **Tone:** Professional but approachable

---

## 🆘 Need Help?

- **User questions:** See [Main README](../README.md)
- **Development questions:** See [CLAUDE.md](development/CLAUDE.md)
- **Contributing questions:** See [CONTRIBUTING.md](development/CONTRIBUTING.md)
- **Can't find something:** Check this index or search within docs/

---

## 📜 Version History

- **v5.0** - Tier 4: Continuous outcomes, non-inferiority testing (current)
- **v4.0** - Tier 3: Modern UI, Bootstrap 5, help system
- **v3.0** - Tier 2: Survival analysis, matched case-control
- **v2.0** - Tier 1: Two-group comparisons, effect measures

See [Enhancement Reports](reports/enhancements/) for detailed version documentation.

---

**Last Updated:** 2025-10-24
**Documentation Framework:** [Diataxis](https://diataxis.fr/)
