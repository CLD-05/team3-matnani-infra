output "created_namespaces_list" {
  value = [for ns in kubernetes_namespace.namespaces : ns.metadata[0].name]
}