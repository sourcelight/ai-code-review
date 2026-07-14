# Testing AI Code Review Workflow

This guide explains how to test the AI code review workflow locally before using it in GitHub Actions.

## Prerequisites

1. **Anthropic API Key**
   - Sign up at https://console.anthropic.com/
   - Create an API key
   - Set it as an environment variable

## Setup

### Windows (PowerShell)
```powershell
$env:ANTHROPIC_API_KEY = "your-api-key-here"
```

### Linux/Mac (Bash)
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

## Running the Test

### Option 1: Use PowerShell Script (Windows)
```powershell
cd C:\job_local\code-review-ai-repo\code-review-springboot-fe
.\test-ai-review.ps1
```

### Option 2: Use Bash Script (Linux/Mac/Git Bash)
```bash
cd /c/job_local/code-review-ai-repo/code-review-springboot-fe
chmod +x test-ai-review.sh
./test-ai-review.sh
```

## What the Test Does

1. **Validates API Key** - Checks if ANTHROPIC_API_KEY is set
2. **Loads Review Rules** - Reads the three review rule files:
   - `.github/ai-review/react-review.md`
   - `.github/ai-review/java-review.md`
   - `.github/ai-review/security-review.md`
3. **Creates Sample Diff** - Generates a simulated PR diff with intentional issues
4. **Calls Anthropic API** - Sends the diff and rules to Claude Sonnet 4
5. **Displays Review** - Shows the AI-generated code review
6. **Saves Results** - Stores the review in `test-results/ai-review-TIMESTAMP.md`

## Sample Diff Issues

The test uses a sample diff with intentional problems to verify the AI catches them:

### Security Issues
- SQL injection vulnerability
- Hardcoded credentials
- Sensitive data in logs
- XSS vulnerability (dangerouslySetInnerHTML)
- Missing input validation

### React Issues
- Using `any` type
- Missing useEffect dependency array
- No error handling
- No loading states
- Missing accessibility (alt text)
- Null reference errors

### Java Issues
- Business logic in wrong layer
- Missing authorization checks
- No proper validation
- Logging sensitive information

## Expected Output

The AI review should identify:
- **Critical Issues**: SQL injection, hardcoded credentials, XSS
- **Medium Issues**: Missing validation, error handling, logging issues
- **Minor Issues**: TypeScript types, accessibility, code organization
- **Suggestions**: Improvements for security, performance, and maintainability

## Output Location

Review results are saved to:
```
test-results/ai-review-YYYYMMDD-HHMMSS.md
```

## Troubleshooting

### "ANTHROPIC_API_KEY is not set"
Set the environment variable as shown in Setup section.

### "API call failed"
- Check your API key is valid
- Verify you have API credits
- Check your internet connection

### "Failed to load review rules"
Make sure you're running the script from the project root directory.

## Cost Estimate

Each test call costs approximately:
- Input tokens: ~3,000-5,000 tokens
- Output tokens: ~1,000-2,000 tokens
- Estimated cost: ~$0.05-0.10 per test (Claude Sonnet 4)

## Next Steps

After successful testing:
1. Add `ANTHROPIC_API_KEY` to GitHub repository secrets
2. Create a pull request to trigger the actual workflow
3. Verify the AI review appears as a comment on the PR

## Real GitHub Actions Workflow

The actual workflow (`.github/workflows/ai-review.yml`) will:
- Trigger automatically on PR events
- Fetch the real PR diff
- Call Anthropic API with GitHub Actions secret
- Post review as PR comment
- Work with no manual intervention

This test script simulates that entire process locally!
