#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
build_args=(-c release)
if [[ -n "${LITEFOCUS_MACOS_SDK:-}" ]]; then
    build_args+=(--sdk "$LITEFOCUS_MACOS_SDK")
elif [[ -d /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ]]; then
    build_args+=(--sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk)
fi
swift build "${build_args[@]}"
mkdir -p build/LiteFocus.app/Contents/MacOS build/LiteFocus.app/Contents/Resources
cp .build/release/LiteFocus build/LiteFocus.app/Contents/MacOS/LiteFocus
cp Support/Info.plist build/LiteFocus.app/Contents/Info.plist
cp Support/LiteFocus.icns build/LiteFocus.app/Contents/Resources/LiteFocus.icns
codesign --force --sign - build/LiteFocus.app
codesign --verify --strict build/LiteFocus.app
printf '%s\n' "$PWD/build/LiteFocus.app"
