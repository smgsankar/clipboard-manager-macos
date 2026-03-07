# Agent Instructions for Clipboard Manager

## Project Overview

This is a macOS clipboard manager application built with Swift and SwiftUI. The application monitors clipboard changes, stores clipboard history in a database, provides search functionality, and offers a menu bar interface with keyboard shortcuts.

## Project Structure

- **Sources/ClipboardManager/**: Main application code
  - **App/**: Application lifecycle and coordination
  - **Core/**: Core business logic (database, store, watcher, search)
  - **Models/**: Data models and preferences
  - **Preferences/**: Settings UI
  - **UI/**: User interface components
  - **Utilities/**: Helper classes and system integrations
- **Tests/ClipboardManagerTests/**: Comprehensive test suite
- **docs/**: Project documentation

## Critical Testing Requirements

⚠️ **MANDATORY: All code changes MUST include corresponding tests.**

### Testing Standards

1. **Test Coverage Requirements**
   - Every new function, method, or class MUST have unit tests
   - UI components MUST have UI component tests
   - Core business logic MUST have comprehensive unit tests
   - Database operations MUST be tested with in-memory/mock databases
   - System integrations MUST have integration tests or mocks

2. **Test Organization**
   - Test files should mirror the source file structure
   - Test class names should match: `{ClassName}Tests.swift`
   - Group related tests using `// MARK: - Test Group Name`
   - Use descriptive test method names: `test_methodName_whenCondition_shouldExpectedBehavior`

3. **Test Quality Standards**
   - **Arrange-Act-Assert** pattern for all tests
   - Each test should test ONE specific behavior
   - Use XCTest framework assertions appropriately
   - Mock external dependencies (pasteboard, system APIs, file system)
   - Test both success and failure paths
   - Test edge cases and boundary conditions
   - Avoid test interdependencies

4. **Before Submitting Changes**
   - Run the full test suite: `swift test`
   - Verify test coverage: `./scripts/coverage.sh`
   - Ensure all tests pass
   - Add tests for any bug fixes to prevent regression
   - Update tests when refactoring existing code

### Example Test Structure

```swift
final class ExampleServiceTests: XCTestCase {
    var sut: ExampleService!
    var mockDependency: MockDependency!
    
    override func setUp() {
        super.setUp()
        mockDependency = MockDependency()
        sut = ExampleService(dependency: mockDependency)
    }
    
    override func tearDown() {
        sut = nil
        mockDependency = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetDependency() {
        XCTAssertNotNil(sut.dependency)
    }
    
    // MARK: - Business Logic Tests
    
    func test_performAction_whenValidInput_shouldReturnSuccess() {
        // Arrange
        let input = "test"
        
        // Act
        let result = sut.performAction(input)
        
        // Assert
        XCTAssertTrue(result.isSuccess)
    }
}
```

## Swift Code Standards

### General Guidelines

- Use Swift 5.5+ features appropriately (async/await, actors, etc.)
- Follow Apple's Swift API Design Guidelines
- Prefer value types (structs) over reference types (classes) when appropriate
- Use meaningful, descriptive names for all identifiers
- Keep functions focused and small (single responsibility)
- Use type inference where it improves readability
- Avoid force unwrapping (`!`) unless absolutely necessary and safe

### SwiftUI Patterns

- Prefer `@State` for view-local state
- Use `@StateObject` for view-owned ObservableObject instances
- Use `@ObservedObject` for ObservableObject instances passed from parent
- Use `@EnvironmentObject` sparingly and document dependencies
- Extract complex views into separate view structs
- Use view modifiers for reusable styling
- Preview providers for all custom views

### Concurrency

- Use `@MainActor` for UI-related code
- Prefer structured concurrency (async/await, TaskGroup)
- Use actors for thread-safe state management
- Document thread safety requirements

### Error Handling

- Use proper Swift error handling (throws, do-catch, Result)
- Define custom error types when appropriate
- Log errors using AppLogger
- Provide meaningful error messages

## Architecture Patterns

### Coordinator Pattern

The app uses a coordinator pattern (`AppCoordinator`) to manage application flow and dependencies. When modifying app-level functionality:
- Consider impact on AppCoordinator
- Maintain clear separation of concerns
- Test coordinator logic

### Store Pattern

`ClipboardStore` manages clipboard state. When working with clipboard data:
- Use the store as the single source of truth
- Emit appropriate events/notifications
- Test store state transitions

### Database Layer

`ClipboardDatabase` handles persistence. When modifying database code:
- Use parameterized queries to prevent SQL injection
- Handle migration scenarios
- Test with in-memory databases
- Clean up resources properly

## Common Development Tasks

### Adding a New Feature

1. Identify where the feature belongs in the architecture
2. Create/update model objects if needed
3. Implement core logic with proper error handling
4. **Write unit tests for the core logic**
5. Add UI components if needed
6. **Write UI component tests**
7. Update AppCoordinator if needed
8. **Update integration tests**
9. Run full test suite and verify coverage
10. Update documentation if needed

### Fixing a Bug

1. Write a failing test that reproduces the bug
2. Fix the bug in the source code
3. Verify the test now passes
4. Check for similar bugs in related code
5. Run full test suite

### Refactoring Code

1. Ensure existing tests pass before refactoring
2. Make incremental changes
3. Update tests to reflect new structure (if needed)
4. Verify all tests still pass after each change
5. Ensure test coverage remains high

## macOS-Specific Considerations

### System Integrations

- **Clipboard Access**: Use `NSPasteboard` carefully, test with mocks
- **Keyboard Shortcuts**: Test using `HotkeyManager`, avoid conflicts
- **Menu Bar**: Test MenuBar components, ensure proper lifecycle
- **Launch at Login**: Test LaunchAtLoginManager behavior
- **Permissions**: Document any new permission requirements

### Performance

- Clipboard monitoring should be efficient and non-blocking
- Database queries should be optimized and indexed
- UI updates should be on main thread
- Consider memory usage for large clipboard history

## Documentation

- Use Swift documentation comments (`///`) for public APIs
- Document complex algorithms or non-obvious code
- Update TECH_SPEC.md for architectural changes
- Keep README current with feature changes

## Before Committing

- [ ] All tests pass: `swift test`
- [ ] Test coverage is maintained or improved
- [ ] Code follows Swift style guidelines
- [ ] No compiler warnings
- [ ] SwiftLint passes
- [ ] Documentation is updated
- [ ] Manual testing completed for UI changes

## Additional Resources

- See [TECH_SPEC.md](docs/TECH_SPEC.md) for technical specifications
- See [COVERAGE.md](docs/COVERAGE.md) for coverage guidelines
- Run `./scripts/coverage.sh` to check test coverage
- Run `./scripts/lint.sh` to manually run SwiftLint (also runs automatically during builds)

---

**Remember: Tests are not optional. Every code change requires corresponding tests.**
