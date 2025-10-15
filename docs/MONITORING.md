# Monitoring and Observability Guide

This document provides comprehensive guidance on monitoring, observability, and alerting for the MERN Blog application deployment.

## Monitoring Architecture

### Overview
The monitoring stack provides comprehensive observability across all layers of the application:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Monitoring Stack                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │ Prometheus  │  │   Grafana   │  │ AlertManager│           │
│  │  (Metrics)  │  │(Dashboards) │  │  (Alerts)   │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │ OpenSearch  │  │   Fluentd   │  │    Jaeger   │           │
│  │   (Logs)    │  │(Log Agent)  │  │  (Traces)   │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

## Metrics Collection

### Prometheus Configuration
Prometheus collects metrics from various sources:

#### Application Metrics
```yaml
# ServiceMonitor for application metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: mern-blog-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: mern-blog
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```

#### Kubernetes Metrics
- **kube-state-metrics**: Kubernetes object state metrics
- **node-exporter**: Node-level hardware and OS metrics
- **kubelet**: Container and pod metrics
- **cAdvisor**: Container resource usage metrics

#### Custom Metrics
```javascript
// Application metrics example
const promClient = require('prom-client');

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status']
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});
```

### Key Metrics to Monitor

#### Application Metrics
- **Request Rate**: Requests per second
- **Response Time**: 50th, 95th, 99th percentiles
- **Error Rate**: 4xx and 5xx error percentages
- **Active Users**: Concurrent user sessions

#### Infrastructure Metrics
- **CPU Usage**: Node and container CPU utilization
- **Memory Usage**: Node and container memory consumption
- **Disk Usage**: Available disk space
- **Network I/O**: Network traffic and errors

#### Kubernetes Metrics
- **Pod Status**: Running, pending, failed pods
- **Deployment Status**: Replica availability
- **Service Endpoints**: Healthy endpoint count
- **Ingress Status**: Load balancer health

## Logging

### Log Collection with Fluentd
Fluentd collects logs from various sources:

```yaml
# Fluentd configuration for log collection
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    
    <filter kubernetes.**>
      @type kubernetes_metadata
      @id filter_kube_metadata
    </filter>
    
    <match kubernetes.**>
      @type opensearch
      host opensearch
      port 9200
      index_name logstash
      type_name _doc
    </match>
```

### Log Structure
Standardized log format across all components:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "INFO",
  "message": "Request processed successfully",
  "service": "mern-blog",
  "namespace": "mern-blog",
  "pod": "mern-blog-abc123",
  "request_id": "req-123456",
  "user_id": "user-789",
  "method": "GET",
  "path": "/api/articles",
  "status": 200,
  "duration_ms": 45,
  "ip_address": "192.168.1.100"
}
```

### Log Levels
- **ERROR**: System errors requiring immediate attention
- **WARN**: Warning conditions that may require attention
- **INFO**: General information about application flow
- **DEBUG**: Detailed information for debugging

## Dashboards

### Grafana Dashboard Configuration
Comprehensive dashboards for different stakeholders:

#### Application Dashboard
```json
{
  "dashboard": {
    "title": "MERN Blog Application",
    "panels": [
      {
        "title": "Request Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ]
  }
}
```

#### Infrastructure Dashboard
- **Node Metrics**: CPU, memory, disk usage per node
- **Pod Metrics**: Resource usage per pod
- **Network Metrics**: Network I/O and errors
- **Storage Metrics**: Persistent volume usage

#### Security Dashboard
- **Vulnerability Status**: Current vulnerabilities by severity
- **Security Events**: Failed authentication attempts
- **Compliance Status**: Security policy compliance
- **Threat Detection**: Suspicious activity alerts

### Dashboard Access
```bash
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Default credentials
Username: admin
Password: admin123
```

## Alerting

### Alert Rules
Comprehensive alerting rules for proactive monitoring:

```yaml
# Prometheus alert rules
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: mern-blog-alerts
spec:
  groups:
  - name: mern-blog-application
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value }} errors per second"
    
    - alert: HighResponseTime
      expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High response time detected"
        description: "95th percentile response time is {{ $value }} seconds"
```

### Alert Severity Levels
- **Critical**: Immediate action required (page on-call)
- **Warning**: Attention needed within 1 hour
- **Info**: Informational alerts for tracking

### Alert Channels
- **Slack**: Real-time notifications to #alerts channel
- **PagerDuty**: Escalation for critical alerts
- **Email**: Summary reports and non-critical alerts
- **Webhook**: Custom integrations

### AlertManager Configuration
```yaml
# AlertManager routing configuration
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
  - match:
      severity: critical
    receiver: 'pagerduty'
    group_wait: 10s
    repeat_interval: 5m
  - match:
      severity: warning
    receiver: 'slack'
    group_wait: 30s
    repeat_interval: 30m
```

## Performance Monitoring

### Application Performance Monitoring (APM)
- **Response Time Tracking**: End-to-end request timing
- **Database Query Performance**: Slow query identification
- **External Service Calls**: Third-party service monitoring
- **User Experience Metrics**: Real user monitoring (RUM)

### Infrastructure Performance
- **Resource Utilization**: CPU, memory, disk, network
- **Kubernetes Performance**: API server latency, etcd performance
- **Storage Performance**: IOPS, throughput, latency
- **Network Performance**: Bandwidth, latency, packet loss

### Performance Baselines
- **Response Time**: < 200ms for 95th percentile
- **Availability**: 99.9% uptime SLA
- **Error Rate**: < 0.1% error rate
- **Throughput**: > 1000 requests per second

## Capacity Planning

### Resource Forecasting
- **Historical Analysis**: Trend analysis of resource usage
- **Growth Projections**: Capacity planning based on business growth
- **Seasonal Patterns**: Traffic pattern analysis
- **Cost Optimization**: Right-sizing recommendations

### Scaling Triggers
- **CPU Utilization**: Scale up when > 70% for 5 minutes
- **Memory Utilization**: Scale up when > 80% for 5 minutes
- **Request Rate**: Scale up when > 80% of capacity
- **Error Rate**: Scale up when error rate > 1%

## Troubleshooting

### Common Issues and Solutions

#### High Response Time
```bash
# Check application metrics
kubectl top pods -n mern-blog

# Check database connections
kubectl logs -f deployment/mern-blog -n mern-blog | grep "database"

# Check external service calls
kubectl logs -f deployment/mern-blog -n mern-blog | grep "external"
```

#### High Error Rate
```bash
# Check error logs
kubectl logs -f deployment/mern-blog -n mern-blog | grep "ERROR"

# Check ingress status
kubectl get ingress -n mern-blog
kubectl describe ingress mern-blog-ingress -n mern-blog

# Check service endpoints
kubectl get endpoints -n mern-blog
```

#### Resource Exhaustion
```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n mern-blog

# Check persistent volume usage
kubectl get pv
kubectl describe pv <pv-name>
```

### Monitoring Commands
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Visit http://localhost:9090/targets

# Check OpenSearch health
kubectl port-forward -n logging svc/opensearch 9200:9200
curl http://localhost:9200/_cluster/health

# Check Grafana dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Visit http://localhost:3000
```

## Best Practices

### Monitoring Best Practices
1. **Golden Signals**: Monitor latency, traffic, errors, saturation
2. **SLI/SLO**: Define service level indicators and objectives
3. **Alert Fatigue**: Avoid too many alerts, focus on actionable alerts
4. **Runbook Integration**: Link alerts to runbooks and procedures
5. **Regular Reviews**: Monthly review of alerts and thresholds

### Logging Best Practices
1. **Structured Logging**: Use JSON format for machine readability
2. **Log Levels**: Use appropriate log levels consistently
3. **Context Information**: Include relevant context in logs
4. **Log Rotation**: Implement log rotation and retention policies
5. **Sensitive Data**: Avoid logging sensitive information

### Dashboard Best Practices
1. **User-Focused**: Design dashboards for specific user roles
2. **Key Metrics**: Focus on most important metrics
3. **Visual Hierarchy**: Use appropriate chart types
4. **Mobile-Friendly**: Ensure dashboards work on mobile devices
5. **Regular Updates**: Keep dashboards updated with changing requirements

## Monitoring Tools Integration

### External Integrations
- **AWS CloudWatch**: Cloud resource monitoring
- **DataDog**: Advanced APM and infrastructure monitoring
- **New Relic**: Application performance monitoring
- **Splunk**: Enterprise log management and analytics

### Custom Integrations
- **Webhook Endpoints**: Custom alert processing
- **API Integrations**: Third-party service monitoring
- **Custom Metrics**: Business-specific metrics collection
- **Machine Learning**: Anomaly detection and prediction

---

This monitoring guide provides comprehensive observability for the MERN Blog application, ensuring reliable operation and quick issue resolution.
