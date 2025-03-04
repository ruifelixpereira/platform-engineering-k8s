# Lab 02. Prepapre Sample Application

## Azure Voting App

This sample creates a multi-container application in an Azure Kubernetes Service (AKS) cluster. The application interface has been built using Python / Flask. The data component is using Redis.

To walk through a quick deployment of this application, see the AKS [quick start](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough?WT.mc_id=none-github-nepeters).

To walk through a complete experience where this code is packaged into container images, uploaded to Azure Container Registry, and then run in and AKS cluster, see the [AKS tutorials](https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app?WT.mc_id=none-github-nepeters).

## Prepare Image

This script `prepare-image-01.sh` creates a container image with the Azure Voting App and uploads it to the Container registry. Prior to run it copy the file `.env.template` to a new file `.env` and customize it according to your environment.

```bash
./prepare-image-01.sh
```

## Deploy Application

Run the provided script `deploy-app-02.sh` to deploy the application to the AKS cluster. Prior to run it copy the file `.env.template` to a new file `.env` and customize it according to your environment.

```bash
./deploy-app-02.sh
```

Check pods to see if they are both running:

```bash
kubectl get pods -n azure-vote-02
```

## Test the application

When the application runs, a Kubernetes service exposes the application front end to the internet. This process can take a few minutes to complete.

```bash
kubectl get service azure-vote-front -n azure-vote-02
```

Copy the EXTERNAL-IP address from the output. To see the application in action, open a web browser to the external IP address of your service.


## Clean up

When you're finished with the sample application you can clean all of the Kubernetes and Azure resources up by deleting the azure-vote namespace in your cluster.

```bash
kubectl delete namespace azure-vote-02
```

Kubernetes will delete the web application pod and the operator will delete the Azure resource group and resources.


## References:

- [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis)
