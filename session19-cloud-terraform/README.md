# Session 19: Cloud & Terraform in Action

## Task: End-to-End Cloud Infrastructure
Built a complete cloud infrastructure project on AWS using Terraform.

### Architecture
Terraform provisioned the following AWS resources:
- VPC
- Subnet
- Security Group
- EC2 Instance
- S3 Bucket

```mermaid
graph TD
    subgraph AWS Cloud
        S3[🪣 Amazon S3 Bucket]
        
        subgraph VPC ["☁️ VPC"]
            subgraph Subnet ["🟢 Public Subnet"]
                SG["🛡️ Security Group\n(Allows HTTP/SSH)"]
                EC2["🖥️ EC2 Instance"]
                SG --- EC2
            end
        end
    end
    
    style S3 fill:#f0a500,color:#fff
    style VPC fill:#4a90d9,color:#fff
    style Subnet fill:#2ecc71,color:#fff
    style SG fill:#e04b5a,color:#fff
    style EC2 fill:#f39c12,color:#fff
```

### Outputs & Screenshots
![architecture/output](06-terraform-vpc/image-6.png)
![terraform apply 1](06-terraform-vpc/image.png)
![terraform apply 2](06-terraform-vpc/image-1.png)
![terraform apply 3](06-terraform-vpc/image-2.png)
![terraform apply 4](06-terraform-vpc/image-3.png)
![terraform apply 5](06-terraform-vpc/image-4.png)
![terraform destroy](06-terraform-vpc/image-5.png)

### Terraform Project Details
- **Source Code**: [View Terraform Files (06-terraform-vpc)](06-terraform-vpc)
- **Providers, Variables, Resources, Outputs, Dependencies**: Defined in `.tf` files.
- **Commands Executed**: `plan`, `apply`, `destroy`.


