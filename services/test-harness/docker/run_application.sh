#!/bin/sh

# run_application.sh
# run_application shell script


crond > /dev/null &

exec /application ${FLAGS}
