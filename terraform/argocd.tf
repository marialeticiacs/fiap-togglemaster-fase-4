resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.6" 

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
  
  depends_on = [
    aws_eks_node_group.node_group
  ]
}