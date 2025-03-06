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

# Create image
az acr build --registry $acr_name --image $image_name:$image_tag --file ./Dockerfile .
#docker build -t $image_name:$image_tag .
az acr build --registry $acr_name --image $image_name:$image_tag-rad --file ./Dockerfile.rad .

# Login to ACR.
#az acr login --name $acr_name

# Get login server name
#acrLoginServer=$(az acr show --name $acr_name --query loginServer --output tsv)

# Tag image
#docker tag $image_name:$image_tag $acrLoginServer/$image_name:$image_tag

# Push image
#docker push $acrLoginServer/$image_name:$image_tag

# List images in repository
az acr repository list --name $acr_name --output table

# Show tags for the image
az acr repository show-tags --name $acr_name --repository $image_name --output table
