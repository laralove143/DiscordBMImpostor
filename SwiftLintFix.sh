#!/bin/sh

scheme_name=DiscordBMImpostor

cd ~/Documents/$scheme_name
/opt/homebrew/bin/swiftlint lint --fix --format
