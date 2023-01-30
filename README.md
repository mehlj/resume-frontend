# resume-frontend
Frontend for Cloud Resume Challenge project.

## Remote State
The `state_bucket/` directory contains Terraform code that must be applied first - to provision the remote state S3 bucket and DynamoDB that the rest of the project depends on.

Upon initial interaction with the project only, do the following:
```
$ cd state_bucket
$ terraform init
$ terraform apply
```