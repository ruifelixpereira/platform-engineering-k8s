# Lab 04. Using Crossplane

Crossplane is an open-source Kubernetes add-on that extends Kubernetes to create and manage infrastructure using Kubernetes-style APIs. It allows you to define and manage cloud resources, including Azure, using Kubernetes manifests.

## Installing & Configuring Crossplane

Crossplane is made up muliple providers for clouds and their resources, initally to start you ned to install the Azure provider here.

From your Terminal run:

```bash
# set the right k8s context
kubectl config use-context plat-eng-02

```bash
# Install up
curl -sL "https://cli.upbound.io" | sh
sudo mv up /usr/local/bin/
up version
``` 

```bash
# Install Universal Crossplane
up uxp install

# wait until pods running
kubectl get pods -n upbound-system
```

![alt text](media/crossplane-pods.png)


### Install the Azure provider

Check for the latest version of the [provider for Azure](https://marketplace.upbound.io/providers/upbound/provider-family-azure/v1.11.1)

![alt text](media/provider.png)

Note this is the Upbound Official Azure provider, not the community provider!

Run this command to install the provider:

```bash
kubectl apply -f provider-azure.yaml
```

It may take up to 5 minutes to report HEALTHY==true.

```bash
kubectl get providers.pkg.crossplane.io
```

![alt text](media/providers-health.png)


### Setup provider authentication

Setting up provider permissions to Azure can follow different options. In this example we are going to use a User Assigned Identity (UAI) for the AKS cluster, this is a recommended approach as it is more secure than using a Service Principal.

When we created the AKS cluster in the previous lab 01 we created a UAI for the cluster. We will use this UAI to authenticate with Azure and we will grant 'Contributor' permissions to the AKS UAI on the subscription. Note, this is NOT recommended, it is for demonstration purposes. You must be conservative and just grant the identity contributor to a resource group or custom role, however you may find that deployments may require permissions outside of the resource group, or you may even wish to have Crossplane create RG's with RBAC etc.

Run the following commands to get the UAI, set the permissions and configure the Crossplane Azure provider:

```bash
./config-provider-01.sh
```

## Deploying Resources & Providers

The core Azure provider only support a ~6 Kinds which link to specific Azure operations or resouces, you can see these by going to ['ProviderConfig' tab](https://marketplace.upbound.io/providers/upbound/provider-family-azure/v1.11.1/config), one of them is 'Resource Group':

![alt text](media/kinds.png)

Now if you want to create a ResourceGroup, click on it, and this will show you the API documentation, what can be set, then the 'Example' tab shows an example. To test if the Crossplane installation has been successful run:

```bash
kubectl apply -f resourcegroup.yaml
```

This will create a K8s resource of the Kind 'ResourceGroup', so you can interact with it like any other K8s resource, to check the status"

```bash
kubectl describe ResourceGroup rg-myfirst
```

If this has worked successfully you should see Successfully requested creation of external resource in the Events and naturally check your Azure subcription and check if the resource group was created.

To delete the resource group, you can change the creation YAML to 'kubectl delete -f..', or just run:

```bash
kubectl delete ResourceGroup rg-myfirst
```

## Deploying more resources

To be able to deploy and manage more Azure resources you need to install additional providers, go to the ['Providers' tab](https://marketplace.upbound.io/providers/upbound/provider-family-azure/v1.11.1/providers) and you will see more of them.

![alt text](media/list-providers.png)

Let's for example select provider-azure-cache:

![alt text](media/cache.png)

Upon clicking `Install Package Manifest` you will see this, which you can run:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure-cache
spec:
  package: xpkg.upbound.io/upbound/provider-azure-cache:v1
```

Run this command to install the azure cache provider:
```bash
kubectl apply -f provider-azure-cache.yaml
```

You can check which providers are installed and healthy by running:

```bash
kubectl get providers.pkg.crossplane.io
```

![alt text](media/installed-providers.png)


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
watch kubectl get -n azure-vote-04 resourcegroup,rediscache
```

You can also find the resource group in the Azure portal and watch the Azure Cache for Redis instance being created there.

### Note
It may take a few minutes for the Azure Cache for Redis to be provisioned. In that time, you may see some ResourceNotFound messages in the logs indicating that the secret, the Azure Cache for Redis or the application deployment are not ready. This is OK! Once the Redis instance is created, secrets will be created and will unblock the sample application container creation. All errors will eventually resolve once the Redis instance is provisioned. These errors are ASO monitoring the creation of each resource, allowing it to take the next step as soon as the resource is available.


## Test the application

When the application runs, a Kubernetes service exposes the application front end to the internet. This process can take a few minutes to complete.

```bash
kubectl get service azure-vote-front -n azure-vote-04
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
kubectl delete namespace azure-vote-04
```

Kubernetes will delete the web application pod and the operator will delete the Azure resource group and resources.

## Compositions

TODO

## References

- [Crossplace setup guide](https://github.com/danielsollondon/platform-engineering/blob/main/readme.md)
- [Crossplane provider for Azure](https://marketplace.upbound.io/providers/upbound/provider-family-azure/v1.11.1)