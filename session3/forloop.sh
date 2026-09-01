#!/bin/bash

for i in {1..5}
do 
  echo "This is the iteration number: $i"
done

# print excluding 5

# way-1
for i in {1..4}
do
  echo "This is the iteration number: $i"
done

# way-2
for i in {1..5}
do
  if [ $i -eq 5 ]; then
    continue
  fi
  echo "This is the iteration number: $i"
done

# way-3
for i in {1..5}
do
  if [ $i -ne 5 ]; then
    echo "This is the iteration number: $i"
  fi
done