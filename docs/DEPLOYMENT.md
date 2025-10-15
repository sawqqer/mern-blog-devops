# Deployment Guide

This guide provides step-by-step instructions for deploying the MERN Blog application to AWS using Kubernetes.

## Prerequisites

### Required Tools
- AWS CLI v2.x
- kubectl v1.28+
- Terraform v1.5+
- Helm v3.12+
- Docker v20.10+
- Node.js v18.x+

### AWS Account Setup
- AWS account with appropriate permissions
- IAM user with programmatic access
- Route53 hosted zone (optional, for custom domain)

### Required Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "iam:*",
        "ecr:*",
        "secretsmanager:*",
        "acm:*",
        "route53:*",
        "s3:*",
        "cloudformation:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Environment Setup

### 1. Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-west-2)
# Enter your default output format (json)
```

### 2. Clone Repository
```bash
git clone <repository-url>
cd mern-blog-starter-master
```

### 3. Set Environment Variables
```bash
export AWS_REGION="us-west-2"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export CLUSTER_NAME="mern-blog-eks"
export ECR_REPOSITORY="mern-blog"
```

## Infrastructure Deployment

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

Example `terraform.tfvars`:
```hcl
environment = "dev"
aws_region  = "us-west-2"
project_name = "mern-blog"
team_name    = "devops"
cost_center  = "engineering"
kubernetes_version = "1.28"
node_instance_types = ["t3.medium", "t3.large"]
```

### 3. Plan and Apply Infrastructure
```bash
# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### 4. Configure kubectl
```bash
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
kubectl get nodes
```

## Container Registry Setup

### 1. Create ECR Repository
```bash
aws ecr create-repository \
  --repository-name $ECR_REPOSITORY \
  --region $AWS_REGION
```

### 2. Get Login Token
```bash
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

## Application Deployment

### 1. Build and Push Docker Image
```bash
# Build the application
docker build -t $ECR_REPOSITORY:latest .

# Tag for ECR
docker tag $ECR_REPOSITORY:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
```

### 2. Update Kubernetes Manifests
```bash
# Update image references in deployment files
sed -i "s|image: mern-blog:.*|image: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest|g" k8s/deployment.yaml
```

### 3. Deploy Application
```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/
```

### 4. Verify Deployment
```bash
# Check pod status
kubectl get pods -n mern-blog

# Check service status
kubectl get svc -n mern-blog

# Check ingress status
kubectl get ingress -n mern-blog
```

## Monitoring Stack Deployment

### 1. Add Helm Repositories
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add opensearch https://opensearch-project.github.io/helm-charts
helm repo add aqua https://aquasecurity.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

### 2. Deploy Prometheus and Grafana
```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/prometheus-values.yaml \
  --wait
```

### 3. Deploy OpenSearch
```bash
helm upgrade --install opensearch opensearch/opensearch \
  --namespace logging \
  --create-namespace \
  --values monitoring/opensearch-values.yaml \
  --wait
```

### 4. Deploy OpenSearch Dashboards
```bash
helm upgrade --install opensearch-dashboards opensearch/opensearch-dashboards \
  --namespace logging \
  --values monitoring/opensearch-dashboards-values.yaml \
  --wait
```

### 5. Deploy Fluentd
```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install fluentd fluent/fluentd \
  --namespace logging \
  --values monitoring/fluentd-values.yaml \
  --wait
```

## Security Stack Deployment

### 1. Deploy Trivy Security Scanner
```bash
helm upgrade --install trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace \
  --values security/trivy-operator-values.yaml \
  --wait
```

### 2. Deploy cert-manager
```bash
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --values security/cert-manager-values.yaml \
  --wait
```

### 3. Configure AWS Secrets Manager
```bash
# Create secrets in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "mern-blog/production/database" \
  --description "Database credentials" \
  --secret-string '{"username":"admin","password":"secure-password","host":"db.example.com","port":"5432"}'

aws secretsmanager create-secret \
  --name "mern-blog/production/app" \
  --description "Application secrets" \
  --secret-string '{"jwt-secret":"your-jwt-secret","api-key":"your-api-key"}'

# Deploy secrets synchronization
kubectl apply -f security/aws-secrets-manager.yaml
```

## DNS and SSL Configuration

### 1. Configure Route53 (if using custom domain)
```bash
# Get the ALB DNS name
ALB_DNS=$(kubectl get ingress mern-blog-ingress -n mern-blog -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Create Route53 record
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "mern-blog.example.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "'$ALB_DNS'"}]
      }
    }]
  }'
```

### 2. Configure SSL Certificate
```bash
# Create Let's Encrypt cluster issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: alb
EOF
```

## Verification and Testing

### 1. Health Checks
```bash
# Check application health
kubectl get pods -n mern-blog
kubectl logs -f deployment/mern-blog -n mern-blog

# Check monitoring stack
kubectl get pods -n monitoring
kubectl get pods -n logging

# Check security stack
kubectl get pods -n trivy-system
kubectl get pods -n cert-manager
```

### 2. Access Applications
```bash
# Get application URL
kubectl get ingress mern-blog-ingress -n mern-blog

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access OpenSearch Dashboards
kubectl port-forward -n logging svc/opensearch-dashboards 5601:5601
```

### 3. Run Smoke Tests
```bash
# Test application endpoints
curl -f https://mern-blog.example.com/health
curl -f https://mern-blog.example.com/

# Test monitoring endpoints
curl -f http://localhost:3000/api/health
curl -f http://localhost:5601/api/status
```

## CI/CD Pipeline Setup

### 1. Configure GitHub Secrets
Add the following secrets to your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`
- `SLACK_WEBHOOK_URL` (optional)
- `PAGERDUTY_INTEGRATION_KEY` (optional)

### 2. Enable GitHub Actions
The CI/CD pipeline will automatically trigger on:
- Push to `main` branch (production deployment)
- Push to `develop` branch (staging deployment)
- Pull requests (testing and validation)

### 3. Monitor Pipeline Execution
```bash
# Check GitHub Actions runs
gh run list

# View pipeline logs
gh run view <run-id>
```

## Troubleshooting

### Common Issues

#### 1. Pod Startup Issues
```bash
# Check pod events
kubectl describe pod <pod-name> -n mern-blog

# Check pod logs
kubectl logs <pod-name> -n mern-blog

# Check resource constraints
kubectl top pods -n mern-blog
```

#### 2. Ingress Issues
```bash
# Check ingress status
kubectl get ingress -n mern-blog
kubectl describe ingress mern-blog-ingress -n mern-blog

# Check ALB status
aws elbv2 describe-load-balancers --names mern-blog-alb
```

#### 3. Monitoring Issues
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Visit http://localhost:9090/targets

# Check OpenSearch health
kubectl port-forward -n logging svc/opensearch 9200:9200
curl http://localhost:9200/_cluster/health
```

#### 4. Security Issues
```bash
# Check Trivy scan results
kubectl get vulnerabilityreports -n mern-blog

# Check cert-manager certificates
kubectl get certificates -A
kubectl describe certificate <cert-name>
```

## Cleanup

### 1. Remove Application
```bash
kubectl delete namespace mern-blog
kubectl delete namespace mern-blog-staging
```

### 2. Remove Monitoring Stack
```bash
helm uninstall prometheus -n monitoring
helm uninstall opensearch -n logging
helm uninstall opensearch-dashboards -n logging
helm uninstall fluentd -n logging
```

### 3. Remove Security Stack
```bash
helm uninstall trivy-operator -n trivy-system
helm uninstall cert-manager -n cert-manager
```

### 4. Remove Infrastructure
```bash
cd terraform
terraform destroy
```

### 5. Clean Up ECR
```bash
aws ecr delete-repository \
  --repository-name $ECR_REPOSITORY \
  --force \
  --region $AWS_REGION
```

## Next Steps

1. **Configure Custom Domain**: Set up your own domain with Route53
2. **Set Up Monitoring**: Configure alerts and dashboards
3. **Implement Backup**: Set up automated backups
4. **Security Hardening**: Review and implement additional security measures
5. **Performance Tuning**: Optimize based on monitoring data
6. **Cost Optimization**: Review and optimize costs

---

This deployment guide provides a comprehensive approach to deploying the MERN Blog application with enterprise-level DevOps practices.
