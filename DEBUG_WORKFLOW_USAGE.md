# Debug Workflow Usage Guide

## Overview

The debug workflow (`ai-review-debug.yml`) is **DISABLED for automatic triggering** to prevent API conflicts with the main workflow. It can only be run **manually** when you need detailed debugging output.

## Why It's Disabled

- ✅ Prevents both workflows from running simultaneously
- ✅ Avoids Anthropic API rate limiting and concurrent request issues
- ✅ The main workflow (`ai-review.yml`) handles all automatic PR reviews
- 🔧 Debug workflow is available when you need troubleshooting

## How to Manually Run the Debug Workflow

### Step 1: Go to Actions Tab

1. Navigate to your GitHub repository
2. Click on the **"Actions"** tab at the top
3. In the left sidebar, click **"AI Code Review (Debug - Manual Only)"**

### Step 2: Run Workflow

1. Click the **"Run workflow"** dropdown button (top right)
2. Select the branch (usually `main`)
3. Enter the **PR number** you want to debug
4. Click **"Run workflow"**

### Visual Guide

```
GitHub Repo
  └─ Actions tab
      └─ AI Code Review (Debug - Manual Only)
          └─ "Run workflow" button
              └─ Enter PR number: [123]
              └─ Click "Run workflow"
```

## When to Use the Debug Workflow

Use the debug workflow when:

- ❌ The main workflow fails and you need to see detailed logs
- 🐛 The review comment doesn't appear and you want to troubleshoot
- 📊 You want to see API response sizes and timing information
- 🔍 You need to verify the prompt being sent to Claude
- ⚙️ You're testing changes to the review guidelines

## What the Debug Workflow Shows

The debug workflow provides extra information:

1. **Test Comment First**
   - Posts a simple comment to verify GitHub permissions work
   - If this appears, GitHub integration is OK

2. **Detailed Sizes**
   - Diff size in characters
   - Review rules sizes
   - Prompt size
   - API response size

3. **API Response Details**
   - Explicit error checking
   - Error type and message if API fails
   - First 200 characters of the review preview

4. **Full Review in Logs**
   - Complete AI review printed in workflow logs
   - Even if comment posting fails, you can see the review

5. **Step-by-Step Status**
   - Each step prints its progress
   - Easy to identify which step failed

## Comparing Output

**Main Workflow (`ai-review.yml`):**
```
✓ Get PR diff
✓ Load review rules
✓ Run AI Code Review
✓ Post review comment
```

**Debug Workflow (`ai-review-debug.yml`):**
```
✓ Test comment posting first
  → 🧪 Debug Test: GitHub comment posting works!
  
✓ Get PR diff
  → Base branch: main
  → Head branch: feature/test
  → Diff size: 5432 characters
  
✓ Load review rules
  → React rules size: 2341 characters
  → Java rules size: 3156 characters
  → Security rules size: 4523 characters
  
✓ Run AI Code Review
  → Prompt size: 15452 characters
  → Calling Anthropic API...
  → API Response received
  → Response size: 18234 characters
  → Review size: 17845 characters
  → First 200 characters: # Code Review Summary...
  
✓ Show review in logs
  → [Full review content printed here]
  
✓ Post review comment
  → Review length: 17845
  → Comment posted successfully!
```

## Example: Manual Debug Run

```bash
# 1. Create a test PR (PR #42)
git checkout -b test/debug-workflow
echo "// test" >> backend/README.md
git commit -am "Test debug workflow"
git push origin test/debug-workflow

# 2. Open PR on GitHub (note the PR number, e.g., #42)

# 3. Go to Actions → AI Code Review (Debug - Manual Only)

# 4. Click "Run workflow"
#    - Branch: main
#    - PR number: 42
#    - Click "Run workflow"

# 5. Watch the workflow run with detailed logs
```

## Troubleshooting with Debug Workflow

### Issue: Main workflow fails silently

**Solution:** Run debug workflow with same PR number
- Check which step fails
- Look at sizes to ensure data is being captured
- Verify API response contains valid review

### Issue: Comment doesn't appear

**Debug workflow shows:**
```
✓ Test comment posting first
  → 🧪 Debug Test: GitHub comment posting works!
✓ Post review comment
  → Comment posted successfully!
```

**Diagnosis:** If test comment appears but review doesn't:
- GitHub permissions are OK
- Problem is in the main workflow's comment formatting
- Compare the two workflows' comment posting code

### Issue: API errors

**Debug workflow shows:**
```
ERROR: API returned error type: authentication_error
Error message: invalid x-api-key
```

**Diagnosis:**
- API key is incorrect or expired
- Check: Settings → Secrets → ANTHROPIC_API_KEY
- Verify key at console.anthropic.com

### Issue: Empty review

**Debug workflow shows:**
```
Response size: 234 characters
ERROR: Review text is empty!
```

**Diagnosis:**
- API response is valid but contains no review content
- Check "Show review in logs" step to see what API returned
- May need to adjust max_tokens or prompt

## Re-enabling Automatic Triggering

If you want the debug workflow to run automatically (not recommended due to API conflicts):

1. Open `.github/workflows/ai-review-debug.yml`
2. Find these lines:
```yaml
on:
  workflow_dispatch:  # Manual trigger only

# Uncomment below to enable automatic triggering
# on:
#   pull_request:
#     types: [opened, synchronize, reopened]
```

3. Comment out `workflow_dispatch` and uncomment the `pull_request` section:
```yaml
# on:
#   workflow_dispatch:  # Manual trigger only

# Enabled automatic triggering
on:
  pull_request:
    types: [opened, synchronize, reopened]
```

⚠️ **Warning:** This will cause both workflows to run simultaneously again, which may trigger API rate limits!

## Summary

- 🔒 **Debug workflow is disabled** for automatic runs
- 🎯 **Main workflow handles all PRs** automatically  
- 🔧 **Debug workflow available for troubleshooting** when needed
- ▶️ **Run manually from Actions tab** with PR number
- 📊 **Provides detailed logs** for debugging issues
- 🚫 **Prevents API conflicts** by not running simultaneously

The debug workflow is your troubleshooting tool - use it when the main workflow has issues!
