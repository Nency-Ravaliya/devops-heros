# Used for the runs in README.md: every API call goes to a local Moto server, not to AWS.
#   terraform apply -var-file=emulator.tfvars
# Leave this file out (use_emulator defaults to false) to talk to real AWS.
use_emulator      = true
emulator_endpoint = "http://localhost:5000"
