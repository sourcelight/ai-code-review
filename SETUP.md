# Quick Setup Guide

## First Time Setup

### 1. Backend

```bash
cd backend
mvn spring-boot:run
```

Backend starts on http://localhost:8080

### 2. Frontend

```bash
cd frontend
npm install
npm run dev
```

Frontend starts on http://localhost:5173

### 3. Login

Open http://localhost:5173 in your browser and login with:
- Username: `admin`
- Password: `password`

## GitHub Actions Setup

To enable AI Code Review:

1. Get an Anthropic API key from https://console.anthropic.com/
2. Add it as a repository secret:
   - Go to Settings → Secrets and variables → Actions
   - Create secret named `ANTHROPIC_API_KEY`
   - Paste your API key

## Testing the Application

1. Start backend (port 8080)
2. Start frontend (port 5173)
3. Login with admin/password
4. You should see "Hello authenticated user" message
5. Click Logout to return to login page

## Testing CI/CD

1. Push code to GitHub
2. CI workflow runs automatically on push to main or PRs
3. AI review workflow runs automatically on PRs

## Project Features

✅ Spring Boot 3.2.5 + Java 21  
✅ React 18 + TypeScript + Vite  
✅ JWT Authentication  
✅ Protected and public endpoints  
✅ H2 in-memory database  
✅ GitHub Actions CI  
✅ AI Code Review with Anthropic Claude  
✅ Three custom review rules (React, Java, Security)  

## Next Steps

- Customize `application.yml` for your needs
- Modify AI review rules in `.github/ai-review/`
- Add more features and endpoints
- Deploy to production

Enjoy! 🚀
