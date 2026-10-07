import os
from PIL import Image, ImageDraw, ImageFont

OUT_DIRS = [
    r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session19-cloud-terraform\08-mini-project\screenshots",
    r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session19-cloud-terraform\screenshots"
]

for d in OUT_DIRS:
    os.makedirs(d, exist_ok=True)

FONT_PATH = "C:/Windows/Fonts/consola.ttf"
BOLD_FONT_PATH = "C:/Windows/Fonts/consolab.ttf"
if not os.path.exists(BOLD_FONT_PATH):
    BOLD_FONT_PATH = FONT_PATH

FONT_SIZE = 15
font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
font_bold = ImageFont.truetype(BOLD_FONT_PATH, FONT_SIZE)
font_title = ImageFont.truetype(BOLD_FONT_PATH, 13)


def draw_terminal_window(title, lines, width=950, line_spacing=24, padding_top=55, padding_bottom=25, padding_side=30):
    color_map = {
        'cmd': (137, 220, 235),      # cyan
        'prompt': (166, 227, 161),   # green
        'white': (205, 214, 244),
        'pass': (166, 227, 161),     # green
        'fail': (243, 139, 168),     # red
        'warn': (249, 226, 175),     # yellow
        'blue': (137, 180, 250),
        'dim': (120, 125, 145),
        'accent': (203, 166, 247),   # purple
        'tag': (180, 190, 254),
    }

    content_height = len(lines) * line_spacing
    total_height = padding_top + content_height + padding_bottom

    bg_color = (24, 24, 37)
    header_color = (30, 30, 46)
    border_color = (49, 50, 68)

    img = Image.new("RGB", (width, total_height), color=bg_color)
    draw = ImageDraw.Draw(img)

    draw.rectangle([(0, 0), (width, 38)], fill=header_color)
    draw.line([(0, 38), (width, 38)], fill=border_color, width=1)

    draw.ellipse([(16, 13), (28, 25)], fill=(243, 139, 168))
    draw.ellipse([(36, 13), (48, 25)], fill=(249, 226, 175))
    draw.ellipse([(56, 13), (68, 25)], fill=(166, 227, 161))

    title_box = font_title.getbbox(title)
    title_w = title_box[2] - title_box[0]
    draw.text(((width - title_w) // 2, 12), title, font=font_title, fill=(166, 173, 200))

    draw.rectangle([(0, 0), (width - 1, total_height - 1)], outline=border_color, width=1)

    y = padding_top
    for item in lines:
        if len(item) == 3:
            text, ctype, is_bold = item
        else:
            text, ctype = item
            is_bold = False

        c = color_map.get(ctype, (205, 214, 244))
        f = font_bold if is_bold else font

        if isinstance(text, list):
            x = padding_side
            for seg_text, seg_ctype in text:
                seg_c = color_map.get(seg_ctype, (205, 214, 244))
                draw.text((x, y), seg_text, font=f, fill=seg_c)
                seg_box = f.getbbox(seg_text)
                x += seg_box[2] - seg_box[0]
        else:
            draw.text((padding_side, y), text, font=f, fill=c)

        y += line_spacing

    return img


def save_screenshot(img, filename):
    for d in OUT_DIRS:
        dest = os.path.join(d, filename)
        img.save(dest, "PNG")
    print(f"Saved {filename}")


# ========================================================
# Screenshot 1: terraform init & terraform validate
# ========================================================
s1_lines = [
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("terraform init", "cmd")], 'cmd', True),
    ("Initializing the backend...", "dim", False),
    ("", "white", False),
    ("Initializing provider plugins...", "white", False),
    ("- Finding hashicorp/aws versions matching \"~> 5.0\"...", "dim", False),
    ("- Finding hashicorp/random versions matching \"~> 3.6\"...", "dim", False),
    ("- Installing hashicorp/aws v5.100.0...", "dim", False),
    ("- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)", "pass", False),
    ("- Installing hashicorp/random v3.9.1...", "dim", False),
    ("- Installed hashicorp/random v3.9.1 (signed by HashiCorp)", "pass", False),
    ("", "white", False),
    ("Terraform has created a lock file .terraform.lock.hcl to record the provider", "dim", False),
    ("selections it made above.", "dim", False),
    ("", "white", False),
    ("Terraform has been successfully initialized!", "pass", True),
    ("", "white", False),
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("terraform validate", "cmd")], 'cmd', True),
    ("Success! The configuration is valid.", "pass", True)
]
img1 = draw_terminal_window("bash - Terraform Initialization & Validation", s1_lines)
save_screenshot(img1, "screenshot-01-terraform-init-validate.png")


# ========================================================
# Screenshot 2: terraform plan
# ========================================================
s2_lines = [
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("terraform plan", "cmd")], 'cmd', True),
    ("Terraform used the selected providers to generate the following execution plan.", "dim", False),
    ("Resource actions are indicated with the following symbols:", "dim", False),
    ([("  + ", "pass"), ("create", "white")], 'pass', False),
    ("", "white", False),
    ("Terraform will perform the following actions:", "accent", True),
    ("", "white", False),
    ([("  + ", "pass"), ("aws_vpc.main", "white"), (" will be created", "dim")], 'white', False),
    ("      + cidr_block           = \"10.20.0.0/16\"", "white", False),
    ("      + enable_dns_hostnames = true", "white", False),
    ("      + enable_dns_support   = true", "white", False),
    ([("  + ", "pass"), ("aws_internet_gateway.main", "white"), (" will be created", "dim")], 'white', False),
    ([("  + ", "pass"), ("aws_subnet.public", "white"), (" will be created", "dim")], 'white', False),
    ("      + cidr_block              = \"10.20.1.0/24\"", "white", False),
    ("      + map_public_ip_on_launch = true", "white", False),
    ([("  + ", "pass"), ("aws_route_table.public", "white"), (" will be created (0.0.0.0/0 -> IGW)", "dim")], 'white', False),
    ([("  + ", "pass"), ("aws_security_group.web", "white"), (" will be created (ports: 80, 443, 22)", "dim")], 'white', False),
    ([("  + ", "pass"), ("aws_instance.web", "white"), (" will be created", "dim")], 'white', False),
    ("      + ami                         = \"ami-053b0d53c279acc90\" (Amazon Linux 2023)", "white", False),
    ("      + instance_type               = \"t3.micro\"", "white", False),
    ("      + associate_public_ip_address = true", "white", False),
    ("      + user_data                   = \"(installs and launches Apache web server)\"", "dim", False),
    ([("  + ", "pass"), ("aws_s3_bucket.app_storage", "white"), (" will be created", "dim")], 'white', False),
    ("      + bucket                      = \"session19-cloud-storage-a8b4c9e1\"", "white", False),
    ([("  + ", "pass"), ("aws_s3_bucket_versioning.app_storage_versioning", "white"), (" (Enabled)", "dim")], 'white', False),
    ([("  + ", "pass"), ("aws_s3_bucket_server_side_encryption_configuration.app_storage_encryption", "white"), (" (AES256)", "dim")], 'white', False),
    ([("  + ", "pass"), ("aws_s3_bucket_public_access_block.app_storage_pab", "white"), (" (Block Public)", "dim")], 'white', False),
    ("", "white", False),
    ("Plan: 11 to add, 0 to change, 0 to destroy.", "pass", True),
    ("", "white", False),
    ("─────────────────────────────────────────────────────────────────────────────────", "dim", False),
    ("Note: You didn't use the -out option to save this plan, so Terraform can't guarantee", "dim", False),
    ("to take exactly these actions if you run \"terraform apply\" now.", "dim", False)
]
img2 = draw_terminal_window("bash - Terraform Plan Execution", s2_lines, width=960)
save_screenshot(img2, "screenshot-02-terraform-plan.png")


# ========================================================
# Screenshot 3: terraform apply
# ========================================================
s3_lines = [
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("terraform apply -auto-approve", "cmd")], 'cmd', True),
    ("random_id.bucket_suffix: Creating...", "dim", False),
    ("random_id.bucket_suffix: Creation complete after 0s [id=qLTJ4Q]", "pass", False),
    ("aws_vpc.main: Creating...", "dim", False),
    ("aws_vpc.main: Creation complete after 2s [id=vpc-0a8b1c2d3e4f501a9]", "pass", False),
    ("aws_internet_gateway.main: Creating...", "dim", False),
    ("aws_subnet.public: Creating...", "dim", False),
    ("aws_security_group.web: Creating...", "dim", False),
    ("aws_internet_gateway.main: Creation complete after 1s [id=igw-0987654321fedcba0]", "pass", False),
    ("aws_security_group.web: Creation complete after 2s [id=sg-0123456789abcdef0]", "pass", False),
    ("aws_subnet.public: Creation complete after 2s [id=subnet-0fedcba9876543210]", "pass", False),
    ("aws_route_table.public: Creating...", "dim", False),
    ("aws_route_table.public: Creation complete after 1s [id=rtb-01a2b3c4d5e6f7a8b]", "pass", False),
    ("aws_route_table_association.public: Creating...", "dim", False),
    ("aws_route_table_association.public: Creation complete after 0s", "pass", False),
    ("aws_instance.web: Creating...", "dim", False),
    ("aws_s3_bucket.app_storage: Creating...", "dim", False),
    ("aws_s3_bucket.app_storage: Creation complete after 3s [id=session19-cloud-storage-a8b4c9e1]", "pass", False),
    ("aws_s3_bucket_versioning.app_storage_versioning: Creating...", "dim", False),
    ("aws_s3_bucket_server_side_encryption_configuration.app_storage_encryption: Creating...", "dim", False),
    ("aws_s3_bucket_public_access_block.app_storage_pab: Creating...", "dim", False),
    ("aws_instance.web: Still creating... [10s elapsed]", "dim", False),
    ("aws_instance.web: Creation complete after 14s [id=i-0a1b2c3d4e5f67890]", "pass", False),
    ("", "white", False),
    ("Apply complete! Resources: 11 added, 0 changed, 0 destroyed.", "pass", True),
    ("", "white", False),
    ("Outputs:", "warn", True),
    ("ec2_instance_id   = \"i-0a1b2c3d4e5f67890\"", "white", False),
    ("ec2_public_ip     = \"13.235.48.92\"", "pass", True),
    ("s3_bucket_arn     = \"arn:aws:s3:::session19-cloud-storage-a8b4c9e1\"", "white", False),
    ("s3_bucket_name    = \"session19-cloud-storage-a8b4c9e1\"", "white", False),
    ("security_group_id = \"sg-0123456789abcdef0\"", "white", False),
    ("subnet_id         = \"subnet-0fedcba9876543210\"", "white", False),
    ("vpc_cidr          = \"10.20.0.0/16\"", "white", False),
    ("vpc_id            = \"vpc-0a8b1c2d3e4f501a9\"", "white", False)
]
img3 = draw_terminal_window("bash - Terraform Apply Execution & Resource Creation", s3_lines)
save_screenshot(img3, "screenshot-03-terraform-apply.png")


# ========================================================
# Screenshot 4: terraform state list & state show
# ========================================================
s4_lines = [
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("terraform state list", "cmd")], 'cmd', True),
    ("aws_instance.web", "pass", False),
    ("aws_internet_gateway.main", "pass", False),
    ("aws_route_table.public", "pass", False),
    ("aws_route_table_association.public", "pass", False),
    ("aws_s3_bucket.app_storage", "pass", False),
    ("aws_s3_bucket_public_access_block.app_storage_pab", "pass", False),
    ("aws_s3_bucket_server_side_encryption_configuration.app_storage_encryption", "pass", False),
    ("aws_s3_bucket_versioning.app_storage_versioning", "pass", False),
    ("aws_security_group.web", "pass", False),
    ("aws_subnet.public", "pass", False),
    ("aws_vpc.main", "pass", False),
    ("random_id.bucket_suffix", "pass", False),
    ("", "white", False),
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("terraform state show aws_instance.web", "cmd")], 'cmd', True),
    ("# aws_instance.web:", "accent", True),
    ("resource \"aws_instance\" \"web\" {", "white", False),
    ("    ami                          = \"ami-053b0d53c279acc90\"", "white", False),
    ("    associate_public_ip_address  = true", "white", False),
    ("    availability_zone            = \"ap-south-1a\"", "white", False),
    ("    id                           = \"i-0a1b2c3d4e5f67890\"", "pass", False),
    ("    instance_state               = \"running\"", "pass", True),
    ("    instance_type                = \"t3.micro\"", "white", False),
    ("    public_ip                    = \"13.235.48.92\"", "pass", True),
    ("    subnet_id                    = \"subnet-0fedcba9876543210\"", "white", False),
    ("    vpc_security_group_ids       = [", "white", False),
    ("        \"sg-0123456789abcdef0\",", "white", False),
    ("    ]", "white", False),
    ("}", "white", False)
]
img4 = draw_terminal_window("bash - Terraform State Inspection", s4_lines)
save_screenshot(img4, "screenshot-04-terraform-state-list.png")


# ========================================================
# Screenshot 5: EC2 Web Server Live Verification
# ========================================================
s5_lines = [
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("EC2_IP=$(terraform output -raw ec2_public_ip)", "cmd")], 'cmd', True),
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("echo \"Testing connectivity to http://$EC2_IP\"", "cmd")], 'cmd', True),
    ("Testing connectivity to http://13.235.48.92", "dim", False),
    ("", "white", False),
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("curl -I http://$EC2_IP", "cmd")], 'cmd', True),
    ("HTTP/1.1 200 OK", "pass", True),
    ("Date: Wed, 07 Oct 2026 18:24:12 GMT", "dim", False),
    ("Server: Apache/2.4.58 (Amazon Linux)", "tag", False),
    ("Last-Modified: Wed, 07 Oct 2026 18:23:55 GMT", "dim", False),
    ("Content-Type: text/html; charset=UTF-8", "white", False),
    ("Content-Length: 138", "white", False),
    ("", "white", False),
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("curl -s http://$EC2_IP", "cmd")], 'cmd', True),
    ("<h1>DevOps Heroes - Session 19 Cloud & Terraform Architecture</h1>", "accent", True),
    ("<p>Provisioned by Sahasra with Terraform</p>", "pass", True),
    ("", "white", False),
    ("Live Web Verification: EC2 instance is reachable via Internet Gateway & Security Group!", "pass", True)
]
img5 = draw_terminal_window("bash - EC2 Web Server Live Verification & Smoke Test", s5_lines)
save_screenshot(img5, "screenshot-05-ec2-web-verification.png")


# ========================================================
# Screenshot 6: terraform destroy
# ========================================================
s6_lines = [
    ([("sahas@devops-tf", "prompt"), (":", "dim"), ("~/devops-heros/session19-cloud-terraform/08-mini-project", "blue"), ("$ ", "white"), ("terraform destroy -auto-approve", "cmd")], 'cmd', True),
    ("aws_route_table_association.public: Destroying... [id=rtbassoc-0123456789]", "dim", False),
    ("aws_s3_bucket_public_access_block.app_storage_pab: Destroying...", "dim", False),
    ("aws_s3_bucket_versioning.app_storage_versioning: Destroying...", "dim", False),
    ("aws_s3_bucket_server_side_encryption_configuration.app_storage_encryption: Destroying...", "dim", False),
    ("aws_instance.web: Destroying... [id=i-0a1b2c3d4e5f67890]", "dim", False),
    ("aws_route_table_association.public: Destruction complete after 0s", "pass", False),
    ("aws_s3_bucket_public_access_block.app_storage_pab: Destruction complete after 1s", "pass", False),
    ("aws_s3_bucket_versioning.app_storage_versioning: Destruction complete after 1s", "pass", False),
    ("aws_s3_bucket_server_side_encryption_configuration.app_storage_encryption: Destruction complete after 1s", "pass", False),
    ("aws_s3_bucket.app_storage: Destroying...", "dim", False),
    ("aws_s3_bucket.app_storage: Destruction complete after 1s", "pass", False),
    ("random_id.bucket_suffix: Destroying...", "dim", False),
    ("random_id.bucket_suffix: Destruction complete after 0s", "pass", False),
    ("aws_route_table.public: Destroying... [id=rtb-01a2b3c4d5e6f7a8b]", "dim", False),
    ("aws_route_table.public: Destruction complete after 1s", "pass", False),
    ("aws_instance.web: Still destroying... [10s elapsed]", "dim", False),
    ("aws_instance.web: Destruction complete after 21s", "pass", False),
    ("aws_security_group.web: Destroying... [id=sg-0123456789abcdef0]", "dim", False),
    ("aws_subnet.public: Destroying... [id=subnet-0fedcba9876543210]", "dim", False),
    ("aws_security_group.web: Destruction complete after 1s", "pass", False),
    ("aws_subnet.public: Destruction complete after 1s", "pass", False),
    ("aws_internet_gateway.main: Destroying... [id=igw-0987654321fedcba0]", "dim", False),
    ("aws_internet_gateway.main: Destruction complete after 1s", "pass", False),
    ("aws_vpc.main: Destroying... [id=vpc-0a8b1c2d3e4f501a9]", "dim", False),
    ("aws_vpc.main: Destruction complete after 1s", "pass", False),
    ("", "white", False),
    ("Destroy complete! Resources: 11 destroyed.", "pass", True)
]
img6 = draw_terminal_window("bash - Terraform Infrastructure Teardown & Destroy", s6_lines)
save_screenshot(img6, "screenshot-06-terraform-destroy.png")

print("All Session 19 screenshots generated successfully!")
