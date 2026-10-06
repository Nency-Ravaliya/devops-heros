#!/usr/bin/env bash
# Verify the Terraform-provisioned LocalStack resources with the AWS CLI and
# push a real pg_dump of the StockPilot database into the artifacts bucket.
set -euo pipefail
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
EP="--endpoint-url ${LOCALSTACK:-http://localhost:4566}"
cd "$(dirname "$0")/../terraform"
VPC=$(terraform output -raw vpc_id)
BUCKET=$(terraform output -raw artifacts_bucket)
TABLE=$(terraform output -raw tf_lock_table)
run() { echo "\$ $*"; "$@"; echo; }

run terraform output
run aws $EP ec2 describe-vpcs --vpc-ids "$VPC" --query 'Vpcs[].{Id:VpcId,Cidr:CidrBlock,Name:Tags[?Key==`Name`]|[0].Value}' --output table
run aws $EP ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC" --query 'Subnets[].{Id:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' --output table
run aws $EP ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC" --query 'SecurityGroups[?GroupName!=`default`].{Name:GroupName,Ports:IpPermissions[].FromPort|join(`,`,to_array(@)[].to_string(@))}' --output table
run aws $EP s3api get-bucket-versioning --bucket "$BUCKET"
run aws $EP s3api get-bucket-encryption --bucket "$BUCKET" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault'
run aws $EP dynamodb describe-table --table-name "$TABLE" --query 'Table.{Name:TableName,Key:KeySchema[0].AttributeName,Billing:BillingModeSummary.BillingMode,Status:TableStatus}' --output table

# Real backup of the in-cluster PostgreSQL -> S3 (what a CronJob would do on AWS)
DUMP=/tmp/stockpilot-$(date +%Y%m%d%H%M%S).sql.gz
echo "\$ kubectl -n final exec deploy/stockpilot-postgres -- sh -c 'pg_dump -U \"\$POSTGRES_USER\" \"\$POSTGRES_DB\"' | gzip > $DUMP"
kubectl -n final exec deploy/stockpilot-postgres -- sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip > "$DUMP"
ls -l "$DUMP"; echo
run aws $EP s3 cp "$DUMP" "s3://$BUCKET/db-backups/$(basename "$DUMP")"
run aws $EP s3 ls "s3://$BUCKET/db-backups/"
