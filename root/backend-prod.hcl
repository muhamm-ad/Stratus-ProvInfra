bucket         = "stratus-provinfra-state-prod"
key            = "terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-lock"
encrypt        = true
