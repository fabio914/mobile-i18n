#!/bin/sh

swift build -c release
mv .build/release/i18nGen /usr/local/bin

