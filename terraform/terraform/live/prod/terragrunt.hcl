include {
  path = find_in_parent_folders()
}

inputs = {
  env          = "prod"
  yc_token     = "t1.9euelXXXXXXXX-prod"       # put here real prod-token
  yc_cloud_id  = "b1g76u2XXXXXXXX-prod"
  yc_folder_id = "b1gsgjXXXXXXXX-prod"
  yc_zone      = "ru-central1-a"
  image_id     = "fd81gsj7pb9oi8ks3cvo"        # Ubuntu 24.04 LTS
  ssh_key_path = "~/.ssh/id_ed25519_yacloud.pub"
  master_name  = "k3s-master-prod"

  cidr_blocks = ["10.1.0.0/24"]

  k3s_nodes = [
    {
      name     = "k3s-master-prod"
      cores    = 2
      memory   = 2
      disk     = 15
      fraction = 100
      platform = "intel-ice-lake"
    },
    {
      name     = "k3s-worker-1-prod"
      cores    = 2
      memory   = 1
      disk     = 10
      fraction = 20
      platform = "intel-ice-lake"
    },
    {
      name     = "k3s-worker-2-prod"
      cores    = 2
      memory   = 1
      disk     = 10
      fraction = 20
      platform = "intel-ice-lake"
    }
  ]
}
