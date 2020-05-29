# terraform-flights-alarm
The repo contains the Hashicorp Terraform resources files to the 'Flight Price Alarm' application with a full AWS infrastructure environment
This repo is part of my final [Cloud School](https://www.linkedin.com/company/cloud-school/) ['Flight Price Alarm'](https://github.com/lightenzm/flight-price-alarm) project

## What are we provisioning here?
- ELB + SG
- RDS + SG
- LaunchConfiguration includes a user-data script and SG  
- AutoscalingGroup

## CD
The user-data scripts installs Chef-solo, downloads the Chef resources and run it. 
Chef will deploy and run the application on the instance (for details see the [chef repo](https://github.com/lightenzm/chef-flight-price-alarm))

## Persistence
- The terraform statefile is stored in an AWS S3 bucket
- The terraform lock file is stored in AWS Dynamodb

## How to use
- Clone this repository
- cd the 'modules' directory
- Type 'terraform apply' (the first time would require 'terraform init'. You will be required to fill the missing variables at this point if they are missing)
