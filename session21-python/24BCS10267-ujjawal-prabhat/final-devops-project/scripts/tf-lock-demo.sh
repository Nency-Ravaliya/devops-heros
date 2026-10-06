#!/usr/bin/env bash
# Demonstrates DynamoDB state locking: two concurrent applies on the same state.
set -uo pipefail
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
cd "$(dirname "$0")/../terraform/backend-demo"
echo '$ terraform init -no-color'
terraform init -no-color | grep -E 'backend|Successfully|initialized'
echo
echo '$ terraform apply -auto-approve -no-color   # (A) holds the lock ~25s, started in background'
terraform apply -auto-approve -no-color > /tmp/tf-lock-a.log 2>&1 &
A=$!
sleep 8
echo
echo '$ aws dynamodb scan --table-name stockpilot-dev-tf-locks   # while (A) is running'
aws --endpoint-url http://localhost:4566 dynamodb scan --table-name stockpilot-dev-tf-locks \
  --query 'Items[].{LockID:LockID.S,Info:Info.S}' --output json | cut -c1-260
echo
echo '$ terraform apply -auto-approve -no-color -lock-timeout=0s   # (B) concurrent apply'
terraform apply -auto-approve -no-color -lock-timeout=0s 2>&1 | sed -n '1,14p'
echo "(B) exit code: ${PIPESTATUS[0]}"
wait $A
echo
echo '--- (A) output ---'
tail -6 /tmp/tf-lock-a.log
echo
echo '$ aws s3 ls s3://stockpilot-dev-artifacts-24bcs10267/tfstate/'
aws --endpoint-url http://localhost:4566 s3 ls s3://stockpilot-dev-artifacts-24bcs10267/tfstate/
