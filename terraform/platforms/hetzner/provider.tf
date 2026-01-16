provider "hcloud" {
  token = env("HETZNER_TOKEN")
}

provider "hcloud" {
  alias  = "account"
  token  = var.account_token != "" ? var.account_token : env("HETZNER_TOKEN")
}
