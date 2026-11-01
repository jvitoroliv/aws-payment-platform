#!/bin/bash

set -e

# Script to compare security groups across environments and regions
# Usage: ./sg-compare.sh <environment> [region] [comparison-type]
#   environment: dev, test, stage, prod (required)
#   region: us-east-1 (default), us-west-2 (optional)
#   comparison-type: sg-to-sg (default), sg-to-allowlist (optional)

# Resolve script location regardless of caller's working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to display usage
usage() {
    echo "Usage: $0 <environment> [region] [comparison-type]"
    echo ""
    echo "Arguments:"
    echo "  environment      Environment to compare (dev, test, stage, prod) - REQUIRED"
    echo "  region          AWS region (us-east-1, us-west-2) - Default: us-east-1"
    echo "  comparison-type Comparison type (sg-to-sg, sg-to-allowlist) - Default: sg-to-sg"
    echo ""
    echo "Examples:"
    echo "  $0 dev                           # dev us-east-1 sg-to-sg"
    echo "  $0 prod us-west-2               # prod us-west-2 sg-to-sg"
    echo "  $0 stage us-east-1 sg-to-allowlist  # stage us-east-1 sg-to-allowlist"
    exit 1
}

# Validate environment parameter
if [[ $# -lt 1 ]]; then
    echo "Error: Environment parameter is required"
    usage
fi

ENVIRONMENT=$1
REGION=${2:-us-east-1}
COMPARISON_TYPE=${3:-sg-to-sg}

# Validate environment
case $ENVIRONMENT in
    dev)
        export AWS_PROFILE=dev
        ;;
    test)
        export AWS_PROFILE=dev
        ;;
    stage)
        export AWS_PROFILE=stage
        ;;
    prod)
        export AWS_PROFILE=prod
        ;;
    *)
        echo "Error: Invalid environment '$ENVIRONMENT'. Must be one of: dev, test, stage, prod"
        usage
        ;;
esac

# Validate region
case $REGION in
    us-east-1|us-west-2)
        ;;
    *)
        echo "Error: Invalid region '$REGION'. Must be one of: us-east-1, us-west-2"
        usage
        ;;
esac

# Validate comparison type
case $COMPARISON_TYPE in
    sg-to-sg|sg-to-allowlist)
        ;;
    *)
        echo "Error: Invalid comparison type '$COMPARISON_TYPE'. Must be one of: sg-to-sg, sg-to-allowlist"
        usage
        ;;
esac

# Set up AWS region
export AWS_REGION=$REGION
AWS_REGION_SHORT=$(echo $REGION | sed 's/us-east-1/ue1/; s/us-west-2/uw2/')

echo "# Comparing security groups in ${ENVIRONMENT} ${REGION} environment (${COMPARISON_TYPE})"
echo

# Function to get Cards API source SG based on environment and region
get_cards_api_source_sg() {
    local env=$1
    local region=$2
    
    case "${env}-${region}" in
        dev-us-east-1)
            echo "dev-us-east-1-card-service-alb-20240827230321755300000004"
            ;;
        dev-us-west-2)
            echo "dev-us-west-2-card-service-alb-20240827235512676800000007"
            ;;
        test-us-east-1)
            echo "test-us-east-1-card-service-alb-20240827225305472000000007"
            ;;
        test-us-west-2)
            echo "test-us-west-2-card-service-alb-20240827235533740400000007"
            ;;
        stage-us-east-1)
            echo "stage-us-east-1-card-service-alb-2024120320091342820000000a"
            ;;
        stage-us-west-2)
            echo "stage-us-west-2-card-service-alb-20241203200908047500000004"
            ;;
        prod-us-east-1)
            echo "prod-us-east-1-card-service-alb-2024112100402472890000000e"
            ;;
        prod-us-west-2)
            echo "prod-us-west-2-card-service-alb-20241121004008803300000002"
            ;;
        *)
            echo "ERROR: Unknown environment-region combination: ${env}-${region}" >&2
            exit 1
            ;;
    esac
}

# Function to get target SGs for Cards API based on environment and comparison type
get_cards_api_targets() {
    local env=$1
    local comparison_type=$2
    
    if [[ $comparison_type == "sg-to-allowlist" ]]; then
        echo "--target-allowlist ${env}-cards-api-internal-alb-ingress --environment ${env}"
    else
        # Check if environment has dual targets
        case $env in
            dev|test)
                echo "--target-sgs ${env}-cards-api-internal-alb-ingress-1 ${env}-cards-api-internal-alb-ingress-2"
                ;;
            stage|prod)
                echo "--target-sgs ${env}-cards-api-internal-alb-ingress-1"
                ;;
        esac
    fi
}

# Function to get target SGs for other APIs based on environment and comparison type
get_standard_targets() {
    local env=$1
    local comparison_type=$2
    local service=$3
    
    if [[ $comparison_type == "sg-to-allowlist" ]]; then
        echo "--target-allowlist ${env}-${service} --environment ${env}"
    else
        # Check if environment has dual targets for internal services
        if [[ $service == *"internal"* ]]; then
            case $env in
                dev|test)
                    echo "--target-sgs ${env}-${service}-1 ${env}-${service}-2"
                    ;;
                stage|prod)
                    echo "--target-sgs ${env}-${service}-1"
                    ;;
            esac
        else
            # Public services always have single target
            echo "--target-sgs ${env}-${service}-1"
        fi
    fi
}

# Cards API internal security groups comparison
echo "## Comparing Cards API internal security groups"
CARDS_SOURCE_SG=$(get_cards_api_source_sg $ENVIRONMENT $REGION)
CARDS_TARGETS=$(get_cards_api_targets $ENVIRONMENT $COMPARISON_TYPE)
${SCRIPT_DIR}/sg-compare.sh --source-sgs $CARDS_SOURCE_SG $CARDS_TARGETS
echo

# Payments API internal security groups comparison
if [[ $ENVIRONMENT != "stage" ]]; then
    echo "## Comparing Payments API internal security groups"
    PAYMENTS_TARGETS=$(get_standard_targets $ENVIRONMENT $COMPARISON_TYPE "payments-api-internal-alb-ingress")
    ${SCRIPT_DIR}/sg-compare.sh --source-sgs payments-scheduler-api-${ENVIRONMENT}-${REGION}-internal-https-lb-sg $PAYMENTS_TARGETS
    echo
fi

# TAG API internal security groups comparison
echo "## Comparing TAG API internal security groups"
TAG_INTERNAL_TARGETS=$(get_standard_targets $ENVIRONMENT $COMPARISON_TYPE "tag-api-internal-alb-ingress")
${SCRIPT_DIR}/sg-compare.sh --source-sgs ecs-api_internal_${ENVIRONMENT}_${REGION}_https_lb_0 $TAG_INTERNAL_TARGETS
echo

# TAG API Public security groups comparison
echo "## Comparing TAG API Public security groups"
TAG_PUBLIC_TARGETS=$(get_standard_targets $ENVIRONMENT $COMPARISON_TYPE "tag-api-public-alb-ingress")
${SCRIPT_DIR}/sg-compare.sh --source-sgs ecs-api_${ENVIRONMENT}_${REGION}_https_lb_0 $TAG_PUBLIC_TARGETS
echo

# TAG Common API internal security groups comparison
echo "## Comparing TAG Common API internal security groups"
TAG_COMMON_INTERNAL_TARGETS=$(get_standard_targets $ENVIRONMENT $COMPARISON_TYPE "tag-common-api-internal-alb-ingress")
${SCRIPT_DIR}/sg-compare.sh --source-sgs ecs-common-api_${ENVIRONMENT}_${REGION}_internal_https_lb_0 $TAG_COMMON_INTERNAL_TARGETS
echo

# TAG Common API Public security groups comparison
echo "## Comparing TAG Common API Public security groups"
TAG_COMMON_PUBLIC_TARGETS=$(get_standard_targets $ENVIRONMENT $COMPARISON_TYPE "tag-common-api-public-alb-ingress")
${SCRIPT_DIR}/sg-compare.sh --source-sgs ecs-common-api_${ENVIRONMENT}_${REGION}_https_lb_0 $TAG_COMMON_PUBLIC_TARGETS
echo

# TAG Web internal security groups comparison
echo "## Comparing TAG Web internal security groups"
TAG_WEB_INTERNAL_TARGETS=$(get_standard_targets $ENVIRONMENT $COMPARISON_TYPE "tag-web-internal-alb-ingress")
${SCRIPT_DIR}/sg-compare.sh --source-sgs web-internal_${ENVIRONMENT}_${REGION}_https_lb_0 $TAG_WEB_INTERNAL_TARGETS
echo

# TAG Web public security groups comparison
echo "## Comparing TAG Web public security groups"
TAG_WEB_PUBLIC_TARGETS=$(get_standard_targets $ENVIRONMENT $COMPARISON_TYPE "tag-web-public-alb-ingress")
${SCRIPT_DIR}/sg-compare.sh --source-sgs web_${ENVIRONMENT}_${REGION}_https_lb_0 $TAG_WEB_PUBLIC_TARGETS
echo

echo "# Comparison complete for ${ENVIRONMENT} ${REGION} (${COMPARISON_TYPE})"
