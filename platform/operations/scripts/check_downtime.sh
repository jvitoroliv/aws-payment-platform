#!/bin/bash

ENV=$1
## to run for testing on risky infra changes to ensure no downtime [[ in preceding envs ]]
## while true; do ./check_downtime.sh test; done


function testCurl {
  echo -n "checking $1 ($2)..."
  curl -s -o /dev/null -w "%{http_code}" $2 && echo " ok" || echo " NOT OK"
}

testCurl "$1 web url" "https://$1-www.platform.example.com/build-info.json"

testCurl "$1 api url" "https://$1-api.platform.example.com/"

testCurl "$1 api url" "https://common-api-$1.platform.example.com/"