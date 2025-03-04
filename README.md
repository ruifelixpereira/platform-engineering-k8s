# Platform Engineering with Kubernetes labs

This repository contains a series of labs that are designed to help you learn how to practice Platform Engineering with Kubernetes and Azure. The labs help you to understand different tools like [Azure Service Operator (ASO)](https://azure.github.io/azure-service-operator/), [Crossplane](https://www.crossplane.io/) and [Radius](https://radapp.io/) using a sample Hello World application composed of:
- Application container with a web app that will run in K8s.
- Redis Cache that will be provided by the Azure Cache for Redis native service.

Our Platform Engineering labs requires a Kubernetes environment. If you don't have one yet, follow [Lab 01](lab-01-setup-aks/README.md) to set it up.

Beware that ASO and Crossplane cannot coexist in the same K8s cluster sincr they both create similar kinds of objects (CRDs). If you want to try both, you will need to create two different clusters.

## Labs available

- Lab 01: [Setup AKS](lab-01-setup-aks/README.md)
- Lab 02: [Prepare Hello World App](lab-02-prep-app/README.md)
- Lab 03: [Using Azure Service Operator v2](lab-03-aso/README.md)
- Lab 04: [Using Crossplane](lab-04-crossplane/README.md)
- Lab 05: [Using Radius](lab-05-radius/README.md)
