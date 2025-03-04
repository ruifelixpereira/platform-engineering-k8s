# Lab 01. Setup AKS Kubernetes cluster

Our Platform Engineering labs requires a Kubernetes environment. If you don't have one yet, this addresses the creation of a testing K8s cluster using an AKS.

You can use the provided scripts. Create a copy of the file `.env.template` with the name `.env`, customize the settings and then you can use the following scripts:

```bash
# Create AKS
./aks-cluster-setup.sh 
```

## Troubleshooting

In case a VM SKU is not available, you can check what is available with the following command:

```bash
az vm list-skus --location westus --size Standard_D --all --output table
```
