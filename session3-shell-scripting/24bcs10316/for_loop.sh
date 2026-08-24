#!/bin/bash

# for i in 1 2 3 4 
for i in {1..4}
do
    echo "This is iteration number $i"
done


# Task: print 1 2 3 4 from range 1-5
for i in {1..5}
do
  if [ $i -ne 5 ]; then
    echo "Number is $i"
  fi
done

# or
for i in {1..5}
do
  if [ $i -eq 5 ]; then
    continue
  else
    echo "Now number is $i"
  fi
done