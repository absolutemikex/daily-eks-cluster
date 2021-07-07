data "aws_iam_policy_document" "EfsCsiDriverAssumePolicy" {

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
      values = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_policy" "efs_csi_driver_policy" {
  name   = "EfsCsiDriverPolicy"
  policy = file("policies/EfsCsiDriverPolicy.json")
}

resource "aws_iam_role" "efscsidriverrole" {
  name = "efs-csi-driver-role-${module.eks.cluster_id}"
  assume_role_policy = data.aws_iam_policy_document.EfsCsiDriverAssumePolicy.json
}

resource "aws_iam_role_policy_attachment" "efs-csi-driver-attach" {
  policy_arn = aws_iam_policy.efs_csi_driver_policy.arn
  role = aws_iam_role.efscsidriverrole.name
}

resource "helm_release" "efs_csi_driver_helm" {
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart = "aws-efs-csi-driver"
  name = "aws-efs-csi-driver"
  namespace = "kube-system"
  version = "1.2.1"
  depends_on = [ aws_iam_role.efscsidriverrole,
                 aws_iam_policy.efs_csi_driver_policy,
                 aws_iam_role_policy_attachment.efs-csi-driver-attach,
                 module.eks ]
}