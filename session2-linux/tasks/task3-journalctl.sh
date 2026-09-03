#!/bin/bash

# View system logs
journalctl -n 20

# View logs for a specific service
journalctl -u ssh -n 20