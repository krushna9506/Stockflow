#!/bin/bash
echo "==> Navigating to stockflow directory..."
cd stockflow || exit 1

echo "==> Downloading Flutter SDK for Vercel..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$(pwd)/flutter/bin"

echo "==> Fetching Flutter dependencies..."
flutter pub get

echo "==> Building Flutter Web Release..."
flutter build web --release
