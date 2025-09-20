include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  vpc_name = "stage-network"
}
