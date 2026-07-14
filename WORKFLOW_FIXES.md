# GitHub Actions Workflow Fixes

## Error: "bad substitution" (Multiple Locations)

### Problem
The workflow was failing with errors:
```
git fetch origin : bad substitution
echo : bad substitution
Error: Process completed with exit code 1.
```

### Root Cause
GitHub Actions expressions like `${{ github.base_ref }}` and `${{ steps.rules.outputs.react }}` were being used directly inside bash scripts, causing the shell to misinterpret them as bash variable expansions.

**Bad (causes error):**
```yaml
run: |
  git fetch origin "${{ github.base_ref }}"
  DIFF=$(git diff origin/"${{ github.base_ref }}"...HEAD)
```

The shell sees `origin/"${{ github.base_ref }}"` and tries to parse `${{` as a bash variable substitution, which fails.

### Solution
Store the GitHub Actions expression in a bash variable first, then use that variable:

**Good (works correctly):**
```yaml
run: |
  BASE_REF="${{ github.base_ref }}"
  echo "Base branch: $BASE_REF"
  git fetch origin "$BASE_REF"
  DIFF=$(git diff "origin/$BASE_REF"...HEAD)
```

Now the GitHub Actions expression is evaluated BEFORE the bash script runs, and bash only sees regular variables.

### 3. Pass Step Outputs via Environment Variables

The same issue occurred with step outputs in the prompt:

**Bad (causes error):**
```yaml
run: |
  PROMPT="Review guidelines:
  ${{ steps.rules.outputs.react }}
  
  Diff:
  ${{ steps.diff.outputs.diff }}
  "
```

**Good (works correctly):**
```yaml
env:
  REACT_RULES: ${{ steps.rules.outputs.react }}
  JAVA_RULES: ${{ steps.rules.outputs.java }}
  SECURITY_RULES: ${{ steps.rules.outputs.security }}
  PR_DIFF: ${{ steps.diff.outputs.diff }}
run: |
  PROMPT="Review guidelines:
  $REACT_RULES
  
  Diff:
  $PR_DIFF
  "
```

**Key principle:** GitHub Actions expressions (`${{ ... }}`) can ONLY be used in:
- `env:` blocks
- `with:` blocks  
- Other YAML fields

They CANNOT be used directly inside `run:` bash scripts. Use `env:` to pass them as environment variables first.

---

## Additional Fixes Applied

### 1. Proper Multiline Output Handling

Changed from:
```bash
echo "diff<<EOF" >> $GITHUB_OUTPUT
echo "$DIFF" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT
```

To:
```bash
{
  echo 'diff<<EOF'
  echo "$DIFF"
  echo 'EOF'
} >> "$GITHUB_OUTPUT"
```

**Why?**
- Groups output into a single block (more reliable)
- Single quotes prevent premature variable expansion
- Quotes around `$GITHUB_OUTPUT` prevent word splitting

### 2. Consistent Quote Usage

All `$GITHUB_OUTPUT` references now use double quotes: `"$GITHUB_OUTPUT"`

This prevents errors if the path contains spaces or special characters.

---

## Files Fixed

1. ✅ `.github/workflows/ai-review.yml` - Main workflow
2. ✅ `.github/workflows/ai-review-debug.yml` - Debug workflow

Both files now have:
- ✅ Proper variable handling for `github.base_ref`
- ✅ Correct multiline output syntax
- ✅ Consistent quoting throughout

---

## Testing the Fix

### 1. Commit and push the changes:
```bash
git add .github/workflows/
git commit -m "Fix bash substitution error in workflows"
git push origin main
```

### 2. Create a test PR:
```bash
git checkout -b test/workflow-fix
echo "# Test" >> README.md
git commit -am "Test workflow fix"
git push origin test/workflow-fix
```

### 3. Open PR and check:
- ✅ Workflows should trigger automatically
- ✅ "Get PR diff" step should succeed (no more "bad substitution" error)
- ✅ Debug workflow should post a test comment
- ✅ AI review should appear as a comment

---

## Expected Workflow Execution

With these fixes, the workflow will:

1. ✅ Checkout code
2. ✅ Post test comment (debug workflow only)
3. ✅ Fetch base branch and calculate diff
4. ✅ Load review rules from markdown files
5. ✅ Call Anthropic API with the prompt
6. ✅ Extract AI review from response
7. ✅ Post review as a PR comment

---

## If Issues Persist

### Check Actions Logs
Go to: `Actions → AI Code Review → [workflow run]`

Look for specific errors in each step.

### Common Issues After This Fix

**"ANTHROPIC_API_KEY not set"**
- Add the secret: Settings → Secrets and variables → Actions → New repository secret
- Name: `ANTHROPIC_API_KEY`
- Value: Your API key

**"Permission denied" or "Resource not accessible"**
- Repository Settings → Actions → General → Workflow permissions
- Select: "Read and write permissions"
- Enable: "Allow GitHub Actions to create and approve pull requests"

**API errors (404, 401, etc.)**
- Check your Anthropic API key is valid
- Verify you have API credits available
- Model name is correct: `claude-sonnet-4-6`

**Review text empty or not posted**
- Debug workflow will show exact point of failure
- Check "Show review in logs" step output
- Verify jq is extracting content correctly

---

## Summary

The "bad substitution" error was caused by improper mixing of GitHub Actions expressions and bash variable syntax. The fix separates these concerns by:

1. Capturing GitHub Actions expressions in bash variables first
2. Using proper multiline output syntax with grouping
3. Consistent quoting throughout

These changes make the workflows more robust and compatible with GitHub Actions' bash runner.
