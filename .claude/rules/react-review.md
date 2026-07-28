---
patterns:
  - "frontend/**/*.tsx"
  - "frontend/**/*.ts"
  - "frontend/**/*.jsx"
  - "frontend/**/*.js"
  - "**/package.json"
  - "**/package-lock.json"
priority: 1
---

# React Frontend Review Guidelines

The AI reviewer should verify the following React and TypeScript best practices:

## React Best Practices
- Components follow Single Responsibility Principle
- Functional components are used consistently
- React hooks are used correctly (dependencies, order, conditional usage)
- No unnecessary re-renders (proper use of useMemo, useCallback, React.memo)
- State management is appropriate for the scope
- Side effects are properly handled with useEffect

## TypeScript Correctness
- Proper type annotations for props, state, and functions
- No use of `any` type unless absolutely necessary
- Type inference is leveraged where appropriate
- Interfaces and types are well-defined
- No type assertions without good reason

## Component Quality
- Component readability and maintainability
- Naming consistency (PascalCase for components, camelCase for functions/variables)
- Proper prop validation
- Avoid prop drilling when unnecessary (consider context or state management)
- Components are appropriately sized and not overly complex

## Error Handling
- Try-catch blocks for async operations
- Error boundaries for component errors
- User-friendly error messages
- Proper loading states

## Axios Usage
- Proper HTTP methods
- Error handling in API calls
- Request/response typing
- Interceptors used correctly

## Folder Organization
- Logical file and folder structure
- Components, pages, utilities properly separated
- Consistent naming conventions

## Accessibility
- Semantic HTML elements
- Proper ARIA labels where needed
- Keyboard navigation support
- Form labels and input associations

## Code Quality
- No duplicated logic
- Reusable components where appropriate
- Clean and readable code
- Proper use of modern JavaScript/TypeScript features

## Suggested Improvements
Provide concrete, actionable suggestions for improvement whenever possible.
