package terraform.security

deny[msg] {
  some r
  input.resource_changes[r].type == "yandex_vpc_security_group_rule"
  input.resource_changes[r].change.after.v4_cidr_blocks[_] == "0.0.0.0/0"
  msg := "0.0.0.0/0 in security group is forbidden"
}

deny[msg] {
  some r
  input.resource_changes[r].type == "yandex_storage_bucket"
  flags := input.resource_changes[r].change.after.anonymous_access_flags
  flags.read
  msg := "Public buckets in Object Storage are forbidden"
}

deny[msg] {
  some r
  input.resource_changes[r].type == "yandex_storage_bucket"
  not input.resource_changes[r].change.after.server_side_encryption_configuration
  msg := "Bucket without SSE-KMS is forbidden"
}

deny[msg] {
  some r
  input.resource_changes[r].type == "yandex_compute_instance"
  labels := input.resource_changes[r].change.after.labels
  (labels.Owner == "" or labels.Env == "" or labels.CostCenter == "")
  msg := "Missing required labels Owner/Env/CostCenter on VM"
}

warn[msg] {
  not input.configuration.provider_config.yandex.version
  msg := "Yandex provider version is not pinned (versions.tf)"
}
