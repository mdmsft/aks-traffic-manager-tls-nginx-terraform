# Multi-tenant AKS with Traffic Manager, NGINX Ingress Controller and TLS Termination

## Prerequisites
* Variable `dns_zone_id`: Azure DNS Zone ID to integrate with
* Variables `subscription_id` and `tenant_id`
* X.509 wildcard certificate and key matching Azure DNS zone name (in PEM format)

## Provision Azure resources
```sh
terraform plan -out main.tfplan -var-file main.tfvars; terraform apply main.tfplan
```

## Install NGINX ingress controller
```sh
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.service.loadBalancerIP=$loadBalancerIP --set controller.service.annotations."service\.beta\.kubernetes\.io\/azure-load-balancer-resource-group"=$resourceGroupName
```

## Provision Kubernetes manifests
Grab `hostname` from the Terraform output, set `TLS_CRT` and `TLS_KEY` environment variables and execute for every tenant:
```sh
HOSTNAME=$hostname TLS_CRT=`cat <tls-crt>` TLS_KEY=`cat <tls-key>` kubectl apply -k k8s/<tailspin|wingtip>
```