# MERN Blog - Enterprise DevOps Project

## 🚀 Project Overview

This is a comprehensive DevOps project showcasing modern cloud-native practices for a MERN (MongoDB, Express.js, React, Node.js) blog application. The project demonstrates enterprise-level DevOps skills suitable for a **Strong Middle DevOps Engineer** position in the US market.

## 🏗️ Architecture

### Technology Stack (2025 US Market Standard)

- **Cloud Provider**: AWS (Amazon Web Services)
- **Infrastructure as Code**: Terraform
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Kubernetes (AWS EKS)
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana
- **Logging**: OpenSearch + Fluentd
- **Security**: Trivy, AWS Secrets Manager, cert-manager
- **Application**: React.js (Frontend)

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │    EKS      │  │     ECR     │  │  Secrets    │        │
│  │   Cluster   │  │ Repository  │  │  Manager    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Prometheus  │  │   Grafana   │  │ OpenSearch  │        │
│  │             │  │             │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │    Trivy    │  │ cert-manager│  │   Fluentd   │        │
│  │             │  │             │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
mern-blog-starter-master/
├── .github/workflows/          # GitHub Actions CI/CD
│   ├── ci-cd.yml              # Main CI/CD pipeline
│   ├── terraform.yml          # Infrastructure pipeline
│   └── monitoring.yml         # Monitoring setup
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml         # Namespace definitions
│   ├── configmap.yaml         # Configuration maps
│   ├── deployment.yaml        # Application deployments
│   ├── service.yaml           # Service definitions
│   ├── ingress.yaml           # Ingress controllers
│   ├── rbac.yaml              # RBAC configurations
│   ├── network-policy.yaml    # Network security policies
│   ├── pod-security-policy.yaml # Pod security policies
│   ├── hpa.yaml               # Horizontal Pod Autoscaler
│   └── pdb.yaml               # Pod Disruption Budgets
├── terraform/                 # Infrastructure as Code
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Variable definitions
│   ├── outputs.tf             # Output values
│   ├── versions.tf            # Provider versions
│   ├── terraform.tfvars.example # Example variables
│   └── modules/               # Terraform modules
│       ├── monitoring/        # Monitoring module
│       └── logging/           # Logging module
├── monitoring/                # Monitoring configuration
│   ├── prometheus-values.yaml # Prometheus Helm values
│   ├── grafana-dashboards/    # Grafana dashboards
│   ├── grafana-datasources/   # Grafana data sources
│   ├── alert-rules/           # Prometheus alert rules
│   ├── opensearch-values.yaml # OpenSearch configuration
│   ├── opensearch-dashboards-values.yaml
│   └── fluentd-values.yaml    # Fluentd configuration
├── security/                  # Security configurations
│   ├── trivy-operator-values.yaml # Trivy security scanner
│   ├── cert-manager-values.yaml   # Certificate management
│   └── aws-secrets-manager.yaml   # Secrets management
├── Dockerfile                 # Multi-stage Docker build
├── Dockerfile.dev             # Development Docker build
├── docker-compose.yml         # Local development
├── nginx.conf                 # Nginx configuration
├── .dockerignore              # Docker ignore file
└── README.md                  # This documentation
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl installed and configured
- Docker installed
- Terraform >= 1.5.0
- Helm >= 3.12.0
- Node.js >= 18.x

### 1. Infrastructure Setup

```bash
# Clone the repository
git clone <repository-url>
cd mern-blog-starter-master

# Configure AWS credentials
aws configure

# Initialize Terraform
cd terraform
terraform init
terraform plan
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name mern-blog-eks
```

### 2. Application Deployment

```bash
# Build and push Docker image
docker build -t mern-blog:latest .
docker tag mern-blog:latest <ECR_REGISTRY>/mern-blog:latest
docker push <ECR_REGISTRY>/mern-blog:latest

# Deploy to Kubernetes
kubectl apply -f k8s/
```

### 3. Monitoring Setup

```bash
# Install monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add opensearch https://opensearch-project.github.io/helm-charts
helm repo update

# Deploy Prometheus and Grafana
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --values monitoring/prometheus-values.yaml

# Deploy OpenSearch
helm upgrade --install opensearch opensearch/opensearch \
  --namespace logging --create-namespace \
  --values monitoring/opensearch-values.yaml
```

### 4. Security Setup

```bash
# Install Trivy for security scanning
helm repo add aqua https://aquasecurity.github.io/helm-charts
helm upgrade --install trivy-operator aqua/trivy-operator \
  --namespace trivy-system --create-namespace \
  --values security/trivy-operator-values.yaml

# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --values security/cert-manager-values.yaml
```

## 🔧 Development

### Local Development

```bash
# Start local development environment
docker-compose up -d

# Access the application
open http://localhost:3000

# View logs
docker-compose logs -f react-app

# Stop the environment
docker-compose down
```

### Testing

```bash
# Run unit tests
npm test

# Run linting
npm run lint

# Run security scan
trivy fs .

# Run Terraform validation
cd terraform
terraform validate
terraform plan
```

## 📊 Monitoring & Observability

### Prometheus Metrics

- Application performance metrics
- Kubernetes cluster metrics
- Custom business metrics
- Alert rules for critical issues

### Grafana Dashboards

- **Application Dashboard**: Request rate, response time, error rate
- **Infrastructure Dashboard**: CPU, memory, disk usage
- **Security Dashboard**: Vulnerability reports, compliance status

### OpenSearch Logging

- Centralized log collection with Fluentd
- Structured logging with JSON format
- Log retention and archival policies
- Real-time log analysis and alerting

## 🔒 Security

### Security Scanning

- **Trivy**: Container vulnerability scanning
- **Checkov**: Infrastructure security scanning
- **GitHub Security**: Code vulnerability scanning

### Secrets Management

- AWS Secrets Manager integration
- Automatic secret rotation
- Kubernetes secret synchronization
- Encrypted storage and transmission

### Network Security

- Kubernetes Network Policies
- Pod Security Policies
- TLS/SSL certificate management
- RBAC and service account security

## 🚀 CI/CD Pipeline

### GitHub Actions Workflows

1. **CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
   - Security scanning with Trivy
   - Build and test application
   - Docker image build and push
   - Deploy to staging and production
   - Smoke tests and health checks

2. **Infrastructure Pipeline** (`.github/workflows/terraform.yml`)
   - Terraform validation and security scanning
   - Infrastructure deployment
   - Environment-specific configurations

3. **Monitoring Pipeline** (`.github/workflows/monitoring.yml`)
   - Monitoring stack deployment
   - Alert rule configuration
   - Dashboard provisioning

### Deployment Strategy

- **Blue-Green Deployment**: Zero-downtime deployments
- **Canary Releases**: Gradual rollout with monitoring
- **Rolling Updates**: Safe application updates
- **Automated Rollback**: Quick recovery from failures

## 📈 Scaling & Performance

### Horizontal Pod Autoscaler (HPA)

- CPU and memory-based scaling
- Custom metrics scaling
- Scheduled scaling for predictable traffic

### Cluster Autoscaler

- Automatic node scaling based on demand
- Cost optimization through spot instances
- Multi-AZ deployment for high availability

### Performance Optimization

- Multi-stage Docker builds for smaller images
- Nginx caching and compression
- CDN integration for static assets
- Database connection pooling

## 🔧 Configuration Management

### Environment Configuration

- **Development**: Local Docker Compose setup
- **Staging**: EKS cluster with limited resources
- **Production**: Full EKS cluster with monitoring

### Secrets Management

```bash
# Store secrets in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "mern-blog/production/database" \
  --description "Database credentials" \
  --secret-string '{"username":"admin","password":"secure-password"}'

# Sync secrets to Kubernetes
kubectl apply -f security/aws-secrets-manager.yaml
```

## 📋 Best Practices

### Infrastructure

- **Immutable Infrastructure**: All changes through code
- **Infrastructure as Code**: Terraform for all resources
- **Version Control**: All configurations in Git
- **Environment Parity**: Consistent environments

### Security

- **Defense in Depth**: Multiple security layers
- **Least Privilege**: Minimal required permissions
- **Regular Scanning**: Automated vulnerability checks
- **Secure Defaults**: Secure configurations by default

### Monitoring

- **Comprehensive Observability**: Metrics, logs, and traces
- **Proactive Alerting**: Alert before issues occur
- **SLA Monitoring**: Track service level objectives
- **Cost Monitoring**: Track and optimize costs

## 🚨 Troubleshooting

### Common Issues

1. **Pod Startup Issues**
   ```bash
   kubectl describe pod <pod-name> -n mern-blog
   kubectl logs <pod-name> -n mern-blog
   ```

2. **Ingress Issues**
   ```bash
   kubectl get ingress -n mern-blog
   kubectl describe ingress mern-blog-ingress -n mern-blog
   ```

3. **Monitoring Issues**
   ```bash
   kubectl get pods -n monitoring
   kubectl logs -f deployment/prometheus-server -n monitoring
   ```

### Health Checks

```bash
# Application health
curl https://mern-blog.com/health

# Prometheus health
curl http://prometheus.monitoring.svc.cluster.local:9090/-/healthy

# OpenSearch health
curl http://opensearch.logging.svc.cluster.local:9200/_cluster/health
```

## 📚 Additional Resources

### Documentation

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Training Materials

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [DevOps Best Practices](https://docs.microsoft.com/en-us/azure/devops/learn/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **DevOps Engineer**: Infrastructure and automation
- **Security Engineer**: Security scanning and compliance
- **Platform Engineer**: Monitoring and observability
- **Site Reliability Engineer**: Incident response and optimization

---

**Note**: This project demonstrates enterprise-level DevOps practices suitable for a Strong Middle DevOps Engineer position in the US market. It showcases modern cloud-native technologies, security best practices, and comprehensive monitoring and observability.