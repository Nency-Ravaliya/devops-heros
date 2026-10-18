# Session 3: Shell scripting

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

Run `bash system-info.sh` and enter a directory such as `/tmp/my-system-report`.
The script stores the date, hostname, username, and report paths in variables.
`read -r -p` asks for input; quotes preserve spaces in the directory name.
`mkdir -p` creates the directory, `touch` creates the file, and `>` writes the
process list. Redirection replaces an existing report; `>>` would append.

Actual commands and output are in `evidence/system-info.txt`.
Try a path containing spaces and an empty input to see why input handling matters.

## Verification

The required script ran in a disposable Ubuntu container and wrote the process report.

No pending local script check.

Command output: [evidence/](evidence/).
