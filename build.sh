#!/bin/bash

set -e

echo "🚀 Building TruyThuDien iOS App..."

cd "$(dirname "$0")"

echo "📦 Generating Xcode project with XcodeGen..."
xcodegen generate

echo "✅ Project generated successfully!"

echo ""
echo "📱 To open the project:"
echo "   open TruyThuDien.xcodeproj"
echo ""
echo "🏗️ To build from command line:"
echo "   xcodebuild -project TruyThuDien.xcodeproj -scheme TruyThuDien -destination 'platform=iOS Simulator,name=iPhone 17' build"
echo ""
echo "🧪 To run tests:"
echo "   xcodebuild -project TruyThuDien.xcodeproj -scheme TruyThuDien -destination 'platform=iOS Simulator,name=iPhone 17' test"
