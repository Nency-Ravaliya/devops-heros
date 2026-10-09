#!/bin/bash

# Check the location of adduser
which adduser

# Check the location of useradd
which useradd

# Display help for adduser
adduser --help

# Display help for useradd
useradd --help

# Create a test user using adduser
sudo adduser linux_test_user

# Verify that the user was created
id linux_test_user

# Display the user's account information
getent passwd linux_test_user
