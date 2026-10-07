# 05 - Security Groups

A Security Group is a virtual firewall for supported AWS resources such as EC2.

Think:

> "Who is allowed to talk to my server?"

---

## Example

Suppose we have a web server.

We want:

```text
HTTP  -> allowed
HTTPS -> allowed
SSH   -> restricted
```

A security group contains rules describing allowed traffic.

---

## Example Rules

```text
Inbound

Port 22  -> SSH
Port 80  -> HTTP
Port 443 -> HTTPS
```

For example:

```text
Internet
   |
   +-- HTTP 80  ------> ALLOW
   |
   +-- HTTPS 443 -----> ALLOW
   |
   +-- SSH 22 --------> RESTRICT
```

---

## Security Group vs Route Table

| Component | Question |
|---|---|
| Route Table | Where should traffic go? |
| Security Group | Is this traffic allowed? |

Example:

```text
Packet
  |
  v
Route Table
  |
  v
Security Group
  |
  +-- Allowed -> Resource
  |
  +-- Not allowed -> Blocked
```

This is a simplified mental model for teaching.

---

## Terraform Example

```hcl
resource "aws_security_group" "web" {
  name        = "session19-web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound IPv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## SSH Warning

This is technically possible:

```hcl
cidr_blocks = ["0.0.0.0/0"]
```

for SSH.

But it exposes SSH to the entire internet.

For a real environment, restrict SSH to a trusted source or use a safer access method.

For example:

```text
Your trusted IP
     |
     +---- TCP 22 ----> Server
```

---

## Stateful

Security Groups are stateful.

If an allowed connection is established, the response traffic is automatically allowed as part of that connection.

For beginner understanding:

```text
Allowed request
      |
      v
Server
      |
      v
Response can return
```

---

## Check Security Groups (Optional - You can check directly in dashboard too)

```bash
aws ec2 describe-security-groups \
  --query 'SecurityGroups[].{GroupId:GroupId,Name:GroupName,VpcId:VpcId}'
```

---

## Practice Questions

1. What does a Security Group do?
2. What is an inbound rule?
3. What is an outbound rule?
4. Why is `0.0.0.0/0` risky for SSH?
5. How is a Security Group different from a route table?

Key memory trick:

```text
Route Table = WHERE?
Security Group = ALLOWED?
```
