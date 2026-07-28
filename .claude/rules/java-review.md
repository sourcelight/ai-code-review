---
patterns:
  - "backend/**/*.java"
  - "**/pom.xml"
  - "backend/**/*.yml"
  - "backend/**/*.yaml"
  - "backend/**/*.properties"
priority: 1
---

# Java Backend Review Guidelines

The AI reviewer should verify the following Java and Spring Boot best practices:

## SOLID Principles
- Single Responsibility: Each class has one clear purpose
- Open/Closed: Code is open for extension, closed for modification
- Liskov Substitution: Subtypes are substitutable for their base types
- Interface Segregation: Interfaces are focused and specific
- Dependency Inversion: Depend on abstractions, not concretions

## Clean Code
- Meaningful and descriptive names
- Functions are small and focused
- No magic numbers or strings
- Proper code comments only where necessary
- No commented-out code

## Java 21 Idioms
- Use of modern Java features (records, sealed classes, pattern matching, text blocks)
- Proper use of Optional
- Streams API usage where appropriate
- Correct use of var keyword

## Spring Boot Best Practices
- Constructor injection over field injection
- Proper use of annotations (@Service, @Controller, @Component)
- Configuration via application.yml
- Proper REST API design
- DTOs for data transfer
- Appropriate use of Spring features

## Exception Handling
- Proper exception handling strategies
- Custom exceptions when appropriate
- Global exception handler usage
- Meaningful error messages
- Proper HTTP status codes

## Business Logic
- Business logic should NOT be in controllers
- Service layer properly implemented
- Clear separation of concerns
- Proper transaction management

## Logging
- Appropriate logging levels (debug, info, warn, error)
- Meaningful log messages
- No sensitive data in logs
- SLF4J usage

## Package Organization
- Logical package structure
- Clear boundaries between layers
- Consistent naming conventions

## Code Quality
- No code duplication
- High readability
- Proper encapsulation
- Immutability where appropriate

## Testability
- Code is easily testable
- Dependencies can be mocked
- Clear test boundaries

## Null Safety
- Proper null checks
- Use of Optional where appropriate
- @NonNull/@Nullable annotations

## Performance Considerations
- Efficient database queries
- Proper caching strategies
- No N+1 query problems
- Appropriate collection usage

## Concrete Improvements
Provide specific, actionable suggestions for refactoring and improvement.
