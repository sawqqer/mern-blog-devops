# Logging module for OpenSearch and Fluentd

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

# Create namespace for logging
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
    labels = {
      name = "logging"
    }
  }
}

# Install OpenSearch using Helm
resource "helm_release" "opensearch" {
  name       = "opensearch"
  repository = "https://opensearch-project.github.io/helm-charts"
  chart      = "opensearch"
  namespace  = kubernetes_namespace.logging.metadata[0].name
  version    = "~> 2.0"

  values = [
    yamlencode({
      singleNode = true
      
      persistence = {
        enabled = true
        storageClass = "gp3"
        size = "50Gi"
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

      config = {
        "opensearch.yml" = {
          "plugins.security.disabled" = "true"
          "cluster.name" = "opensearch-cluster"
          "node.name" = "opensearch-node"
          "discovery.type" = "single-node"
          "bootstrap.memory_lock" = "true"
          "network.host" = "0.0.0.0"
          "http.port" = "9200"
          "transport.port" = "9300"
          "cluster.initial_cluster_manager_nodes" = "opensearch-node"
        }
      }

      service = {
        type = "ClusterIP"
        port = 9200
      }
    })
  ]

  depends_on = [kubernetes_namespace.logging]
}

# Install OpenSearch Dashboards
resource "helm_release" "opensearch_dashboards" {
  name       = "opensearch-dashboards"
  repository = "https://opensearch-project.github.io/helm-charts"
  chart      = "opensearch-dashboards"
  namespace  = kubernetes_namespace.logging.metadata[0].name
  version    = "~> 2.0"

  values = [
    yamlencode({
      persistence = {
        enabled = true
        storageClass = "gp3"
        size = "5Gi"
      }

      resources = {
        requests = {
          memory = "512Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "1Gi"
          cpu    = "500m"
        }
      }

      config = {
        "opensearch_dashboards.yml" = {
          "opensearch.hosts" = ["http://opensearch:9200"]
          "opensearch.security.multitenancy.enabled" = "false"
          "opensearch.security.readonly_mode.roles" = "[]"
        }
      }

      service = {
        type = "ClusterIP"
        port = 5601
      }
    })
  ]

  depends_on = [helm_release.opensearch]
}

# Install Fluentd using Helm
resource "helm_release" "fluentd" {
  name       = "fluentd"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluentd"
  namespace  = kubernetes_namespace.logging.metadata[0].name
  version    = "~> 0.3"

  values = [
    yamlencode({
      replicaCount = 2

      image = {
        repository = "fluent/fluentd-kubernetes-daemonset"
        tag        = "v1.16-debian-elasticsearch7-1"
        pullPolicy = "IfNotPresent"
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

      config = {
        fluent.conf = <<-EOF
          @include systemd.conf
          @include kubernetes.conf
          @include conf.d/*.conf

          <match **>
            @type opensearch
            @id out_os
            @log_level info
            include_tag_key true
            host "#{ENV['OPENSEARCH_HOST']}"
            port "#{ENV['OPENSEARCH_PORT']}"
            path ""
            scheme "#{ENV['OPENSEARCH_SCHEME']}"
            ssl_verify "#{ENV['OPENSEARCH_SSL_VERIFY']}"
            ssl_version "#{ENV['OPENSEARCH_SSL_VERSION']}"
            reload_connections "#{ENV['OPENSEARCH_RELOAD_CONNECTIONS']}"
            reconnect_on_error "#{ENV['OPENSEARCH_RECONNECT_ON_ERROR']}"
            reload_on_failure "#{ENV['OPENSEARCH_RELOAD_ON_FAILURE']}"
            log_es_400_reason "#{ENV['OPENSEARCH_LOG_ES_400_REASON']}"
            logstash_prefix "#{ENV['OPENSEARCH_LOGSTASH_PREFIX']}"
            logstash_format "#{ENV['OPENSEARCH_LOGSTASH_FORMAT']}"
            logstash_dateformat "#{ENV['OPENSEARCH_LOGSTASH_DATEFORMAT']}"
            index_name "#{ENV['OPENSEARCH_INDEX_NAME']}"
            type_name "#{ENV['OPENSEARCH_TYPE_NAME']}"
            include_timestamp "#{ENV['OPENSEARCH_INCLUDE_TIMESTAMP']}"
            template_name "#{ENV['OPENSEARCH_TEMPLATE_NAME']}"
            template_file "#{ENV['OPENSEARCH_TEMPLATE_FILE']}"
            template_overwrite "#{ENV['OPENSEARCH_TEMPLATE_OVERWRITE']}"
            template_pattern "#{ENV['OPENSEARCH_TEMPLATE_PATTERN']}"
            request_timeout "#{ENV['OPENSEARCH_REQUEST_TIMEOUT']}"
            suppress_type_name "#{ENV['OPENSEARCH_SUPPRESS_TYPE_NAME']}"
            <buffer>
              @type file
              path /var/log/fluentd-buffers/kubernetes.system.buffer
              flush_mode interval
              retry_type exponential_backoff
              flush_thread_count 2
              flush_interval 5s
              retry_forever
              retry_max_interval 30
              chunk_limit_size 2M
              queue_limit_length 8
              overflow_action block
            </buffer>
          </match>
        EOF
      }

      env = [
        {
          name  = "OPENSEARCH_HOST"
          value = "opensearch"
        },
        {
          name  = "OPENSEARCH_PORT"
          value = "9200"
        },
        {
          name  = "OPENSEARCH_SCHEME"
          value = "http"
        },
        {
          name  = "OPENSEARCH_SSL_VERIFY"
          value = "false"
        },
        {
          name  = "OPENSEARCH_LOGSTASH_PREFIX"
          value = "logstash"
        },
        {
          name  = "OPENSEARCH_LOGSTASH_FORMAT"
          value = "true"
        },
        {
          name  = "OPENSEARCH_LOGSTASH_DATEFORMAT"
          value = "%Y%m%d"
        },
        {
          name  = "OPENSEARCH_INDEX_NAME"
          value = "logstash"
        },
        {
          name  = "OPENSEARCH_TYPE_NAME"
          value = "_doc"
        }
      ]

      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }

      tolerations = [
        {
          key    = "node-role.kubernetes.io/control-plane"
          effect = "NoSchedule"
        },
        {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      ]

      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [
              {
                matchExpressions = [
                  {
                    key      = "kubernetes.io/os"
                    operator = "In"
                    values   = ["linux"]
                  }
                ]
              }
            ]
          }
        }
      }
    })
  ]

  depends_on = [helm_release.opensearch]
}
