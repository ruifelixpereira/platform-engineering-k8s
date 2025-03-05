#!/bin/bash

# load environment variables
set -a && source .env && set +a

# Required variables
required_vars=(
    "resource_group"
    "k8s_cluster_name"
    "kbl_aks_uai"
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

subscriptionID=$(az account show --query id --output tsv)
tenantID=$(az account show --query tenantId --output tsv)

# Get the principal ID for a system-assigned managed identity.
kbl_aks_uai_cli_id=$(az identity show --name $kbl_aks_uai  --resource-group $resource_group --query clientId --output tsv)

# set permissions
az role assignment create --assignee $kbl_aks_uai_cli_id --role "Contributor" --scope /subscriptions/$subscriptionID
# here we are using a very coarse, high priviliged role, this is NOT RECOMMENDED, so please review with your security teams. Later you will be setting RBAC on resources so you need to ensure that whatever UAI you use has the right permissions. Also think about how you are securing access to this K8s cluster!

# set context
kubectl config use-context $k8s_cluster_name

# add helm repo
helm repo add aso2 https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts

# install ASO
helm upgrade --install aso2 aso2/azure-service-operator \
    --create-namespace \
    --namespace=azureserviceoperator-system \
    --set azureSubscriptionID=$subscriptionID \
    --set azureClientID=$kbl_aks_uai_cli_id \
    --set crdPattern='resources.azure.com/*;containerservice.azure.com/*;keyvault.azure.com/*;managedidentity.azure.com/*;eventhub.azure.com/*;cache.azure.com/*'
