# Clipboard Manager for macOS

## Technical Specification

## 1. Overview

A lightweight macOS menu bar clipboard manager that records clipboard
history and allows users to quickly access and reuse previously copied
text.

Users can: - Access recent clipboard entries from the menu bar - Open a
searchable popup window to browse full history - Copy previous items
back to the clipboard

------------------------------------------------------------------------

## 2. Goals

-   Capture clipboard changes reliably
-   Provide quick access to recent clipboard items
-   Provide searchable clipboard history
-   Maintain minimal system resource usage
-   Operate fully locally without external services

------------------------------------------------------------------------

## 3. Non‑Goals (MVP)

-   Clipboard image history
-   Clipboard file history
-   Cloud sync
-   Cross‑device sync
-   Rich text storage

------------------------------------------------------------------------

## 4. Platform

    Platform: macOS
    Language: Swift
    UI Framework: SwiftUI
    Persistence: SQLite
    App Type: Menu bar application

------------------------------------------------------------------------

## 5. System Architecture

    Menu Bar UI
          |
    Clipboard Store
          |
    SQLite Database
          |
    Clipboard Watcher

Supporting components:

    Hotkey Manager
    Preferences Manager
    Search Engine

------------------------------------------------------------------------

## 6. Clipboard Watcher

Responsible for detecting clipboard changes.

    Monitor: NSPasteboard.general.changeCount
    Polling interval: 300ms

Pseudo logic:

    loop every 300ms
        read pasteboard.changeCount
        if changeCount changed
            read clipboard text
            process item

Processing rules:

-   Ignore non-text clipboard types
-   Ignore empty values
-   Ignore entries larger than size limit
-   Prevent duplicates

------------------------------------------------------------------------

## 7. Clipboard Store

Responsibilities:

    addClipboardItem()
    removeClipboardItem()
    clearHistory()
    getRecentItems()
    searchItems()

Duplicate handling:

    If copied content already exists:
        move item to top
        update timestamp

------------------------------------------------------------------------

## 8. Database

Location:

    ~/Library/Application Support/ClipboardManager/clipboard.db

Table:

    clipboard_items

    id              TEXT (UUID)
    content         TEXT
    timestamp       INTEGER
    source_app      TEXT

Indexes:

    timestamp DESC
    content

------------------------------------------------------------------------

## 9. Data Model

    ClipboardItem

    id: UUID
    content: String
    timestamp: Date
    sourceApplication: String

------------------------------------------------------------------------

## 10. Clipboard Size Limit

Large clipboard entries are ignored.

Recommended limit:

    1MB

------------------------------------------------------------------------

## 11. Menu Bar UI

Menu layout:

    Clipboard
    ----------------------
    item1
    item2
    item3
    item4
    item5
    item6
    item7
    ----------------------
    Show All
    Preferences
    Quit

Rules:

-   Maximum 7 clipboard items
-   Single line preview
-   Text ellipsized if too long

Selecting an item copies it back to clipboard.

------------------------------------------------------------------------

## 12. Popup Window

Opened by:

-   Show All
-   Global shortcut

Layout:

    +-----------------------------------+
    | Search clipboard...               |
    |-----------------------------------|
    | clipboard item                    |
    | clipboard item                    |
    | clipboard item                    |
    +-----------------------------------+

Features:

-   Search clipboard history
-   Copy item again
-   Delete item
-   Clear history

------------------------------------------------------------------------

## 13. Search

Search exists only in popup.

Behavior:

    Case insensitive
    Substring match

Example:

    Search: dock
    Matches: docker ps, docker compose

------------------------------------------------------------------------

## 14. Global Shortcut

Default:

    Cmd + Shift + V

User configurable via preferences.

------------------------------------------------------------------------

## 15. Preferences

Available settings:

    Shortcut configuration
    History size: 10 → 1000
    Default history size: 100
    Launch at login (enabled by default)

------------------------------------------------------------------------

## 16. Clipboard Reuse Workflow

    User copies text
    ↓
    Clipboard watcher detects change
    ↓
    Item stored in database
    ↓
    User opens popup
    ↓
    User selects item
    ↓
    Item copied back to clipboard
    ↓
    User pastes normally (Cmd + V)

------------------------------------------------------------------------

## 17. Performance Targets

    Clipboard detection latency < 300ms
    Memory usage < 50MB
    CPU usage minimal when idle
    Database queries < 50ms

------------------------------------------------------------------------

## 18. Privacy

Clipboard data:

    Stored locally only
    No telemetry
    No analytics
    No cloud sync

------------------------------------------------------------------------

## 19. Project Structure

    ClipboardManager
    │
    ├── App
    │   └── ClipboardApp.swift
    │
    ├── Core
    │   ├── ClipboardWatcher.swift
    │   ├── ClipboardStore.swift
    │   └── ClipboardDatabase.swift
    │
    ├── Models
    │   └── ClipboardItem.swift
    │
    ├── UI
    │   ├── MenuBarView.swift
    │   ├── PopupWindow.swift
    │   └── ClipboardListView.swift
    │
    ├── Preferences
    │   └── PreferencesView.swift
    │
    └── Utilities
        ├── HotkeyManager.swift
        └── LaunchAtLoginManager.swift
