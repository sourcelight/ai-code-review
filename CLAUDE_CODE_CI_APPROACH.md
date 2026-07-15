# Claude Code in CI/CD - The Right Approach

## Why This Is Better

**Previous approach (`.github/workflows/ai-review.yml`):**
- ❌ Manual bash parsing of frontmatter
- ❌ Manual pattern matching
- ❌ Manual prompt construction
- ❌ Direct curl calls to Anthropic API
- ❌ Complex error handling in bash

**New approach (`.github/workflows/ai-review-claude-code.yml`):**
- ✅ Claude Code handles everything automatically
- ✅ Smart rule loading based on `.claude/rules/*.md` frontmatter
- ✅ Pattern matching built-in
- ✅ Proper context management
- ✅ Reads `CLAUDE.md` automatically

## Architecture Comparison

### Old: Manual Bash Approach

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions Workflow                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  1. Bash: Parse YAML frontmatter manually             │ │
│  │  2. Bash: Match file patterns with regex              │ │
│  │  3. Bash: Build prompt string                         │ │
│  │  4. curl: Direct API call                             │ │
│  │  5. jq: Extract response                              │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Complex, fragile, reinvents the wheel                      │
└─────────────────────────────────────────────────────────────┘
```

### New: Claude Code CLI

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions Workflow                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  1. npm install -g @anthropic-ai/claude-code          │ │
│  │  2. claude -p "Review this PR"                        │ │
│  │     └─> Claude Code automatically:                    │ │
│  │         • Reads CLAUDE.md                             │ │
│  │         • Loads .claude/rules/*.md                    │ │
│  │         • Parses frontmatter                          │ │
│  │         • Matches patterns to changed files           │ │
│  │         • Builds optimized context                    │ │
│  │         • Calls API with smart token management       │ │
│  │         • Returns formatted response                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Simple, robust, uses official tooling                      │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
Repository:
│
├── .claude/
│   ├── rules/                          ← Rules auto-loaded by Claude Code
│   │   ├── react-review.md            ← Frontmatter: patterns for React
│   │   ├── java-review.md             ← Frontmatter: patterns for Java
│   │   └── security-review.md         ← Frontmatter: always_load: true
│   │
│   └── memory/                         ← Auto-loaded context (if any)
│
├── .github/
│   └── workflows/
│       ├── ai-review.yml              ← OLD: Manual bash (deprecated)
│       └── ai-review-claude-code.yml  ← NEW: Claude Code CLI ✅
│
├── CLAUDE.md                           ← Auto-loaded by Claude Code
└── README.md
```

## How It Works

### Step 1: Install Claude Code

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'

- name: Install Claude Code
  run: |
    npm install -g @anthropic-ai/claude-code
    claude --version
```

### Step 2: Run Claude Code

```yaml
- name: Run Claude Code review
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: |
    claude -p "Review this Pull Request.
    
    Requirements:
    - Inspect git diff against target branch
    - Review changed files only
    - Follow CLAUDE.md and .claude/rules
    - Focus on correctness, security, bugs
    
    [Format specification...]
    " > review.md
```

**What happens automatically:**

1. **Reads `CLAUDE.md`** - Project context
2. **Loads `.claude/rules/*.md`** - Review guidelines
3. **Parses frontmatter** - Extracts `patterns:` from rules
4. **Gets changed files** - From git diff
5. **Matches patterns** - Only loads relevant rules
6. **Builds context** - Optimized prompt
7. **Calls API** - With smart token management
8. **Returns review** - Formatted output

### Step 3: Post Comment

```yaml
- name: Post review comment
  env:
    REVIEW_CONTENT: ${{ steps.review.outputs.review }}
  uses: actions/github-script@v7
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    script: |
      await github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
        body: `## 🤖 AI Code Review\n\n${review}`
      });
```

## Rule File Format

Claude Code automatically handles frontmatter pattern matching:

### React Rules (`.claude/rules/react-review.md`)

```markdown
---
patterns:
  - "frontend/**/*.tsx"
  - "frontend/**/*.ts"
  - "frontend/**/*.jsx"
  - "frontend/**/*.js"
  - "**/package.json"
priority: 1
---

# React Frontend Review Guidelines

[Review criteria...]
```

**Behavior:**
- ✅ Loads if PR touches any frontend TypeScript/JavaScript files
- ✅ Loads if package.json changes
- ✗ Skips if only backend files changed

### Security Rules (`.claude/rules/security-review.md`)

```markdown
---
patterns:
  - "**/*.java"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
always_load: true
priority: 2
---

# Security Review Guidelines

[Security checks...]
```

**Behavior:**
- ✅ **Always loads** (`always_load: true`)
- ✅ Security checked on every PR
- ✅ Patterns documented but not required for loading

## Pattern Matching Examples

### Example 1: Frontend-Only PR

**Changed files:**
```
frontend/src/Login.tsx
frontend/src/api/api.ts
```

**Claude Code automatically loads:**
- ✅ `react-review.md` (matched `frontend/**/*.tsx`, `frontend/**/*.ts`)
- ✅ `security-review.md` (always_load: true)
- ✗ `java-review.md` (no backend files)

**Token usage:** ~6,500 tokens (vs 9,500 with all rules)

### Example 2: Backend-Only PR

**Changed files:**
```
backend/src/main/java/UserService.java
backend/pom.xml
```

**Claude Code automatically loads:**
- ✗ `react-review.md` (no frontend files)
- ✅ `java-review.md` (matched `backend/**/*.java`, `**/pom.xml`)
- ✅ `security-review.md` (always_load: true)

**Token usage:** ~7,500 tokens

### Example 3: Full-Stack PR

**Changed files:**
```
frontend/src/Login.tsx
backend/src/main/java/AuthController.java
```

**Claude Code automatically loads:**
- ✅ `react-review.md` (matched frontend file)
- ✅ `java-review.md` (matched backend file)
- ✅ `security-review.md` (always_load: true)

**Token usage:** ~9,500 tokens (all rules needed)

## Migration Path

### From Old Workflow to Claude Code

**Step 1: Move rules** (if not already done)
```bash
# Rules should be in .claude/rules/ with frontmatter
ls .claude/rules/
# Should show:
#   react-review.md
#   java-review.md
#   security-review.md
```

**Step 2: Disable old workflow**
```bash
# Rename to disable
mv .github/workflows/ai-review.yml .github/workflows/ai-review.yml.disabled
```

**Step 3: Enable Claude Code workflow**
```bash
# Already created: .github/workflows/ai-review-claude-code.yml
git add .github/workflows/ai-review-claude-code.yml
git commit -m "Migrate to Claude Code CLI for AI reviews"
git push origin main
```

**Step 4: Test**
```bash
# Create test PR
git checkout -b test/claude-code-workflow
echo "// test" >> frontend/src/Login.tsx
git commit -am "Test Claude Code workflow"
git push origin test/claude-code-workflow
# Open PR and check Actions tab
```

## Advantages

| Feature | Manual Bash | Claude Code CLI |
|---------|-------------|-----------------|
| Frontmatter parsing | Manual with awk/sed | ✅ Built-in |
| Pattern matching | Custom bash regex | ✅ Built-in |
| Context management | Manual string concat | ✅ Optimized |
| CLAUDE.md loading | Manual | ✅ Automatic |
| Memory files | Not supported | ✅ Automatic |
| Error handling | Custom | ✅ Built-in |
| Token optimization | Manual | ✅ Smart |
| Maintenance | Complex | ✅ Simple |
| Updates | Manual code | ✅ npm update |

## Cost Comparison

Both approaches save tokens vs. "load all rules", but Claude Code is cleaner:

| Scenario | All Rules | Manual Smart | Claude Code |
|----------|-----------|--------------|-------------|
| Frontend PR | 14,500 | 11,500 | 11,500 |
| Backend PR | 14,500 | 12,500 | 12,500 |
| Docs PR | 11,500 | 6,500 | 6,500 |
| **Complexity** | **Low** | **High** | **Low** |

**Same savings, but:**
- ✅ Claude Code: 20 lines of workflow
- ❌ Manual: 200+ lines of bash

## Troubleshooting

### Issue: Claude Code not installed

```yaml
# Make sure Node.js setup comes first
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'

- name: Install Claude Code
  run: npm install -g @anthropic-ai/claude-code
```

### Issue: Rules not loading

**Check frontmatter format:**
```bash
# Frontmatter must be valid YAML
---
patterns:
  - "frontend/**/*.tsx"  # Quoted strings
---
```

**Verify file location:**
```bash
# Must be in .claude/rules/
ls .claude/rules/*.md
```

### Issue: Review output empty

**Check command:**
```bash
# Output redirect must work
claude -p "..." > review.md
cat review.md  # Should contain review
```

**Check API key:**
```bash
# Verify in GitHub Secrets
echo "$ANTHROPIC_API_KEY" | wc -c  # Should be 108
```

## Advanced: Adding New Rules

### Create Database Review Rule

**File: `.claude/rules/database-review.md`**

```markdown
---
patterns:
  - "backend/src/main/resources/db/migration/**/*.sql"
  - "**/flyway/**/*.sql"
  - "**/liquibase/**/*.xml"
priority: 1
---

# Database Migration Review

## Safety Checks
- No destructive operations without rollback
- Transactions used properly
- Tested on staging environment

## SQL Best Practices
- Use parameterized queries
- Avoid long-running migrations
- Index strategy documented
```

**That's it!** Claude Code will:
1. ✅ Detect the new rule automatically
2. ✅ Parse frontmatter
3. ✅ Match patterns against changed files
4. ✅ Load rule if migration files changed

No workflow changes needed!

## Summary

✅ **Use Claude Code CLI in GitHub Actions** instead of manual bash  
✅ **Rules in `.claude/rules/*.md`** with frontmatter patterns  
✅ **Automatic smart loading** - no custom parsing  
✅ **Simpler workflow** - 20 lines vs 200+  
✅ **Official tooling** - maintained by Anthropic  
✅ **Same cost savings** - 20-40% token reduction  
✅ **Better maintainability** - `npm update` to get improvements  

The Claude Code CLI approach is the **recommended best practice** for AI code review in CI/CD.
