data "aws_iam_policy_document" "AwsLoadBalancerControllerAssumePolicy" {

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
      values = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_policy" "aws_load_balancer_policy" {
  name   = "AWSLbControllerPolicy"
  policy = file("policies/AWSLoadbalancercontroller.json")
}

resource "aws_iam_role" "awsLoadBalancerController" {
  name = "aws-load-balancer-controller-role-${module.eks.cluster_id}"
  assume_role_policy = data.aws_iam_policy_document.AwsLoadBalancerControllerAssumePolicy.json
}

resource "aws_iam_role_policy_attachment" "aws-lb-controller-attach" {
  policy_arn = aws_iam_policy.aws_load_balancer_policy.arn
  role = aws_iam_role.awsLoadBalancerController.name
}

resource "helm_release" "awsLoadBalancerControllerHelm" {
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  name = "aws-load-balancer-controller"
  namespace = "kube-system"
  version = "1.1.6"
  set {
      name = "region"
      value = "us-east-1"   # Edit to desired region
    }
  set {
    name = "clusterName"
    value = module.eks.cluster_id   # Cluster Name
  }
  set {
    name = "vpcId"
    value = module.vpc.vpc_id   # Add VPC ID here
  }
  set {
    name = "serviceAccount.create"
    value = "true"
  }
  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.awsLoadBalancerController.arn
  }
  depends_on = [ aws_iam_role.awsLoadBalancerController,
                 aws_iam_policy.aws_load_balancer_policy,
                 aws_iam_role_policy_attachment.aws-lb-controller-attach,
                 module.eks ]
}