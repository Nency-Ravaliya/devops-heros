#!/bin/bash

for i in {1..10} # 1 to 10 inclusive
do
  echo "This is iteration number $i"
done

echo "-----------------------------"

for i in {1..10..2} # 1 to 10 inclusive, incrementing by 2
do
  echo "This is iteration number $i"
done

echo "-----------------------------"

for ((i=1; i<=10; i++)) # C-style for loop
do
  echo "This is iteration number $i"
done
