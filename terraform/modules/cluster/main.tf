# --- IAM Role para o Cluster EKS ---
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# --- O Cluster EKS ---
resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# --- IAM Role para o Node Group (As máquinas) ---
resource "aws_iam_role" "node_group_role" {
  name = "${var.project_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}

# --- O Node Group ---
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.project_name}-nodes"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_policy
  ]
}

# --- Instalação do ArgoCD via Helm ---
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.6"
  
  timeout          = "600" 
  wait             = true

  depends_on = [aws_eks_node_group.node_group]
}

# --- OIDC Provider (Necessário para o IRSA funcionar) ---
data "tls_certificate" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# --- Política de Acesso para o Analytics (SQS e DynamoDB) ---
resource "aws_iam_policy" "analytics_policy" {
  name        = "${var.project_name}-analytics-policy"
  description = "Permissoes para o analytics-service acessar SQS e DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:us-east-2:236604670467:analytics-queue"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = "arn:aws:dynamodb:us-east-2:236604670467:table/togglemaster-analytics"
      }
    ]
  })
}

# --- IAM Role para a ServiceAccount do Analytics ---
resource "aws_iam_role" "analytics_irsa_role" {
  name = "${var.project_name}-analytics-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:togglemaster:analytics-service-account"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "analytics_attach" {
  policy_arn = aws_iam_policy.analytics_policy.arn
  role       = aws_iam_role.analytics_irsa_role.name
}

# --- Criação do Namespace togglemaster ---
resource "kubernetes_namespace" "togglemaster" {
  metadata {
    name = "togglemaster"
  }
}

# --- Criação da ServiceAccount no Kubernetes via Terraform ---
resource "kubernetes_service_account" "analytics_sa" {
  metadata {
    name      = "analytics-service-account"
    namespace = kubernetes_namespace.togglemaster.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.analytics_irsa_role.arn
    }
  }

  depends_on = [aws_eks_node_group.node_group, kubernetes_namespace.togglemaster]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"
  
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  })
}