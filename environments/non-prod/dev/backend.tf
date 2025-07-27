terraform {
  backend "gcs" {
    bucket  = "terraform-statefile-np"
    prefix  = "dev/terraform/state"
  }
} 