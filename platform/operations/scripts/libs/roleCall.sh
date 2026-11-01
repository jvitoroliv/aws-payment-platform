#!/bin/bash

#!/bin/bash
# roleCall.sh
# roleCall shell script
# Usage: see --help or README.md


if [[ ! $( timeout 1 nc -vz 169.254.169.254 80 2>&1 ) ]]; then
    echo "Could not contact metadata endpoint..."
    if [[ $(uname -a | grep Darwin ) ]]; then
	echo "running on a mac, skipping metadata check..."
	return
    else
	echo "not running on a mac, something has gone wrong. Exiting"
	exit 1 
    fi
fi

curlCmd="curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials"

role=`$curlCmd`
AWS_ACCESS_KEY_ID=`$curlCmd/$role | grep AccessKeyId | cut -d ':' -f 2 | tr -d '\", '`
AWS_SECRET_ACCESS_KEY=`$curlCmd/$role | grep SecretAccessKey | cut -d ':' -f 2 | tr -d '\", '`
AWS_SESSION_TOKEN=`$curlCmd/$role | grep Token | cut -d ':' -f 2 | tr -d '\", '`

if [[ -z $AWS_DEFAULT_REGION ]]; then
    AWS_DEFAULT_REGION=us-east-1
fi

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN
export AWS_DEFAULT_REGION