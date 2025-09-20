include {
  path = find_in_parent_folders()
}

inputs = {
  env          = "stage"
  yc_token     = "t1.9euelXXXXXXXX-stage"      # put here real stage-token
  yc_cloud_id  = "b1g76u2XXXXXXXX-stage"
  yc_folder_id = "b1gsgjXXXXXXXX-stage"
  yc_zone      = "ru-central1-a"
  image_id     = "fd81gsj7pb9oi8ks3cvo"        # Ubuntu 24.04 LTS
  ssh_key_path = "~/.ssh/id_ed25519_yacloud.pub"
  master_name  = "k3s-master-stage"

  cidr_blocks = ["10.2.0.0/24"]

  k3s_nodes = [
    {
      name     = "k3s-master-stage"
      cores    = 2
      memory   = 2
      disk     = 15
      fraction = 100
      platform = "intel-ice-lake"
    },
    {
      name     = "k3s-worker-1-stage"
      cores    = 2
      memory   = 1
      disk     = 10
      fraction = 20
      platform = "intel-ice-lake"
    },
    {
      name     = "k3s-worker-2-stage"
      cores    = 2
      memory   = 1
      disk     = 10
      fraction = 20
      platform = "intel-ice-lake"
    }
  ]
}
