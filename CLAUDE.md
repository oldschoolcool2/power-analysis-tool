# CLAUDE.md - Documentation Guidelines for Power Analysis Tool

This file provides guidelines for maintaining and adding documentation to this project.

---

## Documentation System

This project uses the **[Diataxis documentation framework](https://diataxis.fr/)** to organize all documentation into four distinct categories based on user needs.

### Quick Reference

| Category | Purpose | When to Use |
|----------|---------|-------------|
| **Tutorials** | Learning-oriented | Teaching someone through hands-on lessons |
| **How-To Guides** | Task-oriented | Solving a specific problem step-by-step |
| **Reference** | Information-oriented | Looking up technical specifications |
| **Explanation** | Understanding-oriented | Explaining "why" and design decisions |

---

## File Naming Convention

**All documentation files MUST follow this naming pattern:**

```
###-document-name.md
```

This convention applies to **all directories** including `reports/` subdirectories. Files are numbered in logical order so readers can navigate to any folder and read through documents sequentially to understand the full picture.

### Rules:

1. **Three-digit number** with leading zeros (e.g., `001`, `002`, `010`)
2. **Kebab-case** for the document name (lowercase, hyphen-separated)
3. **`.md` extension** for Markdown files
4. **Sequential ordering** - number files in the order they should be read

### Examples:

✅ **Correct:**
- `001-contributing.md`
- `002-antipatterns-guide.md`
- `010-advanced-features.md`
- `001-initial-analysis.md` (in reports subdirectory)

❌ **Incorrect:**
- `1-contributing.md` (missing leading zeros)
- `contributing.md` (missing number prefix)
- `001_contributing.md` (underscore instead of hyphen)
- `001-Contributing.md` (capital letters in name)
- `001-contributing` (missing .md extension)
- `IMPLEMENTATION_STATUS.md` (ALL_CAPS, missing number)

---

## Directory Structure

```
docs/
├── README.md                      # Documentation index
├── 001-tutorials/                 # 📚 Learning-oriented guides
│   └── ###-tutorial-name.md
├── 002-how-to-guides/             # 🛠️ Task-oriented instructions
│   └── ###-guide-name.md
├── 003-reference/                 # 📖 Information-oriented specs
│   └── ###-reference-name.md
├── 004-explanation/               # 💡 Understanding-oriented discussions
│   └── ###-explanation-name.md
└── reports/                       # 📊 Historical reports (also use ###-name.md)
    ├── enhancements/
    │   └── topic-name/
    │       ├── README.md          # Optional: topic overview
    │       └── ###-report-name.md
    └── quality/
        └── topic-name/
            └── ###-report-name.md
```

---

## Adding New Documentation

### Step 1: Determine the Category

Ask yourself what the user needs:

**Am I teaching someone to do something?** → `001-tutorials/`
- Example: "Your first development session"
- Characteristics: Hands-on, step-by-step, learning by doing
- User is a beginner wanting to acquire skills

**Am I solving a specific problem?** → `002-how-to-guides/`
- Example: "How to deploy to production"
- Characteristics: Goal-oriented, practical steps
- User has a specific task to accomplish

**Am I documenting technical details?** → `003-reference/`
- Example: "API endpoints reference"
- Characteristics: Dry, factual, comprehensive
- User needs to look something up

**Am I explaining "why"?** → `004-explanation/`
- Example: "Why we chose monolithic architecture"
- Characteristics: Discussion, context, rationale
- User wants to understand the reasoning

### Step 2: Choose a Number

1. Look at existing files in the target category
2. Choose the next available number
3. Leave gaps (e.g., `001`, `010`, `020`) to allow future insertions

### Step 3: Create the File

```bash
# Navigate to the docs directory
cd docs/

# Create the file with the correct naming pattern
# Example: Adding a new how-to guide
touch 002-how-to-guides/004-deploy-to-production.md
```

### Step 4: Use the Template

Every new documentation file should start with this template:

```markdown
# Document Title

**Type:** [Tutorial | How-To | Reference | Explanation]
**Audience:** [Developers | Contributors | End Users | Architects]
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

Add your new document to `docs/README.md` in the appropriate section.

---

## Content Guidelines

### Writing Style

- **Clear and concise**: Get to the point quickly
- **Active voice**: "Run the command" not "The command should be run"
- **Present tense**: "The function returns" not "The function will return"
- **Professional but approachable**: Avoid jargon when possible
- **No emojis** unless already established in the document style

### Code Blocks

Always specify the language:

````markdown
```r
# R code example
result <- calc_effect_measures(0.15, 0.10)
```

```bash
# Bash command example
docker-compose up --build
```

```python
# Python example
def hello():
    print("Hello, World!")
```
````

### Headers

- Use **sentence case**, not title case
- ✅ "How to add a new analysis type"
- ❌ "How To Add A New Analysis Type"

### Lists

- Use `-` for bullet points (not `*` or `+`)
- Use numbers for ordered lists
- Keep items parallel in structure

### Implementation Plans

When documenting implementation plans or feature roadmaps:

- **Focus on what needs to be done**, not how long it will take
- **Do not include time estimates** (e.g., "2 hours", "1 day", "1 week")
- **Do not include scheduling details** (e.g., "by Friday", "next sprint")
- Keep steps actionable and clear without temporal commitments

**Why?** Time estimates become outdated quickly and add unnecessary detail. We care about the logical sequence of work, not calendar predictions.

✅ **Good:**
- "Implement input validation for sample size calculation"
- "Add unit tests for new effect size functions"

❌ **Avoid:**
- "Implement input validation (2 hours)"
- "Add unit tests by end of week"

---

## Moving or Renaming Files

**IMPORTANT: Use `git mv` to preserve file history**

```bash
# Correct way to move/rename documentation
git mv docs/old-location/file.md docs/###-category/###-new-name.md

# Incorrect way (loses git history)
mv docs/old-location/file.md docs/###-category/###-new-name.md
```

---

## Documentation Workflow

### When Adding Features

1. **Write the code**
2. **Update reference documentation** if APIs changed
3. **Add how-to guide** if new workflows introduced
4. **Update explanation** if design decisions made
5. **Create enhancement report** in `reports/enhancements/`
6. **Update main README.md** if user-facing changes

### When Refactoring

1. **Update reference documentation** if internals changed
2. **Update explanation** if architectural changes made
3. **Create quality report** in `reports/quality/`

### Before Committing

- [ ] Documentation files follow `###-document-name.md` naming
- [ ] New files added to `docs/README.md` index
- [ ] Code examples tested and working
- [ ] Links are relative and working
- [ ] Spell check completed
- [ ] Git history preserved if moving files

---

## Documentation Categories in Detail

### Tutorials (Learning-Oriented)

**Purpose:** Teach through practical lessons

**Characteristics:**
- Hands-on exercises
- Learning by doing
- Step-by-step guidance
- Works toward a working result
- Assumes little prior knowledge

**Example titles:**
- "Your first development session"
- "Building your first analysis tab"
- "Understanding reactive programming with an example"

**Template structure:**
```markdown
# Tutorial: [Title]

## Prerequisites
- List what the learner needs before starting

## Step 1: [First step]
Instructions...

## Step 2: [Second step]
Instructions...

## What You Learned
Summary of skills acquired

## Next Steps
Links to related tutorials or how-to guides
```

---

### How-To Guides (Task-Oriented)

**Purpose:** Solve specific problems

**Characteristics:**
- Goal-oriented
- Assumes user knows what they want to do
- Practical steps without explanation
- Multiple paths to achieve goal acceptable

**Example titles:**
- "How to add a new analysis type"
- "How to deploy to production"
- "How to run tests"

**Template structure:**
```markdown
# How to [Task]

## Goal
What you'll accomplish

## Prerequisites
What you need before starting

## Steps

### 1. [Step description]
```bash
command
```

### 2. [Step description]
Instructions...

## Verification
How to verify success

## Troubleshooting
Common issues and solutions
```

---

### Reference (Information-Oriented)

**Purpose:** Describe technical details

**Characteristics:**
- Dry, factual, comprehensive
- Consistent structure
- No opinions or explanations
- Complete information

**Example titles:**
- "Helper functions API"
- "Configuration file reference"
- "Input naming conventions"

**Template structure:**
```markdown
# [Component] Reference

## Overview
Brief factual description

## [Category 1]

### `function_name(param1, param2)`

**Parameters:**
- `param1` (type): Description
- `param2` (type): Description

**Returns:** Description

**Example:**
```r
result <- function_name(val1, val2)
```

## [Category 2]
...
```

---

### Explanation (Understanding-Oriented)

**Purpose:** Clarify and illuminate

**Characteristics:**
- Discusses alternatives
- Explains "why" not "how"
- Provides context
- Can be opinionated

**Example titles:**
- "Why monolithic app.R structure?"
- "Design decisions for reactive programming"
- "Trade-offs in caching strategies"

**Template structure:**
```markdown
# [Topic] Explanation

## Context
Background and situation

## The Problem
What challenge we faced

## Alternatives Considered

### Option 1: [Name]
**Pros:**
- ...

**Cons:**
- ...

### Option 2: [Name]
...

## Decision
What we chose and why

## Trade-offs
What we gained and what we lost

## Future Considerations
When we might revisit this decision
```

---

## Common Documentation Tasks

### Documenting a New Function

1. Add to **reference/** documentation
2. Include in the appropriate API section
3. Follow the function documentation template

### Documenting a New Feature

1. Update user **README.md** (if user-facing)
2. Add **how-to guide** for using the feature
3. Add **explanation** for design decisions
4. Update **reference** for any new APIs
5. Create **enhancement report** in `reports/enhancements/`

### Documenting a Bug Fix

1. Update **reference** if behavior changed
2. Add **troubleshooting section** to relevant how-to guide
3. Create **quality report** in `reports/quality/` if significant

### Updating for Deprecation

1. Mark deprecated items in **reference** docs
2. Add **migration guide** to how-to-guides/
3. Explain **reasoning** in explanation/
4. Update **examples** to use new approach

---

## Documentation Quality Checklist

Before finalizing documentation:

- [ ] **Accurate**: All information is correct and tested
- [ ] **Complete**: Covers all necessary information
- [ ] **Clear**: Easy to understand for target audience
- [ ] **Consistent**: Follows project style and conventions
- [ ] **Current**: Reflects latest version of code
- [ ] **Findable**: Indexed in docs/README.md
- [ ] **Named correctly**: Follows `###-document-name.md` pattern
- [ ] **Links work**: All relative links are valid
- [ ] **Code tested**: All code examples have been tested

---

## Examples of Good Documentation

### Good Tutorial Example

```markdown
# Tutorial: Your first development session

## Prerequisites
- R ≥ 4.2.0 installed
- Git installed
- Basic R familiarity

## Step 1: Clone the repository

First, clone the project:

```bash
git clone <url>
cd power-analysis-tool
```

You should see these key files:
- app.R - Main application
- renv.lock - Dependencies

## Step 2: Install dependencies
...
```

### Good How-To Example

```markdown
# How to add a new analysis type

## Prerequisites
- Development environment set up
- Familiar with Shiny reactivity

## Steps

### 1. Create UI tab
In app.R, add a new tabPanel:

```r
tabPanel("Power (ANOVA)",
  value = "power_anova",
  # inputs here
)
```
...
```

### Good Reference Example

```markdown
# Helper Functions API

## calc_effect_measures(p1, p2)

Calculates effect measures from two proportions.

**Parameters:**
- `p1` (numeric): Proportion in group 1 (0-1)
- `p2` (numeric): Proportion in group 2 (0-1)

**Returns:** List with three elements:
- `RR` (numeric or NA): Relative Risk
- `OR` (numeric or NA): Odds Ratio
- `RD` (numeric): Risk Difference
...
```

### Good Explanation Example

```markdown
# Why monolithic app.R structure?

## Context
The application is currently ~1,815 lines in a single app.R file.

## The Problem
Should we split into modules or keep monolithic?

## Alternatives Considered

### Option 1: Shiny Modules
**Pros:**
- Better organization
- Reusable components

**Cons:**
- Adds complexity for small app
- Namespace management overhead

### Option 2: Monolithic (chosen)
**Pros:**
- Simple deployment
- Easy to navigate
- Industry standard for <2000 lines

**Cons:**
- May need refactoring if it grows

## Decision
Keep monolithic until app exceeds 2,000 lines.

## Trade-offs
We trade long-term scalability for short-term simplicity...
```

---

## Maintenance

### Regular Reviews

Review documentation quarterly:
- [ ] Remove obsolete content
- [ ] Update for new R/package versions
- [ ] Fix broken links
- [ ] Update examples
- [ ] Check numbering sequence

### Version Updates

When releasing a new version:
- [ ] Update all "Last Updated" dates
- [ ] Create enhancement report
- [ ] Update main README.md
- [ ] Update docs/README.md version history

---

## Resources

### Diataxis Framework
- Website: https://diataxis.fr/
- Tutorials: https://diataxis.fr/tutorials/
- How-to guides: https://diataxis.fr/how-to-guides/
- Reference: https://diataxis.fr/reference/
- Explanation: https://diataxis.fr/explanation/

### Markdown Guide
- Basic syntax: https://www.markdownguide.org/basic-syntax/
- Extended syntax: https://www.markdownguide.org/extended-syntax/

### Writing Style
- Microsoft Writing Style Guide: https://learn.microsoft.com/en-us/style-guide/welcome/
- Google Developer Documentation Style Guide: https://developers.google.com/style

---

## Questions?

If you're unsure about where to put documentation:
1. Check `docs/README.md` for examples
2. Look at existing documentation in each category
3. When in doubt, ask yourself: "What does the user need right now?"
   - To learn? → Tutorial
   - To solve a problem? → How-To
   - To look something up? → Reference
   - To understand why? → Explanation

---

**Last Updated:** 2025-10-24
**Maintained By:** Development Team
**Documentation Framework:** [Diataxis](https://diataxis.fr/)
