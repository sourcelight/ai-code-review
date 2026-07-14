# Simple AI Code Review Test Script
Write-Host "================================" -ForegroundColor Cyan
Write-Host "AI Code Review Test" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check API key
if (-not $env:ANTHROPIC_API_KEY) {
    Write-Host "ERROR: ANTHROPIC_API_KEY not set" -ForegroundColor Red
    exit 1
}
Write-Host "OK: API key is set" -ForegroundColor Green
Write-Host ""

# Load rules
Write-Host "Loading review rules..." -ForegroundColor Cyan
$reactRules = Get-Content ".github\ai-review\react-review.md" -Raw
$javaRules = Get-Content ".github\ai-review\java-review.md" -Raw
$securityRules = Get-Content ".github\ai-review\security-review.md" -Raw
Write-Host "OK: Rules loaded" -ForegroundColor Green
Write-Host ""

# Load sample diff
Write-Host "Loading sample diff..." -ForegroundColor Cyan
$diff = Get-Content "test-sample-diff.txt" -Raw
Write-Host "OK: Diff loaded" -ForegroundColor Green
Write-Host ""

# Build prompt
$promptText = @"
You are an expert code reviewer. Please review the following Pull Request changes according to these guidelines:

## React Frontend Review Guidelines
$reactRules

## Java Backend Review Guidelines
$javaRules

## Security Review Guidelines
$securityRules

## Pull Request Diff
``````diff
$diff
``````

Please provide your review in the following format:

# Code Review Summary

## Overall Assessment
Brief summary here

## Critical Issues
List critical issues or None found

## Medium Issues
List medium issues or None found

## Minor Issues
List minor issues or None found

## Suggested Improvements
List suggestions

## Positive Observations
List positive aspects
"@

Write-Host "OK: Prompt built" -ForegroundColor Green
Write-Host ""

# Call API
Write-Host "Calling Anthropic API..." -ForegroundColor Cyan
Write-Host "This may take 10-30 seconds..." -ForegroundColor Yellow
Write-Host ""

$body = @{
    model = "claude-sonnet-4-6"
    max_tokens = 4096
    messages = @(
        @{
            role = "user"
            content = $promptText
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" `
        -Method Post `
        -Headers @{
            "content-type" = "application/json"
            "x-api-key" = $env:ANTHROPIC_API_KEY
            "anthropic-version" = "2023-06-01"
        } `
        -Body $body

    $reviewText = $response.content[0].text

    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "AI REVIEW RESULT" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $reviewText
    Write-Host ""
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Test completed successfully!" -ForegroundColor Green

} catch {
    Write-Host "ERROR: API call failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
