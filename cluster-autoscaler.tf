resource "aws_iam_role" "clusterAutoscalerRole" {
  name = "clusterAutoscalerRole"
  assume_role_policy = data.aws_iam_policy_document.ClusterAutoScalerRoleAssumePolicy.json
}

data "aws_iam_policy_document" "ClusterAutoScalerRoleAssumePolicy" {

  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test = "StringEquals"
      variable = replace("${module.eks.cluster_oidc_issuer_url}:sub","https://","")
      values = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  policy_arn = aws_iam_policy.worker_autoscaling.arn
  role       = aws_iam_role.clusterAutoscalerRole.name
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${module.eks.cluster_id}"
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}


resource "helm_release" "autoscaler" {
    repository = "https://kubernetes.github.io/autoscaler"
    name = "cluster-autoscaler"
    chart = "cluster-autoscaler"
    namespace = "kube-system"
    version = "9.4.0"
    set {
      name = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.clusterAutoscalerRole.arn
    }
    set {
      name = "rbac.create"
      value = true
    }
    set {
      name = "cloudProvider"
      value = "aws"
    }
    set {
      name = "awsRegion"
      value = "us-east-1"
    }
    set {
      name = "autoDiscovery.clusterName"
      value = module.eks.cluster_id
    }
    set {
      name = "autoDiscovery.enabled"
      value = true
    }
    set {
      name = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    }
    set {
      name = "extraEnv.AWS_STS_REGIONAL_ENDPOINTS"
      value = "regional"
    }
}