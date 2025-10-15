# Troubleshooting Guide

This comprehensive troubleshooting guide helps diagnose and resolve common issues in the MERN Blog application deployment.

## Quick Diagnostics

### Health Check Commands
```bash
# Check overall cluster health
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
kubectl get ingress --all-namespaces

# Check application health
kubectl get pods -n mern-blog
kubectl logs -f deployment/mern-blog -n mern-blog

# Check monitoring stack
kubectl get pods -n monitoring
kubectl get pods -n logging
```

## Application Issues

### Pod Startup Problems

#### Pod Stuck in Pending State
```bash
# Check pod events
kubectl describe pod <pod-name> -n mern-blog

# Common causes and solutions:
# 1. Insufficient resources
kubectl top nodes
kubectl describe node <node-name>

# 2. Image pull issues
kubectl describe pod <pod-name> -n mern-blog | grep -A 10 "Events:"

# 3. Node selector issues
kubectl get nodes --show-labels
```

#### Pod CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> -n mern-blog --previous

# Check pod events
kubectl describe pod <pod-name> -n mern-blog

# Common solutions:
# 1. Check resource limits
kubectl describe pod <pod-name> -n mern-blog | grep -A 5 "Limits:"

# 2. Check environment variables
kubectl describe pod <pod-name> -n mern-blog | grep -A 10 "Environment:"

# 3. Check volume mounts
kubectl describe pod <pod-name> -n mern-blog | grep -A 10 "Mounts:"
```

#### Image Pull Errors
```bash
# Check ECR authentication
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.us-west-2.amazonaws.com

# Check image existence
aws ecr describe-images --repository-name mern-blog --region us-west-2

# Check image pull secrets
kubectl get secrets -n mern-blog
kubectl describe secret <secret-name> -n mern-blog
```

### Application Performance Issues

#### High Response Time
```bash
# Check application metrics
kubectl top pods -n mern-blog

# Check Prometheus metrics
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Visit http://localhost:9090 and query:
# rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# Check application logs for slow queries
kubectl logs -f deployment/mern-blog -n mern-blog | grep -i "slow\|timeout\|error"

# Check resource usage
kubectl describe pod <pod-name> -n mern-blog | grep -A 5 "Requests:\|Limits:"
```

#### High Memory Usage
```bash
# Check memory usage
kubectl top pods -n mern-blog

# Check for memory leaks in logs
kubectl logs -f deployment/mern-blog -n mern-blog | grep -i "memory\|leak\|oom"

# Check memory limits
kubectl describe pod <pod-name> -n mern-blog | grep -A 5 "Limits:"

# Check if pods are being killed
kubectl get events -n mern-blog | grep -i "oom\|killed"
```

#### High CPU Usage
```bash
# Check CPU usage
kubectl top pods -n mern-blog

# Check for CPU-intensive operations in logs
kubectl logs -f deployment/mern-blog -n mern-blog | grep -i "cpu\|processing\|computation"

# Check CPU limits and requests
kubectl describe pod <pod-name> -n mern-blog | grep -A 5 "Requests:\|Limits:"

# Check HPA status
kubectl get hpa -n mern-blog
kubectl describe hpa mern-blog-hpa -n mern-blog
```

## Infrastructure Issues

### Kubernetes Cluster Issues

#### Node Problems
```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check node resources
kubectl top nodes

# Check node events
kubectl get events --field-selector involvedObject.kind=Node

# Common node issues:
# 1. Disk pressure
kubectl describe node <node-name> | grep -i "disk\|pressure"

# 2. Memory pressure
kubectl describe node <node-name> | grep -i "memory\|pressure"

# 3. Network issues
kubectl describe node <node-name> | grep -i "network\|unreachable"
```

#### Network Connectivity Issues
```bash
# Test pod-to-pod connectivity
kubectl run test-pod --image=busybox --rm -it -- nslookup mern-blog-service.mern-blog.svc.cluster.local

# Check DNS resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup kubernetes.default.svc.cluster.local

# Check network policies
kubectl get networkpolicies -n mern-blog
kubectl describe networkpolicy mern-blog-network-policy -n mern-blog

# Check service endpoints
kubectl get endpoints -n mern-blog
kubectl describe service mern-blog-service -n mern-blog
```

#### Persistent Volume Issues
```bash
# Check PV status
kubectl get pv
kubectl describe pv <pv-name>

# Check PVC status
kubectl get pvc -n mern-blog
kubectl describe pvc <pvc-name> -n mern-blog

# Check storage class
kubectl get storageclass
kubectl describe storageclass gp3

# Common PV issues:
# 1. Volume not bound
kubectl get pv | grep Available

# 2. Volume failed to mount
kubectl describe pod <pod-name> -n mern-blog | grep -A 10 "MountVolume"
```

### AWS Infrastructure Issues

#### EKS Cluster Issues
```bash
# Check cluster status
aws eks describe-cluster --name mern-blog-eks --region us-west-2

# Check cluster logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/mern-blog-eks

# Check node group status
aws eks describe-nodegroup --cluster-name mern-blog-eks --nodegroup-name main-node-group --region us-west-2

# Common EKS issues:
# 1. Cluster not accessible
aws eks update-kubeconfig --region us-west-2 --name mern-blog-eks

# 2. Node group scaling issues
aws autoscaling describe-auto-scaling-groups --region us-west-2
```

#### Load Balancer Issues
```bash
# Check ALB status
aws elbv2 describe-load-balancers --names mern-blog-alb --region us-west-2

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region us-west-2

# Check ingress status
kubectl get ingress -n mern-blog
kubectl describe ingress mern-blog-ingress -n mern-blog

# Common ALB issues:
# 1. Targets unhealthy
kubectl get pods -n mern-blog -o wide
kubectl get endpoints -n mern-blog

# 2. SSL certificate issues
kubectl get certificates -n mern-blog
kubectl describe certificate mern-blog-tls -n mern-blog
```

## Monitoring Issues

### Prometheus Issues
```bash
# Check Prometheus status
kubectl get pods -n monitoring | grep prometheus
kubectl logs -f deployment/prometheus-server -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Visit http://localhost:9090/targets

# Check Prometheus configuration
kubectl get configmap -n monitoring | grep prometheus
kubectl describe configmap prometheus-server -n monitoring

# Common Prometheus issues:
# 1. Targets down
kubectl get servicemonitors -n monitoring
kubectl describe servicemonitor mern-blog-app -n monitoring

# 2. Metrics not collected
kubectl logs -f deployment/prometheus-server -n monitoring | grep -i "error\|failed"
```

### Grafana Issues
```bash
# Check Grafana status
kubectl get pods -n monitoring | grep grafana
kubectl logs -f deployment/prometheus-grafana -n monitoring

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Visit http://localhost:3000

# Check Grafana configuration
kubectl get configmap -n monitoring | grep grafana
kubectl describe configmap prometheus-grafana -n monitoring

# Common Grafana issues:
# 1. Dashboard not loading
kubectl logs -f deployment/prometheus-grafana -n monitoring | grep -i "error"

# 2. Data source issues
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Check data sources in Grafana UI
```

### OpenSearch Issues
```bash
# Check OpenSearch status
kubectl get pods -n logging | grep opensearch
kubectl logs -f deployment/opensearch -n logging

# Check OpenSearch health
kubectl port-forward -n logging svc/opensearch 9200:9200
curl http://localhost:9200/_cluster/health

# Check OpenSearch indices
curl http://localhost:9200/_cat/indices

# Common OpenSearch issues:
# 1. Cluster health issues
curl http://localhost:9200/_cluster/health?pretty

# 2. Index issues
curl http://localhost:9200/_cat/indices?v
```

### Fluentd Issues
```bash
# Check Fluentd status
kubectl get pods -n logging | grep fluentd
kubectl logs -f daemonset/fluentd -n logging

# Check Fluentd configuration
kubectl get configmap -n logging | grep fluentd
kubectl describe configmap fluentd-config -n logging

# Common Fluentd issues:
# 1. Log collection issues
kubectl logs -f daemonset/fluentd -n logging | grep -i "error\|failed"

# 2. Buffer issues
kubectl logs -f daemonset/fluentd -n logging | grep -i "buffer"
```

## Security Issues

### Trivy Security Scanner Issues
```bash
# Check Trivy status
kubectl get pods -n trivy-system
kubectl logs -f deployment/trivy-operator -n trivy-system

# Check vulnerability reports
kubectl get vulnerabilityreports -n mern-blog
kubectl describe vulnerabilityreport <report-name> -n mern-blog

# Check config audit reports
kubectl get configauditreports -n mern-blog
kubectl describe configauditreport <report-name> -n mern-blog

# Common Trivy issues:
# 1. Scan failures
kubectl logs -f deployment/trivy-operator -n trivy-system | grep -i "error"

# 2. High vulnerability count
kubectl get vulnerabilityreports -n mern-blog -o jsonpath='{.items[*].report.summary}'
```

### Certificate Issues
```bash
# Check cert-manager status
kubectl get pods -n cert-manager
kubectl logs -f deployment/cert-manager -n cert-manager

# Check certificates
kubectl get certificates -n mern-blog
kubectl describe certificate mern-blog-tls -n mern-blog

# Check certificate requests
kubectl get certificaterequests -n mern-blog
kubectl describe certificaterequest <request-name> -n mern-blog

# Check cluster issuers
kubectl get clusterissuers
kubectl describe clusterissuer letsencrypt-prod

# Common certificate issues:
# 1. Certificate not issued
kubectl logs -f deployment/cert-manager -n cert-manager | grep -i "error\|failed"

# 2. Certificate expired
kubectl get certificates -n mern-blog -o jsonpath='{.items[*].status.conditions[*].message}'
```

### Secrets Management Issues
```bash
# Check secrets status
kubectl get secrets -n mern-blog
kubectl describe secret mern-blog-secrets -n mern-blog

# Check AWS Secrets Manager sync
kubectl get cronjobs -n mern-blog
kubectl logs -f job/aws-secrets-sync-<timestamp> -n mern-blog

# Check secrets in AWS
aws secretsmanager list-secrets --region us-west-2
aws secretsmanager get-secret-value --secret-id mern-blog/production/database --region us-west-2

# Common secrets issues:
# 1. Secret not synced
kubectl logs -f job/aws-secrets-sync-<timestamp> -n mern-blog | grep -i "error"

# 2. Secret access denied
kubectl describe serviceaccount mern-blog-sa -n mern-blog
```

## CI/CD Issues

### GitHub Actions Issues
```bash
# Check workflow runs
gh run list

# View workflow logs
gh run view <run-id>

# Check workflow status
gh run list --status in_progress

# Common CI/CD issues:
# 1. Build failures
gh run view <run-id> --log

# 2. Deployment failures
kubectl get events -n mern-blog | grep -i "deployment\|failed"

# 3. Test failures
gh run view <run-id> --log | grep -i "test\|failed"
```

### Terraform Issues
```bash
# Check Terraform state
cd terraform
terraform state list
terraform state show <resource-name>

# Check Terraform plan
terraform plan

# Check Terraform validation
terraform validate

# Common Terraform issues:
# 1. State lock issues
terraform force-unlock <lock-id>

# 2. Resource conflicts
terraform import <resource-type>.<name> <resource-id>

# 3. Provider issues
terraform init -upgrade
```

## Performance Troubleshooting

### Slow Application Performance
```bash
# Check application metrics
kubectl top pods -n mern-blog

# Check database connections
kubectl logs -f deployment/mern-blog -n mern-blog | grep -i "database\|connection"

# Check external service calls
kubectl logs -f deployment/mern-blog -n mern-blog | grep -i "external\|api"

# Check network latency
kubectl run test-pod --image=busybox --rm -it -- ping <external-service>

# Check DNS resolution time
kubectl run test-pod --image=busybox --rm -it -- nslookup <domain-name>
```

### High Resource Usage
```bash
# Check resource usage across cluster
kubectl top nodes
kubectl top pods --all-namespaces

# Check resource limits and requests
kubectl describe pods -n mern-blog | grep -A 5 "Requests:\|Limits:"

# Check HPA status
kubectl get hpa -n mern-blog
kubectl describe hpa mern-blog-hpa -n mern-blog

# Check cluster autoscaler
kubectl get nodes
aws autoscaling describe-auto-scaling-groups --region us-west-2
```

## Emergency Procedures

### Application Rollback
```bash
# Rollback deployment
kubectl rollout undo deployment/mern-blog -n mern-blog

# Check rollback status
kubectl rollout status deployment/mern-blog -n mern-blog

# Rollback to specific revision
kubectl rollout undo deployment/mern-blog --to-revision=2 -n mern-blog
```

### Scale Down for Emergency
```bash
# Scale down application
kubectl scale deployment mern-blog --replicas=0 -n mern-blog

# Scale down monitoring
kubectl scale deployment prometheus-server --replicas=0 -n monitoring

# Scale down logging
kubectl scale deployment opensearch --replicas=0 -n logging
```

### Emergency Access
```bash
# Access pod shell
kubectl exec -it <pod-name> -n mern-blog -- /bin/sh

# Port forward for emergency access
kubectl port-forward -n mern-blog svc/mern-blog-service 8080:80

# Access logs directly
kubectl logs -f <pod-name> -n mern-blog --tail=100
```

## Contact Information

### On-Call Contacts
- **Primary On-Call**: +1-xxx-xxx-xxxx
- **Secondary On-Call**: +1-xxx-xxx-xxxx
- **Escalation**: +1-xxx-xxx-xxxx

### Emergency Channels
- **Slack**: #incidents
- **PagerDuty**: Critical alerts
- **Email**: incidents@company.com

### Documentation Resources
- **Runbooks**: [Internal Wiki]
- **Architecture Docs**: [Architecture Documentation]
- **Monitoring Docs**: [Monitoring Guide]
- **Security Docs**: [Security Guide]

---

This troubleshooting guide provides comprehensive coverage of common issues and their solutions for the MERN Blog application deployment.
