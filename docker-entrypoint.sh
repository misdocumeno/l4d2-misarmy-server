#!/bin/bash

set -e

if [ "$SM_ENV" = "debug" ]; then
    echo "Starting with debugger..."
    exec node --inspect-wait=0.0.0.0:9229 dist/index.js
else
    exec node dist/index.js
fi