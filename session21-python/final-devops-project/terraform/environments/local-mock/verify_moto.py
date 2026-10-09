"""Query the Moto mock directly (boto3) to prove Terraform really created the resources.

usage:  pip install boto3 && python verify_moto.py [http://localhost:4577]
"""
import sys

import boto3

ENDPOINT = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:4577"
KW = dict(endpoint_url=ENDPOINT, region_name="ap-south-1",
          aws_access_key_id="test", aws_secret_access_key="test")
ec2, eks, ecr = (boto3.client(s, **KW) for s in ("ec2", "eks", "ecr"))
F = [{"Name": "tag:Project", "Values": ["taskboard"]}]


def name(tags):
    return next((t["Value"] for t in tags or [] if t["Key"] == "Name"), "-")


print("== VPCs")
for v in ec2.describe_vpcs(Filters=F)["Vpcs"]:
    print(f"  {v['VpcId']:24} {v['CidrBlock']:15} {name(v.get('Tags'))}")
print("== Subnets")
for s in sorted(ec2.describe_subnets(Filters=F)["Subnets"], key=lambda s: s["CidrBlock"]):
    print(f"  {s['SubnetId']:26} {s['CidrBlock']:16} {s['AvailabilityZone']:12} {name(s.get('Tags'))}")
print("== Internet / NAT gateways")
for g in ec2.describe_internet_gateways(Filters=F)["InternetGateways"]:
    print(f"  {g['InternetGatewayId']:26} {name(g.get('Tags'))}")
for n in ec2.describe_nat_gateways(Filter=F)["NatGateways"]:
    print(f"  {n['NatGatewayId']:26} {n['State']:10} {name(n.get('Tags'))}")
print("== Security groups")
for g in ec2.describe_security_groups(Filters=F)["SecurityGroups"]:
    print(f"  {g['GroupId']:26} {g['GroupName']}")
print("== EKS")
for c in eks.list_clusters()["clusters"]:
    d = eks.describe_cluster(name=c)["cluster"]
    print(f"  cluster {c}  v{d['version']}  {d['status']}")
    for ng in eks.list_nodegroups(clusterName=c)["nodegroups"]:
        n = eks.describe_nodegroup(clusterName=c, nodegroupName=ng)["nodegroup"]
        sc = n["scalingConfig"]
        print(f"  nodegroup {ng}  {n['instanceTypes']}  min={sc['minSize']} desired={sc['desiredSize']} max={sc['maxSize']}  {n['status']}")
print("== ECR")
for r in ecr.describe_repositories()["repositories"]:
    print(f"  {r['repositoryUri']}  scanOnPush={r['imageScanningConfiguration']['scanOnPush']}  {r['imageTagMutability']}")
