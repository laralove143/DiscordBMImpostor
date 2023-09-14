#!/bin/sh

scheme_name=DiscordBMImpostor

cd ~/Documents/$scheme_name
rm -rf ~/Library/Developer/Xcode/DerivedData/$scheme_name*
xcodebuild -scheme $scheme_name -destination platform="macOS,arch=arm64" > xcodebuild.log
/opt/homebrew/bin/swiftlint analyze --compiler-log-path xcodebuild.log > analyze.log
open -a Xcode analyze.log
