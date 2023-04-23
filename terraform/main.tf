terraform {
  backend "gcs" {
    bucket = "storybooks-terraform-devops-terraformv2"
    prefix = "/state/storybooks"
  }
}