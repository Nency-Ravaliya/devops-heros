#!/bin/bash

# Create the original file
echo "Hello Linux" > original.txt

# Create a soft (symbolic) link
ln -s original.txt soft_link.txt

# Create a hard link
ln original.txt hard_link.txt

# Display inode numbers and file information
ls -li original.txt soft_link.txt hard_link.txt

# Deleting the original file
rm original.txt

# Trying to access the soft link
# This will fail because the original file has been deleted
cat soft_link.txt

# Accessing the hard link
# This will still work because it points to the same inode
cat hard_link.txt

# Delete the soft and hard links
rm soft_link.txt hard_link.txt

