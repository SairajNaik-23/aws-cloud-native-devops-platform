#!/usr/bin/env bash
# Tear everything down to stop AWS charges.
# The K8s LoadBalancer Service must be deleted FIRST, otherwise the AWS load
# balancer it created blocks the VPC from being destroyed.
set -euo pipefail

echo ">> Deleting Kubernetes resources (removes the AWS load balancer)"
kubectl delete namespace devops-app --ignore-not-found
helm uninstall datadog-agent -n datadog || true

echo ">> Waiting 60s for the load balancer to be removed"
sleep 60

echo ">> Destroying infrastructure"
cd "$(dirname "$0")/../terraform"
terraform destroy -auto-approve
