# Example of setting up the AWS VPC CNI with IRSA. This should be applied after the AWS VPC CNI is reapplied
# with the updated configuration for Custom Networking

#data "aws_iam_policy_document" "VPC_CNIRoleAssumePolicy" {
#
#  statement {
#    effect = "Allow"
#    actions = ["sts:AssumeRoleWithWebIdentity"]
#    principals {
#      type = "Federated"
#      identifiers = [module.eks.oidc_provider_arn]
#    }
#    condition {
#      test = "StringEquals"
#      variable = replace("${module.eks.cluster_oidc_issuer_url}:sub","https://","")
#      values = ["system:serviceaccount:kube-system:aws-node"]
#    }
#  }
#}
#
#resource "aws_iam_policy" "aws_vpc_cni_policy" {
#  name   = "AwsVpcCNIPolicy"
#  policy = file("policies/aws-vpc-cni-policy.json")
#}
#
#resource "aws_iam_role" "awsVpcCniController" {
#  name = "aws-vpc-cni-controller-role-${module.eks.cluster_id}"
#  assume_role_policy = data.aws_iam_policy_document.VPC_CNIRoleAssumePolicy.json
#}
#
#resource "aws_iam_role_policy_attachment" "aws-vpc-cni-controller-attach" {
#  policy_arn = aws_iam_policy.aws_vpc_cni_policy.arn
#  role = aws_iam_role.awsVpcCniController.name
#}
#
#resource "kubernetes_manifest" "serviceaccount_aws_node" {
#  provider = kubernetes-alpha
#  manifest = {
#    "apiVersion" = "v1"
#    "kind" = "ServiceAccount"
#    "metadata" = {
#      "annotations" = {
#        "eks.amazonaws.com/role-arn" = aws_iam_role.awsVpcCniController.arn
#      }
#      "name" = "aws-node"
#      "namespace" = "kube-system"
#    }
#  }
#  depends_on = [ aws_iam_role.awsVpcCniController ]
#}
#