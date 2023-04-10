terraform {
  backend "gcs" {
    bucket = "storybooks-terraform-devops-terraform"
    prefix = "/state/storybooks"
  }
}