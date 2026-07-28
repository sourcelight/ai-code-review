# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository, both for **interactive development** and **automated code reviews**.

## Project Overview

Full-stack application with Spring Boot backend (Java 21) and React frontend (TypeScript + Vite) featuring JWT authentication.

**Repository Structure:**
- `backend/` - Spring Boot REST API (port 9090)
- `frontend/` - React + TypeScript + Vite (port 5173)
- `.claude/rules/` - AI code review rules with pattern matching
- `.github/workflows/` - CI/CD including automated code reviews

## Architecture

### Backend Architecture

**JWT Authentication Flow:**
1. `JwtAuthenticationFilter` (OncePerRequestFilter) intercepts all requests
2. Extracts Bearer token from Authorization header
3. `JwtUtil` validates token signature and expiration
4. If valid, sets authentication in SecurityContext
5. Controllers access authenticated user via SecurityContext

**Security Configuration:**
- Public endpoints: `/api/auth/**`, `/api/public`, `/h2-console/**`
- All other `/api/**` endpoints require valid JWT
- CORS configured for `http://localhost:5173`
- CSRF disabled (stateless JWT authentication)
- Session management: STATELESS

**Package Structure:**
- `config/` - Spring Security setup, CORS, beans
- `controller/` - REST endpoints (keep business logic OUT of controllers)
- `dto/` - Request/response objects for API contracts
- `security/` - JWT filter implementation
- `service/` - Business logic layer (use constructor injection)
- `util/` - JWT token generation/validation utilities
- `exception/` - Global exception handler

**Key Details:**
- H2 in-memory database (resets on restart)
- BCrypt password encoding
- JWT secret and expiration configured in `application.yml`
- Constructor injection used throughout (not field injection)
- Backend runs on port **9090** (not 8080)

### Frontend Architecture

**Authentication Flow:**
1. User submits credentials to `/api/auth/login`
2. Store JWT token in localStorage
3. Axios request interceptor (`api.ts`) automatically adds `Bearer <token>` to all requests
4. Router protects routes by checking localStorage token

**Key Files:**
- `api/api.ts` - Axios instance with base URL (`http://localhost:9090/api`) and JWT interceptor
- `pages/Login.tsx` - Login form, stores token on success
- `pages/Home.tsx` - Protected page showing authenticated content
- `App.tsx` - React Router setup with authentication routing

**API Integration:**
- Base URL: `http://localhost:9090/api`
- Token storage: localStorage (key: `'token'`)
- Request interceptor auto-attaches token to all API calls

## Important Conventions

### Backend

- **Constructor injection only** - Never use `@Autowired` field injection
- **Business logic in services** - Controllers should be thin, delegating to services
- **Use DTOs** - Never expose entity classes directly in controller methods
- **Java 21 features** - Leverage records, pattern matching, sealed classes where appropriate
- **No hardcoded secrets** - JWT secret in `application.yml` is for dev only; use environment variables in production

### Frontend

- **TypeScript strict mode** - Avoid `any` type; use proper type annotations
- **API calls via axios instance** - Always import from `api/api.ts` to get automatic JWT injection
- **Error handling** - Wrap async operations in try-catch; show user-friendly error messages
- **Loading states** - Handle loading/error states in components

### Security

- **JWT token validation** - Backend validates on every request via filter
- **CORS whitelist** - Only `http://localhost:5173` allowed; update for production domains
- **Password encoding** - BCrypt used; never store plaintext passwords
- **Token storage** - localStorage used for simplicity; consider HttpOnly cookies for production

## Common Patterns

**Adding a new protected endpoint:**
1. Create method in controller with proper HTTP mapping
2. Business logic goes in service layer
3. Use DTOs for request/response
4. Endpoint automatically requires JWT (not under `/api/auth/**` or `/api/public`)

**Adding a new React page:**
1. Create component in `pages/`
2. Add route in `App.tsx`
3. Check token in component or use route guards
4. Import axios from `api/api.ts` for authenticated API calls

---

## For Automated Code Reviews (CI/CD Context)

When Claude Code runs in GitHub Actions for PR reviews:

### Review Rules Location

Code review guidelines are in `.claude/rules/` with automatic pattern matching:
- `.claude/rules/react-review.md` - React/TypeScript best practices
- `.claude/rules/java-review.md` - Java/Spring Boot patterns, SOLID principles
- `.claude/rules/security-review.md` - OWASP Top 10, JWT security, secrets management

**Smart Loading:** Rules load automatically based on changed files:
- Frontend changes → loads `react-review.md`
- Backend changes → loads `java-review.md`
- Security rules → always loaded (`always_load: true`)

### Review Focus

When reviewing PRs, prioritize:

1. **Security Issues** (Critical)
   - SQL injection, XSS, authentication bypasses
   - Hardcoded secrets or credentials
   - Improper JWT validation
   - CORS misconfigurations

2. **Architecture Violations** (High)
   - Business logic in controllers
   - Field injection instead of constructor injection
   - Direct entity exposure (not using DTOs)
   - Violation of SOLID principles

3. **Type Safety** (Medium)
   - Use of `any` type in TypeScript
   - Missing type annotations
   - Improper Optional usage in Java

4. **Best Practices** (Low)
   - Code duplication
   - Missing error handling
   - Inconsistent naming
   - TODO/FIXME comments

### Review Output Format

Provide reviews in this structure:

```markdown
# Code Review Summary

## Overall Assessment
[Brief assessment of changes - 2-3 sentences]

## Critical Issues
[Security vulnerabilities, breaking changes, or 'None found']
- Issue description with file:line reference
- Why it's critical
- Suggested fix

## Medium Issues
[Architecture violations, type safety, or 'None found']
- Issue description with file:line reference
- Why it matters
- Suggested fix

## Minor Issues
[Style, best practices, or 'None found']

## Suggested Improvements
[Optional refactoring, optimizations]

## Positive Observations
[Good practices worth highlighting]
```

### What NOT to Flag in Automated Reviews

- Formatting issues (handled by linters/formatters)
- Subjective style preferences
- Naming that follows existing conventions
- TODOs/FIXMEs (unless security-related)
- Test code (unless obviously broken)

### Context Awareness

- **PR size matters**: Large PRs get high-level review; small PRs get detailed review
- **Changed files matter**: Only review what actually changed
- **Test changes**: Be lenient with test code unless tests are fundamentally broken
- **Documentation**: Don't flag missing docs unless API contracts changed

---

## For Interactive Development

### Development Commands

**Backend (Spring Boot):**
```bash
cd backend
mvn spring-boot:run          # Start server on port 9090
mvn test                     # Run all tests
mvn clean install            # Clean build with dependency installation
mvn test -Dtest=ClassName    # Run a single test class
```

**Frontend (React + Vite):**
```bash
cd frontend
npm install                  # Install dependencies
npm run dev                  # Start dev server on port 5173
npm run build                # Build for production
npm run preview              # Preview production build
```

**Testing the Full Stack:**
1. Start backend (runs on port 9090)
2. Start frontend (runs on port 5173)
3. Login credentials: `admin` / `password`

### Testing Notes

- Backend tests use Spring Boot Test framework
- H2 console available at `http://localhost:9090/h2-console`
  - JDBC URL: `jdbc:h2:mem:testdb`
  - Username: `sa`
  - Password: (empty)
- Default test user: `admin` / `password`

### Configuration Files

- `backend/src/main/resources/application.yml` - Server port (9090), H2 config, JWT settings
- `frontend/src/api/api.ts` - Backend base URL, request/response interceptors
- `backend/pom.xml` - Java 21, Spring Boot 3.2.5, JJWT 0.12.5
- `frontend/package.json` - React 18, TypeScript, Vite
