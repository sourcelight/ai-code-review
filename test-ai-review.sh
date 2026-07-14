#!/bin/bash

# Test script for AI Code Review workflow
# This simulates what GitHub Actions does in the ai-review.yml workflow

set -e

echo "=================================="
echo "AI Code Review Workflow Test"
echo "=================================="
echo ""

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "ERROR: ANTHROPIC_API_KEY environment variable is not set"
    echo "Please set it with: export ANTHROPIC_API_KEY='your-key-here'"
    exit 1
fi

echo "✓ ANTHROPIC_API_KEY is set"
echo ""

# Load review rules
echo "Loading review rules..."
REACT_RULES=$(cat .github/ai-review/react-review.md)
JAVA_RULES=$(cat .github/ai-review/java-review.md)
SECURITY_RULES=$(cat .github/ai-review/security-review.md)
echo "✓ Review rules loaded"
echo ""

# Create a sample diff (simulating a PR)
echo "Creating sample diff..."
DIFF=$(cat <<'EOF'
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
EOF
)
echo "✓ Sample diff created"
echo ""

# Build the prompt
echo "Building AI review prompt..."
PROMPT=$(cat <<EOF
You are an expert code reviewer. Please review the following Pull Request changes according to these guidelines:

## React Frontend Review Guidelines
$REACT_RULES

## Java Backend Review Guidelines
$JAVA_RULES

## Security Review Guidelines
$SECURITY_RULES

## Pull Request Diff
\`\`\`diff
$DIFF
\`\`\`

Please provide your review in the following format:

# Code Review Summary

## Overall Assessment
[Brief summary]

## Critical Issues
[List critical issues or 'None found']

## Medium Issues
[List medium issues or 'None found']

## Minor Issues
[List minor issues or 'None found']

## Suggested Improvements
[List suggestions]

## Positive Observations
[List positive aspects]
EOF
)
echo "✓ Prompt built"
echo ""

# Call Anthropic API
echo "Calling Anthropic API (Claude Sonnet 4)..."
echo "This may take 10-30 seconds..."
echo ""

RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d "{
    \"model\": \"claude-sonnet-4-20250514\",
    \"max_tokens\": 4096,
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": $(echo "$PROMPT" | jq -Rs .)
      }
    ]
  }")

# Check for errors
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo "ERROR: API call failed"
    echo "$RESPONSE" | jq '.error'
    exit 1
fi

# Extract review text
REVIEW_TEXT=$(echo "$RESPONSE" | jq -r '.content[0].text')

if [ -z "$REVIEW_TEXT" ] || [ "$REVIEW_TEXT" = "null" ]; then
    echo "ERROR: Failed to extract review text from response"
    echo "Response:"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

echo "✓ AI review completed successfully!"
echo ""
echo "=================================="
echo "AI CODE REVIEW RESULT"
echo "=================================="
echo ""
echo "$REVIEW_TEXT"
echo ""
echo "=================================="
echo "Test completed successfully!"
echo "=================================="

# Save review to file
mkdir -p test-results
OUTPUT_FILE="test-results/ai-review-$(date +%Y%m%d-%H%M%S).md"
cat > "$OUTPUT_FILE" <<EOFR
# AI Code Review Test Result
Generated: $(date)

## Sample Diff Reviewed
\`\`\`diff
$DIFF
\`\`\`

---

$REVIEW_TEXT
EOFR

echo ""
echo "Review saved to: $OUTPUT_FILE"
