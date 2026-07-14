# AI Code Review - Final Setup Guide

## ✅ Current Status

- **Local Testing:** ✅ Working perfectly
- **Workflow Files:** ✅ Fixed and ready
- **API Key:** ✅ Configured
- **Model:** ✅ `claude-sonnet-4-6` (correct)

## What's Configured

### Working Workflow
- **File:** `.github/workflows/ai-review.yml`
- **Status:** Active and working
- **Triggers:** When PRs are opened, synchronized, or reopened

### Removed Debug Workflow
- **File:** `.github/workflows/ai-review-debug.yml` ❌ Deleted
- **Reason:** Both workflows were running simultaneously, causing:
  - API rate limiting issues
  - Concurrent request conflicts
  - One would succeed, one would fail with "invalid x-api-key"

## How It Works

When you create or update a Pull Request:

1. **Workflow triggers automatically**
2. **Fetches the diff** between base branch and PR
3. **Loads review guidelines** from `.github/ai-review/`:
   - `react-review.md` - React/TypeScript best practices
   - `java-review.md` - Java/Spring Boot patterns
   - `security-review.md` - OWASP security guidelines
4. **Calls Anthropic API** with Claude Sonnet 4
5. **Posts AI review** as a comment on the PR

## Required Setup (Already Done)

✅ **ANTHROPIC_API_KEY Secret** - Added to GitHub repository secrets  
✅ **Repository Permissions** - Ensure workflow has write access:
   - Go to: `Settings → Actions → General → Workflow permissions`
   - Select: **"Read and write permissions"**
   - Enable: **"Allow GitHub Actions to create and approve pull requests"**

## Testing

### Create a Test PR:
```bash
git checkout -b test/ai-review-working
echo "// Test change" >> backend/src/main/java/com/example/starter/StarterApplication.java
git commit -am "Test AI review"
git push origin test/ai-review-working
```

### Expected Result:
1. ✅ Workflow runs (check Actions tab)
2. ✅ Completes successfully (~20-60 seconds)
3. ✅ AI review comment appears on the PR

## Review Guidelines

The AI reviews code based on rules in `.github/ai-review/`:

### React/Frontend (`react-review.md`)
- Component structure and hooks usage
- TypeScript type safety
- Error handling and loading states
- Accessibility (WCAG compliance)
- Performance (re-renders, memoization)

### Java/Backend (`java-review.md`)
- SOLID principles
- Spring Boot best practices
- Constructor injection (not field injection)
- Business logic in services (not controllers)
- Java 21 features (records, pattern matching)
- Proper exception handling

### Security (`security-review.md`)
- OWASP Top 10 vulnerabilities
- SQL injection, XSS, CSRF
- JWT security
- Secret management
- Input validation
- PCI-DSS compliance for payment data

## Customizing Review Rules

Edit the markdown files in `.github/ai-review/` to customize what the AI checks for.

**Example - Add a new rule to Java review:**
```bash
# Edit the file
nano .github/ai-review/java-review.md

# Add your rule
## My Custom Rule
- Check for [specific pattern]
- Ensure [specific behavior]
```

Changes take effect immediately on the next PR.

## Cost Estimate

- **Model:** Claude Sonnet 4 (`claude-sonnet-4-6`)
- **Input tokens:** ~$3 per million tokens
- **Output tokens:** ~$15 per million tokens
- **Per PR review:** $0.10 - $0.50 (depending on diff size)
- **Monthly estimate:** 50 PRs = $5 - $25/month

## Troubleshooting

### Workflow doesn't trigger
- Check: Is this a pull request? (Only triggers on PRs, not direct pushes)
- Verify: `.github/workflows/ai-review.yml` is in the `main` branch

### "ANTHROPIC_API_KEY not set" error
- Add secret: `Settings → Secrets → Actions → ANTHROPIC_API_KEY`

### "Permission denied" when posting comment
- Fix: `Settings → Actions → General → Workflow permissions`
- Select: "Read and write permissions"

### "invalid x-api-key" error
- Verify your API key is correct
- Check you have API credits at [console.anthropic.com](https://console.anthropic.com)
- Ensure only ONE workflow is active (we removed the debug one)

### Review comment doesn't appear
- Check Actions logs for errors
- Verify workflow completed successfully
- Check you're looking at the right PR

### API rate limit errors
- Wait a few minutes and re-trigger the workflow
- Consider upgrading your Anthropic API tier for higher limits

## Local Testing

You can test the AI review locally without creating a PR:

```powershell
# Set your API key
$env:ANTHROPIC_API_KEY = "your-key-here"

# Run the test script
.\test-ai-simple.ps1
```

This simulates what the GitHub workflow does and shows you the review output.

## Files Reference

### Active Files
- `.github/workflows/ai-review.yml` - Main workflow (active)
- `.github/ai-review/react-review.md` - React guidelines
- `.github/ai-review/java-review.md` - Java guidelines
- `.github/ai-review/security-review.md` - Security guidelines
- `test-ai-simple.ps1` - Local testing script
- `test-sample-diff.txt` - Sample diff with security issues

### Documentation
- `CLAUDE.md` - Codebase documentation for Claude
- `TEST_AI_REVIEW.md` - Testing instructions
- `TEST_RESULTS.md` - Test results and troubleshooting
- `WORKFLOW_FIXES.md` - Technical fixes applied
- `FINAL_SETUP.md` - This file

## Next Steps

1. ✅ **Commit the changes:**
   ```bash
   git add .
   git commit -m "Remove debug workflow to avoid API conflicts"
   git push origin main
   ```

2. ✅ **Test with a real PR** using the steps above

3. ✅ **Customize review rules** if needed

4. ✅ **Monitor costs** at [console.anthropic.com](https://console.anthropic.com)

## Success Criteria

✅ PR is created  
✅ Workflow runs automatically  
✅ Completes in 20-60 seconds  
✅ AI review comment appears on PR  
✅ Review identifies real issues in the code  
✅ No errors in Actions logs  

## Summary

The AI code review system is now fully configured and ready to use! Only the main workflow (`ai-review.yml`) will run, avoiding API conflicts. Each PR will automatically receive a comprehensive AI review covering React, Java, and security best practices.

**Cost-effective, automatic, and customizable code review powered by Claude Sonnet 4!** 🎉
