# Example of using Kubernetes Alpha Provider to deploy the manifests via TF
# These EniConfigs are sample configrations that are needed to configure custom networking
# These should be applied after the AWS VPC CNI is reapplied with the custom networking changes?

resource "kubernetes_manifest" "customCNI1" {
  provider = kubernetes-alpha
  manifest = {
      apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
      kind = "ENIConfig"
      metadata = {
          name = "us-east-1a"
      }
      spec = {
          subnet = "subnet-0fc2529ca8a5f8bf5"
          securityGroups = [
              module.eks.worker_security_group_id
          ]
      }
  }
}

resource "kubernetes_manifest" "customCNI2" {
  provider = kubernetes-alpha
  manifest = {
      apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
      kind = "ENIConfig"
      metadata = {
          name = "us-east-1b"
      }
      spec = {
          subnet = "subnet-04f0b3e95a3c7e242"
          securityGroups = [
              module.eks.worker_security_group_id
          ]
      }
  }
}

resource "kubernetes_manifest" "customCNI3" {
  provider = kubernetes-alpha
  manifest = {
      apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
      kind = "ENIConfig"
      metadata = {
          name = "us-east-1c"
      }
      spec = {
          subnet = "subnet-02acd01b74fff3f90"
          securityGroups = [
              module.eks.worker_security_group_id
          ]
      }
  }
}