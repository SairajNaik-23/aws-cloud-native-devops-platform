# Interview Guide: Cloud-Native DevOps Platform on AWS

## 60-second explanation

> "I built an end-to-end DevOps platform on AWS. First, I wrote Terraform code to create a VPC across two Availability Zones, an EKS cluster with worker nodes in private subnets, and an ECR repository. Then I set up a Jenkins pipeline that triggers on every GitHub push through a webhook. It runs unit tests, builds a Docker image, tags it with the build number and git commit, pushes it to ECR, and deploys it to EKS with a rolling update. If the new pods don't become healthy, the pipeline automatically rolls back. The app scales with a Horizontal Pod Autoscaler, and I installed the Datadog Agent with Helm to collect metrics and logs from every pod and node."

## Explain it step by step

1. **Infrastructure (Terraform):** VPC → public subnets (load balancer) + private subnets (EKS nodes) + NAT gateway → EKS cluster → ECR.
2. **Code push:** developer pushes → GitHub webhook calls Jenkins.
3. **CI:** Jenkins runs tests → builds the Docker image → pushes it to ECR.
4. **CD:** Jenkins runs `kubectl apply` with the new image tag → Kubernetes does a rolling update.
5. **Run:** the Service creates an AWS load balancer → traffic reaches healthy pods only.
6. **Monitor:** the Datadog Agent runs on every node → metrics, logs and alerts.

## Common questions

**Q: Why put EKS nodes in private subnets?**
Security. Nodes have no public IPs, so they can't be reached from the internet. Only the load balancer is public. Nodes reach the internet (to pull images and updates) through the NAT gateway.

**Q: How does Jenkins get access to AWS without storing keys?**
Jenkins runs on EC2 with an IAM role attached. The AWS CLI picks up temporary credentials from the instance metadata automatically. For EKS, the role is added as an EKS access entry with cluster-admin policy.

**Q: How do you get zero-downtime deployments?**
A rolling update with `maxUnavailable: 0` and `maxSurge: 1`. Kubernetes starts a new pod, waits for its readiness probe to pass, and only then removes an old pod.

**Q: What happens if a bad version is deployed?**
`kubectl rollout status` times out, the pipeline runs `kubectl rollout undo` to go back to the previous ReplicaSet, and the build is marked failed.

**Q: Liveness vs readiness probe?**
Liveness: "is the container alive?" If it fails, Kubernetes restarts the container. Readiness: "can it take traffic?" If it fails, the pod is removed from the Service endpoints but not restarted.

**Q: How does auto-scaling work?**
The HPA reads CPU from metrics-server and adds pods when average CPU goes above 60% (from 2 up to 6 pods). If the nodes run out of room, the node group can grow to 3 nodes.

**Q: Why tag images with build number + git SHA instead of only `latest`?**
Every deployment then points to an exact commit, so you can trace and roll back. `latest` changes all the time and doesn't tell you what's running.

**Q: Where is Terraform state stored?**
Locally by default. For a team, use the S3 backend with DynamoDB locking (already written in `versions.tf`, commented out). That prevents two people running `apply` at the same time.

**Q: How is the Datadog API key protected?**
It's stored as a Kubernetes Secret created from an environment variable, never committed to Git. The Helm chart reads it through `apiKeyExistingSecret`.

**Q: What would you improve for production?**
One NAT gateway per AZ, HTTPS with ACM and the AWS Load Balancer Controller (ALB Ingress), GitOps with Argo CD, image scanning as a pipeline gate (Trivy), and separate dev/prod environments with Terraform workspaces or separate state.
