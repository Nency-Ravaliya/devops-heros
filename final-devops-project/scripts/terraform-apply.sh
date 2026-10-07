#!/usr/bin/env bash
# Provision the Kubernetes cluster + platform with Terraform and record every command.
set +e
cd "$(dirname "$0")/.."
OUT=outputs; mkdir -p $OUT
run() { f="$OUT/$1.txt"; shift; { echo "\$ $*"; "$@" 2>&1; echo "[exit code: $?]"; } | tee "$f"; }
cd terraform
export TF_IN_AUTOMATION=true TF_CLI_ARGS="-no-color"
run ../$OUT/10-terraform-init     terraform init -input=false
run ../$OUT/11-terraform-validate terraform validate
run ../$OUT/12-terraform-plan     terraform plan -input=false -out=tfplan
run ../$OUT/13-terraform-apply    terraform apply -input=false -auto-approve tfplan
run ../$OUT/14-terraform-output   terraform output
run ../$OUT/15-terraform-state    terraform state list
KCFG=$(terraform output -raw kubeconfig_path)
mkdir -p ~/.kube && cp "$KCFG" ~/.kube/config
cd ..
{
echo "\$ kubectl get nodes -o wide"; kubectl get nodes -o wide; echo
echo "\$ helm list -A"; helm list -A; echo
echo "\$ kubectl get pods -A"; kubectl get pods -A; echo
} > $OUT/16-cluster.txt 2>&1
grep -q "Apply complete" $OUT/13-terraform-apply.txt
