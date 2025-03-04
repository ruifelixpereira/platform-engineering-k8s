#!/bin/bash

# load environment variables
set -a && source .env && set +a

# Required variables
required_vars=(
    "shared_resource_group"
    "acr_name"
    "resource_group"
    "location"
    "k8s_cluster_name"
    "k8s_cluster_vm_size"
    "cp_aks_uai"
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

#
# Create/Get shared resource group.
#
srg_query=$(az group list --query "[?name=='$shared_resource_group']")
if [ "$srg_query" == "[]" ]; then
   echo -e "\nCreating Resource group '$shared_resource_group'"
   az group create --name ${shared_resource_group} --location ${location}
else
   echo "Resource group $shared_resource_group already exists."
   #RG_ID=$(az group show --name $resource_group --query id -o tsv)
fi

#
# Create ACR
#
ar_query=$(az acr list --query "[?name=='$acr_name']")
if [ "$ar_query" == "[]" ]; then
   echo -e "\nCreating Container Registry '$acr_name'"
   az acr create --resource-group $shared_resource_group --name $acr_name --sku Basic
else
   echo "Container Registry $acr_name already exists."
fi

#
# Create/Get workload resource group.
#
rg_query=$(az group list --query "[?name=='$resource_group']")
if [ "$rg_query" == "[]" ]; then
   echo -e "\nCreating Resource group '$resource_group'"
   az group create --name ${resource_group} --location ${location}
else
   echo "Resource group $resource_group already exists."
   #RG_ID=$(az group show --name $resource_group --query id -o tsv)
fi

# Create identities
az identity create --name $cp_aks_uai --resource-group $resource_group
az identity create --name $kbl_aks_uai --resource-group $resource_group
cp_aks_uai_id=$(az identity show --name $cp_aks_uai --resource-group $resource_group --query id --output tsv)
kbl_aks_uai_id=$(az identity show --name $kbl_aks_uai  --resource-group $resource_group --query id --output tsv)

#
# Create AKS cluster
#
aks_query=$(az aks list --query "[?name=='$k8s_cluster_name']")
if [ "$aks_query" == "[]" ]; then
   echo -e "\nCreating AKS cluster '$k8s_cluster_name'"
   az aks create \
     --resource-group ${resource_group} \
     --name ${k8s_cluster_name} \
     --enable-managed-identity \
     --node-count 1 \
     --enable-cluster-autoscaler \
     --min-count 1 \
     --max-count 3 \
     --node-vm-size ${k8s_cluster_vm_size} \
     --generate-ssh-keys \
     --attach-acr ${acr_name} \
     --assign-identity $cp_aks_uai_id \
     --assign-kubelet-identity $kbl_aks_uai_id #\
     #--enable-oidc-issuer \
     #--enable-workload-identity \
     #--enable-addons monitoring
else
   echo "AKS cluster $k8s_cluster_name already exists."

   # Attach using acr-name
   #az aks update -g ${resource_group} -n ${k8s_cluster_name} --attach-acr ${acr_name}
fi

# Get cluster credentials to local .kube/config
az aks get-credentials -g ${resource_group} -n ${k8s_cluster_name}

echo "Created aks cluster ${k8s_cluster_name}"

