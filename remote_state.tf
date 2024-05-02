terraform {
  backend "s3" {
    bucket = "nbltfstates"
    key    = "platform/dev/tfstate"
    region = "us-east-1"
  }
}
