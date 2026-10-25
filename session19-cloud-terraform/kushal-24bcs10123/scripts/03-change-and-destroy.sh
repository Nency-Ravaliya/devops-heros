#!/usr/bin/env bash
# Session 19 / step 3: a change that forces replacement, a change that updates in place, then destroy everything.
cd "$(dirname "$0")/.." && . scripts/lib.sh
cd terraform-project
V="-var-file=localstack.tfvars"
hr "CHANGE 1: a bigger instance type -> update in place (EC2 supports it after a stop)"
x "tf plan -input=false $V -var instance_type=t3.small | grep -E '~|-/\+|Plan:'"
hr "CHANGE 2: a different subnet CIDR -> the subnet must be replaced, and everything that depends on it"
x "tf plan -input=false $V -var public_subnet_cidr=10.20.2.0/24 | grep -E '^  # |Plan:'"
hr "terraform destroy"
x "tf destroy -input=false -auto-approve $V"
hr "LOCALSTACK IS EMPTY AGAIN"
x "awsl ec2 describe-vpcs --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,Default:IsDefault}' --output table"
x "awsl ec2 describe-instances --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}' --output table"
x "awsl s3 ls; echo \"(buckets left: \$(awsl s3 ls | wc -l | tr -d ' '))\""
x "tf state list; echo '(state is empty)'"
