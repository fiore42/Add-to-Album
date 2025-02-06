#!/bin/bash

# Find all function definitions in .swift files
find . -name "*.swift" | xargs grep -E "func\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\(" | awk '{for (i=1; i<=NF; i++) if ($i == "func") print $(i+1)}' | sed 's/(.*//' | sort | uniq -d


