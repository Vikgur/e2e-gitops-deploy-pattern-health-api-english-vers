include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/vm"
}

inputs = {
  vm_prefix = "stage"
}
