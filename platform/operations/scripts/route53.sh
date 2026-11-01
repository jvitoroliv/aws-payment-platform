#!/bin/bash

# route53.sh
# DNS records


submitPayload(){
  payload=$(echo "{
    \"Comment\": \"Update for failover\",
            \"Changes\" : [
                {
                    \"Action\": \"UPSERT\",
                    \"ResourceRecordSet\": {
                        \"Name\": \"$1\",
                        \"Type\": \"A\",
                        \"SetIdentifier\": \"$2\",
                        \"Weight\": $3,
                        \"AliasTarget\": {
                            \"HostedZoneId\": \"$4\",
                            \"DNSName\": \"$5\",
                            \"EvaluateTargetHealth\": true
                        }
                    }
                }
            ]
  }")
  echo $payload
  aws route53 change-resource-record-sets --hosted-zone-id $4 --change-batch $payload
}

while [[ -z "${FAIL_OVER_TO_REGION}" ]]; do
  echo "Please choose what region is you are going to fail over to"
  echo -n "FAIL_OVER_TO_REGION: "
  read FAIL_OVER_TO_REGION
    case ${FAIL_OVER_TO_REGION} in
    *us-east-1*)
      export ACTIVE_REGION="us-west-2"
      ;;
    *us-west-2*)
      export ACTIVE_REGION="us-east-1"
      ;;
    *)
      echo "you typed ${FAIL_OVER_TO_REGION} but that isn't a valid choice; please try typing us-east-1 or us-west-2"
      unset FAIL_OVER_TO_REGION
    esac
done

while [[ -z "${ENVIRONMENT}" ]]; do
    echo "Please choose dev test stage prod"
    echo -n "ENVIRONMENT: "
    read ENVIRONMENT

    case "${ENVIRONMENT}" in
    *dev*)
      export ENVIRONMENT=dev
      export ZONEID=ZA7YAMJFXSO1M
      ;;
    *test*)
      export ENVIRONMENT=test
      export ZONEID=ZA7YAMJFXSO1M
      ;;
    *stage*)
      export ENVIRONMENT=stage
      export ZONEID=Z1H1FL5HABSF5
      ;;
    *prod*)
      export ENVIRONMENT=prod
      export ZONEID=Z1H1FL5HABSF5
      ;;
    *)
      echo "you typed ${ENVIRONMENT} but that isn't a valid choice; please try typing dev test stage or prod"
      unset ENVIRONMENT
    esac

done

## Order Goes DNSName; Identifier; Name

declare -a TEST_DNS_EAST=(
"mock-us-east-1-test.platform.example.com.;mock-test-us-east-1;mock-test.platform.example.com."
"fargate-api-test-us-east-1.platform.example.com.;us-east-1 test api;test-api.platform.example.com."
"fargate-api-internal-test-us-east-1.platform.example.com.;us-east-1 test internal api;test-internal-api.platform.example.com."
"fargate-www-test-us-east-1.platform.example.com.;us-east-1 test www;test-www.platform.example.com."
)

declare -a TEST_DNS_WEST=(
"mock-us-west-2-test.platform.example.com.;Mock us-west-2;mock-test.platform.example.com."
"fargate-api-test-us-west-2.platform.example.com.;us-west-2 test api;test-api.platform.example.com."
"fargate-api-internal-test-us-west-2.platform.example.com.;us-west-2 test internal api;test-internal-api.platform.example.com."
"fargate-www-test-us-west-2.platform.example.com.;us-west-2 test www;test-www.platform.example.com."
)

declare -a PROD_DNS_EAST=(
"dualstack.fargate-alb-api-prod-0000000000.us-east-1.elb.amazonaws.com.;us-east-1-api-prod;api.platform.example.com."
"dualstack.internal-fargate-alb-api-internal-prod-0000000000.us-east-1.elb.amazonaws.com.;us-east-1-internal-api-prod;internal-api.platform.example.com."
"dualstack.fargate-alb-web-prod-0000000000.us-east-1.elb.amazonaws.com.;us-east-1-www-prod;www.platform.example.com."
)

declare -a PROD_DNS_WEST=(
"dualstack.fargate-alb-api-prod-1111111111.us-west-2.elb.amazonaws.com.;us-west-2-api-prod;api.platform.example.com."
"dualstack.internal-fargate-alb-api-internal-prod-1111111111.us-west-2.elb.amazonaws.com.;us-west-2-internal-api-prod;internal-api.platform.example.com."
"dualstack.fargate-alb-web-prod-1111111111.us-west-2.elb.amazonaws.com.;us-west-2-www-prod;www.platform.example.com."
)

genApiCall(){
      for DNSNAME in "${@}"; do
      if [[ "${FAIL_OVER_TO_REGION}" == "us-east-1" ]]; then
        export WEIGHT=100
      elif [[ "${FAIL_OVER_TO_REGION}" != "us-east-1" ]]; then
        export WEIGHT=0
      fi
      IFS=';'
      read -a dnsSplit <<< "$DNSNAME"
      submitPayload "${dnsSplit[2]}" "${dnsSplit[1]}" $WEIGHT $ZONEID "${dnsSplit[0]}"
     done

    for DNSNAME in "${@}"; do
      if [[ "${FAIL_OVER_TO_REGION}" == "us-west-2" ]]; then
        export WEIGHT=100
      elif [[ "${FAIL_OVER_TO_REGION}" != "us-west-2" ]]; then
        export WEIGHT=0
      fi
      IFS=';'
      read -a dnsSplit <<< "$DNSNAME"
      submitPayload "${dnsSplit[2]}" "${dnsSplit[1]}" $WEIGHT $ZONEID "${dnsSplit[0]}"
     done
}

if [[ "${ENVIRONMENT}" == "test" ]]; then
    genApiCall "${TEST_DNS_EAST[@]}" "${TEST_DNS_WEST[@]}"
elif [[ "${ENVIRONMENT}" == "prod" ]]; then
    genApiCall "${PROD_DNS_EAST[@]}" "${PROD_DNS_WEST[@]}"
fi


