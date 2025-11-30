# Strapi Terraform Demo

## Files
- `terraform/` - Terraform scripts 
- `docker/` - Docker Compose config

## Quick deploy
1. Edit `terraform/variables.tf` or pass `-var` values for DB password, and set `ec2_key_name` to an existing key pair name in your AWS account.
2. `cd terraform`
3. `terraform init`
4. `terraform apply -auto-approve`
5. After EC2 is ready, visit: `http://<ec2_public_ip>:1337`
   

## Cleanup
`terraform destroy -auto-approve
