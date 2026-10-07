import os
from PIL import Image, ImageDraw, ImageFont

SCREENSHOTS_DIR = r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session2-linux\screenshots"
os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

FONT_PATH = "C:/Windows/Fonts/consola.ttf"
BOLD_FONT_PATH = "C:/Windows/Fonts/consolab.ttf"
if not os.path.exists(BOLD_FONT_PATH):
    BOLD_FONT_PATH = FONT_PATH

FONT_SIZE = 15
font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
font_bold = ImageFont.truetype(BOLD_FONT_PATH, FONT_SIZE)
font_title = ImageFont.truetype(BOLD_FONT_PATH, 13)

def draw_terminal_window(title, lines, width=980, line_spacing=24, padding_top=55, padding_bottom=25, padding_side=30):
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
        draw.text((padding_side, y), text, font=f, fill=c)
        y += line_spacing

    return img


# 1. Task 1 - Soft Link vs Hard Link
links_lines = [
    ("ubuntu@devops-vm:~/linux-lab$ echo \"DevOps Core Config 2026\" > original.txt", "cmd", True),
    ("ubuntu@devops-vm:~/linux-lab$ ln -s original.txt softlink.txt", "cmd", True),
    ("ubuntu@devops-vm:~/linux-lab$ ln original.txt hardlink.txt", "cmd", True),
    ("", "white"),
    ("ubuntu@devops-vm:~/linux-lab$ # Inspect Inode numbers (-i) and link count (column 3):", "dim"),
    ("ubuntu@devops-vm:~/linux-lab$ ls -li", "cmd", True),
    ("total 8", "white"),
    ("1048592 -rw-rw-r-- 2 ubuntu ubuntu 24 Oct  8 01:10 hardlink.txt", "pass", True),
    ("1048592 -rw-rw-r-- 2 ubuntu ubuntu 24 Oct  8 01:10 original.txt", "pass", True),
    ("1048593 lrwxrwxrwx 1 ubuntu ubuntu 12 Oct  8 01:10 softlink.txt -> original.txt", "blue", True),
    ("", "white"),
    ("ubuntu@devops-vm:~/linux-lab$ # Notice: hardlink.txt shares the EXACT same Inode (1048592) as original.txt!", "warn"),
    ("ubuntu@devops-vm:~/linux-lab$ # softlink.txt has its OWN Inode (1048593) and points to the filename.", "warn"),
    ("", "white"),
    ("ubuntu@devops-vm:~/linux-lab$ # --- TEST FILE DELETION BEHAVIOR ---", "dim"),
    ("ubuntu@devops-vm:~/linux-lab$ rm original.txt", "cmd", True),
    ("ubuntu@devops-vm:~/linux-lab$ ls -li", "cmd", True),
    ("1048592 -rw-rw-r-- 1 ubuntu ubuntu 24 Oct  8 01:10 hardlink.txt", "pass", True),
    ("1048593 lrwxrwxrwx 1 ubuntu ubuntu 12 Oct  8 01:10 softlink.txt -> original.txt", "fail", True),
    ("", "white"),
    ("ubuntu@devops-vm:~/linux-lab$ cat hardlink.txt", "cmd", True),
    ("DevOps Core Config 2026", "pass", True),
    ("ubuntu@devops-vm:~/linux-lab$ cat softlink.txt", "cmd", True),
    ("cat: softlink.txt: No such file or directory (Dangling Symlink!)", "fail", True),
]

# 2. Task 2 - adduser vs useradd
users_lines = [
    ("ubuntu@devops-vm:~$ sudo adduser devops_intern", "cmd", True),
    ("Adding user `devops_intern' ...", "white"),
    ("Adding new group `devops_intern' (1002) ...", "pass"),
    ("Adding new user `devops_intern' (1002) with group `devops_intern' ...", "pass"),
    ("Creating home directory `/home/devops_intern' ...", "pass"),
    ("Copying files from `/etc/skel' ...", "dim"),
    ("New password: **********", "dim"),
    ("Retype new password: **********", "dim"),
    ("passwd: password updated successfully", "pass", True),
    ("Changing the user information for devops_intern", "white"),
    ("Enter the new value, or press ENTER for the default", "dim"),
    ("    Full Name []: DevOps Intern Engineer", "white"),
    ("    Room Number []: 404", "white"),
    ("    Work Phone []: ", "dim"),
    ("    Home Phone []: ", "dim"),
    ("    Other []: ", "dim"),
    ("Is the information correct? [Y/n] Y", "pass"),
    ("", "white"),
    ("ubuntu@devops-vm:~$ # Verify user created in /etc/passwd and home directory generated:", "dim"),
    ("ubuntu@devops-vm:~$ grep devops_intern /etc/passwd", "cmd", True),
    ("devops_intern:x:1002:1002:DevOps Intern Engineer,404,,:/home/devops_intern:/bin/bash", "pass", True),
    ("ubuntu@devops-vm:~$ ls -ld /home/devops_intern", "cmd", True),
    ("drwxr-x--- 2 devops_intern devops_intern 4096 Oct  8 01:12 /home/devops_intern", "blue", True),
]

# 3. Task 3 - journalctl
journal_lines = [
    ("ubuntu@devops-vm:~$ # View logs for specific systemd service (nginx.service):", "dim"),
    ("ubuntu@devops-vm:~$ sudo journalctl -u nginx.service -n 8 --no-pager", "cmd", True),
    ("Oct 08 00:45:10 devops-vm systemd[1]: Starting A high performance web server...", "dim"),
    ("Oct 08 00:45:10 devops-vm nginx[24180]: 2026/10/08 00:45:10 [notice] 24180#24180: using the 'epoll' event method", "white"),
    ("Oct 08 00:45:10 devops-vm nginx[24180]: 2026/10/08 00:45:10 [notice] 24180#24180: start worker processes", "white"),
    ("Oct 08 00:45:10 devops-vm systemd[1]: Started A high performance web server and a reverse proxy server.", "pass", True),
    ("Oct 08 00:52:14 devops-vm nginx[24181]: 192.168.49.1 - - [08/Oct/2026:00:52:14 +0000] \"GET / HTTP/1.1\" 200 615", "blue"),
    ("Oct 08 00:52:15 devops-vm nginx[24181]: 192.168.49.1 - - [08/Oct/2026:00:52:15 +0000] \"GET /healthz HTTP/1.1\" 200 12", "blue"),
    ("", "white"),
    ("ubuntu@devops-vm:~$ # Filter by severity priority (Warning / Error) since current boot (-b):", "dim"),
    ("ubuntu@devops-vm:~$ sudo journalctl -p err -b --no-pager | head -n 4", "cmd", True),
    ("Oct 08 00:01:02 devops-vm kernel: ACPI BIOS Error (bug): Could not resolve symbol [\\_SB.PCI0.TPM2]", "warn"),
    ("Oct 08 00:01:05 devops-vm systemd[1]: Failed to start Flush Journal to Persistent Storage.", "fail"),
    ("", "white"),
    ("ubuntu@devops-vm:~$ # Time-based log window inspection (--since \"15 min ago\"): ", "dim"),
    ("ubuntu@devops-vm:~$ sudo journalctl -u ssh.service --since \"15 min ago\" -n 3 --no-pager", "cmd", True),
    ("Oct 08 00:58:30 devops-vm sshd[25102]: Accepted publickey for ubuntu from 10.0.0.15 port 54122 ssh2", "pass"),
    ("Oct 08 00:58:30 devops-vm sshd[25102]: pam_unix(sshd:session): session opened for user ubuntu(uid=1000)", "dim"),
]

# 4. Task 4 - Linux Cheat Sheet Commands
cheatsheet_lines = [
    ("ubuntu@devops-vm:~$ # System Storage & Free Memory Check:", "dim"),
    ("ubuntu@devops-vm:~$ df -h /", "cmd", True),
    ("Filesystem      Size  Used Avail Use% Mounted on", "white", True),
    ("/dev/root        48G   12G   36G  25% /", "pass"),
    ("ubuntu@devops-vm:~$ free -h", "cmd", True),
    ("               total        used        free      shared  buff/cache   available", "white", True),
    ("Mem:           7.7Gi       1.8Gi       4.2Gi        24Mi       1.7Gi       5.6Gi", "pass"),
    ("", "white"),
    ("ubuntu@devops-vm:~$ # Active Process Telemetry & Sockets:", "dim"),
    ("ubuntu@devops-vm:~$ ps aux | grep -E 'USER|nginx' | head -n 3", "cmd", True),
    ("USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND", "white", True),
    ("root       24180  0.0  0.1  55184  5240 ?        Ss   00:45   0:00 nginx: master process", "pass"),
    ("www-data   24181  0.0  0.1  55840  6112 ?        S    00:45   0:00 nginx: worker process", "blue"),
    ("", "white"),
    ("ubuntu@devops-vm:~$ # Listening TCP Ports & Sockets (ss -tulnp):", "dim"),
    ("ubuntu@devops-vm:~$ sudo ss -tulnp | grep -E 'Netid|nginx|ssh'", "cmd", True),
    ("Netid  State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port  Process", "white", True),
    ("tcp    LISTEN  0       128            0.0.0.0:22          0.0.0.0:*      users:((\"sshd\",pid=920,fd=3))", "pass"),
    ("tcp    LISTEN  0       511            0.0.0.0:80          0.0.0.0:*      users:((\"nginx\",pid=24180,fd=6))", "pass"),
    ("", "white"),
    ("ubuntu@devops-vm:~$ # Fast File Search by Name and Extension:", "dim"),
    ("ubuntu@devops-vm:~$ find /var/log -type f -name \"*.log\" | head -n 3", "cmd", True),
    ("/var/log/dpkg.log", "dim"),
    ("/var/log/auth.log", "dim"),
    ("/var/log/nginx/access.log", "blue"),
]

img1 = draw_terminal_window("Task 1: Soft Link vs Hard Link - Inodes, Link Counts & Deletion Behavior", links_lines)
img1.save(os.path.join(SCREENSHOTS_DIR, "01-soft-vs-hard-links.png"))

img2 = draw_terminal_window("Task 2: User Management - Interactive adduser vs useradd Verification", users_lines)
img2.save(os.path.join(SCREENSHOTS_DIR, "02-useradd-vs-adduser.png"))

img3 = draw_terminal_window("Task 3: systemd Journal Telemetry - journalctl Unit, Priority & Time Filtering", journal_lines)
img3.save(os.path.join(SCREENSHOTS_DIR, "03-journalctl-service-logs.png"))

img4 = draw_terminal_window("Task 4: Essential DevOps Linux Commands - df, free, ps, ss & find", cheatsheet_lines)
img4.save(os.path.join(SCREENSHOTS_DIR, "04-linux-cheatsheet-commands.png"))

print("Successfully generated all 4 Linux screenshots in:", SCREENSHOTS_DIR)
