#!/usr/bin/env bash

#TODO - refactor/remove

usage() {
    echo "USAGE: Encrypt or decrypt the 'paramStore.tf' file in all terraform envs"
    echo ""
    echo "./cryptAllEnvs.sh [encrypt/decrypt]"
}

# this gives use ROLE; from role build case on prod sub prod
. ./aws_cli_auth_role_mfa.sh

# set our base root dir as ops root
ROOT_DIR="$( cd ../"${BASH_SOURCE[0]%/*}" || exit; pwd )"

# get all our terraform envs, and regions and append them into arrays
cd "$ROOT_DIR/terraform/environments" || exit

dirs=$( ls -l | awk '{ print $9 }' | grep -v "localstack" ) # dropping local stack as there are no secrets.

subProdDir=()
prodDir=()
# hard coded for now, was simpler. In the future just added if we move into another region.
regions=(us-east-1 us-west-2)

# logically filter the returned envs based on prod / subprod env names
for i in $dirs; do
    if [[ $i != "prod" && $i != "stage" ]]; then
        subProdDir+=("$i")
    else
        prodDir+=("$i")
    fi
done

# loop through all envs, and regions. then decrypt or encrypt using the paramstore.sh script
# nesting the loops to iterate through each env/region in the case of your auth method to filter
envs=()
case "${ENVIRONMENT}_${ROLE}" in
  *test_admin*)
    envs=("${subProdDir[@]}")
    ;;
  *prod_admin*)
    envs=("${prodDir[@]}")
    ;;
   *)
   echo -e "you need to auth as a test_admin or a prod_admin"
   ;;
esac

for i in "${envs[@]}"; do
    for j in "${regions[@]}"; do
        echo -e "$1ing file in $ROOT_DIR/terraform/environments/$i/$j"
        cd "$ROOT_DIR/terraform/environments/$i/$j" || exit && ../../../../scripts/paramStore.sh $1
    done
done

cd "$ROOT_DIR/scripts" || exit
