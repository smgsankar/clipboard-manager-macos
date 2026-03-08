# Clipboard Manager for macOS

A lightweight, native macOS clipboard manager that monitors and stores your clipboard history, providing quick access to previously copied text through a menu bar interface.

## Features

- 📋 **Automatic Clipboard Monitoring** - Captures text copied to clipboard automatically
- 🔍 **Full-Text Search** - Quickly find previously copied content with fuzzy search
- ⌨️ **Keyboard Shortcuts** - Customizable hotkeys for instant access
- 📦 **SQLite Storage** - Reliable local persistence with efficient database management
- 🎨 **Menu Bar Interface** - Clean, native SwiftUI interface in the macOS menu bar
- 🔒 **Privacy First** - All data stored locally, no cloud sync or external services
- ⚡️ **Lightweight** - Minimal system resource usage with efficient polling
- 🚀 **Launch at Login** - Optional auto-start on system boot

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 6.0 or later
- Xcode 15.0 or later (for development)

## Installation

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/smgsankar/clipboard-manager-macos.git
cd clipboard-manager-macos
```

2. Build the project:
```bash
swift build -c release
```

3. Run the application:
```bash
.build/release/ClipboardManager
```

## Usage

### Basic Operations

Once running, Clipboard Manager appears in your menu bar with a clipboard icon:

- **View Recent Items**: Click the menu bar icon to see your recent clipboard history
- **Search History**: Use the search field to filter clipboard entries
- **Reuse Content**: Click any item to copy it back to your clipboard
- **Delete Items**: Remove individual entries or clear entire history

### Keyboard Shortcuts

Configure custom keyboard shortcuts in Preferences:

1. Click the menu bar icon
2. Select "Preferences..."
3. Set your preferred shortcut combination

Default: `⌘⇧V` (Command + Shift + V)

### Preferences

Access preferences through the menu bar:

- **History Limit**: Configure how many clipboard items to retain
- **Launch at Login**: Auto-start the app when you log in
- **Keyboard Shortcut**: Customize the global hotkey

## Architecture

The application follows a clean, modular architecture:

```
┌─────────────────┐
│   Menu Bar UI   │
│    (SwiftUI)    │
└────────┬────────┘
         │
┌────────▼────────┐
│ Clipboard Store │
│  (Observable)   │
└────────┬────────┘
         │
┌────────▼────────┐
│SQLite Database  │
│  (Persistence)  │
└─────────────────┘

   Supporting:
   • Clipboard Watcher
   • Search Service
   • Hotkey Manager
   • Launch Manager
```

### Key Components

- **ClipboardWatcher**: Monitors `NSPasteboard` for changes (300ms polling)
- **ClipboardStore**: Central state management and business logic
- **ClipboardDatabase**: SQLite persistence layer with efficient queries
- **ClipboardSearchService**: Full-text search with fuzzy matching
- **HotkeyManager**: Global keyboard shortcut registration
- **AppCoordinator**: Application lifecycle and component coordination

## Development

### Project Structure

```
Sources/ClipboardManager/
├── App/              # Application lifecycle and coordination
├── Core/             # Core business logic (database, store, watcher)
├── Models/           # Data models and preferences
├── Preferences/      # Settings UI
├── UI/               # User interface components
└── Utilities/        # Helper classes and system integrations

Tests/ClipboardManagerTests/  # Comprehensive test suite
docs/                         # Technical documentation
scripts/                      # Development tools
```

### Running Tests

```bash
# Run all tests
swift test

# Run with coverage report
./scripts/coverage.sh

# Run specific test suite
swift test --filter ClipboardStoreTests
```

### Code Quality

This project maintains high code quality standards:

- **Test Coverage**: 66.52% and growing
- **Core Components**: 93-100% coverage
- **All PRs require tests**: Every code change must include tests
- **SwiftLint**: Automatic linting on build
- **Documentation**: Comprehensive inline documentation

### Testing Requirements

⚠️ **All code changes MUST include corresponding tests.**

- Unit tests for business logic
- UI component tests with ViewInspector
- Integration tests for system interactions
- Mock-based tests for external dependencies

See [AGENTS.md](AGENTS.md) for detailed testing guidelines.

### Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful, descriptive names
- Prefer value types (structs) over reference types (classes)
- Document public APIs with Swift doc comments
- Keep functions focused and small (single responsibility)

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Write tests** for all new functionality
3. **Run the test suite** and ensure all tests pass
4. **Follow code style** guidelines and Swift best practices
5. **Update documentation** as needed
6. **Submit a pull request** with a clear description

### Development Workflow

```bash
# Create a feature branch
git checkout -b feature/my-new-feature

# Make changes and add tests
# ...

# Run tests
swift test

# Check coverage
./scripts/coverage.sh

# Commit and push
git commit -am "Add new feature"
git push origin feature/my-new-feature
```

## Documentation

- [TECH_SPEC.md](docs/TECH_SPEC.md) - Technical specifications and architecture
- [COVERAGE.md](docs/COVERAGE.md) - Test coverage report and guidelines
- [AGENTS.md](AGENTS.md) - Development guidelines and standards

## Troubleshooting

### Application doesn't start

- Ensure you're running macOS 13.0 or later
- Check that no other clipboard managers are running
- Review logs in Console.app (filter by "ClipboardManager")

### Clipboard changes not detected

- Verify the app is running in the menu bar
- Check that you're copying text (images/files not supported in MVP)
- Ensure the text is not empty or over the size limit

### Keyboard shortcut not working

- Check for conflicts with other applications
- Try configuring a different key combination in Preferences
- Ensure the app has necessary accessibility permissions

## Privacy & Security

- **All data stored locally**: No cloud sync or external services
- **No network access**: Application runs completely offline
- **SQLite encryption**: Future enhancement planned
- **Secure deletion**: Clipboard items can be permanently removed

## Roadmap

Future enhancements under consideration:

- [ ] Image clipboard support
- [ ] File clipboard support
- [ ] Rich text formatting preservation
- [ ] Clipboard snippets/favorites
- [ ] SQLite database encryption
- [ ] Export/import clipboard history
- [ ] Sync across devices (optional, privacy-respecting)

## License

[Add your chosen license here]

## Acknowledgments

Built with:
- [Swift](https://swift.org/)
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [SQLite](https://www.sqlite.org/)
- [ViewInspector](https://github.com/nalexn/ViewInspector) (testing)

---

**Made with ❤️ for macOS**
