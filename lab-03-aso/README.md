# Lab 03. Using ASO v2

[Azure Service Operator](https://azure.github.io/azure-service-operator/) (ASO) is a Kubernetes Operator that enables you to provision and manage Azure services using Kubernetes. Instead of deploying and managing your Azure resources separately from your Kubernetes application, ASO allows you to manage them together, automatically configuring your application as needed. For example, ASO can set up your Redis Cache or PostgreSQL database server and then configure your Kubernetes application to use them. ASO v2 is the latest version of ASO and supports more than 150 different Azure resources, with more added every release. See the full list of [supported resources](https://azure.github.io/azure-service-operator/reference/).

## Setup ASO v2

1. Install [cert-manager](https://cert-manager.io/docs/installation/kubernetes/) on the cluster using the following command.

    ```bash
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.14.4/cert-manager.yaml
    ```

    Check that the cert-manager pods have started successfully before continuing.

    ```bash
    $ kubectl get pods -n cert-manager
    NAME                                      READY   STATUS    RESTARTS   AGE
    cert-manager-5597cff495-lmphj             1/1     Running   0          1m
    cert-manager-cainjector-bd5f9c764-gvxm4   1/1     Running   0          1m
    cert-manager-webhook-c4b5687dc-x66bj      1/1     Running   0          1m
    ```

    (Alternatively, you can wait for cert-manager to be ready with `cmctl check api --wait=2m` - see the [cert-manager documentation](https://cert-manager.io/docs/usage/cmctl/) for more information about `cmctl`.)

2. Create an Azure Service Principal. You'll need this to grant Azure Service Operator permissions to create resources in your subscription.

    First, copy file `.env.template` to a new file `.env`, edit it and set the following environment variables to your Azure Tenant ID and Subscription ID with your values:

    ```bash
    AZURE_TENANT_ID=<your-tenant-id-goes-here>
    AZURE_SUBSCRIPTION_ID=<your-subscription-id-goes-here>
    ```

    You can find these values by using the Azure CLI: az account show

    Next, create a service principal with Contributor permissions for your subscription.

    You can optionally use a service principal with a more restricted permission set (for example contributor to just a Resource Group), but that will restrict what you can do with ASO. See [using reduced permissions](https://azure.github.io/azure-service-operator/guide/authentication/reducing-access/#using-a-credential-for-aso-with-reduced-permissions) for more details.

    ```bash
    ./create-sp-01.sh
    ```
    
    This should give you output like the following:

    ```bash
    "appId": "xxxxxxxxxx",
    "displayName": "azure-service-operator",
    "name": "http://azure-service-operator",
    "password": "xxxxxxxxxxx",
    "tenant": "xxxxxxxxxxxxx"
    ```

    Once you have created a service principal, set the following variables to your app ID and password values:

    ```bash
    AZURE_CLIENT_ID=<your-client-id> # This is the appID from the service principal we created.
    AZURE_CLIENT_SECRET=<your-client-secret> # This is the password from the service principal we created.
    ```

3. Install [the latest v2+ Helm chart](https://github.com/Azure/azure-service-operator/tree/main/v2/charts):

    ```bash
    helm repo add aso2 https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts
    ```

    ```bash
    helm upgrade --install aso2 aso2/azure-service-operator \
        --create-namespace \
        --namespace=azureserviceoperator-system \
        --set azureSubscriptionID=$AZURE_SUBSCRIPTION_ID \
        --set azureTenantID=$AZURE_TENANT_ID \
        --set azureClientID=$AZURE_CLIENT_ID \
        --set azureClientSecret=$AZURE_CLIENT_SECRET \
        --set crdPattern='resources.azure.com/*;containerservice.azure.com/*;keyvault.azure.com/*;managedidentity.azure.com/*;eventhub.azure.com/*;cache.azure.com/*'
    ```

    [!WARNING] ASO does not install all available CRDs by default, so ensure you set the `crdPattern` variable to include the CRDs you are interested in using.
    You can use `--set crdPattern=*` to install all the CRDs, but be aware of the [limits of the Kubernetes you are running](https://github.com/Azure/azure-service-operator/issues/2920).
    Using `*` is not recommended on AKS Free-tier clusters.

    See [CRD management](https://azure.github.io/azure-service-operator/guide/crd-management/) for more details.

    Alternatively you can install from the [release YAML directly](https://azure.github.io/azure-service-operator/guide/installing-from-yaml/).

    To learn more about other authentication options, see the [authentication documentation](https://azure.github.io/azure-service-operator/guide/authentication/).


### Usage

Once the controller has been installed in your cluster, you should be able to run the following:

```bash
$ kubectl get pods -n azureserviceoperator-system
NAME                                                READY   STATUS    RESTARTS   AGE
azureserviceoperator-controller-manager-5b4bfc59df-lfpqf   2/2     Running   0          24s

# check out the logs for the running controller
$ kubectl logs -n azureserviceoperator-system azureserviceoperator-controller-manager-5b4bfc59df-lfpqf manager 

# let's create an Azure ResourceGroup in westcentralus with the name "aso-sample-rg"
cat <<EOF | kubectl apply -f -
apiVersion: resources.azure.com/v1api20200601
kind: ResourceGroup
metadata:
  name: aso-sample-rg
  namespace: default
spec:
  location: westcentralus
EOF
# resourcegroup.resources.azure.com/aso-sample-rg created

# another alternative
kubectl apply -f test-rg.yaml

# let's see what the ResourceGroup resource looks like
$ kubectl describe resourcegroups/aso-sample-rg
Name:         aso-sample-rg
Namespace:    default
Labels:       <none>
Annotations:  resource-id.azure.com: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/aso-sample-rg
              resource-sig.azure.com: 1e3a37c42f6beadbe23d53cf0d271f02d2805d6e295a7e13d5f07bda1fc5b800
API Version:  resources.azure.com/v1alpha1api20200601
Kind:         ResourceGroup
Metadata:
  Creation Timestamp:  2021-08-23T23:59:06Z
  Finalizers:
    serviceoperator.azure.com/finalizer
  Generation:  1
Spec:
  Azure Name:  aso-sample-rg
  Location:    westcentralus
Status:
  Conditions:
    Last Transition Time:  2021-08-23T23:59:13Z
    Reason:                Succeeded
    Status:                True
    Type:                  Ready
  Id:                      /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/aso-sample-rg
  Location:                westcentralus
  Name:                    aso-sample-rg
  Provisioning State:      Succeeded
Events:
  Type    Reason             Age   From                     Message
  ----    ------             ----  ----                     -------
  Normal  BeginDeployment    32s   ResourceGroupController  Created new deployment to Azure with ID "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Resources/deployments/k8s_1629763146_19a8f8c2-046e-11ec-8e54-3eec50af7c79"
  Normal  MonitorDeployment  32s   ResourceGroupController  Monitoring Azure deployment ID="/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Resources/deployments/k8s_1629763146_19a8f8c2-046e-11ec-8e54-3eec50af7c79", state="Accepted"
  Normal  MonitorDeployment  27s   ResourceGroupController  Monitoring Azure deployment ID="/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Resources/deployments/k8s_1629763146_19a8f8c2-046e-11ec-8e54-3eec50af7c79", state="Succeeded"
```

```bash
# delete the ResourceGroup
$ kubectl delete resourcegroups/aso-sample-rg
# resourcegroup.resources.azure.com "aso-sample-rg" deleted
```

For samples of additional resources, see the [resource samples directory](https://github.com/Azure/azure-service-operator/tree/main/v2/samples).


## Deploy the application and Azure resources

The YAML documents in azure-vote-managed-redis.yaml create:

- A Kubernetes namespace named azure-vote,
- An Azure resource group named aso-redis-demo,
- An Azure Cache for Redis instance.
- A deployment and service for the popular [AKS voting sample app](https://github.com/Azure-Samples/azure-voting-app-redis).

The redis.cache.azure.com instance is configured to retrieve two secrets that are produced by the Azure Cache for Redis instance - hostname and primaryKey. As described [here](https://azure.github.io/azure-service-operator/guide/secrets/#how-to-retrieve-secrets-created-by-azure), these secrets need to be mapped to our sample application and the container for our sample application will be blocked until these two secrets are created.

The Voting Sample is configured with environment variables that read the secrets for the managed Redis hostname and access key, allowing the sample to use the managed cache.

### Steps to install

Run the provided script `deploy-app-02.sh` to deploy the application to the AKS cluster. Prior to run it copy the file `.env.template` to a new file `.env` and customize it according to your environment.

```bash
./deploy-app-02.sh
```

The operator will start creating the resource group and Azure Cache for Redis instance in Azure. You can monitor their progress with:

```bash
watch kubectl get -n azure-vote-03 resourcegroup,redis
```

You can also find the resource group in the Azure portal and watch the Azure Cache for Redis instance being created there.

### Note
It may take a few minutes for the Azure Cache for Redis to be provisioned. In that time, you may see some ResourceNotFound messages in the logs indicating that the secret, the Azure Cache for Redis or the application deployment are not ready. This is OK! Once the Redis instance is created, secrets will be created and will unblock the sample application container creation. All errors will eventually resolve once the Redis instance is provisioned. These errors are ASO monitoring the creation of each resource, allowing it to take the next step as soon as the resource is available.


## Test the application

When the application runs, a Kubernetes service exposes the application front end to the internet. This process can take a few minutes to complete.

```bash
kubectl get service azure-vote-front -n azure-vote-03
```

Copy the EXTERNAL-IP address from the output. To see the application in action, open a web browser to the external IP address of your service.

Alternatively, for kind clusters, you can also use the following command

```bash
kubectl port-forward -n azure-vote service/azure-vote-front 8080:80
```

If you're interested in code for the application, it is available [here](https://github.com/Azure-Samples/azure-voting-app-redis).


## Clean up

When you're finished with the sample application you can clean all of the Kubernetes and Azure resources up by deleting the azure-vote namespace in your cluster.

```bash
kubectl delete namespace azure-vote-03
```

Kubernetes will delete the web application pod and the operator will delete the Azure resource group and resources.


## References

- [Azure Service Operator](https://azure.github.io/azure-service-operator/)
- [ASO v2 Setup](https://azure.github.io/azure-service-operator/docs/setup/aso-v2/)
- [Hello World Example](https://azure.github.io/azure-service-operator/tutorials/tutorial-redis/)
- [Sample with Redis](https://github.com/Azure-Samples/azure-service-operator-samples/tree/master/azure-votes-redis)
