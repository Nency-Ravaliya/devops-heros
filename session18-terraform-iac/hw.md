# Terraform Screenshots

![Terraform Screenshot 1](screenshots/Screenshot%202026-09-29%20132139.png)

![Terraform Screenshot 2](screenshots/Screenshot%202026-09-29%20132152.png)

![Terraform Screenshot 3](screenshots/Screenshot%202026-09-29%20132229.png)

![Terraform Screenshot 4](screenshots/Screenshot%202026-09-29%20132243.png)

![Terraform Screenshot 5](screenshots/Screenshot%202026-09-29%20132253.png)

![Terraform Screenshot 6](screenshots/Screenshot%202026-09-29%20132303.png)

![Terraform Screenshot 7](screenshots/Screenshot%202026-09-29%20132311.png)


# In-Depth Architectural Guide to Core AWS Cloud Services

## 1. Amazon Elastic Compute Cloud (EC2)

### Architectural Foundation
Amazon EC2 is the foundational compute service of AWS. Underneath the virtual machines you deploy sits the AWS Nitro System, a combination of custom hardware and a lightweight hypervisor. This architecture offloads virtualization functions (like networking and storage routing) to dedicated hardware, allowing the virtual machine to use nearly 100% of the underlying server's resources.

### Instance Categories and Workload Matching
Choosing the right instance type is critical for performance and cost-efficiency:
* **General Purpose (M, T instances):** Provide a balance of compute, memory, and networking. Ideal for web servers, container orchestration nodes (like Kubernetes worker nodes), and standard backend APIs.
* **Compute Optimized (C instances):** Offer high-performance processors for compute-bound applications, such as batch processing, distributed data analysis, or running high-performance web servers.
* **Memory Optimized (R, X instances):** Designed to deliver fast performance for workloads that process large datasets in memory, such as in-memory databases (Redis) or real-time big data analytics.
* **Accelerated Computing (P, G instances):** Equipped with hardware accelerators, such as NVIDIA GPUs. These are strictly required for executing GPU-accelerated machine learning workloads, training deep learning models (like YOLO for vehicle detection or ResNet architectures), applying parameter-efficient fine-tuning (LoRA), and processing complex computer vision tasks.

### Storage and Scaling
* **Amazon Elastic Block Store (EBS):** EC2 instances rely on EBS for persistent block-level storage. These act like physical hard drives but exist over the network. You can choose Solid State Drives (gp3 for general use, io2 for high IOPS) or Hard Disk Drives (st1 for large sequential workloads).
* **Auto Scaling Groups (ASG):** This feature automatically adjusts the number of running EC2 instances based on CPU utilization or network traffic, ensuring high availability during peak usage and reducing costs during idle periods.

## 2. Amazon Simple Storage Service (S3)

### Architectural Foundation
Amazon S3 is a highly distributed object storage system. It abandons the traditional file system hierarchy (directories and nested folders). Instead, data is stored in a flat namespace called a "Bucket." Each file is an "Object" identified by a unique "Key" (a string that acts like a filepath but is functionally just a unique identifier). 

### Data Engineering and Analytics Integration
S3 serves as the foundation for modern cloud data lakes. 
* **Optimized Formats:** While it can store raw formats like CSV or tab-separated datasets, it is highly optimized for columnar storage formats like PyArrow/Parquet. 
* **Data Partitioning:** By structuring S3 Keys logically (e.g., `s3://my-bucket/dataset/year=2026/month=09/data.parquet`), analytical tools can scan only the relevant partitions, drastically reducing query time and costs.
* **Multipart Uploads:** For transferring massive datasets (such as hundreds of thousands of aerial survey images), S3 utilizes multipart uploads, breaking the file into smaller chunks that upload in parallel.

### Security and Lifecycle Management
* **Block Public Access:** S3 provides account-level and bucket-level switches to entirely block public internet access, protecting against accidental data leaks.
* **Pre-signed URLs:** Allows you to generate a temporary, time-limited web link to grant a user or application secure access to a specific object without making the bucket public.
* **Lifecycle Policies:** Automated rules that transition data to cheaper storage tiers (like Glacier) or delete objects after a specified number of days, reducing the overhead of manual data management.

## 3. AWS Networking (Amazon VPC)

### Architectural Foundation
The Virtual Private Cloud (VPC) is a logically isolated section of the AWS cloud where you define the entire virtual network topology. It relies on software-defined networking to control the flow of packets.

### Traffic Flow and Subnet Architecture
A standard production VPC is divided into tiers:
* **Public Subnets:** These contain resources that must be reachable from the internet (e.g., Application Load Balancers, Bastion Hosts). They route external traffic through an **Internet Gateway (IGW)**.
* **Private Subnets:** These house the application logic, container clusters (like Minikube/Kubernetes deployments), and databases. They have no direct inbound path from the internet. 
* **NAT Gateways:** Placed in the public subnet, a Network Address Translation (NAT) Gateway allows resources in the private subnet to initiate outbound connections (e.g., pulling Docker images from a registry or installing Python packages via the AWS Command Line Interface) while strictly blocking unsolicited inbound traffic.

### Multi-Layer Security
* **Route Tables:** Act as a map, directing network traffic based on destination IP addresses. You must explicitly route subnet traffic to the IGW or NAT Gateway.
* **Security Groups:** Stateful firewalls attached to individual EC2 instances or database network interfaces. "Stateful" means if you allow an incoming request on port 443, the return traffic is automatically allowed.
* **Network ACLs:** Stateless firewalls attached to the subnet boundaries. You must explicitly define rules for both inbound and outbound traffic.

## 4. AWS Identity and Access Management (IAM)

### Architectural Foundation
IAM controls authentication (who is the entity) and authorization (what is the entity allowed to do). It is a global service that applies to all AWS regions simultaneously.

### The Policy Engine
Authorization in AWS is governed by JSON-formatted Policy Documents. Every API call made to AWS is evaluated against these policies. A policy consists of statements detailing:
* **Effect:** Allow or Deny (Explicit Deny always overrides an Allow).
* **Action:** The specific API call (e.g., `s3:GetObject`, `ec2:StartInstances`).
* **Resource:** The specific Amazon Resource Name (ARN) the action applies to (e.g., `arn:aws:s3:::my-dataset-bucket/*`).
* **Condition:** When the action is valid (e.g., only if the user has multi-factor authentication enabled, or only from a specific IP address).

### IAM Roles and Secure Workflows
Hardcoding AWS Access Keys inside source code or configuration files is a critical security vulnerability. 
* **EC2 Instance Profiles:** Instead of keys, you create an IAM Role with a policy (e.g., allowing read access to a specific S3 bucket) and attach that Role to the EC2 instance. 
* Any application running on that instance (such as a Python script running data modeling processes) automatically inherits those permissions via temporary, auto-rotating credentials generated by the instance metadata service.

## 5. Amazon DynamoDB

### Architectural Foundation
DynamoDB is a fully managed, serverless NoSQL database. Under the hood, data is distributed across multiple physical storage partitions automatically based on the table's Partition Key. It is highly optimized for read/write speeds, offering single-digit millisecond latency.

### Data Modeling (NoSQL)
Unlike relational databases, DynamoDB does not support table joins. Data must be modeled based entirely on the application's access patterns (how the data will be queried).
* **Composite Keys:** A table typically uses a Partition Key (used to locate the physical server hosting the data) and a Sort Key (used to order the data within that partition).
* **Denormalization:** Because there are no joins, related data is often stored together in the same item, or duplicated across items, to allow retrieving all necessary data in a single query.
* **Use Cases:** Ideal for extremely high-throughput, low-latency workloads such as managing strict execution state trackers, recording real-time competition leaderboard submissions, or storing rapid stream-processing metadata.

### Advanced Capabilities
* **Global Secondary Indexes (GSIs):** Allow you to query the table using a completely different attribute as the partition key, offering flexibility in how data is retrieved.
* **DynamoDB Streams:** A time-ordered sequence of item-level modifications (inserts, updates, deletes) in a table. This stream can trigger external compute functions instantly when data changes.

## 6. Amazon Relational Database Service (RDS) and Aurora

### Architectural Foundation
RDS removes the administrative burden of running a traditional relational database (like PostgreSQL, MySQL, or SQL Server). AWS manages the underlying EC2 instance, the EBS storage volumes, OS patching, database software updates, and automated snapshots.

### Amazon Aurora
Aurora is a specialized database engine built by AWS that is fully compatible with PostgreSQL and MySQL but features a cloud-native distributed storage subsystem. 
* Aurora automatically replicates data six times across three different Availability Zones, providing massive fault tolerance and read performance that vastly exceeds standard open-source databases.

### Relational Data Modeling and ACID Compliance
RDS and Aurora are strictly structured. 
* **Schema Design:** Data is organized into tables with strict column types. This allows for complex analytical SQL queries. 
* **Table Joins:** Highly effective for querying heterogeneous data sources, such as executing complex relational joins between large municipal operational datasets and external localized weather datasets to analyze correlations.
* **ACID Transactions:** Ensures Atomicity, Consistency, Isolation, and Durability. This guarantees that complex, multi-step database transactions (like financial ledgers or inventory management) succeed entirely or fail entirely, preventing corrupted or partial data states.
