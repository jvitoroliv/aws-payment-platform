#!/bin/sh

set -euo

# Give karapace schema registry a little more time to start-up properly
sleep 15

for schema in /schemas/*; do
    python3 ./prep.py "$schema"
    http post http://karapace-registry:7878/subjects/issuing.account-management.company-value/versions < data.json
done
