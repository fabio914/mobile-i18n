#!/bin/sh

swift build -c release
sudo mv .build/release/i18nGen /usr/local/bin

