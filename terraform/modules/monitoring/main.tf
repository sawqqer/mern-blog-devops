# Monitoring module for Prometheus and Grafana

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Create namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

# Install Prometheus using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "~> 52.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              memory = "2Gi"
              cpu    = "1000m"
            }
            limits = {
              memory = "4Gi"
              cpu    = "2000m"
            }
          }
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          ruleSelectorNilUsesHelmValues           = false
        }
      }
      
      grafana = {
        enabled = true
        adminPassword = "admin123"
        persistence = {
          enabled = true
          storageClassName = "gp3"
          size = "10Gi"
        }
        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "100m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }
        service = {
          type = "ClusterIP"
          port = 80
        }
      }

      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }
      }

      kubeStateMetrics = {
        enabled = true
      }

      nodeExporter = {
        enabled = true
      }

      kubelet = {
        enabled = true
      }

      kubeControllerManager = {
        enabled = true
      }

      kubeScheduler = {
        enabled = true
      }

      kubeEtcd = {
        enabled = true
      }

      kubeProxy = {
        enabled = true
      }

      kubeApiServer = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# Create ServiceMonitor for application metrics
resource "kubernetes_manifest" "app_metrics_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "mern-blog-app"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app = "mern-blog"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "mern-blog"
        }
      }
      endpoints = [
        {
          port     = "metrics"
          path     = "/metrics"
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus]
}

# Create PrometheusRule for custom alerts
resource "kubernetes_manifest" "app_alerts" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "mern-blog-alerts"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app = "mern-blog"
      }
    }
    spec = {
      groups = [
        {
          name = "mern-blog"
          rules = [
            {
              alert = "HighErrorRate"
              expr  = "rate(http_requests_total{status=~\"5..\"}[5m]) > 0.1"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High error rate detected"
                description = "Error rate is {{ $value }} errors per second"
              }
            },
            {
              alert = "HighResponseTime"
              expr  = "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High response time detected"
                description = "95th percentile response time is {{ $value }} seconds"
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus]
}
