#!/usr/bin/env sh

#!/bin/bash
# verify_background_index.sh
# verify_background_index shell script
# Usage: see --help or README.md


if [ -f "indexes.js" ]; then
    indexes="./indexes.js"
else
    indexes="scripts/mongo_indexes/indexes.js"
fi

missing_background=$(grep -n "\.createIndex" ${indexes} | grep -v "background: true")
if [ -n "$missing_background" ]; then
    echo "There are indexes without 'background: true' set:"
    echo "$missing_background"
    exit 1
fi

exit 0