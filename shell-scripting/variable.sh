#!/bin/bash

[ -f variable.log ] && cat variable.log

current_time=$(date "+%Y-%m-%d %H:%M:%S")

echo "### File over-write successfull , timed : $current_time" > variable.log

cat variable.log
