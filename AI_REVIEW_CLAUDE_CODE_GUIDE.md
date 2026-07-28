# AI Code Review System (Claude Code) - Complete Guide

> **Companion document.** This guide describes the **Claude Code CLI** implementation of the
> AI review system, using **structured JSON output** validated against a schema.
> For the original **direct Anthropic API** implementation (raw `curl` to `/v1/messages`),
> see [`AI_REVIEW_COMPLETE_GUIDE.md`](./AI_REVIEW_COMPLETE_GUIDE.md).
> A side-by-side comparison is in [Direct API vs Claude Code](#direct-api-vs-claude-code).

## 📋 Table of Contents

1. [Introduction](#introduction)
2. [Direct API vs Claude Code](#direct-api-vs-claude-code)
3. [System Architecture](#system-architecture)
4. [Detailed Operational Flow](#detailed-operational-flow)
5. [Structured Output Schema](#structured-output-schema)
6. [Review Rules & Smart Loading](#review-rules--smart-loading)
7. [Configuration](#configuration)
8. [Model & Rate Limits (Important)](#model--rate-limits-important)
9. [Practical Examples](#practical-examples)
10. [Troubleshooting](#troubleshooting)
11. [Monitoring and Costs](#monitoring-and-costs)
12. [Best Practices](#best-practices)

---

## Introduction

The **AI Code Review System (Claude Code)** automates code review using the **Claude Code CLI**
(`claude`) running inside GitHub Actions. Whenever a Pull Request is created or updated, the system:

✅ Installs the Claude Code CLI on the runner
✅ Lets Claude **autonomously explore the repo** (git diff, read files, grep) as an agent
✅ **Automatically loads `CLAUDE.md`** and the matching `.claude/rules/*.md` files
✅ Emits a **structured JSON review** validated against `review-schema.json`
✅ Renders a **summary comment** + **inline comments** anchored to `file:line`
✅ **Gates the PR** (fails the check) based on severity / recommendation

**Two key differences from the direct-API version:**
1. **Agentic** — instead of us pasting the diff + all rules into a `curl` payload, Claude Code runs
   `git diff` itself, reads only the changed files, and pulls in the relevant rules on its own.
2. **Structured output** — instead of free-form markdown, the reviewer returns machine-readable JSON.
   That JSON drives inline comments, a summary table, and an automated merge gate.

**Estimated cost:** ~$0.10 - $0.40 per review (higher than direct API because the agent sends more
context — system prompt + tool definitions + files it reads).

---

## Direct API vs Claude Code

| Aspect | Direct API (`ai-review-debug.yml`) | Claude Code (`ai-review-claude-code.yml`) |
|---|---|---|
| **How it calls Claude** | `curl` → `https://api.anthropic.com/v1/messages` | `claude -p "..."` CLI in headless mode |
| **Who builds the diff** | Workflow runs `git diff`, injects into prompt | **Claude runs `git diff` itself** (agentic) |
| **Who loads the rules** | Workflow `cat`s each `.md` into env vars | **Claude auto-loads** `CLAUDE.md` + `.claude/rules/*.md` |
| **File reading** | Only sees the diff text you pasted | Can **open any file** in the repo for context |
| **Output format** | Free-form markdown text | **Structured JSON** validated against a schema |
| **Comment style** | One markdown issue comment | Summary comment **+ inline `file:line` comments** |
| **Merge gating** | None | Fails the check on `critical` / `request_changes` |
| **Model selection** | Explicit in JSON payload (`"model": "..."`) | **Must be pinned** with `--model` (else uses CLI default) |
| **Prompt size (input tokens)** | Small (just rules + diff) | Large (system prompt + tool schemas + files) |
| **Rate-limit sensitivity** | Low | **High** — see [Model & Rate Limits](#model--rate-limits-important) |

**Bottom line:** the direct API is cheaper and simpler; Claude Code is more capable (real repo
exploration, smart rule loading, structured/inline output, automated gating) but sends far more input
tokens, which makes the **choice of model and its per-minute rate limit critical**.

---

## System Architecture

### Overall Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         GITHUB REPOSITORY                        │
│  Developer → Push Code → Pull Request Created/Updated            │
└────────────────────────────┬────────────────────────────────────┘
                             │ Trigger (pull_request)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS WORKFLOW                     │
│           (.github/workflows/ai-review-claude-code.yml)          │
│                                                                   │
│  1: Checkout (fetch-depth: 0)                                    │
│  2: Setup Node.js 20                                             │
│  3: Install Claude Code CLI                                      │
│  4: Verify Claude Code (claude --version)                       │
│  5: Smoke test (minimal prompt, no tools)                       │
│  6: Run review → JSON → validate against schema                 │
│  7: Post summary + inline comments, gate the PR                 │
└────────────────────────────┬────────────────────────────────────┘
                             │ claude -p "..." --model claude-sonnet-5
                             │            --output-format json
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        CLAUDE CODE CLI                           │
│                    (agent, model: Sonnet 5)                      │
│                                                                   │
│  • Reads CLAUDE.md automatically                                │
│  • Runs `git diff` against base branch (Bash tool)             │
│  • Reads changed files (Read tool)                              │
│  • Loads matching .claude/rules/*.md (smart loading)           │
│  • Reads review-schema.json and emits conforming JSON           │
└────────────────────────────┬────────────────────────────────────┘
                             │ envelope JSON  →  .structured_output
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              EXTRACTION  (workflow, on the runner)               │
│  • --json-schema constrains the answer NATIVELY (Anthropic       │
│    structured outputs) → guaranteed schema-conformant             │
│  • jq: pull the object from `.structured_output`                 │
│  • node: cross-field checks (counts match, end_line >= line)   │
└────────────────────────────┬────────────────────────────────────┘
                             │ review.json (validated)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              PULL REQUEST OUTPUT  (github-script)                │
│                                                                   │
│  🤖 Summary comment: assessment · verdict · findings table      │
│  💬 Inline comments: one per finding, anchored to file:line     │
│  🚦 Gate: check fails if critical > 0 or request_changes         │
└─────────────────────────────────────────────────────────────────┘
```

### Core Components

```
Repository Structure:
│
├── .github/
│   └── workflows/
│       ├── ai-review-claude-code.yml   ← Claude Code workflow (ACTIVE)
│       ├── ai-review-debug.yml         ← Direct-API debug workflow (manual only)
│       └── ci.yml                      ← Build/test CI
│
├── .claude/
│   ├── rules/                          ← Review rules (auto-loaded by Claude Code)
│   │   ├── react-review.md            ← React/TypeScript rules
│   │   ├── java-review.md             ← Java/Spring Boot rules
│   │   └── security-review.md         ← OWASP security rules (always loaded)
│   └── settings.local.json            ← Local dev permissions (gitignored)
│
├── review-schema.json                  ← JSON Schema the review output must satisfy
├── backend/                            ← Java code to review
├── frontend/                           ← React code to review
└── CLAUDE.md                           ← Project docs + review instructions (auto-loaded)
```

> **Note:** Unlike the direct-API version (which reads rules from `.github/ai-review/`), Claude Code
> reads rules from **`.claude/rules/`** and the project **`CLAUDE.md`** — the standard Claude Code
> convention. It also reads **`review-schema.json`** to shape its output.

---

## Detailed Operational Flow

### Step 1: Workflow Trigger

```
Developer Actions                    GitHub Actions Trigger
─────────────────                    ──────────────────────
git push origin feature/new-feature
Opens Pull Request on GitHub    →    workflow: ai-review-claude-code.yml
                                     trigger: pull_request
                                     types: [opened, synchronize, reopened]
```

### Step 2: Environment Setup (Node + Claude Code)

```yaml
- uses: actions/setup-node@v4
  with: { node-version: '20' }        # Node is also used later for the cross-field check
- name: Install Claude Code
  run: curl -fsSL https://claude.ai/install.sh | bash
- name: Verify Claude Code
  run: claude --version
```

### Step 3: Smoke Test (fail fast)

A **minimal** call proves install + auth + model access work before the expensive review. If it
fails, the problem is setup/auth/model — not the review prompt or the diff.

```yaml
OUT=$(claude -p "Reply with the single word: OK" \
      --model claude-sonnet-5 --output-format text 2>smoke-err.log)
```

### Step 4: The Agentic Review (native structured output)

We give Claude Code **instructions** (not a pre-built prompt) and constrain its answer to
`review-schema.json` with the **`--json-schema`** flag. This uses Anthropic **structured outputs**:
Claude's final answer is forced to conform to the schema — no "please output only JSON" begging, no
fence-stripping, no external validator needed.

```yaml
claude -p "Review this Pull Request.
  - Inspect the git diff against origin/$BASE_REF; review changed files only.
  - Follow CLAUDE.md and apply .claude/rules/*.md (smart pattern matching).
  - For every finding set 'file' (repo-relative) and 'line' (1-indexed, NEW file).
  - Set summary.counts to the exact number of findings at each severity.
  - Set summary.recommendation: request_changes if any critical, else comment, else approve." \
  --model claude-sonnet-5 \
  --allowedTools "Bash,Read,Grep,Glob" \
  --permission-mode bypassPermissions \
  --output-format json \
  --json-schema "$(cat review-schema.json)" \
  > out.json 2> claude-error.log
```

**What each critical flag does:**

```
--model claude-sonnet-5        Pin the model. NEVER rely on the CLI default (it may pick
                               Opus 4.x, rate-limited to 10k ITPM in this workspace → 429).
--allowedTools "Bash,Read,     Grant the exact tools the agent needs:
   Grep,Glob"                    Bash → git diff · Read → open files · Grep/Glob → search.
--permission-mode              Headless CI can't answer permission prompts; this lets the
   bypassPermissions             agent use its tools unattended. (Safe: throwaway runner.)
--output-format json           Wrap the result in a JSON envelope with metadata + fields.
--json-schema "$(cat ...)"     Constrain the final answer to review-schema.json. The
                               validated object is returned in `.structured_output`.
```

> **Note:** `--json-schema` only constrains the *final answer*. The agent can still freely use its
> tools (git diff, read files) during the turn — only the message it produces at the end is shaped.

### Step 5: Extract the constrained object

Because `--json-schema` guarantees conformance, extraction is a one-liner — read the
**`.structured_output`** field of the envelope. There is no fence-stripping and no separate schema
validator (that job is done natively by structured outputs).

```
out.json  (envelope)                       review.json  (the review)
────────────────────                       ──────────────────────────
{                                           {
  "type": "result",                           "schema_version": "1.0",
  "result": { "content": [...] },              "overall_assessment": "...",
  "structured_output": {  ──────────────►      "summary": { ... },
     ...the review...                          "findings": [ ... ],
  },                                           "positive_observations": [ ... ]
  "total_cost_usd": 0.21                     }
}
```

```bash
# Pull the schema-constrained object straight out of the envelope
jq '.structured_output // empty' out.json > review.json

# Fail loudly if the run errored or produced no structured output
if [ "$CLAUDE_EXIT" -ne 0 ] || [ ! -s review.json ]; then
  cat claude-error.log; cat out.json          # + version / key-length diagnostics
  exit 1
fi

# Cross-field checks that NO JSON Schema can express (counts match findings, end_line >= line)
node -e '... verify summary.counts == actual counts ...'
```

> **Why still a Node check?** Structured outputs (native or `ajv`) enforce *shape* — types, enums,
> required fields — but cannot enforce **relationships between values**, like "`summary.counts` must
> equal the number of findings" or "`end_line >= line`". That one small check stays.

If the run fails or returns no `structured_output`, the workflow dumps stderr + raw output +
diagnostics and fails, so problems are loud rather than silent.

### Step 6: Post Summary + Inline Comments, Gate the PR

`actions/github-script` reads the validated `review.json` and renders the output:

```
review.json ──► github-script
                  │
                  ├─► Summary comment (issues table + verdict + positives)
                  │      via pulls.createReview(event: COMMENT, body, comments[])
                  │
                  ├─► Inline comments: one per finding with a `line`
                  │      { path: file, line, side: 'RIGHT', body: what/why/fix }
                  │
                  └─► Gate: if critical > 0 || recommendation == 'request_changes'
                          → core.setFailed(...)   (red check → blocks merge if required)
```

**Fallback:** if `createReview` is rejected (HTTP 422 — e.g. a finding points at a line **not in the
diff**, which GitHub won't accept for an inline comment), the script catches the error and posts the
entire review as a single plain issue comment instead. You never lose the review.

**Failure path:** a separate step posts a short "review could not be completed" comment linking to the
logs if the review step itself failed.

---

## Structured Output Schema

The contract between the reviewer and the workflow is **`review-schema.json`** (JSON Schema
draft-07). It is passed to `claude` via **`--json-schema "$(cat review-schema.json)"`**, which
**natively constrains** the model's answer (Anthropic structured outputs) — the conformant object
comes back in the envelope's `.structured_output` field.

> **Subset caveat:** structured outputs honor a *subset* of JSON Schema. Basic shape keywords
> (`type`, `enum`, `required`, `properties`, `additionalProperties`, `definitions`/`$ref`, arrays, nested
> objects) are reliably enforced. Advanced keywords — `allOf`/`if`/`then`, and sometimes `pattern` —
> may be ignored or rejected. For that reason this schema avoids conditional composition, and the
> `pattern`/`minLength` constraints on `id`, `cwe`, etc. are best treated as *documentation* rather
> than hard guarantees. If `claude` rejects the schema, simplify the unsupported keywords.

### Top-level shape

```
review.json
├── schema_version        "1.0"  (evolve the contract safely)
├── review {}             optional context: base/head ref, sha, files_reviewed, rules_applied
├── overall_assessment    string → top of the summary comment
├── summary
│   ├── recommendation     approve | comment | request_changes   ← gates the PR
│   └── counts             { critical, medium, minor }            ← must match findings
├── findings[]            ← each renders as an inline comment + summary row
└── positive_observations[]
```

### Each finding

| Field | Required | Purpose |
|---|---|---|
| `id` | ✅ | Stable ID like `SEC-001`, `ARCH-002` (pattern `^[A-Z]{3,4}-[0-9]{3}$`) |
| `severity` | ✅ | `critical` / `medium` / `minor` — drives gating |
| `category` | ✅ | Closed enum: `security`, `architecture`, `type-safety`, `react-hooks`, … |
| `title` | ✅ | One-line summary |
| `file` | ✅ | Repo-relative path — the inline-comment anchor |
| `line` / `end_line` | ⬜ | 1-indexed line(s) in the NEW file; required to post inline |
| `description` / `rationale` / `suggestion` | ✅ | what / why / fix |
| `suggested_code` | ⬜ | Optional corrected snippet (rendered as a fenced block) |
| `rule_source` | ⬜ | Traceability: `security-review.md#injection-risks`, `OWASP A03:2021` |
| `cwe` | ⬜ | Optional `CWE-89` etc. for security findings (pattern `^CWE-[0-9]+$`) |
| `confidence` | ⬜ | `high` / `medium` / `low` — lets you suppress low-confidence noise |

### Two rules enforced by the workflow (not the schema)

Structured outputs enforce *shape*, but not *relationships between values*, so the workflow checks
these in a small Node step:
- `summary.counts` must equal the actual number of findings at each severity.
- `end_line >= line` for any multi-line finding.

### Sample instance

```json
{
  "schema_version": "1.0",
  "overall_assessment": "Adds a user lookup endpoint. One critical SQL injection must be fixed before merge; otherwise the controller/service split is clean.",
  "summary": { "recommendation": "request_changes", "counts": { "critical": 1, "medium": 1, "minor": 0 } },
  "findings": [
    {
      "id": "SEC-001",
      "severity": "critical",
      "category": "security",
      "title": "SQL injection via string concatenation",
      "file": "backend/src/main/java/com/example/UserController.java",
      "line": 15,
      "description": "User-supplied `id` is concatenated directly into the SQL query.",
      "rationale": "Allows arbitrary SQL execution (OWASP A03).",
      "suggestion": "Use a parameterized query with a bind parameter.",
      "suggested_code": "String query = \"SELECT * FROM users WHERE id = ?\";\nreturn jdbcTemplate.queryForObject(query, User.class, id);",
      "rule_source": "security-review.md#injection-risks",
      "cwe": "CWE-89",
      "confidence": "high"
    }
  ],
  "positive_observations": ["Correct use of @PathVariable and constructor injection."]
}
```

### Changing the schema

If you add/rename a field, bump `schema_version`. Because the schema is passed to `--json-schema` at
review time, the reviewer adapts automatically — but remember to (a) keep new keywords inside the
supported subset (see caveat above), and (b) update the `github-script` rendering step to use any
new fields.

---

## Review Rules & Smart Loading

Rules live in **`.claude/rules/`** and are discovered and loaded **automatically** — and only the
ones relevant to the changed files are included.

```
DEVELOPER writes rules → PR changes files → Claude Code matches rules → JSON findings
   .claude/rules/*.md      *.tsx / *.java     via frontmatter patterns    (schema-shaped)
```

### Smart Loading (frontmatter — the real headers in this repo)

```markdown
---
# .claude/rules/react-review.md
patterns:
  - "frontend/**/*.tsx"
  - "frontend/**/*.ts"
  - "**/package.json"
priority: 1
---
```

```markdown
---
# .claude/rules/security-review.md
patterns:
  - "**/*.java"
  - "**/*.ts"
  # ...*.tsx, *.js, *.yml, *.yaml, *.properties, Dockerfile, .env*
priority: 2
always_load: true
---
```

- `patterns` → load this rule only when changed files match these globs
- `priority` → ordering hint when multiple rules apply (lower = first)
- `always_load: true` → load on **every** review (security runs on all PRs)

### The Three Rule Files

| File | Applies to | Focus |
|---|---|---|
| `.claude/rules/react-review.md` | `frontend/**` (`.ts`, `.tsx`) | Hooks, type safety, error handling, a11y |
| `.claude/rules/java-review.md` | `backend/**` (`.java`, `pom.xml`, `*.yml`) | SOLID, constructor injection, DTOs, Java 21 |
| `.claude/rules/security-review.md` | **always** | OWASP Top 10, JWT, secrets, CORS |

Edit any file in `.claude/rules/`; changes take effect on the **next PR**. Map your findings to a
rule via the `rule_source` field so the inline comment cites the guideline it came from.

---

## Configuration

### Prerequisites

**1. Anthropic API Key** — create at `console.anthropic.com` (108-char `sk-ant-api03-...`).

**2. GitHub Secret** — `Settings → Secrets and variables → Actions → New repository secret`:
name `ANTHROPIC_API_KEY`, value = your key.

**3. GitHub Actions Permissions** — `Settings → Actions → General → Workflow permissions`:
✅ Read and write permissions, ✅ Allow GitHub Actions to create and approve pull requests.
(Required so the bot can post review comments and set the check status.)

**4. Workspace Model Rate Limits** — the pinned model must have a high enough *input tokens per
minute* limit (see next section). This is the #1 setup failure.

### Workflow structure

```yaml
name: AI Code Review (Claude Code)
on: { pull_request: { types: [opened, synchronize, reopened] } }
permissions: { pull-requests: write, contents: read }
jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - Checkout (fetch-depth: 0)
      - Setup Node.js 20
      - Install Claude Code
      - Verify Claude Code
      - Smoke test (minimal call)
      - Run review → --json-schema (native) → jq .structured_output → node cross-checks
      - Post summary + inline comments, gate via setFailed
      - (on failure) Post "review could not be completed" comment
```

### Files that make it work

- `.github/workflows/ai-review-claude-code.yml` — orchestration
- `review-schema.json` — the output contract (enforced natively via `--json-schema`)
- `.claude/rules/*.md` — auto-loaded, smart-matched review rules
- `CLAUDE.md` — project conventions (auto-loaded)
- `ANTHROPIC_API_KEY` — auth secret

---

## Model & Rate Limits (Important)

Claude Code's request includes its **own system prompt + all tool definitions**, plus `CLAUDE.md`,
the matched rules, `review-schema.json`, and any files it reads. That baseline can be **tens of
thousands of input tokens** — so the request only succeeds if the **pinned model** has a high enough
**Input Tokens Per Minute (ITPM)** limit in your workspace.

### The rate limits that caused the original failure (Certification Group workspace)

| Model | Input Tokens / Min (excl. cache) | Suitable for Claude Code? |
|---|---:|---|
| **Claude Sonnet 5** | **10,000,000** | ✅ Yes — pin this |
| Claude Sonnet 4.x | 100,000 | ✅ Usually fine |
| Claude Haiku 4.x | 100,000 | ✅ Fine (cheaper, less thorough) |
| **Claude Opus 4.x** | **10,000** | ❌ Too low — causes 429 |
| Claude Fable 5 | 100 | ❌ Never use for this |

```
Symptom:  API Error: Request rejected (429) · exceed the rate limit ... 10,000 input tokens/min.
Cause:    CLI default model was Opus 4.x (10,000 ITPM). One review request exceeds that,
          so it is rejected every time — retrying does NOT help.
Fix:      Pin a high-limit model:  --model claude-sonnet-5   (10,000,000 ITPM)
```

**Key lesson:** always pin `--model` explicitly. Check/raise per-model limits at
Console → select workspace → **Manage → Limits** (`Analytics → Rate limits` is read-only monitoring).

---

## Practical Examples

### Example 1: Backend PR with a Security Bug

**Code in PR:**

```java
// backend/src/main/java/com/example/UserController.java   (line 15)
String query = "SELECT * FROM users WHERE id = " + id;   // ❌ SQL Injection
return jdbcTemplate.queryForObject(query, User.class);
```

**Reviewer emits (validated `review.json`, abbreviated):**

```json
{
  "schema_version": "1.0",
  "summary": { "recommendation": "request_changes", "counts": { "critical": 1, "medium": 0, "minor": 0 } },
  "findings": [{
    "id": "SEC-001", "severity": "critical", "category": "security",
    "title": "SQL injection via string concatenation",
    "file": "backend/src/main/java/com/example/UserController.java", "line": 15,
    "description": "User input concatenated directly into SQL.",
    "rationale": "Arbitrary SQL execution (OWASP A03).",
    "suggestion": "Use a parameterized query.",
    "suggested_code": "String query = \"SELECT * FROM users WHERE id = ?\";",
    "rule_source": "security-review.md#injection-risks", "cwe": "CWE-89"
  }]
}
```

**Result on the PR:**
- 💬 An **inline comment on line 15** with the what/why/fix and the suggested snippet.
- 🤖 A **summary comment** with a findings table and verdict `request_changes`.
- 🚦 The **check fails** (critical > 0), blocking merge if the check is required.

### Example 2: Frontend PR with Type Safety Issues

`UserProfile.tsx` uses `any`, an untyped `useState`, and a fetch with no error handling. Claude
loads `react-review.md` (matched via `*.tsx`) + `security-review.md`, and emits three `medium`
`type-safety` / `error-handling` findings — each posted inline at its line, verdict `comment`, check
stays green.

### Example 3: Complete Workflow Timeline

```
10:00:00  Developer: git push origin feature/auth-fix
10:00:06  Workflow 'AI Code Review (Claude Code)' triggered
10:00:25  Node 20 + Claude Code CLI installed
10:00:33  Smoke test OK (model reachable)
10:00:35  Claude runs git diff + reads files + loads rules + emits JSON
10:01:05  out.json received → jq .structured_output → node cross-checks (PASS)
10:01:07  Summary + inline comments posted; check gated on severity
10:01:08  Developer: notification - "🤖 AI Code Review posted"

TOTAL: ~60-70 seconds     COST: ~$0.15 - $0.40
```

---

## Troubleshooting

### Problem 1: Step fails with `exit code 1`, log ends on the extraction block

**Cause:** `shell: bash -e` prints the whole step script; the tail isn't where it failed. The
`claude` call (or the `node` cross-check) returned non-zero.

**Solution:** already handled — the step wraps the call in `set +e`, then dumps stderr + raw output +
diagnostics if the run failed or produced no `structured_output`. Read those log groups.

### Problem 2: `429 · exceed the rate limit ... 10,000 input tokens per minute`

**Cause:** a low-ITPM model (Opus 4.x = 10k). One agentic request exceeds it; retrying won't help.

**Solution:** pin `--model claude-sonnet-5` (10M ITPM). Verify at Console → Manage → Limits.

### Problem 3: `.structured_output` is empty / null

**Cause:** the run errored before producing a constrained answer, or the model hit `max_tokens`
mid-object, or the schema was rejected as unsupported.

**Solution:** read the "claude raw output" log group. If the envelope shows an error, address it
(often rate limit or auth). If it's a `--json-schema` rejection, simplify unsupported keywords
(`allOf`/`if`/`then`, possibly `pattern`) — see the schema subset caveat.

### Problem 4: `Error: --json-schema is not a valid JSON Schema`

**Cause:** the CLI validates the schema with **ajv (draft-07 by default)** before use. Two common
triggers:
- A `"$schema"` pointing at a meta-schema ajv doesn't have registered — e.g.
  `no schema with key or ref "https://json-schema.org/draft/2020-12/schema"`. **Omit the `$schema`
  and `$id` keys** so ajv uses its default (draft-07).
- Using 2019+/2020 keywords (`$defs`) under the draft-07 validator — prefer the draft-07 spelling
  **`definitions`** with `$ref: "#/definitions/..."`.

**Solution:** this repo's `review-schema.json` already omits `$schema`/`$id` and uses `definitions`.
Validate locally with `node -e "JSON.parse(require('fs').readFileSync('review-schema.json','utf8'))"`
and keep the shape within the supported subset.

### Problem 5: Semantic check fails (`counts` mismatch / `end_line < line`)

**Cause:** `summary.counts` doesn't equal the number of findings, or a multi-line range is inverted.

**Solution:** these are caught by the Node step after extraction. Tighten the prompt so the model computes
counts from its own findings; the check exists precisely to catch that drift.

### Problem 6: Inline comments don't appear / `createReview` 422

**Cause:** GitHub only accepts inline comments on lines **present in the PR diff**. A finding
pointing at an unchanged/out-of-diff line makes the whole `createReview` call fail.

**Solution:** the script **falls back** to one plain issue comment containing all findings, so nothing
is lost. To keep the rest inline, we can add per-comment filtering (drop out-of-diff lines to the
summary, keep valid ones inline) — ask if you want that.

### Problem 7: Agent produces nothing / "cannot use tool"

**Cause:** headless mode can't answer permission prompts.

**Solution:** ensure `--allowedTools "Bash,Read,Grep,Glob"` **and** `--permission-mode bypassPermissions`.

### Problem 8: `git diff` empty / base branch missing

**Solution:** `fetch-depth: 0` on checkout **and** `git fetch origin "$BASE_REF" --depth=1` before the review.

### Problem 9: "invalid x-api-key" / auth error

**Solution:** the diagnostics block prints `ANTHROPIC_API_KEY length` — should be `108`. If `0`, the
secret isn't set; re-add it under Settings → Secrets and variables → Actions.

---

## Monitoring and Costs

Monitor at [console.anthropic.com](https://console.anthropic.com):

```
Console → (select workspace)
  ├── Analytics → Usage        (tokens & spend)
  ├── Analytics → Rate limits  (per-model utilization, last 24h)
  ├── Analytics → Cost         (spend breakdown)
  └── Manage   → Limits        (edit per-model RPM / ITPM / OTPM)
```

You can also read per-run cost directly from the envelope: `jq '.total_cost_usd' out.json`.

```
Direct API   : ~$0.10 - $0.15 per review  (small prompt: rules + diff)
Claude Code  : ~$0.15 - $0.40 per review  (agentic: larger context, file reads)
```

---

## Best Practices

1. **Always pin the model** — `--model claude-sonnet-5` on every `claude` call (including the smoke
   test). Never rely on the CLI default.
2. **Keep the smoke test** — isolates setup/auth/model problems in seconds, cheaply.
3. **Constrain natively, then cross-check** — `--json-schema` guarantees the *shape*; the small Node
   step catches value relationships (counts, `end_line`) no schema can express. Keep both.
4. **Version the schema** — bump `schema_version` on any breaking change and update both the prompt
   and the `github-script` renderer.
5. **Use `rule_source` / `cwe`** — traceable findings that cite the guideline (or OWASP/CWE) are far
   more actionable and easier to tune.
6. **Combine AI + human review** — AI first pass (security, type safety, common bugs); human second
   pass (business logic, architecture, edge cases).
7. **Never commit secrets** — `.claude/settings.local.json` must stay gitignored; rotate any key that
   lands in a tracked file or a log.
8. **Watch rate-limit headroom** — as PR volume grows, raise ITPM for the pinned model before you hit
   429s at peak.

---

## Conclusion

The Claude Code implementation turns code review into an **agentic, structured** task: Claude explores
the repo, applies the rules, and returns **schema-validated JSON** that the workflow renders as a
summary comment + inline comments and uses to **gate the PR**.

**Complete flow:**
```
Push → PR → Install Claude Code → Smoke test →
claude -p --json-schema (agent: git diff + read files + load rules) → JSON envelope →
jq .structured_output → node cross-checks →
summary comment + inline comments + severity gate
```

**Key files:**
- `.github/workflows/ai-review-claude-code.yml` — orchestration
- `review-schema.json` — the output contract
- `.claude/rules/*.md` — auto-loaded, smart-matched rules
- `CLAUDE.md` — project conventions (auto-loaded)
- `ANTHROPIC_API_KEY` — auth secret (108 chars)

**The three lessons that make it work:**
1. **Pin a high-ITPM model** (`--model claude-sonnet-5`) — the CLI default (Opus 4.x) is throttled to
   10k ITPM and fails with 429.
2. **Grant tools + bypass permissions** so the headless agent can inspect the repo.
3. **Constrain the output natively** (`--json-schema` → read `.structured_output`) and add the small
   cross-field check, so a bad LLM response fails loudly instead of posting garbage.

**Next steps:** test with a trial PR, tune `.claude/rules/*.md` and `review-schema.json`, monitor cost
& limits, and iterate on the prompt based on the findings you see.

---

**Questions? Issues?** Check [Troubleshooting](#troubleshooting) or read the failure-diagnostics log
groups (stderr, raw output, `.structured_output`, key length) printed by the workflow.
