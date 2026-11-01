#!/bin/bash

#!/bin/bash
# datadogDownTime.sh
# data source lookups
# Usage: see --help or README.md


usage () {
    echo "./datadogDownTime.sh [environment_to_mute]"
}

if [[ -z $1 ]]; then
    echo "Must pass an environment to mute in datadog!"
    usage
    exit 1
fi

if [[ $(uname -a | grep Darwin) ]]; then
    endCmd="date -v+1H +%s"
elif [[ $(uname -a | grep Ubuntu) ]]; then
    endCmd="date -d +1Hour +%s"
else 
    echo "Running on an unrecognized platform, but we'll try anyway..."
    endCmd="date -d +1Hour +%s"
fi

api_key="${DD_API_KEY:?Set DD_API_KEY environment variable}"
app_key="${DD_APP_KEY:?Set DD_APP_KEY environment variable}"

start=$(date +%s)
end=$($endCmd)
env="environment:$1"

output=$(curl -X POST \
-H "Content-type: application/json" \
-H "DD-API-KEY: ${api_key}" \
-H "DD-APPLICATION-KEY: ${app_key}" \
-d '{
      "scope": '\"${env}\"',
      "start": '"${start}"',
      "end": '"${end}"'
}' \
    "https://api.datadoghq.com/api/v1/downtime")

if [[ $(echo $output | grep '"active":true') ]]; then
    echo "Downtime posted successfully!"
    exit 0
else
    echo "Failure while posting downtime..."
    exit 2
fi
