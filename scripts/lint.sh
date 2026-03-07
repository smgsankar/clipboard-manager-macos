#!/bin/bash

# SwiftLint runner script for ClipboardManager
# This script runs SwiftLint on the codebase and reports any violations

set -e

echo "Running SwiftLint..."
echo "==================="
echo ""

# Check if SwiftLint is available
if ! command -v swiftlint &> /dev/null; then
    echo "⚠️  SwiftLint not found in PATH"
    echo ""
    echo "SwiftLint will run automatically during builds via Swift Package Manager plugin."
    echo "To run SwiftLint manually, install it:"
    echo ""
    echo "  brew install swiftlint"
    echo ""
    echo "Or download from: https://github.com/realm/SwiftLint"
    exit 1
fi

# Run SwiftLint
swiftlint lint --strict

echo ""
echo "✅ SwiftLint passed!"
