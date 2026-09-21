#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔨 Building AulaKnob..."
./build_app.sh

echo "🚀 Installing AulaKnob to /Applications..."
rm -rf "/Applications/AulaKnob.app"
cp -R "AulaKnob.app" "/Applications/AulaKnob.app"

echo "🎉 AulaKnob installed to /Applications/AulaKnob.app!"
echo "Starting AulaKnob now..."
open "/Applications/AulaKnob.app"
