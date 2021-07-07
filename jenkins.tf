
#resource "aws_efs_file_system" "jenkins_efs" {
#    creation_token = "jenkins_efs"
#  performance_mode = "generalPurpose"
#}
#
#resource "aws_efs_access_point" "jenkins_backup_access_point" {
#    file_system_id = aws_efs_file_system.jenkins_efs.id
#    posix_user {
#      gid = "1000"
#      uid = "1000"
#    }
#    root_directory {
#      creation_info {
#        owner_gid = "1000"
#        owner_uid = "1000"
#        permissions = "0777"
#      }
#      path = "/backup"
#    }
#  
#}
#resource "aws_efs_mount_target" "efs_mount_point_1" {
#    file_system_id = aws_efs_file_system.jenkins_efs.id
#    subnet_id = "subnet-06d026a92f5dbf212"
#}
#
#resource "aws_efs_mount_target" "efs_mount_point_2" {
#    file_system_id = aws_efs_file_system.jenkins_efs.id
#    subnet_id = "subnet-042623630bca5c2c6"
#}
#
#resource "aws_efs_mount_target" "efs_mount_point_3" {
#    file_system_id = aws_efs_file_system.jenkins_efs.id
#    subnet_id = "subnet-0ba25971808ebef07"
#}
#
#
#resource "kubernetes_namespace" "jenkins_namespace" {
#    metadata {
#      name = "jenkins"
#    }
#    depends_on = [
#      module.eks
#    ]
#}
#
#resource "kubernetes_storage_class" "jenkins_sc" {
#  metadata {
#    name = "jenkins-sc"
#  }
#  storage_provisioner = "efs.csi.aws.com"
#}
#
#resource "kubernetes_persistent_volume" "jenkins_volume" {
#  metadata {
#    name = "jenkins-backup-volume"
#  }
#  spec {
#    capacity = {
#      storage = "100Gi"
#    }
#    storage_class_name = kubernetes_storage_class.jenkins_sc.metadata.0.name
#    volume_mode = "Filesystem"
#    access_modes = ["ReadWriteOnce"]
#    persistent_volume_reclaim_policy = "Delete"
#    persistent_volume_source {
#      csi {
#        driver = "efs.csi.aws.com"
#        volume_handle = "fs-caeb3b7e::fsap-072a4c04765872b78"
#      }
#  }
#}
#depends_on = [
#  kubernetes_storage_class.jenkins_sc
#]
#}
#resource "kubernetes_persistent_volume_claim" "jenkins_backup_claim" {
#  metadata {
#    name = "jenkins-backup-claim"
#    namespace = "jenkins"
#  }
#  spec {
#    access_modes = ["ReadWriteOnce"]
#    resources {
#      requests = {
#        storage = "100Gi"
#      }
#    }
#    
#    storage_class_name = kubernetes_storage_class.jenkins_sc.metadata.0.name
#    volume_name = kubernetes_persistent_volume.jenkins_volume.metadata.0.name
#  }
#  depends_on = [
#  kubernetes_storage_class.jenkins_sc
#]
#}
#
#resource "helm_release" "jenkins" {
#  namespace = "jenkins"
#  name = "jenkins-operator"
#  repository = "https://raw.githubusercontent.com/jenkinsci/kubernetes-operator/master/chart"
#  chart = "jenkins-operator"
#  depends_on = [
#    module.eks,
#    kubernetes_namespace.jenkins_namespace,
#    kubernetes_persistent_volume_claim.jenkins_backup_claim,
#    kubernetes_persistent_volume.jenkins_volume
#  ]
#  values = [
#  file("manifests/jenkins-values.yaml")   # Additional values in YAML some of the values seem to map nicer with YAML.
#  ]
#  set {
#    name = "jenkins.namespace"
#    value = "jenkins"
#  }
#}
#
#resource "helm_release" "external-dns" {
#  namespace = "kube-system"
#  name = "external-dns"
#  repository = "https://charts.bitnami.com/bitnami"
#  chart = "external-dns"
#  set {
#    name = "aws.region"
#    value = "us-east-1"
#  }
#}