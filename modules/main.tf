terraform {
   backend "s3" {
    bucket = "zohar-tf-state"
    key = "env/terraform.tfstate"
    dynamodb_table = "tf-cloudschool-env"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}


module "clouschool-app" {
  source = "../"
  // ???
  instance_type = "t2.micro"
  chef-resources_key = "flightpricealarm/chef-flight-price-alarm.tar.gz"
}
