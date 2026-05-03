#!/usr/bin/env bash
# Claude Code status line: model name + context usage progress bar

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used" ]; then
  # Round to nearest integer
  used_int=$(printf "%.0f" "$used")
  remaining_int=$((100 - used_int))

  # Build a 20-char progress bar
  filled=$(( used_int * 20 / 100 ))
  empty_blocks=$(( 20 - filled ))

  bar=""
  for i in $(seq 1 $filled); do
    bar="${bar}█"
  done
  for i in $(seq 1 $empty_blocks); do
    bar="${bar}░"
  done

  # Color the bar: green < 60%, yellow 60-85%, red > 85%
  if [ "$used_int" -ge 85 ]; then
    color="\033[0;31m"   # red
  elif [ "$used_int" -ge 60 ]; then
    color="\033[0;33m"   # yellow
  else
    color="\033[0;32m"   # green
  fi
  reset="\033[0m"

  printf "%s  ${color}[%s]${reset} %d%% used" "$model" "$bar" "$used_int"
else
  printf "%s  [context: no data]" "$model"
fi
