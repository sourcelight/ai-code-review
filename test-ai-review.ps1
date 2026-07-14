# Test script for AI Code Review workflow
# This simulates what GitHub Actions does in the ai-review.yml workflow

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "AI Code Review Workflow Test" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if ANTHROPIC_API_KEY is set
$ApiKey = $env:ANTHROPIC_API_KEY
if (-not $ApiKey) {
    Write-Host "ERROR: ANTHROPIC_API_KEY environment variable is not set" -ForegroundColor Red
    Write-Host "Please set it with: `$env:ANTHROPIC_API_KEY='your-key-here'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ ANTHROPIC_API_KEY is set" -ForegroundColor Green
Write-Host ""

# Load review rules
Write-Host "Loading review rules..." -ForegroundColor Cyan
$ReactRules = Get-Content -Path ".github\ai-review\react-review.md" -Raw
$JavaRules = Get-Content -Path ".github\ai-review\java-review.md" -Raw
$SecurityRules = Get-Content -Path ".github\ai-review\security-review.md" -Raw
Write-Host "✓ Review rules loaded" -ForegroundColor Green
Write-Host ""

# Create a sample diff (simulating a PR)
Write-Host "Creating sample diff..." -ForegroundColor Cyan
$Diff = @'
diff --git a/backend/src/main/java/com/example/starter/controller/ApiController.java b/backend/src/main/java/com/example/starter/controller/ApiController.java
index 1234567..abcdefg 100644
--- a/backend/src/main/java/com/example/starter/controller/ApiController.java
+++ b/backend/src/main/java/com/example/starter/controller/ApiController.java
@@ -10,6 +10,11 @@ public class ApiController {
     @GetMapping("/hello")
     public ResponseEntity<MessageResponse> hello() {
-        return ResponseEntity.ok(new MessageResponse("Hello authenticated user"));
+        String message = "Hello authenticated user";
+        return ResponseEntity.ok(new MessageResponse(message));
+    }
+
+    @GetMapping("/info")
+    public ResponseEntity<MessageResponse> info() {
+        return ResponseEntity.ok(new MessageResponse("System info endpoint"));
     }
 }

diff --git a/frontend/src/pages/Home.tsx b/frontend/src/pages/Home.tsx
index 2345678..bcdefgh 100644
--- a/frontend/src/pages/Home.tsx
+++ b/frontend/src/pages/Home.tsx
@@ -15,7 +15,7 @@ const Home = () => {
     const fetchMessage = async () => {
       try {
         const response = await api.get('/hello');
-        setMessage(response.data.message);
+        setMessage(response.data.message || 'No message');
       } catch (err) {
         setError('Failed to fetch message');
       }
'@

Write-Host "✓ Sample diff created" -ForegroundColor Green
Write-Host ""

# Build the prompt
Write-Host "Building AI review prompt..." -ForegroundColor Cyan
$PromptText = @"
You are an expert code reviewer. Please review the following Pull Request changes according to these guidelines:

## React Frontend Review Guidelines
$ReactRules

## Java Backend Review Guidelines
$JavaRules

## Security Review Guidelines
$SecurityRules

## Pull Request Diff
``````diff
$Diff
``````

Please provide your review in the following format:

# Code Review Summary

## Overall Assessment
(Brief summary)

## Critical Issues
(List critical issues or 'None found')

## Medium Issues
(List medium issues or 'None found')

## Minor Issues
(List minor issues or 'None found')

## Suggested Improvements
(List suggestions)

## Positive Observations
(List positive aspects)
"@

Write-Host "✓ Prompt built" -ForegroundColor Green
Write-Host ""

# Call Anthropic API
Write-Host "Calling Anthropic API (Claude Sonnet 4)..." -ForegroundColor Cyan
Write-Host "This may take 10-30 seconds..." -ForegroundColor Yellow
Write-Host ""

$Body = @{
    model = "claude-sonnet-4-20250514"
    max_tokens = 4096
    messages = @(
        @{
            role = "user"
            content = $PromptText
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $Response = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" `
        -Method Post `
        -Headers @{
            "content-type" = "application/json"
            "x-api-key" = $ApiKey
            "anthropic-version" = "2023-06-01"
        } `
        -Body $Body `
        -ErrorAction Stop

    $ReviewText = $Response.content[0].text

    if (-not $ReviewText) {
        Write-Host "ERROR: Failed to extract review text from response" -ForegroundColor Red
        Write-Host "Response:" -ForegroundColor Yellow
        $Response | ConvertTo-Json -Depth 10
        exit 1
    }

    Write-Host "✓ AI review completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "AI CODE REVIEW RESULT" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $ReviewText
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Test completed successfully!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Cyan

    # Save review to file
    $null = New-Item -ItemType Directory -Force -Path "test-results"
    $OutputFile = "test-results\ai-review-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

    $OutputContent = @"
# AI Code Review Test Result
Generated: $(Get-Date)

## Sample Diff Reviewed
``````diff
$Diff
``````

---

$ReviewText
"@

    Set-Content -Path $OutputFile -Value $OutputContent
    Write-Host ""
    Write-Host "Review saved to: $OutputFile" -ForegroundColor Green

} catch {
    Write-Host "ERROR: API call failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow
    }
    exit 1
}
