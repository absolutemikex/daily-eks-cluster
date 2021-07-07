# Example setting up the Ebs-Csi-Driver using IRSA - Creates role and policy
# Then finally deploys the helm chart

data "aws_iam_policy_document" "EbsDriverPolicy" {
  statement {
    sid = "EbsCsiDriverPolicy"
    effect = "Allow"
    actions = [ 
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications",
        "ec2:DetachVolume",
        "ec2:ModifyVolume" ]
    resources = [ "*" ]
  }
}

resource "aws_iam_policy" "ebscsidriver" {
  name = "eks-ebs-csi-driver-${module.eks.cluster_id}"
  description = "EBS Policy for Cluster - ${module.eks.cluster_id}"
  policy = data.aws_iam_policy_document.EbsDriverPolicy.json
}

data "aws_iam_policy_document" "ebsRoleAssumePolicy" {

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
      values = ["system:serviceaccount:kube-system:ebs-csi-controller-sa",
            "system:serviceaccount:kube-system:ebs-snapshot-controller"]
    }
  }
}

resource "aws_iam_role" "ebsCsiDriverRole" {
  name = "eks-ebs-csi-driver-role-${module.eks.cluster_id}"
  assume_role_policy = data.aws_iam_policy_document.ebsRoleAssumePolicy.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_attach" {
  policy_arn = aws_iam_policy.ebscsidriver.arn
  role       = aws_iam_role.ebsCsiDriverRole.name
}

resource "helm_release" "aws_ebs_csi_driver" {
    repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
    name = "aws-ebs-csi-driver"
    chart = "aws-ebs-csi-driver"
    namespace = "kube-system"
    version = "1.2.1"

    set {
      name = "region"
      value = "us-east-1"
    }
    set {
      name = "namespace"
      value = "kube-system"
    }
    set {
      name = "enableVolumeScheduling"
      value = true
    }
    set {
      name = "enableVolumeResizing"
      value = true
    }
    set {
      name = "enableVolumeSnapshot"
      value = true
    }
    set{
      name = "serviceAccount.controller.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.ebsCsiDriverRole.arn
    }
}