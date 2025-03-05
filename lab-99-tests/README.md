# Tests

## Check environment variables from secret in a pod

```bash
kubectl apply -f pod4.yaml

kubectl get pods -n azure-vote-04

kubectl exec my-pod4 -n azure-vote-04 -- env
```