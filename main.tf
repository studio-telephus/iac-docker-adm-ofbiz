module "container_adm_ofbiz" {
  source    = "github.com/studio-telephus/terraform-lxd-instance.git?ref=1.0.1"
  name      = "container-adm-ofbiz"
  image     = "images:debian/bookworm"
  profiles  = ["limits", "fs-dir", "nw-adm"]
  autostart = false
  nic = {
    name = "eth0"
    properties = {
      nictype        = "bridged"
      parent         = "adm-network"
      "ipv4.address" = "10.0.10.127"
    }
  }
  mount_dirs = [
    "${path.cwd}/filesystem-shared-ca-certificates",
    "${path.cwd}/filesystem",
  ]
  exec_enabled = true
  exec         = "/mnt/install.sh"
  environment = {
    RANDOM_STRING               = "391db6f3-9db2-4111-8eb9-683c3bbda207"
    SERVER_KEYSTORE_STOREPASS   = var.server_keystore_storepass
    SERVER_TRUSTSTORE_STOREPASS = var.server_truststore_storepass
  }
}
