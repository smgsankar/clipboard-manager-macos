#!/bin/bash

# Script to run tests with code coverage and generate a report
# Usage: ./scripts/coverage.sh

set -e

echo "Running tests with code coverage..."
swift test --enable-code-coverage

echo ""
echo "Generating coverage report..."
echo ""

xcrun llvm-cov report \
  .build/arm64-apple-macosx/debug/ClipboardManagerPackageTests.xctest/Contents/MacOS/ClipboardManagerPackageTests \
  -instr-profile=.build/arm64-apple-macosx/debug/codecov/default.profdata \
  -ignore-filename-regex="\.build|Tests" \
  -use-color

echo ""
echo "To see detailed line-by-line coverage for a specific file, run:"
echo "xcrun llvm-cov show .build/arm64-apple-macosx/debug/ClipboardManagerPackageTests.xctest/Contents/MacOS/ClipboardManagerPackageTests -instr-profile=.build/arm64-apple-macosx/debug/codecov/default.profdata -ignore-filename-regex='\.build|Tests' [FILE_PATH]"
