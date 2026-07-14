# Full-Stack Starter Project

A complete full-stack starter project with Spring Boot backend, React frontend, JWT authentication, and AI-powered code review using Anthropic Claude.

## Features

- **Backend**
  - Spring Boot 3.2.5
  - Java 21
  - Maven
  - Spring Security with JWT Authentication
  - REST APIs
  - H2 In-Memory Database
  - BCrypt Password Encoding

- **Frontend**
  - React 18
  - Vite
  - TypeScript
  - React Router
  - Axios for API calls
  - Simple CSS styling

- **CI/CD**
  - GitHub Actions for automated testing and builds
  - AI Code Review using Anthropic Claude
  - Custom review rules for React, Java, and Security

## Prerequisites

- **Backend**
  - JDK 21 or higher
  - Maven 3.6+

- **Frontend**
  - Node.js 18+ 
  - npm 9+

- **For AI Code Review**
  - GitHub repository
  - Anthropic API key

## Project Structure

```
project-root/
├── backend/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/example/starter/
│   │   │   │   ├── config/           # Security and app configuration
│   │   │   │   ├── controller/       # REST controllers
│   │   │   │   ├── dto/              # Data Transfer Objects
│   │   │   │   ├── exception/        # Exception handlers
│   │   │   │   ├── security/         # JWT filter
│   │   │   │   ├── service/          # Business logic
│   │   │   │   ├── util/             # JWT utilities
│   │   │   │   └── StarterApplication.java
│   │   │   └── resources/
│   │   │       └── application.yml
│   │   └── test/
│   └── pom.xml
├── frontend/
│   ├── src/
│   │   ├── api/                      # Axios configuration
│   │   ├── pages/                    # Login and Home pages
│   │   ├── App.tsx                   # Main app with routing
│   │   ├── main.tsx                  # Entry point
│   │   └── index.css                 # Styles
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.json
│   └── vite.config.ts
└── .github/
    ├── workflows/
    │   ├── ci.yml                    # CI pipeline
    │   └── ai-review.yml             # AI code review
    └── ai-review/
        ├── react-review.md           # React review rules
        ├── java-review.md            # Java review rules
        └── security-review.md        # Security review rules
```

## Getting Started

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Run the Spring Boot application:
   ```bash
   mvn spring-boot:run
   ```

   The backend will start on `http://localhost:8080`

3. Run tests:
   ```bash
   mvn test
   ```

#### H2 Console

The H2 database console is available at `http://localhost:8080/h2-console`

- JDBC URL: `jdbc:h2:mem:testdb`
- Username: `sa`
- Password: (leave empty)

### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

   The frontend will start on `http://localhost:5173`

4. Build for production:
   ```bash
   npm run build
   ```

## Login Credentials

Use these credentials to log in:

- **Username:** `admin`
- **Password:** `password`

## API Endpoints

### Public Endpoints

- `POST /api/auth/login` - User login (returns JWT token)
- `GET /api/public` - Public endpoint (no authentication required)

### Protected Endpoints (Requires JWT)

- `GET /api/hello` - Returns a greeting message

## Authentication Flow

1. User submits login credentials to `/api/auth/login`
2. Backend validates credentials and returns a JWT token
3. Frontend stores the token in localStorage
4. Frontend includes the token in the Authorization header for protected API calls
5. Backend validates the token on each request using the JWT filter

## GitHub Actions CI/CD

### CI Pipeline

The CI pipeline runs on every push to `main` and on pull requests:

- **Backend Job:** Runs Maven tests
- **Frontend Job:** Installs dependencies and builds the project

### AI Code Review

The AI code review workflow automatically reviews pull requests using Anthropic's Claude:

#### Setup

1. Get an Anthropic API key from [Anthropic Console](https://console.anthropic.com/)

2. Add the API key as a GitHub repository secret:
   - Go to your repository Settings
   - Navigate to Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `ANTHROPIC_API_KEY`
   - Value: Your Anthropic API key

#### How It Works

1. When a pull request is opened or updated, the workflow triggers
2. It fetches the diff between the PR and the base branch
3. Loads the review rules from `.github/ai-review/`
4. Sends the diff and rules to Claude via Anthropic API
5. Posts the AI review as a comment on the pull request

#### Review Categories

The AI reviewer checks for:

- **React Best Practices:** Component design, hooks usage, TypeScript correctness
- **Java Best Practices:** SOLID principles, Clean Code, Spring Boot patterns
- **Security Issues:** OWASP Top 10, injection risks, authentication flaws

## Customization

### Backend Configuration

Edit `backend/src/main/resources/application.yml` to configure:
- Database settings
- JWT secret and expiration
- Server port
- Logging levels

**Note:** For production, use environment variables or a secure vault for sensitive configuration like JWT secrets.

### Frontend Configuration

Edit `frontend/src/api/api.ts` to change:
- API base URL
- Request/response interceptors
- Default headers

### AI Review Rules

Customize the review rules in `.github/ai-review/`:
- `react-review.md` - React and TypeScript guidelines
- `java-review.md` - Java and Spring Boot guidelines  
- `security-review.md` - Security best practices

## Development Tips

### Backend

- Use constructor injection for better testability
- Keep business logic in service classes, not controllers
- Use DTOs for API request/response
- Follow package-by-feature or package-by-layer structure

### Frontend

- Keep components small and focused
- Use TypeScript for type safety
- Handle loading and error states
- Avoid prop drilling - use context or state management for deeply nested data

### Security

- Never commit secrets or API keys
- Use HTTPS in production
- Implement rate limiting for authentication endpoints
- Add proper CORS configuration for your domain
- Use strong JWT secrets
- Consider using HttpOnly cookies instead of localStorage for tokens in production

## Troubleshooting

### Backend Issues

**Port 8080 already in use:**
```bash
# Change the port in application.yml
server:
  port: 8081
```

**Maven build fails:**
```bash
# Clean and rebuild
mvn clean install
```

### Frontend Issues

**Port 5173 already in use:**
```bash
# Vite will automatically try the next available port
# Or change it in vite.config.ts
```

**CORS errors:**
- Ensure the backend CORS configuration includes your frontend URL
- Check that the backend is running on port 8080

**Token not working:**
- Check browser console for errors
- Verify the token is stored in localStorage
- Ensure the backend JWT secret matches

## License

This project is provided as-is for educational and starter purposes.

## Contributing

This is a starter template. Feel free to fork and customize for your needs.
