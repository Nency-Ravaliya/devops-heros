#!/usr/bin/env bash
# Session 18 / step 0: show that the laptop's AWS credentials are not usable, then start LocalStack as the stand-in.
cd "$(dirname "$0")/.." && . scripts/lib.sh
hr "TOOLS"
x "terraform version"
x "aws --version"
x "docker version --format 'Docker {{.Server.Version}} ({{.Server.Os}}/{{.Server.Arch}})'"
hr "REAL AWS: the credentials in ~/.aws/credentials are rejected"
x "sed -E 's/(aws_access_key_id *= *)(....).*/\1\2................/; s/(aws_secret_access_key *= *).*/\1<hidden>/' ~/.aws/credentials"
x "env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY aws sts get-caller-identity --region ap-south-1"
hr "REAL AWS: terraform plan fails for the same reason (no -var-file, so the provider talks to amazonaws.com)"
x "cd terraform-s3-demo && env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY terraform init -input=false -no-color | tail -3; env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY terraform plan -input=false -no-color 2>&1 | tail -12; cd .."
hr "LOCALSTACK: the AWS API emulator I use instead"
x "docker ps --filter name=localstack-kushal --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
x "curl -s $LS/_localstack/health | python3 -m json.tool | grep -E 'version|edition|\"(s3|ec2|iam|sts|dynamodb|rds)\"'"
x "awsl sts get-caller-identity"
