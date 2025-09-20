terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    required_var_files = []
  }
}

remote_state {
  backend = "s3"
  config = {
    endpoint                   = "storage.yandexcloud.net"
    bucket                     = "tfstate-health-api"
    key                        = "${path_relative_to_include()}/terraform.tfstate"
    region                     = "ru-central1"
    force_path_style           = true
    skip_region_validation     = true
    skip_credentials_validation= true
  }
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.95.0"
    }
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}
EOF
}
