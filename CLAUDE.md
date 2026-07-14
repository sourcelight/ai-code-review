# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack application with Spring Boot backend (Java 21) and React frontend (TypeScript + Vite) featuring JWT authentication. The project includes AI-powered code review using Anthropic Claude via GitHub Actions.

## Development Commands

### Backend (Spring Boot)

```bash
cd backend
mvn spring-boot:run          # Start server on port 9090
mvn test                     # Run all tests
mvn clean install            # Clean build with dependency installation
mvn test -Dtest=ClassName    # Run a single test class
```

### Frontend (React + Vite)

```bash
cd frontend
npm install                  # Install dependencies
npm run dev                  # Start dev server on port 5173
npm run build                # Build for production (TypeScript compile + Vite build)
npm run preview              # Preview production build
```

### Testing the Full Stack

1. Start backend (runs on port 9090)
2. Start frontend (runs on port 5173)
3. Login credentials: `admin` / `password`

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

### AI Code Review System

GitHub Actions workflow (`.github/workflows/ai-review.yml`) automatically reviews PRs using Anthropic Claude API. Review rules defined in:
- `.github/ai-review/react-review.md` - React/TypeScript best practices
- `.github/ai-review/java-review.md` - Java/Spring Boot patterns, SOLID principles
- `.github/ai-review/security-review.md` - OWASP Top 10, JWT security, secrets management

**To enable:** Add `ANTHROPIC_API_KEY` repository secret in GitHub Settings → Secrets and variables → Actions

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

## Testing Notes

- Backend tests use Spring Boot Test framework
- H2 console available at `http://localhost:9090/h2-console` (JDBC URL: `jdbc:h2:mem:testdb`, username: `sa`, password: empty)
- Default test user created in-memory: `admin` / `password`

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

## Configuration Files

- `backend/src/main/resources/application.yml` - Server port (9090), H2 config, JWT settings
- `frontend/src/api/api.ts` - Backend base URL, request/response interceptors
- `backend/pom.xml` - Java 21, Spring Boot 3.2.5, JJWT 0.12.5
- `frontend/package.json` - React 18, TypeScript, Vite
