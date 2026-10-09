useradd is a low level command minimlist by default . It does not create a home directory or prompt for a password unless specifc flags are provided.

adduser is a high level command , user friendly and interactive by default . It creates a home directory and prompts for a password.

adduser is prefered because it reduces manual stup and precents accidental creation of headless users without home directories.

devops_testuser:x:1006:1006:,,,:/home/devops_testuser:/bin/bash
