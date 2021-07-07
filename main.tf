terraform{
    backend "s3" {
    bucket = "mmiccupoctf"
    key    = "eks/tfgocd.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt = true
  }
}

provider "helm" {
  kubernetes {
    config_path = module.eks.kubeconfig_filename
  }
}

