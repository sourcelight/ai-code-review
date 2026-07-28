# AI Code Review System - Complete Guide

## 📋 Table of Contents

1. [Introduction](#introduction)
2. [System Architecture](#system-architecture)
3. [Detailed Operational Flow](#detailed-operational-flow)
4. [Review Rules](#review-rules)
5. [Configuration](#configuration)
6. [Practical Examples](#practical-examples)
7. [Troubleshooting](#troubleshooting)

---

## Introduction

The **AI Code Review System** automates code review using **Claude Sonnet 4** by Anthropic. Whenever a Pull Request is created or updated on GitHub, the system:

✅ Analyzes code changes  
✅ Applies specific rules for React, Java, and Security  
✅ Generates a detailed review comment  
✅ Identifies critical, medium, and minor issues  

**Estimated cost:** $0.10 - $0.30 per review

---

## System Architecture

### Overall Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         GITHUB REPOSITORY                        │
│                                                                   │
│  Developer → Push Code → Pull Request Created/Updated            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Trigger
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS WORKFLOW                     │
│                  (.github/workflows/ai-review.yml)               │
│                                                                   │
│  Step 1: Checkout code                                           │
│  Step 2: Calculate diff (changes vs base branch)                │
│  Step 3: Load review rules                                      │
│  Step 4: Call Anthropic API with Claude                         │
│  Step 5: Post review comment                                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ API Call
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ANTHROPIC CLAUDE API                        │
│                     (claude-sonnet-4-6)                          │
│                                                                   │
│  Receives: Diff + Review Rules                                   │
│  Analyzes: Code according to guidelines                          │
│  Returns: Structured markdown review                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Response
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PULL REQUEST COMMENT                          │
│                                                                   │
│  🤖 AI Code Review                                               │
│  ├─ Overall Assessment                                           │
│  ├─ Critical Issues                                              │
│  ├─ Medium Issues                                                │
│  ├─ Minor Issues                                                 │
│  ├─ Suggested Improvements                                       │
│  └─ Positive Observations                                        │
└─────────────────────────────────────────────────────────────────┘
```

### Core Components

```
Repository Structure:
│
├── .github/
│   ├── workflows/
│   │   ├── ai-review.yml              ← Main workflow (ACTIVE)
│   │   └── ai-review-debug.yml        ← Debug workflow (manual only)
│   │
│   └── ai-review/                      ← Review rules
│       ├── react-review.md            ← React/TypeScript rules
│       ├── java-review.md             ← Java/Spring Boot rules
│       └── security-review.md         ← OWASP security rules
│
├── backend/                            ← Java code to review
├── frontend/                           ← React code to review
└── CLAUDE.md                           ← Project documentation
```

---

## Detailed Operational Flow

### Step 1: Workflow Trigger

```
Developer Actions                    GitHub Actions Trigger
─────────────────                    ──────────────────────

git checkout -b feature/new-feature
git add .
git commit -m "Add feature X"
git push origin feature/new-feature
                                     
Opens Pull Request on GitHub    →    workflow: ai-review.yml
                                     trigger: pull_request
                                     types: [opened, synchronize, reopened]
```

**Events that trigger the workflow:**
- `opened` - PR just created
- `synchronize` - New commits pushed to the PR
- `reopened` - PR reopened after being closed

### Step 2: Checkout and Diff Calculation

```yaml
# Workflow step: Get PR diff

┌──────────────────────────────────────┐
│  git fetch origin main               │  ← Fetch base branch
│  git diff origin/main...HEAD         │  ← Calculate differences
└──────────────────────────────────────┘
                 │
                 ▼
         ┌──────────────┐
         │  DIFF OUTPUT │
         └──────────────┘
                 │
                 ▼
    +++ frontend/src/Login.tsx
    @@ -15,6 +15,10 @@
    +  const [error, setError] = useState('');
    +  
    +  if (!email) {
    +    setError('Email required');
    +  }
```

**What the diff contains:**
- Modified files
- Lines added (+)
- Lines removed (-)
- Change context

### Step 3: Loading Rules

```
Rule Files                          Loading into Memory
──────────                          ───────────────────

react-review.md     →  REACT_RULES     (environment variable)
java-review.md      →  JAVA_RULES      (environment variable)
security-review.md  →  SECURITY_RULES  (environment variable)
```

**Structure of a rule (example):**

```markdown
## Error Handling

### What to check:
- [ ] Try-catch blocks around async calls
- [ ] User-friendly error messages
- [ ] Loading states managed

### Correct Example:
```typescript
try {
  const data = await api.get('/endpoint');
  setData(data);
} catch (error) {
  setError('Unable to load data');
}
```

### Step 4: Building the Prompt for Claude

```
┌────────────────────────────────────────────────────────────────┐
│                      COMPLETE PROMPT                            │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  "You are an expert code reviewer."                             │
│                                                                  │
│  ## React Frontend Review Guidelines                            │
│  [Contents of react-review.md]                                 │
│                                                                  │
│  ## Java Backend Review Guidelines                              │
│  [Contents of java-review.md]                                  │
│                                                                  │
│  ## Security Review Guidelines                                  │
│  [Contents of security-review.md]                              │
│                                                                  │
│  ## Pull Request Diff                                           │
│  ```diff                                                        │
│  [Git diff output]                                              │
│  ```                                                            │
│                                                                  │
│  Please provide review in this format:                          │
│  - Overall Assessment                                           │
│  - Critical Issues                                              │
│  - Medium Issues                                                │
│  - Minor Issues                                                 │
│  - Suggested Improvements                                       │
│  - Positive Observations                                        │
└────────────────────────────────────────────────────────────────┘
```

### Step 5: Anthropic API Call

```
Request                                Response
───────                                ────────

POST https://api.anthropic.com/v1/messages
Headers:
  - content-type: application/json
  - x-api-key: [ANTHROPIC_API_KEY]
  - anthropic-version: 2023-06-01

Body:                                  {
{                                        "id": "msg_...",
  "model": "claude-sonnet-4-6",         "type": "message",
  "max_tokens": 4096,                   "content": [{
  "messages": [{                          "type": "text",
    "role": "user",                       "text": "# Code Review Summary\n\n
    "content": "[prompt]"                          ## Overall Assessment\n
  }]                                               The changes improve..."
}                                       }]
                                      }
                                      
                                      ↓
                                      
                            Extract review text
                            using jq: .content[0].text
```

### Step 6: Publishing Comment

```
Review Text                         GitHub Comment API
───────────                         ──────────────────

# Code Review Summary              POST /repos/{owner}/{repo}/issues/{pr_number}/comments
                                   
## Overall Assessment      →       Body: "🤖 AI Code Review\n\n[review_text]"
[...]                              
                                   Result: Comment posted on PR
## Critical Issues                 visible to all team members
[...]
```

---

## Review Rules

### How Rules Work

Rules are **Markdown files** that instruct Claude on what to verify. Claude reads these rules before analyzing the code.

```
┌─────────────────────┐
│   DEVELOPER WRITES  │
│   CUSTOM RULES      │
│   IN .md FILES      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  WORKFLOW LOADS     │
│  RULES INTO MEMORY  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  CLAUDE APPLIES     │
│  RULES TO CODE      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  REPORT GENERATED   │
│  FOLLOWING RULES    │
└─────────────────────┘
```

### Rule Structure

#### 1. **React Review** (`.github/ai-review/react-review.md`)

```markdown
# React/TypeScript Best Practices

## 1. Hooks Usage
- Verify useState/useEffect are used correctly
- Check dependency arrays
- Avoid conditional hooks

## 2. Type Safety
- All props must have TypeScript types
- Avoid 'any' type
- Use interfaces for complex objects

## 3. Error Handling
- Try-catch for async operations
- Error state management in UI
- Loading states for API fetches
```

#### 2. **Java Review** (`.github/ai-review/java-review.md`)

```markdown
# Java/Spring Boot Best Practices

## 1. Dependency Injection
- Use constructor injection (NO @Autowired on fields)
- Prefer final for dependencies

## 2. Business Logic
- Business logic only in services
- Controllers must be thin
- Use DTOs for API contracts

## 3. SOLID Principles
- Single Responsibility
- Open/Closed Principle
- Dependency Inversion
```

#### 3. **Security Review** (`.github/ai-review/security-review.md`)

```markdown
# Security Best Practices (OWASP)

## 1. Injection Attacks
- SQL Injection: use prepared statements
- XSS: sanitize user input
- Command Injection: validate parameters

## 2. Authentication
- JWT token validation
- Password hashing with BCrypt
- Secure session management

## 3. Secrets Management
- NO hardcoded API keys
- Use environment variables
- NO secrets in repository
```

### Customizing Rules

**Example: Adding a new rule**

```markdown
<!-- Edit: .github/ai-review/java-review.md -->

## Logging Standards

### What to check:
- [ ] Use SLF4J as logging facade
- [ ] Appropriate log level (DEBUG, INFO, WARN, ERROR)
- [ ] NO System.out.println in production
- [ ] Log exceptions with stack trace

### Example:
```java
// ❌ WRONG
System.out.println("User logged in: " + userId);

// ✅ CORRECT
log.info("User logged in: {}", userId);
```
```

**Changes take effect immediately** on the next PR!

---

## Configuration

### Prerequisites

#### 1. Anthropic API Key

```
Step 1: Sign up at console.anthropic.com
Step 2: Navigate to API Keys
Step 3: Create a new key (sk-ant-api03-...)
Step 4: Copy the key (108 characters)
```

#### 2. GitHub Secrets Configuration

```
GitHub Repository
  └── Settings
      └── Secrets and variables
          └── Actions
              └── New repository secret
                  ├─ Name: ANTHROPIC_API_KEY
                  └─ Value: [your API key]
```

#### 3. GitHub Actions Permissions

```
Repository Settings
  └── Actions
      └── General
          └── Workflow permissions
              ├─ ✅ Read and write permissions
              └─ ✅ Allow GitHub Actions to create and approve pull requests
```

### Configuration Files

**`.github/workflows/ai-review.yml`** (main workflow)

```yaml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  pull-requests: write
  contents: read

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
      - name: Get PR diff
      - name: Load review rules
      - name: Run AI Code Review
      - name: Post review comment
```

---

## Practical Examples

### Example 1: Feature Branch with Security Bug

**Code in PR:**

```java
// backend/src/main/java/com/example/UserController.java
@GetMapping("/user/{id}")
public User getUser(@PathVariable String id) {
    String query = "SELECT * FROM users WHERE id = " + id; // ❌ SQL Injection!
    return jdbcTemplate.queryForObject(query, User.class);
}
```

**AI Review Generated:**

```markdown
## 🤖 AI Code Review

### Overall Assessment
The PR introduces a critical SQL Injection vulnerability in the getUser method.

### Critical Issues ⚠️

#### 1. SQL Injection Vulnerability (UserController.java:15)
**Issue:** Direct concatenation of user parameter in SQL query
**Risk:** An attacker can execute arbitrary SQL queries
**Suggested Fix:**
```java
@GetMapping("/user/{id}")
public User getUser(@PathVariable Long id) {
    String query = "SELECT * FROM users WHERE id = ?";
    return jdbcTemplate.queryForObject(query, User.class, id);
}
```

### Positive Observations ✅
- Correct use of @PathVariable
- Controller/service separation respected
```

### Example 2: React Frontend with Type Safety Issues

**Code in PR:**

```typescript
// frontend/src/components/UserProfile.tsx
export const UserProfile = ({ user }: any) => {  // ❌ any type
  const [data, setData] = useState();  // ❌ type not specified
  
  useEffect(() => {
    fetch('/api/user')
      .then(res => res.json())
      .then(data => setData(data));  // ❌ no error handling
  }, []);  // ✅ dependency array ok
  
  return <div>{user.name}</div>;
}
```

**AI Review Generated:**

```markdown
## 🤖 AI Code Review

### Medium Issues ⚠️

#### 1. Type Safety - any type usage (UserProfile.tsx:1)
**Issue:** Props defined with `any` lose TypeScript benefits
**Suggested Fix:**
```typescript
interface UserProfileProps {
  user: {
    name: string;
    email: string;
  };
}

export const UserProfile = ({ user }: UserProfileProps) => {
```

#### 2. Missing useState type (UserProfile.tsx:2)
**Issue:** `useState()` without explicit type
**Suggested Fix:**
```typescript
const [data, setData] = useState<User | null>(null);
```

#### 3. No error handling (UserProfile.tsx:5)
**Issue:** Fetch without error handling
**Suggested Fix:**
```typescript
try {
  const res = await fetch('/api/user');
  if (!res.ok) throw new Error('Failed to fetch');
  const data = await res.json();
  setData(data);
} catch (error) {
  setError('Unable to load user data');
}
```
```

### Example 3: Complete Workflow Timeline

```
┌──────────────────────────────────────────────────────────────────┐
│  COMPLETE PR REVIEW TIMELINE                                      │
└──────────────────────────────────────────────────────────────────┘

10:00:00  Developer: git push origin feature/auth-fix
10:00:05  GitHub: PR #42 created
10:00:06  GitHub Actions: Workflow 'AI Code Review' triggered
10:00:10  GitHub Actions: Checkout completed
10:00:12  GitHub Actions: Diff calculated (2.5 KB)
10:00:13  GitHub Actions: Rules loaded (12 KB total)
10:00:15  GitHub Actions: Calling Anthropic API...
10:00:35  Anthropic: Review generated (4.2 KB)
10:00:36  GitHub Actions: Review extracted with jq
10:00:38  GitHub Actions: Comment posted on PR #42
10:00:39  Developer: Notification received - "🤖 AI Code Review posted"

TOTAL TIME: ~40 seconds
COST: ~$0.15
```

---

## Troubleshooting

### Problem 1: Workflow Doesn't Start

**Symptoms:**
- PR created but no workflow in Actions tab
- Actions tab is empty

**Diagnosis:**
```bash
# Verify workflow file exists
ls .github/workflows/ai-review.yml

# Verify it's in the main branch
git branch
git checkout main
git log --oneline .github/workflows/ai-review.yml
```

**Solution:**
```bash
# The workflow must be in the main branch to activate
git checkout main
git add .github/workflows/ai-review.yml
git commit -m "Add AI review workflow"
git push origin main
```

### Problem 2: "ANTHROPIC_API_KEY not set"

**Symptoms:**
```
ERROR: ANTHROPIC_API_KEY is not set
Error: Process completed with exit code 1.
```

**Solution:**
```
1. Go to: Repository → Settings → Secrets and variables → Actions
2. Click: "New repository secret"
3. Name: ANTHROPIC_API_KEY
4. Value: sk-ant-api03-... (your complete key, 108 characters)
5. Click: "Add secret"
6. Re-run the workflow
```

### Problem 3: "Permission denied" when posting comment

**Symptoms:**
```
Error: Resource not accessible by integration
RequestError: Bad credentials
```

**Solution:**
```
Settings → Actions → General → Workflow permissions
  
  ○ Read repository contents and packages permissions
  ● Read and write permissions  ← Select this
  
  ☑ Allow GitHub Actions to create and approve pull requests
```

### Problem 4: Empty or "null" review

**Symptoms:**
- Workflow completes successfully
- But comment contains "null" or is empty

**Diagnosis:**
```yaml
# Check workflow logs for step "Run AI Code Review"
# Look for these lines:
Review extracted successfully (0 characters)  ← Problem!
# Should be:
Review extracted successfully (4521 characters)  ← OK
```

**Solution:**
```bash
# Verify rule file format
cat .github/ai-review/react-review.md

# Ensure files are not empty
ls -lh .github/ai-review/

# If files are corrupted, restore them
git checkout main -- .github/ai-review/
```

### Problem 5: "invalid x-api-key"

**Symptoms:**
```
ERROR: API returned error type: authentication_error
Error message: invalid x-api-key
```

**Most common causes:**
- API key copied incorrectly (107 characters instead of 108)
- Extra spaces at beginning/end
- Expired or revoked key

**Solution:**
```bash
# Test key locally
$apiKey = "sk-ant-api03-..."
Write-Host "Key length: $($apiKey.Length) characters"
# Must be exactly 108 characters

# Test the key
curl -H "x-api-key: $apiKey" `
     -H "anthropic-version: 2023-06-01" `
     https://api.anthropic.com/v1/models

# If you get an error, the key is invalid
# Generate a new key at console.anthropic.com
```

### Problem 6: Workflow Too Slow (> 2 minutes)

**Possible causes:**
- Very large diff (>100 KB)
- Very long rules
- Anthropic API overloaded

**Optimizations:**
```yaml
# Limit analyzed files
on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - 'backend/**'
      - 'frontend/**'
      - '!**/*.md'  # Exclude markdown
      - '!**/test/**'  # Exclude tests

# Reduce max_tokens if reviews are too long
max_tokens: 2048  # instead of 4096
```

---

## Monitoring and Costs

### API Usage Dashboard

Monitor costs at: [console.anthropic.com](https://console.anthropic.com)

```
Dashboard
  └── Usage
      ├── Tokens Used
      │   ├─ Input: ~5,000 tokens per review
      │   └─ Output: ~1,500 tokens per review
      │
      └── Costs
          ├─ Input: $3 / 1M tokens
          ├─ Output: $15 / 1M tokens
          └─ Average per review: ~$0.15
```

### Monthly Cost Estimates

```
Scenario 1: Small team (10 PRs/month)
  10 PRs × $0.15 = $1.50/month

Scenario 2: Medium team (50 PRs/month)
  50 PRs × $0.15 = $7.50/month

Scenario 3: Large team (200 PRs/month)
  200 PRs × $0.15 = $30/month
```

---

## Best Practices

### 1. Keep Rules Updated

```bash
# Monthly, review the rules
cd .github/ai-review

# Add new patterns discovered during manual code reviews
# Remove obsolete rules
# Update examples with real code from the project
```

### 2. Combine AI Review + Human Review

```
┌────────────────────┐
│   AI Review        │  ← First pass: find common issues
│   (automated)      │     (security, type safety, best practices)
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   Human Review     │  ← Second pass: business logic,
│   (manual)         │     architecture, edge cases
└────────────────────┘
```

### 3. Iterate on Rules

```markdown
<!-- Start with simple rules -->
## Error Handling
- Verify try-catch blocks

<!-- Add details over time -->
## Error Handling
- Try-catch for async operations
- Error boundaries in React
- Error logging
- Retry logic for network failures
- Fallback UI for critical errors
```

### 4. Feedback Loop

```
Developer reads AI review
    ↓
Identifies false positives
    ↓
Updates rules to be more specific
    ↓
AI review improves on subsequent PRs
```

---

## Conclusion

The AI Code Review system automates code review by applying customizable rules through Claude Sonnet 4 by Anthropic.

**Benefits:**
✅ Automatic and immediate review  
✅ Consistency in code reviews  
✅ Team time savings  
✅ Catches common issues before human review  
✅ Customizable rules for your project  

**Complete flow:**
```
Push → PR → Workflow → Diff → Rules → Claude → Review → Comment
```

**Key files:**
- `.github/workflows/ai-review.yml` - Orchestration
- `.github/ai-review/*.md` - Customizable rules
- `ANTHROPIC_API_KEY` - API authentication

**Next steps:**
1. Test with a trial PR
2. Customize rules for your team
3. Monitor costs at console.anthropic.com
4. Iterate on rules based on feedback

---

**Questions? Issues?** Check the [Troubleshooting](#troubleshooting) section or review the logs on GitHub Actions.
