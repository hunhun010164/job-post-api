name: aws S3, Cloudfront, Route53 & ACM

on:
  push:
    branches:
      - main

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Set up Terraform
      uses: hashicorp/setup-terraform@v1
      with:
        terraform_version: 0.15.0

    - name: Terraform Init
      run: terraform init
      working-directory: ./terraform-directory  # 更改为你的 Terraform 配置目录

    - name: Terraform Apply
      run: terraform apply -auto-approve
      working-directory: ./terraform-directory

    - name: Terraform Plan
      run: terraform plan
      working-directory: ./terraform-directory

    - name: Terraform Destroy
      run: terraform destroy -auto-approve
      working-directory: ./terraform-directory
