#!/bin/bash

# load environment variables
set -a && source .env && set +a

# Required variables
required_vars=(
    "acr_name"
    "image_name"
    "image_tag"
)

# Set the current directory to where the script lives.
cd "$(dirname "$0")"

# Function to check if all required arguments have been set
check_required_arguments() {
    # Array to store the names of the missing arguments
    local missing_arguments=()

    # Loop through the array of required argument names
    for arg_name in "${required_vars[@]}"; do
        # Check if the argument value is empty
        if [[ -z "${!arg_name}" ]]; then
            # Add the name of the missing argument to the array
            missing_arguments+=("${arg_name}")
        fi
    done

    # Check if any required argument is missing
    if [[ ${#missing_arguments[@]} -gt 0 ]]; then
        echo -e "\nError: Missing required arguments:"
        printf '  %s\n' "${missing_arguments[@]}"
        [ ! \( \( $# == 1 \) -a \( "$1" == "-c" \) \) ] && echo "  Either provide a .env file or all the arguments, but not both at the same time."
        [ ! \( $# == 22 \) ] && echo "  All arguments must be provided."
        echo ""
        exit 1
    fi
}

####################################################################################

# Check if all required arguments have been set
check_required_arguments

####################################################################################

# Login to ACR.
az acr login --name $acr_name

# Get login server name
acrLoginServer=$(az acr show --name $acr_name --query loginServer --output tsv)

# Tag image
export APP_NAME=my-azure-vote-03
export IMAGE_COMPLETE_NAME=$acrLoginServer/$image_name:$image_tag
echo "Deploying Azure Voting App $IMAGE_COMPLETE_NAME"

# Replace values and deploy app
envsubst < azure-vote-managed-redis.yaml | kubectl apply -f -

# Check Pods
kubectl get pods -n azure-vote-03
