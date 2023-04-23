terraform {
  backend "gcs" {
    bucket = "storybooks-384602-terraform-state"
    prefix = "/state/storybooks"
  }
}