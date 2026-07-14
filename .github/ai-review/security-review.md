# Security Review Guidelines

The AI reviewer should inspect for the following security concerns based on OWASP Top 10 and general security best practices:

## Injection Risks
- SQL Injection: Use parameterized queries, prepared statements, ORM
- Command Injection: Never execute shell commands with user input
- LDAP Injection: Proper input sanitization
- Expression Language Injection: Avoid dynamic expression evaluation

## Cross-Site Scripting (XSS)
- Proper output encoding
- Content Security Policy headers
- No innerHTML with untrusted data
- Sanitization of user input before rendering

## Cross-Site Request Forgery (CSRF)
- CSRF tokens properly implemented
- SameSite cookie attributes
- Verify origin headers

## JWT Security
- JWT secrets are strong and not hardcoded in production
- Proper token expiration times
- Token validation on every request
- Secure token storage (not in localStorage for sensitive apps)
- Algorithm verification (avoid 'none' algorithm)

## Secret Management
- No hardcoded credentials
- No API keys or tokens in code
- Use environment variables or secure vaults
- Secrets not logged or exposed in error messages

## Authentication Issues
- Strong password policies
- Password hashing (BCrypt, Argon2)
- No password transmission in GET requests
- Proper session management
- Account lockout mechanisms

## Authorization Issues
- Proper role-based access control
- Verify user permissions on every request
- No insecure direct object references
- Principle of least privilege

## Sensitive Data Exposure
- Sensitive data encrypted at rest and in transit
- HTTPS enforced
- No sensitive data in logs
- Proper key management
- No sensitive data in URLs

## Input Validation
- Validate all user inputs
- Whitelist validation preferred over blacklist
- Type checking and length restrictions
- Proper regex validation

## Dependency Vulnerabilities
- Check for known vulnerabilities in dependencies
- Keep dependencies up to date
- Use dependency scanning tools

## CORS Misconfiguration
- CORS properly configured
- No overly permissive CORS settings (avoid wildcard *)
- Proper origin whitelisting

## Security Headers
- X-Frame-Options
- X-Content-Type-Options
- Strict-Transport-Security
- Content-Security-Policy

## Database Security
- Least privilege database access
- Encrypted connections
- No default credentials
- Proper error handling (don't expose schema)

## Error Handling
- No stack traces exposed to users
- Generic error messages for authentication failures
- Proper logging of security events

## Session Management
- Secure session tokens
- Proper session timeout
- Session invalidation on logout
- No session fixation vulnerabilities

## Cryptography
- Use strong, modern algorithms
- Proper key sizes
- No custom crypto implementations
- Secure random number generation

## File Upload Security
- Validate file types
- Limit file sizes
- Scan for malware
- Store outside web root

## Rate Limiting
- API rate limiting implemented
- Brute force protection
- DDoS mitigation

## Logging and Monitoring
- Security events logged
- Anomaly detection
- No sensitive data in logs

## Critical Action Required
Highlight every potential security concern, even if minor. Security issues should be treated as high priority.
