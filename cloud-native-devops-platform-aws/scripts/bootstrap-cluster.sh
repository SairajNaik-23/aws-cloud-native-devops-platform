#!/usr/bin/env bash
# One-time cluster setup after `terraform apply`:
#   1. Point kubectl at the EKS cluster
#   2. Install metrics-server (needed by the HPA)
#   3. Install the Datadog Agent with Helm
#
# Usage: DD_API_KEY=<your-datadog-api-key> ./scripts/bootstrap-cluster.sh
set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-south-1}"
CLUSTER_NAME="${CLUSTER_NAME:-devops-platform-dev-eks}"

: "${DD_API_KEY:?Please export DD_API_KEY first}"

echo ">> Configuring kubectl for ${CLUSTER_NAME}"
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
kubectl get nodes

echo ">> Installing metrics-server"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo ">> Installing Datadog Agent"
kubectl create namespace datadog --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic datadog-secret \
  --namespace datadog \
  --from-literal api-key="$DD_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

helm repo add datadog https://helm.datadoghq.com
helm repo update
helm upgrade --install datadog-agent datadog/datadog \
  --namespace datadog \
  -f monitoring/datadog-values.yaml

echo ">> Done. Check agents with: kubectl get pods -n datadog"
