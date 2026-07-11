bucket         = "stratus-provinfra-state-staging"
key            = "terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-lock"
encrypt        = true
