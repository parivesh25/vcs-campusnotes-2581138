#!/usr/bin/env bash
script_dir=$(dirname -- "$0")
notes_file="$script_dir/notes.txt"
cat -- "$notes_file"
