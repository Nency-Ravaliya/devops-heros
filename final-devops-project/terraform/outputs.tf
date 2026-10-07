output "cluster_name" {
  value = kind_cluster.this.name
}

output "api_endpoint" {
  value = kind_cluster.this.endpoint
}

output "kubeconfig_path" {
  value = kind_cluster.this.kubeconfig_path
}

output "platform_releases" {
  value = concat(
    [helm_release.ingress_nginx.name, helm_release.metrics_server.name, helm_release.argocd.name],
    [for m in helm_release.monitoring : m.name]
  )
}
