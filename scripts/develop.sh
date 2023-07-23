#!/bin/sh

swift ./front_app/ContentView.swift &

# fg 実行でないと port bind しないっぽいので
iex -S mix
